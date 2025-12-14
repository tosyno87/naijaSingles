import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:naijasingles/models/user_model.dart';
import 'package:naijasingles/common/utils/distance.dart' as distance;

/// Service for real-time discovery using Firestore streams
class RealtimeDiscoveryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // static final FirebaseAuth _auth = FirebaseAuth.instance; // Not used in current implementation

  /// Get real-time stream of users for discovery
  static Stream<List<UserModel>> getUsersStream(UserModel currentUser) {
    try {
      debugPrint(
          '🔍 Starting real-time discovery stream for ${currentUser.name}');

      // Build query with basic filters
      Query query = _firestore
          .collection('users')
          .where('id', isNotEqualTo: currentUser.id) // Exclude current user
          .where('userGender',
              isEqualTo: currentUser.showGender) // Gender preference
          .limit(20); // Limit for performance

      return query.snapshots().asyncMap((snapshot) async {
        debugPrint('📡 Real-time stream update: ${snapshot.docs.length} users');

        List<UserModel> users = [];
        List<String> checkedUserIds = await _getCheckedUserIds(currentUser.id!);

        for (var doc in snapshot.docs) {
          try {
            // Skip already checked users
            if (checkedUserIds.contains(doc.id)) continue;

            // Skip blocked users
            if ((doc.data() as Map<String, dynamic>?)?['isBlocked'] == true)
              continue;

            // Create user model
            final user = UserModel.fromDocument(doc);

            // Calculate distance if coordinates available
            if (user.latitude != null &&
                user.longitude != null &&
                currentUser.latitude != null &&
                currentUser.longitude != null) {
              user.distanceBW = distance
                  .calculateDistance(
                    currentUser.latitude!,
                    currentUser.longitude!,
                    user.latitude!,
                    user.longitude!,
                  )
                  .round();
            }

            // Apply age filter
            if (user.age != null && currentUser.ageRange != null) {
              final minAge = currentUser.ageRange!['min'] ?? 18;
              final maxAge = currentUser.ageRange!['max'] ?? 100;
              if (user.age! < minAge || user.age! > maxAge) continue;
            }

            // Apply distance filter
            if (user.distanceBW != null && currentUser.maxDistance != null) {
              if (user.distanceBW! > currentUser.maxDistance!) continue;
            }

            users.add(user);
          } catch (e) {
            debugPrint('⚠️ Error processing user ${doc.id}: $e');
            continue;
          }
        }

        debugPrint('✅ Real-time stream processed: ${users.length} valid users');
        return users;
      });
    } catch (e) {
      debugPrint('❌ Error creating real-time stream: $e');
      return Stream.value([]);
    }
  }

  /// Get paginated users with real-time updates
  static Stream<List<UserModel>> getPaginatedUsersStream(
    UserModel currentUser, {
    int pageSize = 10,
    DocumentSnapshot? lastDocument,
  }) {
    try {
      debugPrint(
          '📄 Starting paginated real-time stream (page size: $pageSize)');

      Query query = _firestore
          .collection('users')
          .where('id', isNotEqualTo: currentUser.id)
          .where('userGender', isEqualTo: currentUser.showGender)
          .orderBy('lastvisited', descending: true)
          .limit(pageSize);

      // Add pagination if last document provided
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      return query.snapshots().asyncMap((snapshot) async {
        debugPrint('📡 Paginated stream update: ${snapshot.docs.length} users');

        List<UserModel> users = [];
        List<String> checkedUserIds = await _getCheckedUserIds(currentUser.id!);

        for (var doc in snapshot.docs) {
          try {
            if (checkedUserIds.contains(doc.id)) continue;
            if ((doc.data() as Map<String, dynamic>?)?['isBlocked'] == true)
              continue;

            final user = UserModel.fromDocument(doc);

            // Calculate distance
            if (user.latitude != null &&
                user.longitude != null &&
                currentUser.latitude != null &&
                currentUser.longitude != null) {
              user.distanceBW = distance
                  .calculateDistance(
                    currentUser.latitude!,
                    currentUser.longitude!,
                    user.latitude!,
                    user.longitude!,
                  )
                  .round();
            }

            // Apply filters
            if (user.age != null && currentUser.ageRange != null) {
              final minAge = currentUser.ageRange!['min'] ?? 18;
              final maxAge = currentUser.ageRange!['max'] ?? 100;
              if (user.age! < minAge || user.age! > maxAge) continue;
            }

            if (user.distanceBW != null && currentUser.maxDistance != null) {
              if (user.distanceBW! > currentUser.maxDistance!) continue;
            }

            users.add(user);
          } catch (e) {
            debugPrint('⚠️ Error processing paginated user ${doc.id}: $e');
            continue;
          }
        }

        debugPrint('✅ Paginated stream processed: ${users.length} valid users');
        return users;
      });
    } catch (e) {
      debugPrint('❌ Error creating paginated stream: $e');
      return Stream.value([]);
    }
  }

  /// Get checked user IDs (users already swiped on)
  static Future<List<String>> _getCheckedUserIds(String currentUserId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('CheckedUser')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('❌ Error getting checked users: $e');
      return [];
    }
  }

  /// Get nearby users stream (real-time)
  static Stream<List<UserModel>> getNearbyUsersStream(
    UserModel currentUser,
    double radiusMiles,
  ) {
    try {
      debugPrint('🗺️ Starting nearby users stream (radius: ${radiusMiles}mi)');

      // For nearby users, we need to get all users and filter by distance
      // This is less efficient but necessary for geolocation queries
      Query query = _firestore
          .collection('users')
          .where('id', isNotEqualTo: currentUser.id)
          .where('userGender', isEqualTo: currentUser.showGender)
          .limit(50); // Limit for performance

      return query.snapshots().asyncMap((snapshot) async {
        debugPrint('📡 Nearby stream update: ${snapshot.docs.length} users');

        List<UserModel> users = [];
        List<String> checkedUserIds = await _getCheckedUserIds(currentUser.id!);

        for (var doc in snapshot.docs) {
          try {
            if (checkedUserIds.contains(doc.id)) continue;
            if ((doc.data() as Map<String, dynamic>?)?['isBlocked'] == true)
              continue;

            final user = UserModel.fromDocument(doc);

            // Calculate distance
            if (user.latitude != null &&
                user.longitude != null &&
                currentUser.latitude != null &&
                currentUser.longitude != null) {
              final distanceMiles = distance.calculateDistance(
                currentUser.latitude!,
                currentUser.longitude!,
                user.latitude!,
                user.longitude!,
              );

              // Filter by radius
              if (distanceMiles <= radiusMiles) {
                user.distanceBW = distanceMiles.round();
                users.add(user);
              }
            }
          } catch (e) {
            debugPrint('⚠️ Error processing nearby user ${doc.id}: $e');
            continue;
          }
        }

        debugPrint(
            '✅ Nearby stream processed: ${users.length} users within ${radiusMiles}mi');
        return users;
      });
    } catch (e) {
      debugPrint('❌ Error creating nearby stream: $e');
      return Stream.value([]);
    }
  }

  /// Get discovery statistics stream
  static Stream<Map<String, dynamic>> getDiscoveryStatsStream(
      UserModel currentUser) {
    try {
      return _firestore
          .collection('users')
          .doc(currentUser.id)
          .collection('CheckedUser')
          .snapshots()
          .map((snapshot) {
        final swipedCount = snapshot.docs.length;
        return {
          'swipedToday': swipedCount,
          'discoveryMethod': 'real-time',
          'lastUpdated': DateTime.now().toIso8601String(),
        };
      });
    } catch (e) {
      debugPrint('❌ Error creating stats stream: $e');
      return Stream.value({
        'swipedToday': 0,
        'discoveryMethod': 'real-time',
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    }
  }
}
