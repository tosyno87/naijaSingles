import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/user_model.dart';
import '../../../services/cached_user_service.dart';
import '../../../services/optimized_match_service.dart';
import '../../../services/paginated_user_service.dart';
import '../../../services/unified_discovery_service.dart';
import '../../constants/constants.dart';
import '../../utils/distance.dart' as distance;

class UserSearchRepo {
  static FirebaseFirestore db = firebaseFireStoreInstance;
  static CollectionReference get docRef => db.collection('users');

  static FirebaseAuth firebaseAuth = firebaseAuthInstance;
  // static final LikesService _likesService = LikesService(); // Removed - using unified service

  // New optimized services
  static final OptimizedMatchService _optimizedMatchService =
      OptimizedMatchService();
  static final CachedUserService _cachedUserService = CachedUserService();
  // static final PaginatedUserService _paginatedUserService = PaginatedUserService(); // Removed - using unified service

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
    db.collection('Item_access').snapshots().listen((doc) {
      if (doc.docs.isNotEmpty) {
        items = doc.docs[0].data();
        // log(doc.docs[0].data().toString());
      }
    });
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

    final swipedCount = querySnapshot.docs.length;
    // log("from frpo count ${swipedCount.toString()}");

    return swipedCount;
  }

  static Future<void> leftSwipe(
      UserModel currentUser, UserModel selectedUser,) async {
    await docRef
        .doc(currentUser.id)
        .collection('CheckedUser')
        .doc(selectedUser.id)
        .set({
      'DislikedUser': selectedUser.id,
      'timestamp': DateTime.now(),
    }, SetOptions(merge: true),);
  }

  static Future<String?> rightSwipe(
      UserModel currentUser, UserModel selectedUser,) async {
    try {
      debugPrint(
          '🚀 Optimized right swipe: ${currentUser.name} → ${selectedUser.name}',);

      // Use optimized match service (2-3 Firestore reads max)
      final currentUserId = currentUser.id;
      final selectedUserId = selectedUser.id;

      if (currentUserId != null && selectedUserId != null) {
        final result = await _optimizedMatchService.handleLike(
            currentUserId, selectedUserId,);

        if (result.isSuccess) {
          if (result.isMatch) {
            debugPrint('🎉 Match created! Match ID: ${result.matchId}');
            return result.matchId;
          } else {
            debugPrint('💌 Like saved, waiting for mutual like');
          }
        } else {
          debugPrint('❌ Error in optimized match service: ${result.error}');
          // Fall back to legacy system
          return await _legacyRightSwipe(currentUser, selectedUser);
        }
      }

      // Update CheckedUser collection for swipe tracking
      await docRef
          .doc(currentUser.id)
          .collection('CheckedUser')
          .doc(selectedUser.id)
          .set({
        'LikedUser': selectedUser.id,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true),);

      return null; // No match created
    } catch (e) {
      debugPrint('❌ Error in optimized rightSwipe: $e');
      // Fallback to legacy behavior if optimized system fails
      return _legacyRightSwipe(currentUser, selectedUser);
    }
  }

  /// Legacy right swipe implementation as fallback
  static Future<String?> _legacyRightSwipe(
      UserModel currentUser, UserModel selectedUser,) async {
    try {
      likedByList = await getLikedByList(currentUser);
      if (likedByList.contains(selectedUser.id) ||
          (selectedUser.isBot ?? false)) {
        debugPrint('Legacy match creation for backward compatibility');
        await docRef
            .doc(currentUser.id)
            .collection('Matches')
            .doc(selectedUser.id)
            .set({
          'Matches': selectedUser.id,
          'isRead': false,
          'userName': selectedUser.name ?? 'Unknown',
          'pictureUrl': selectedUser.imageUrl?.isNotEmpty ?? false
              ? selectedUser.imageUrl![0]
              : '',
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true),);
        await docRef
            .doc(selectedUser.id)
            .collection('Matches')
            .doc(currentUser.id)
            .set({
          'Matches': currentUser.id,
          'userName': currentUser.name ?? 'Unknown',
          'pictureUrl': currentUser.imageUrl?.isNotEmpty ?? false
              ? currentUser.imageUrl![0]
              : '',
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true),);

        // Return a legacy match indicator
        return 'legacy_match';
      }

      // Update legacy CheckedUser collection
      await docRef
          .doc(currentUser.id)
          .collection('CheckedUser')
          .doc(selectedUser.id)
          .set({
        'LikedUser': selectedUser.id,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true),);

      // Update legacy LikedBy collection
      await docRef
          .doc(selectedUser.id)
          .collection('LikedBy')
          .doc(currentUser.id)
          .set({
        'LikedBy': currentUser.id,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true),);

      return null; // No match created
    } catch (e) {
      debugPrint('Error in legacy rightSwipe: $e');
      return null;
    }
  }

  static Query query(UserModel currentUser) {
    if (currentUser.showGender == 'everyone') {
      return docRef
          .where('showGender', whereIn: ['everyone', currentUser.userGender])
          .where('age', isGreaterThanOrEqualTo: currentUser.ageRangeMin ?? 18)
          .where('age', isLessThanOrEqualTo: currentUser.ageRangeMax ?? 100)
          .orderBy('age', descending: false);
    } else {
      return docRef
          .where('userGender', isEqualTo: currentUser.showGender)
          .where('showGender', whereIn: ['everyone', currentUser.userGender])
          .where('age', isGreaterThanOrEqualTo: currentUser.ageRangeMin ?? 18)
          .where('age', isLessThanOrEqualTo: currentUser.ageRangeMax ?? 100)
          .orderBy('age', descending: false);
    }
  }

  /// Optimized user list fetching with unified discovery service
  static Future<List<UserModel>> getUserList(
    UserModel currentUser, {
    bool forceRefresh = false,
    String? intentFilter, // Add intent filter parameter
  }) async {
    try {
      debugPrint('🔍 Getting optimized user list for ${currentUser.name}');
      if (intentFilter != null) {
        debugPrint('🎯 Filtering by intent: $intentFilter');
      }

      // Use unified discovery service for better performance and consistency
      final users = await UnifiedDiscoveryService.getUsersForDiscovery(
        currentUser,
        intentFilter: intentFilter,
        forceRefresh: forceRefresh,
      );

      debugPrint('✅ Retrieved ${users.length} users from unified service');
      return users;
    } catch (e) {
      debugPrint('❌ Error in unified getUserList: $e');
      // Fallback to legacy method
      return _legacyGetUserList(currentUser, intentFilter: intentFilter);
    }
  }

  /// Get more users with pagination
  static Future<List<UserModel>> getMoreUsers(
    UserModel currentUser,
    PaginatedResult<UserModel> previousResult,
  ) async {
    try {
      debugPrint('📄 Loading more users...');

      final result = await _cachedUserService.getMoreUsers(
        currentUser: currentUser,
        previousResult: previousResult,
      );

      if (result.isSuccess) {
        debugPrint('✅ Loaded ${result.items.length} more users');
        return result.items;
      } else {
        debugPrint('❌ Error loading more users: ${result.error}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error in getMoreUsers: $e');
      return [];
    }
  }

  /// Legacy getUserList method as fallback
  static Future<List<UserModel>> _legacyGetUserList(
    UserModel currentUser, {
    String? intentFilter, // Add intent filter parameter
  }) async {
    final List<String> checkedUserIds = [];

    try {
      debugPrint('⚠️ Using legacy getUserList as fallback');
      if (intentFilter != null) {
        debugPrint('🎯 Legacy filtering by intent: $intentFilter');
      }

      // Debug logging
      debugPrint('Getting user list for: ${currentUser.id}');
      debugPrint('Current user auth: ${firebaseAuth.currentUser?.uid}');

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

      debugPrint('Querying main users collection...');
      final querySnapshot = await query(currentUser).get();
      debugPrint('Query returned ${querySnapshot.docs.length} documents');

      if (querySnapshot.docs.isEmpty) {
        debugPrint('no more data');
        return [];
      }

      final List<UserModel> userList = [];

      for (var doc in querySnapshot.docs) {
        try {
          debugPrint('Processing document: ${doc.id}');
          final UserModel temp = UserModel.fromDocument(doc);
          debugPrint('Created UserModel for: ${temp.name}');

          final distance = calculateDistance(currentUser.latitude,
              currentUser.longitude, temp.latitude, temp.longitude,);
          temp.distanceBW = distance.round();

          if (checkedUserIds.contains(temp.id)) {
            debugPrint('Skipping already checked user: ${temp.name}');
            continue;
          }

          // Apply intent filter if specified
          if (intentFilter != null && intentFilter.isNotEmpty) {
            final userIntent = temp.lookingFor ?? 'Dating';
            if (userIntent != intentFilter) {
              debugPrint(
                  'Filtered out user: ${temp.name} (intent: $userIntent, looking for: $intentFilter)',);
              continue;
            }
          }

          if (distance <= currentUser.maxDistance! &&
              temp.id != currentUser.id &&
              !temp.isBlocked!) {
            debugPrint(
                'Adding user: ${temp.name} (intent: ${temp.lookingFor})',);
            userList.add(temp);
          } else {
            debugPrint(
                'Filtered out user: ${temp.name} (distance: $distance, maxDistance: ${currentUser.maxDistance}, blocked: ${temp.isBlocked})',);
          }
        } catch (e) {
          debugPrint('Error processing document ${doc.id}: $e');
          continue;
        }
      }

      debugPrint('Final legacy user list size: ${userList.length}');
      return userList;
    } catch (e) {
      debugPrint('Error in legacy getUserList: $e');
      rethrow;
    }
  }

  static Future<List<String>> getLikedByList(UserModel currentUser) async {
    final snapshot =
        await docRef.doc(currentUser.id).collection('LikedBy').get();
    final List<String> likedByList = [];
    if (snapshot.docs.isNotEmpty) {
      for (final doc in snapshot.docs) {
        likedByList.add(doc.data()['LikedBy']);
      }
    }
    return likedByList;
  }

  static double calculateDistance(lat1, lon1, lat2, lon2) => distance.calculateDistance(lat1, lon1, lat2, lon2);
}
