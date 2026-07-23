import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../features/discovery/data/services/discovery_filtering.dart';
import '../../../models/user_model.dart';
import '../../../services/location_privacy_service.dart';
import '../../../services/user_privacy_service.dart';
import '../../constants/constants.dart';
import '../../utils/app_logger.dart';
import '../../utils/distance.dart' as distance;

/// Privacy-aware user search repository that respects user privacy settings
class PrivacyAwareUserSearchRepo {
  static FirebaseFirestore db = firebaseFireStoreInstance;
  static CollectionReference get docRef => db.collection('users');

  static FirebaseAuth firebaseAuth = firebaseAuthInstance;
  static final UserPrivacyService _privacyService = UserPrivacyService();

  static Map items = {};
  static List<UserModel> matches = [];
  static List<UserModel> newmatches = [];
  static List<String> likedByList = [];
  static List userRemoved = [];
  static int swipecount = 0;
  static List<UserModel> users = [];
  static Map likedMap = {};
  static Map disLikedMap = {};

  static Future<void> getAccessItems() async {
    final doc = await db.collection('Item_access').get();
    if (doc.docs.isNotEmpty) {
      items = doc.docs[0].data();
    }
  }

  static Future<int> getSwipedCount(UserModel currentUser) async {
    final querySnapshot = await db
        .collection('users/${currentUser.id}/CheckedUser')
        .where(
          'timestamp',
          isGreaterThan:
              Timestamp.now().toDate().subtract(const Duration(days: 1)),
        )
        .get();

    return querySnapshot.docs.length;
  }

  /// Get privacy-filtered user list for discovery.
  /// [intentFilter] restricts results to users whose `lookingFor` matches.
  /// 'Mixed' users are always included; a 'Mixed' filter shows everyone.
  static Future<List<UserModel>> getUserList(
    UserModel currentUser, {
    String? intentFilter,
  }) async {
    final List<String> checkedUserIds = [];

    try {
      final effectiveIntent = intentFilter ?? currentUser.lookingFor;
      debugPrint('🔍 Getting privacy-aware user list for: ${currentUser.id}');
      debugPrint('🔍 Effective intent filter: $effectiveIntent');

      // Get already checked users (swipes) + existing matches.
      // Doc id is canonical; LikedUser/DislikedUser are legacy field mirrors.
      final snapshot =
          await db.collection('users/${currentUser.id}/CheckedUser').get();
      if (snapshot.docs.isNotEmpty) {
        for (final doc in snapshot.docs) {
          checkedUserIds.add(doc.id);
          final likedUser = doc.data()['LikedUser'];
          final dislikedUser = doc.data()['DislikedUser'];

          if (likedUser != null) {
            checkedUserIds.add(likedUser.toString());
          }
          if (dislikedUser != null) {
            checkedUserIds.add(dislikedUser.toString());
          }
        }
      }

      try {
        final matchesSnap =
            await db.collection('users/${currentUser.id}/Matches').get();
        for (final doc in matchesSnap.docs) {
          checkedUserIds.add(doc.id);
          final matchedId = doc.data()['Matches'];
          if (matchedId != null) {
            checkedUserIds.add(matchedId.toString());
          }
        }
      } on Object catch (e) {
        debugPrint('⚠️ Could not load Matches for exclusion: $e');
      }

      // Deduplicate while preserving list type expected below.
      final List<String> uniqueChecked = checkedUserIds.toSet().toList();
      checkedUserIds
        ..clear()
        ..addAll(uniqueChecked);

      debugPrint('🔍 Querying users with privacy filters...');

      List<UserModel> userList = <UserModel>[];

      // Prefer geo-local candidates first. A bare limit(50) on discoverable
      // users returns an arbitrary global page (often overseas), which the
      // distance filter then wipes to zero.
      final bool hasSeekerLocation =
          currentUser.latitude != null && currentUser.longitude != null;
      if (hasSeekerLocation) {
        final double maxMiles = _maxDistanceMiles(currentUser);
        final List<UserModel> nearby =
            await getUsersNearby(currentUser, maxMiles);
        userList = applyDiscoveryPreferences(
          nearby.where(
            (UserModel u) =>
                u.id != currentUser.id &&
                !checkedUserIds.contains(u.id) &&
                !(u.isBlocked ?? false),
          ),
          currentUser,
          effectiveIntent,
        );
      }

      // Continue broader scans when nearby results are empty *after*
      // preference filters (e.g. wrong gender in the geohash neighborhood).
      if (userList.isEmpty) {
        debugPrint(
          '📋 Nearby empty — scanning discoverable users within max distance',
        );
        userList = applyDiscoveryPreferences(
          await _getPrivacyAwareUsers(currentUser, checkedUserIds),
          currentUser,
          effectiveIntent,
        );
      }

      if (userList.isEmpty) {
        debugPrint(
          '📋 No privacy-aware users found, falling back to traditional search',
        );
        userList = applyDiscoveryPreferences(
          await _getFallbackUsers(currentUser, checkedUserIds),
          currentUser,
          effectiveIntent,
        );
      }

      // Sparse-market recovery: if maxDistance wiped the deck but candidates
      // exist farther away, show the nearest ones so Connect is not empty
      // after matching the only local profile.
      if (userList.isEmpty && hasSeekerLocation) {
        userList = applyDiscoveryPreferences(
          await _getNearestUsersBeyondMaxDistance(
            currentUser,
            checkedUserIds,
            intentFilter: effectiveIntent,
          ),
          currentUser,
          effectiveIntent,
        );
      }

      AppLogger.debug('Privacy-aware list size: ${userList.length}');
      return userList;
    } on Object catch (e) {
      AppLogger.error('Error in privacy-aware getUserList', error: e);
      rethrow;
    }
  }

  /// Gender, intent, and age preferences shared across discovery stages.
  @visibleForTesting
  static List<UserModel> applyDiscoveryPreferences(
    Iterable<UserModel> users,
    UserModel currentUser,
    String? effectiveIntent,
  ) {
    return users
        .where(
          (UserModel u) =>
              DiscoveryFiltering.matchesGenderPreference(u, currentUser) &&
              DiscoveryFiltering.matchesLookingForIntent(u, effectiveIntent) &&
              DiscoveryFiltering.matchesAgePreference(u, currentUser),
        )
        .toList();
  }

  static const int _discoveryPageSize = 50;

  /// Scan enough pages that age-biased overseas cohorts cannot empty the deck.
  static const int _discoveryMaxPages = 20; // up to 1000 docs
  static const int _discoveryTargetKeep = 25;

  static double _maxDistanceMiles(UserModel currentUser) {
    final int value =
        currentUser.maxDistance ?? currentUser.distanceRange ?? 100;
    return value.toDouble();
  }

  /// Equality filter for paginated distance scans.
  ///
  /// Intentionally avoids `orderBy('age')`, which front-loaded young overseas
  /// profiles and caused 50→0 empty decks with a US maxDistance filter.
  /// Firestore orders by document ID when no orderBy is set, which is enough
  /// for startAfterDocument pagination without an extra composite index.
  static Query _buildDiscoverableScanQuery() {
    return docRef.where('isDiscoverable', isEqualTo: true);
  }

  /// Get users using privacy-aware public profiles
  static Future<List<UserModel>> _getPrivacyAwareUsers(
    UserModel currentUser,
    List<String> checkedUserIds,
  ) async {
    final List<UserModel> userList = [];

    try {
      QueryDocumentSnapshot? lastDoc;
      final double maxMiles = _maxDistanceMiles(currentUser);

      for (int page = 0;
          page < _discoveryMaxPages && userList.length < _discoveryTargetKeep;
          page++) {
        Query query = _buildDiscoverableScanQuery().limit(_discoveryPageSize);
        if (lastDoc != null) {
          query = query.startAfterDocument(lastDoc);
        }
        final querySnapshot = await query.get();
        if (querySnapshot.docs.isEmpty) {
          break;
        }
        lastDoc = querySnapshot.docs.last;

        for (var doc in querySnapshot.docs) {
          try {
            final userId = doc.id;

            if (checkedUserIds.contains(userId) || userId == currentUser.id) {
              continue;
            }

            final rawData = doc.data() as Map<String, dynamic>?;
            if (rawData == null || rawData.isEmpty) {
              continue;
            }

            final filteredData = _privacyService.filterForDiscovery(rawData);
            final UserModel user =
                await _createUserModelFromFilteredData(filteredData, userId);

            if (user.latitude != null &&
                user.longitude != null &&
                currentUser.latitude != null &&
                currentUser.longitude != null) {
              final calculatedDistance = distance.calculateDistance(
                currentUser.latitude!,
                currentUser.longitude!,
                user.latitude!,
                user.longitude!,
              );
              user.distanceBW = calculatedDistance.round();

              if (calculatedDistance > maxMiles) {
                continue;
              }
            } else if (currentUser.latitude != null &&
                currentUser.longitude != null) {
              // Seeker has location; skip candidates we cannot place.
              continue;
            }

            if (!user.isDiscoverable) {
              continue;
            }
            if (user.isBlocked ?? false) {
              continue;
            }

            userList.add(user);
            if (userList.length >= _discoveryTargetKeep) {
              break;
            }
          } on Object catch (e) {
            debugPrint(
              '⚠️ Error processing privacy-aware document ${doc.id}: $e',
            );
            continue;
          }
        }

        if (querySnapshot.docs.length < _discoveryPageSize) {
          break;
        }
      }

      return userList;
    } on Object catch (e) {
      debugPrint('❌ Error in _getPrivacyAwareUsers: $e');
      return [];
    }
  }

  /// Fallback to traditional user loading (for users not yet migrated)
  static Future<List<UserModel>> _getFallbackUsers(
    UserModel currentUser,
    List<String> checkedUserIds,
  ) async {
    final List<UserModel> userList = [];

    try {
      QueryDocumentSnapshot? lastDoc;
      final double maxMiles = _maxDistanceMiles(currentUser);

      for (int page = 0;
          page < _discoveryMaxPages && userList.length < _discoveryTargetKeep;
          page++) {
        Query query = _buildDiscoverableScanQuery().limit(_discoveryPageSize);
        if (lastDoc != null) {
          query = query.startAfterDocument(lastDoc);
        }
        final querySnapshot = await query.get();
        debugPrint(
          '📋 Fallback query page $page returned '
          '${querySnapshot.docs.length} documents',
        );
        if (querySnapshot.docs.isEmpty) {
          break;
        }
        lastDoc = querySnapshot.docs.last;

        for (var doc in querySnapshot.docs) {
          try {
            final UserModel temp = UserModel.fromDocument(doc);

            if (checkedUserIds.contains(temp.id)) {
              continue;
            }
            if (temp.id == currentUser.id) {
              continue;
            }

            final double? cLat = currentUser.latitude;
            final double? cLng = currentUser.longitude;
            final double? uLat = temp.latitude;
            final double? uLng = temp.longitude;
            if (cLat == null || cLng == null || uLat == null || uLng == null) {
              continue;
            }

            final calculatedDistance = distance.calculateDistance(
              cLat,
              cLng,
              uLat,
              uLng,
            );
            temp.distanceBW = calculatedDistance.round();

            if (calculatedDistance > maxMiles) {
              continue;
            }

            if (temp.isBlocked ?? false) {
              continue;
            }

            debugPrint(
              '📋 Adding fallback user: ${temp.name} '
              '(lookingFor=${temp.lookingFor}, '
              'gender=${temp.userGender}, '
              'distance=${temp.distanceBW})',
            );
            userList.add(temp);
            if (userList.length >= _discoveryTargetKeep) {
              break;
            }
          } on Object catch (e) {
            debugPrint('⚠️ Error processing fallback document ${doc.id}: $e');
            continue;
          }
        }

        if (querySnapshot.docs.length < _discoveryPageSize) {
          break;
        }
      }

      return userList;
    } on Object catch (e) {
      debugPrint('❌ Error in _getFallbackUsers: $e');
      return [];
    }
  }

  /// When nobody is within [maxDistance], return the nearest discoverable
  /// profiles (still excluding checked/matched) so sparse metros are usable.
  ///
  /// Preserves age / gender / intent preferences while relaxing distance.
  static Future<List<UserModel>> _getNearestUsersBeyondMaxDistance(
    UserModel currentUser,
    List<String> checkedUserIds, {
    String? intentFilter,
    int limit = 15,
  }) async {
    final double? cLat = currentUser.latitude;
    final double? cLng = currentUser.longitude;
    if (cLat == null || cLng == null) return <UserModel>[];

    final List<UserModel> ranked = <UserModel>[];
    QueryDocumentSnapshot? lastDoc;

    for (int page = 0; page < _discoveryMaxPages; page++) {
      Query query = _buildDiscoverableScanQuery().limit(_discoveryPageSize);
      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }
      final querySnapshot = await query.get();
      if (querySnapshot.docs.isEmpty) break;
      lastDoc = querySnapshot.docs.last;

      for (final doc in querySnapshot.docs) {
        try {
          if (doc.id == currentUser.id || checkedUserIds.contains(doc.id)) {
            continue;
          }
          final UserModel temp = UserModel.fromDocument(doc);
          final double? uLat = temp.latitude;
          final double? uLng = temp.longitude;
          if (uLat == null || uLng == null) continue;
          // Skip null-island defaults from incomplete profiles.
          if (uLat == 0.0 && uLng == 0.0) continue;
          if (temp.isBlocked ?? false) continue;
          if (!DiscoveryFiltering.matchesAgePreference(temp, currentUser)) {
            continue;
          }
          if (!DiscoveryFiltering.matchesGenderPreference(temp, currentUser)) {
            continue;
          }
          if (!DiscoveryFiltering.matchesLookingForIntent(
            temp,
            intentFilter,
          )) {
            continue;
          }

          final double miles =
              distance.calculateDistance(cLat, cLng, uLat, uLng);
          temp.distanceBW = miles.round();
          ranked.add(temp);
        } on Object {
          continue;
        }
      }

      if (querySnapshot.docs.length < _discoveryPageSize) break;
    }

    ranked.sort(
      (UserModel a, UserModel b) =>
          (a.distanceBW ?? 1 << 30).compareTo(b.distanceBW ?? 1 << 30),
    );
    return ranked.take(limit).toList();
  }

  /// Create UserModel from privacy-filtered data (public method)
  static Future<UserModel> createUserModelFromFilteredData(
    Map<String, dynamic> data,
    String userId,
  ) async =>
      _createUserModelFromFilteredData(data, userId);

  /// Create UserModel from privacy-filtered data (private implementation)
  static Future<UserModel> _createUserModelFromFilteredData(
    Map<String, dynamic> data,
    String userId,
  ) async {
    // Prefer exact coordinates for distance filtering; GeoHash is a privacy
    // fallback when lat/lng were stripped from public projections.
    double? latitude;
    double? longitude;

    if (data.containsKey('latitude') && data.containsKey('longitude')) {
      latitude = (data['latitude'] as num?)?.toDouble();
      longitude = (data['longitude'] as num?)?.toDouble();
    }
    if ((latitude == null || longitude == null) &&
        data.containsKey('location') &&
        data['location'] is Map) {
      final Map<dynamic, dynamic> loc = data['location'] as Map;
      latitude ??= (loc['latitude'] as num?)?.toDouble();
      longitude ??= (loc['longitude'] as num?)?.toDouble();
    }
    if ((latitude == null || longitude == null) &&
        data['geoHash'] is String &&
        (data['geoHash'] as String).isNotEmpty) {
      final coords =
          LocationPrivacyService.decodeGeoHash(data['geoHash'] as String);
      latitude ??= coords['lat'];
      longitude ??= coords['lng'];
    }

    return UserModel(
      id: userId,
      name: data['name'],
      age: data['age'],
      userGender: data['userGender'],
      living_in: data['living_in'] ?? data['city'],
      job_title: data['job_title'],
      company: data['company'],
      showMyAge: data['showMyAge'] ?? true,
      latitude: latitude,
      longitude: longitude,
      imageUrl: _extractPhotos(data),
      isBlocked: data['isBlocked'] ?? false,
      lookingFor: () {
        final raw = data['lookingFor']?.toString().trim();
        return (raw == null || raw.isEmpty) ? 'Dating' : raw;
      }(),
      bio: data['bio']?.toString(),
      accountStatus: data['accountStatus']?.toString(),
    );
  }

  /// Resolve photo URLs from the multiple field names used across the schema.
  static List<String> _extractPhotos(Map<String, dynamic> data) {
    for (final key in ['photos', 'Pictures', 'imageUrl']) {
      final value = data[key];
      if (value is List && value.isNotEmpty) {
        return List<String>.from(
          value.map((e) => e?.toString() ?? '').where((url) => url.isNotEmpty),
        );
      }
    }
    return [];
  }

  /// Get location-based users using GeoHash (privacy-aware)
  static Future<List<UserModel>> getUsersNearby(
    UserModel currentUser,
    double radiusMiles,
  ) async {
    try {
      if (currentUser.latitude == null || currentUser.longitude == null) {
        return [];
      }

      // Create GeoHash for current user location
      final currentGeoHash = LocationPrivacyService.generateGeoHash(
        currentUser.latitude!,
        currentUser.longitude!,
        LocationPrecision.medium, // Use medium precision for search
      );

      // Get nearby GeoHashes
      final nearbyGeoHashes = LocationPrivacyService.getGeoHashesInRadius(
        currentGeoHash,
        radiusMiles,
      );

      debugPrint('🗺️ Searching ${nearbyGeoHashes.length} GeoHash areas');

      final List<UserModel> nearbyUsers = [];

      // Query users in nearby GeoHash areas
      for (String geoHash in nearbyGeoHashes) {
        try {
          final query = docRef
              .where('geoHash', isEqualTo: geoHash)
              .where('isDiscoverable', isEqualTo: true)
              .limit(20);

          final snapshot = await query.get();

          for (var doc in snapshot.docs) {
            try {
              if (doc.id == currentUser.id) {
                continue;
              }
              final rawData = doc.data() as Map<String, dynamic>?;
              if (rawData == null || rawData.isEmpty) {
                continue;
              }
              final filteredData = _privacyService.filterForDiscovery(rawData);
              final user = await _createUserModelFromFilteredData(
                filteredData,
                doc.id,
              );

              if (user.latitude != null && user.longitude != null) {
                final actualDistance = distance.calculateDistance(
                  currentUser.latitude!,
                  currentUser.longitude!,
                  user.latitude!,
                  user.longitude!,
                );

                if (actualDistance <= radiusMiles) {
                  user.distanceBW = actualDistance.round();
                  nearbyUsers.add(user);
                }
              }
            } on Object catch (e) {
              debugPrint('⚠️ Error processing nearby user ${doc.id}: $e');
              continue;
            }
          }
        } on Object catch (e) {
          debugPrint('⚠️ Error querying GeoHash $geoHash: $e');
          continue;
        }
      }

      debugPrint('🗺️ Found ${nearbyUsers.length} nearby users');
      return nearbyUsers;
    } on Object catch (e) {
      debugPrint('❌ Error in getUsersNearby: $e');
      return [];
    }
  }

  // Keep existing methods for compatibility
  static Future<List<String>> getLikedByList(UserModel currentUser) async {
    final snapshot =
        await docRef.doc(currentUser.id).collection('LikedBy').get();

    final List<String> likedByList = [];
    for (var doc in snapshot.docs) {
      likedByList.add(doc.id);
    }
    return likedByList;
  }

  static Future<List<UserModel>> getMatches(UserModel currentUser) async {
    final snapshot =
        await docRef.doc(currentUser.id).collection('Matches').get();

    final List<UserModel> matchesList = [];
    for (var doc in snapshot.docs) {
      try {
        // Get privacy-filtered data for matches
        final filteredData = await _privacyService.getFilteredUserData(doc.id);
        if (filteredData != null) {
          final user =
              await _createUserModelFromFilteredData(filteredData, doc.id);
          matchesList.add(user);
        }
      } on Object catch (e) {
        debugPrint('⚠️ Error loading match ${doc.id}: $e');
        continue;
      }
    }
    return matchesList;
  }
}
