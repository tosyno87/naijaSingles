import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

      // Get already checked users
      final snapshot =
          await db.collection('users/${currentUser.id}/CheckedUser').get();
      if (snapshot.docs.isNotEmpty) {
        for (final doc in snapshot.docs) {
          final likedUser = doc.data()['LikedUser'];
          final dislikedUser = doc.data()['DislikedUser'];

          if (likedUser != null) {
            checkedUserIds.add(likedUser);
          }
          if (dislikedUser != null) {
            checkedUserIds.add(dislikedUser);
          }
        }
      }

      debugPrint('🔍 Querying users with privacy filters...');

      // Try to get users from public profiles first (privacy-aware)
      List<UserModel> userList =
          await _getPrivacyAwareUsers(currentUser, checkedUserIds);

      // If no privacy-aware users found, fallback to traditional method
      if (userList.isEmpty) {
        debugPrint(
          '📋 No privacy-aware users found, falling back to traditional search',
        );
        userList = await _getFallbackUsers(currentUser, checkedUserIds);
      }

      // Apply intent filtering in-memory (same logic as the unified path).
      if (effectiveIntent != null &&
          effectiveIntent.isNotEmpty &&
          effectiveIntent != 'Mixed') {
        userList = userList
            .where(
              (u) =>
                  u.lookingFor == null ||
                  u.lookingFor == effectiveIntent ||
                  u.lookingFor == 'Mixed',
            )
            .toList();
      }

      AppLogger.debug('Privacy-aware list size: ${userList.length}');
      return userList;
    } on Object catch (e) {
      AppLogger.error('Error in privacy-aware getUserList', error: e);
      rethrow;
    }
  }

  /// Get users using privacy-aware public profiles
  static Future<List<UserModel>> _getPrivacyAwareUsers(
    UserModel currentUser,
    List<String> checkedUserIds,
  ) async {
    final List<UserModel> userList = [];

    try {
      // Get all users (we'll filter by privacy settings)
      final querySnapshot = await _buildPrivacyAwareQuery(currentUser).get();

      for (var doc in querySnapshot.docs) {
        try {
          final userId = doc.id;

          // Skip already checked users
          if (checkedUserIds.contains(userId) || userId == currentUser.id) {
            continue;
          }

          // Use document data already returned by the list query.
          // Re-fetching via getFilteredUserData would hit the stricter
          // per-document `get` rule and fail with permission-denied.
          final rawData = doc.data() as Map<String, dynamic>?;
          if (rawData == null || rawData.isEmpty) {
            continue;
          }

          // Apply default privacy masks (e.g. hide sexualOrientation)
          // while preserving operational fields like lat/lng and photos.
          final filteredData = _privacyService.filterForDiscovery(rawData);

          final UserModel user =
              await _createUserModelFromFilteredData(filteredData, userId);

          // Calculate distance if location is available
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

            // Apply distance filter
            if (calculatedDistance > currentUser.maxDistance!) {
              continue;
            }
          }

          // Apply other filters
          if (!user.isDiscoverable) {
            continue;
          }
          if (user.isBlocked ?? false) {
            continue;
          }

          userList.add(user);
        } on Object catch (e) {
          debugPrint(
            '⚠️ Error processing privacy-aware document ${doc.id}: $e',
          );
          continue;
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
      final querySnapshot = await _buildTraditionalQuery(currentUser).get();
      debugPrint(
        '📋 Fallback query returned ${querySnapshot.docs.length} documents',
      );

      for (var doc in querySnapshot.docs) {
        try {
          final UserModel temp = UserModel.fromDocument(doc);

          final calculatedDistance = distance.calculateDistance(
            currentUser.latitude!,
            currentUser.longitude!,
            temp.latitude!,
            temp.longitude!,
          );
          temp.distanceBW = calculatedDistance.round();

          if (checkedUserIds.contains(temp.id)) {
            continue;
          }

          if (calculatedDistance <= currentUser.maxDistance! &&
              temp.id != currentUser.id &&
              !temp.isBlocked!) {
            debugPrint('📋 Adding fallback user: ${temp.name}');
            userList.add(temp);
          }
        } on Object catch (e) {
          debugPrint('⚠️ Error processing fallback document ${doc.id}: $e');
          continue;
        }
      }

      return userList;
    } on Object catch (e) {
      debugPrint('❌ Error in _getFallbackUsers: $e');
      return [];
    }
  }

  /// Build privacy-aware query
  static Query _buildPrivacyAwareQuery(UserModel currentUser) {
    final Query query = docRef.where('isDiscoverable', isEqualTo: true);

    return query.limit(50);
  }

  /// Build traditional query (fallback)
  static Query _buildTraditionalQuery(UserModel currentUser) {
    Query query = docRef.where('isDiscoverable', isEqualTo: true);

    if (currentUser.ageRange != null) {
      query = query
          .where(
            'age',
            isGreaterThanOrEqualTo: int.parse(currentUser.ageRange!['min']),
          )
          .where(
            'age',
            isLessThanOrEqualTo: int.parse(currentUser.ageRange!['max']),
          )
          .orderBy('age', descending: false);
    }

    return query.limit(50);
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
    // Handle location data based on privacy settings
    double? latitude;
    double? longitude;

    if (data.containsKey('geoHash')) {
      // Use GeoHash for privacy-aware location
      final geoHash = data['geoHash'] as String?;
      if (geoHash != null) {
        final coords = LocationPrivacyService.decodeGeoHash(geoHash);
        latitude = coords['lat'];
        longitude = coords['lng'];
      }
    } else if (data.containsKey('latitude') && data.containsKey('longitude')) {
      // Fallback to exact coordinates if available
      latitude = data['latitude']?.toDouble();
      longitude = data['longitude']?.toDouble();
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
      lookingFor: data['lookingFor']?.toString() ?? 'Dating',
      bio: data['bio']?.toString(),
      accountStatus: data['accountStatus']?.toString(),
      sexualOrientation: data['sexualOrientation'],
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
