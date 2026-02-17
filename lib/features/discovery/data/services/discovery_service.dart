import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../common/data/repo/privacy_aware_user_search_repo.dart';
import '../../../../common/data/repo/user_search_repo.dart';
import '../../../../common/utils/distance.dart' as distance;
import '../../../../models/user_model.dart';
import '../../../../services/mode_specific_filtering_service.dart';
import '../../../../services/privacy_migration_service.dart';
import '../../../../services/user_privacy_service.dart';
import 'discovery_filtering.dart';
import 'smart_match_service.dart';

/// Consolidated discovery service that combines:
/// - Privacy-aware discovery (from DiscoveryService)
/// - Comprehensive filtering (from UnifiedDiscoveryService)
/// - Real-time streams (from RealtimeDiscoveryService)
///
/// This is the single source of truth for user discovery functionality.
class DiscoveryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final PrivacyMigrationService _migrationService =
      PrivacyMigrationService();

  // Collection references
  static CollectionReference get _usersCollection =>
      _firestore.collection('users');

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // ============================================================================
  // PRIVACY-AWARE DISCOVERY METHODS (from DiscoveryService)
  // ============================================================================

  /// Get user list for discovery (privacy-aware)
  /// Automatically switches between privacy-aware and traditional systems
  static Future<List<UserModel>> getUsersForDiscovery(
    UserModel currentUser, {
    String? intentFilter,
    bool forceRefresh = false,
  }) async {
    try {
      debugPrint('🔍 Starting user discovery for: ${currentUser.name}');
      debugPrint('🔍 Current user ID: ${currentUser.id}');
      debugPrint('🔍 Intent filter: $intentFilter');

      // Check if current user has been migrated to privacy system
      final isMigrated =
          await _migrationService.isUserMigrated(currentUser.id!);
      debugPrint('🔍 User migration status: $isMigrated');

      if (isMigrated) {
        debugPrint('🔒 Using privacy-aware discovery');
        final users = await PrivacyAwareUserSearchRepo.getUserList(currentUser);
        debugPrint(
          '🔒 Privacy-aware discovery returned: ${users.length} users',
        );
        return users;
      } else {
        debugPrint('📋 Using unified discovery (user not migrated)');
        // Use unified discovery service for non-migrated users
        return await _getUsersForDiscoveryUnified(
          currentUser,
          intentFilter: intentFilter,
          forceRefresh: forceRefresh,
        );
      }
    } catch (e) {
      debugPrint('❌ Error in getUsersForDiscovery: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');

      // Fallback to unified method if privacy-aware fails
      try {
        debugPrint('🔄 Falling back to unified discovery');
        return await _getUsersForDiscoveryUnified(
          currentUser,
          intentFilter: intentFilter,
          forceRefresh: forceRefresh,
        );
      } catch (fallbackError) {
        debugPrint('❌ Fallback also failed: $fallbackError');
        return [];
      }
    }
  }

  /// Get nearby users (privacy-aware)
  static Future<List<UserModel>> getNearbyUsers(
    UserModel currentUser,
    double radiusMiles,
  ) async {
    try {
      debugPrint('🗺️ Getting nearby users within $radiusMiles miles');

      // Check if privacy system is available
      final isMigrated =
          await _migrationService.isUserMigrated(currentUser.id!);

      if (isMigrated) {
        debugPrint('🔒 Using privacy-aware nearby search');
        return await PrivacyAwareUserSearchRepo.getUsersNearby(
          currentUser,
          radiusMiles,
        );
      } else {
        debugPrint('📋 Privacy system not available, using unified search');
        // Fallback to unified method with distance filtering
        final allUsers = await _getUsersForDiscoveryUnified(currentUser);
        return allUsers
            .where(
              (user) =>
                  user.distanceBW != null && user.distanceBW! <= radiusMiles,
            )
            .toList();
      }
    } catch (e) {
      debugPrint('❌ Error in getNearbyUsers: $e');
      return [];
    }
  }

  /// Get matches (privacy-aware)
  static Future<List<UserModel>> getMatches(UserModel currentUser) async {
    try {
      debugPrint('💕 Getting matches for: ${currentUser.name}');

      // Check if privacy system is available
      final isMigrated =
          await _migrationService.isUserMigrated(currentUser.id!);

      if (isMigrated) {
        debugPrint('🔒 Using privacy-aware matches');
        return await PrivacyAwareUserSearchRepo.getMatches(currentUser);
      } else {
        debugPrint(
          '📋 Using traditional matches - loading from user subcollection',
        );
        // Fallback: Load matches from user's Matches subcollection
        return await _getTraditionalMatches(currentUser);
      }
    } catch (e) {
      debugPrint('❌ Error in getMatches: $e');
      return [];
    }
  }

  /// Get traditional matches from user's subcollection
  static Future<List<UserModel>> _getTraditionalMatches(
    UserModel currentUser,
  ) async {
    try {
      final snapshot = await PrivacyAwareUserSearchRepo.docRef
          .doc(currentUser.id)
          .collection('Matches')
          .get();

      final List<UserModel> matchesList = [];
      for (var doc in snapshot.docs) {
        try {
          // Get user data from main collection
          final userDoc =
              await PrivacyAwareUserSearchRepo.docRef.doc(doc.id).get();
          if (userDoc.exists) {
            final user = UserModel.fromDocument(userDoc);
            matchesList.add(user);
          }
        } catch (e) {
          debugPrint('⚠️ Error loading traditional match ${doc.id}: $e');
          continue;
        }
      }
      return matchesList;
    } catch (e) {
      debugPrint('❌ Error in _getTraditionalMatches: $e');
      return [];
    }
  }

  /// Check if user discovery should prompt for privacy migration
  static Future<bool> shouldPromptForMigration(String userId) async {
    try {
      final isMigrated = await _migrationService.isUserMigrated(userId);
      return !isMigrated;
    } catch (e) {
      debugPrint('❌ Error checking migration status: $e');
      return false;
    }
  }

  /// Get discovery statistics
  static Future<Map<String, dynamic>> getDiscoveryStats(
    UserModel currentUser,
  ) async {
    try {
      final isMigrated =
          await _migrationService.isUserMigrated(currentUser.id!);
      final swipedCount = isMigrated
          ? await PrivacyAwareUserSearchRepo.getSwipedCount(currentUser)
          : await UserSearchRepo.getSwipedCount(currentUser);

      return {
        'isMigrated': isMigrated,
        'swipedToday': swipedCount,
        'privacyEnabled': isMigrated,
        'discoveryMethod': isMigrated ? 'privacy-aware' : 'unified',
      };
    } catch (e) {
      debugPrint('❌ Error getting discovery stats: $e');
      return {
        'isMigrated': false,
        'swipedToday': 0,
        'privacyEnabled': false,
        'discoveryMethod': 'unified',
      };
    }
  }

  /// Migrate user and refresh discovery
  static Future<bool> migrateAndRefreshDiscovery(String userId) async {
    try {
      debugPrint('🔄 Migrating user and refreshing discovery: $userId');

      final success = await _migrationService.migrateUserData(userId);
      if (success) {
        debugPrint(
          '✅ Migration successful, discovery will now use privacy-aware system',
        );
        return true;
      } else {
        debugPrint('❌ Migration failed');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error in migrateAndRefreshDiscovery: $e');
      return false;
    }
  }

  /// Check if a specific user's data is privacy-filtered
  static Future<bool> isUserDataFiltered(String userId) async {
    try {
      return await _migrationService.isUserMigrated(userId);
    } catch (e) {
      debugPrint('❌ Error checking if user data is filtered: $e');
      return false;
    }
  }

  /// Get user data respecting privacy settings
  static Future<UserModel?> getPrivacyAwareUserData(String userId) async {
    try {
      final isMigrated = await _migrationService.isUserMigrated(userId);

      if (isMigrated) {
        // Use privacy service to get filtered data
        final privacyService = UserPrivacyService();
        final filteredData = await privacyService.getFilteredUserData(userId);
        if (filteredData != null) {
          return await PrivacyAwareUserSearchRepo
              .createUserModelFromFilteredData(filteredData, userId);
        }
      } else {
        // Fallback to traditional method
        debugPrint('📋 User not migrated, using traditional data access');
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting privacy-aware user data: $e');
      return null;
    }
  }

  // ============================================================================
  // UNIFIED DISCOVERY METHODS (from UnifiedDiscoveryService)
  // ============================================================================

  /// Get users for discovery with comprehensive filtering (unified method)
  static Future<List<UserModel>> _getUsersForDiscoveryUnified(
    UserModel currentUser, {
    String? intentFilter,
    bool forceRefresh = false,
  }) async {
    try {
      debugPrint(
        '🔍 UnifiedDiscoveryService: Getting users for ${currentUser.name}',
      );
      debugPrint('   - Intent filter: $intentFilter');
      debugPrint('   - Gender preference: ${currentUser.showGender}');
      debugPrint(
        '   - Age range: ${currentUser.ageRangeMin}-${currentUser.ageRangeMax}',
      );
      debugPrint(
        '   - Max distance: ${(currentUser.maxDistance! * 0.621371).round()} miles',
      );

      // Get already checked users
      final checkedUserIds = await _getCheckedUserIds(currentUser.id!);
      debugPrint('   - Already checked: ${checkedUserIds.length} users');

      // Build optimized query with mode-specific filtering
      Query query = _buildOptimizedQuery(currentUser, intentFilter);
      query = ModeSpecificFilteringService.applyModeSpecificFilters(
        query,
        currentUser,
        intentFilter ?? 'Dating',
      );

      // Execute query
      final querySnapshot = await query.get();
      debugPrint('   - Query returned: ${querySnapshot.docs.length} documents');

      // Process results
      List<UserModel> userList = [];

      for (var doc in querySnapshot.docs) {
        try {
          final userId = doc.id;

          // Skip already checked users and self
          if (checkedUserIds.contains(userId) || userId == currentUser.id) {
            continue;
          }

          // Create UserModel from document
          final user = UserModel.fromDocument(doc);

          // Apply mode-specific validation
          if (!ModeSpecificFilteringService.validateModeMatch(
            user,
            intentFilter ?? 'Dating',
          )) {
            debugPrint('⚠️ User $userId does not match $intentFilter criteria');
            continue;
          }

          // Apply additional filters
          if (!_passesAdditionalFilters(user, currentUser)) {
            continue;
          }

          // Calculate distance if both users have coordinates
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
            if (calculatedDistance > (currentUser.maxDistance ?? 100)) {
              continue;
            }
          }

          debugPrint(
            '✅ Adding user: ${user.name} (${user.distanceBW ?? 'unknown'} miles away)',
          );
          userList.add(user);
        } catch (e) {
          debugPrint('⚠️ Error processing user ${doc.id}: $e');
          continue;
        }
      }

      // Apply smart matching with mode-specific compatibility
      if (userList.isNotEmpty) {
        userList =
            await _applySmartMatching(currentUser, userList, intentFilter);
      }

      debugPrint('🎯 Final result: ${userList.length} discoverable users');
      return userList;
    } catch (e) {
      debugPrint('❌ Error in UnifiedDiscoveryService: $e');
      return [];
    }
  }

  /// Build optimized Firestore query
  static Query _buildOptimizedQuery(
    UserModel currentUser,
    String? intentFilter,
  ) {
    Query query = _usersCollection;
    final normalizedPreference =
        DiscoveryFiltering.normalizeGender(currentUser.showGender);
    if (DiscoveryFiltering.isEveryonePreference(normalizedPreference)) {
      debugPrint(
          '🔍 Gender preference is everyone - skipping gender query filter');
    } else {
      debugPrint(
        '🔍 Applying gender filter in-memory for compatibility: $normalizedPreference',
      );
    }

    // Filter by age range - CRITICAL FOR DISCOVERY
    if (currentUser.ageRangeMin != null && currentUser.ageRangeMax != null) {
      query = query
          .where('age', isGreaterThanOrEqualTo: currentUser.ageRangeMin)
          .where('age', isLessThanOrEqualTo: currentUser.ageRangeMax);
      debugPrint(
        '🔍 Filtering by age: ${currentUser.ageRangeMin}-${currentUser.ageRangeMax}',
      );
    }

    // Filter by intent if specified
    if (intentFilter != null && intentFilter.isNotEmpty) {
      query = query.where('lookingFor', isEqualTo: intentFilter);
      debugPrint('🔍 Filtering by intent: $intentFilter');
    }

    return query;
  }

  /// Get list of already checked user IDs
  static Future<List<String>> _getCheckedUserIds(String currentUserId) async {
    try {
      final snapshot =
          await _firestore.collection('users/$currentUserId/CheckedUser').get();

      final List<String> checkedIds = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['LikedUser'] != null) {
          checkedIds.add(data['LikedUser']);
        }
        if (data['DislikedUser'] != null) {
          checkedIds.add(data['DislikedUser']);
        }
      }

      return checkedIds;
    } catch (e) {
      debugPrint('Error getting checked users: $e');
      return [];
    }
  }

  /// Apply additional filters that can't be done in Firestore query
  static bool _passesAdditionalFilters(UserModel user, UserModel currentUser) {
    if (!DiscoveryFiltering.matchesGenderPreference(user, currentUser)) {
      return false;
    }

    // Skip users who are not discoverable (paused, incognito, deleted, banned)
    if (!user.isDiscoverable) {
      return false;
    }

    // Skip blocked users
    if (user.isBlocked ?? false) {
      return false;
    }

    // Skip bots
    if (user.isBot ?? false) {
      return false;
    }

    // Skip users without complete profiles
    if (user.name == null || user.name!.isEmpty) {
      return false;
    }

    // Skip users without photos
    if (user.imageUrl == null || user.imageUrl!.isEmpty) {
      return false;
    }

    return true;
  }

  /// Apply smart matching with mode-specific compatibility
  static Future<List<UserModel>> _applySmartMatching(
    UserModel currentUser,
    List<UserModel> userList,
    String? intentFilter,
  ) async {
    try {
      debugPrint('🧠 Applying smart matching for ${userList.length} users');

      final smartMatchService = SmartMatchService();
      final mode = intentFilter ?? 'Dating';

      // Use SmartMatchService to get optimized ordering
      final result = await smartMatchService.getOptimizedUserList(
        currentUser: currentUser,
        mode: mode,
        pageSize: userList.length,
      );

      if (result.isSuccess && result.users.isNotEmpty) {
        debugPrint('✅ Smart matching applied: ${result.users.length} users');
        return result.users;
      } else {
        debugPrint('⚠️ Smart matching failed, returning original list');
        return userList;
      }
    } catch (e) {
      debugPrint('❌ Error in smart matching: $e');
      return userList;
    }
  }

  // ============================================================================
  // REAL-TIME STREAM METHODS (from RealtimeDiscoveryService)
  // ============================================================================

  /// Get real-time stream of users for discovery
  static Stream<List<UserModel>> getUsersStream(UserModel currentUser) {
    try {
      debugPrint(
        '🔍 Starting real-time discovery stream for ${currentUser.name}',
      );

      // Build query with basic filters
      final Query query = _firestore
          .collection('users')
          .where('id', isNotEqualTo: currentUser.id) // Exclude current user
          .limit(20); // Limit for performance

      return query.snapshots().asyncMap((snapshot) async {
        debugPrint('📡 Real-time stream update: ${snapshot.docs.length} users');

        final List<UserModel> users = [];
        final List<String> checkedUserIds =
            await _getCheckedUserIds(currentUser.id!);

        for (var doc in snapshot.docs) {
          try {
            // Skip already checked users
            if (checkedUserIds.contains(doc.id)) continue;

            // Skip blocked users
            if ((doc.data() as Map<String, dynamic>?)?['isBlocked'] == true) {
              continue;
            }

            // Create user model
            final user = UserModel.fromDocument(doc);

            if (!DiscoveryFiltering.matchesGenderPreference(
                user, currentUser)) {
              continue;
            }

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
        '📄 Starting paginated real-time stream (page size: $pageSize)',
      );

      Query query = _firestore
          .collection('users')
          .where('id', isNotEqualTo: currentUser.id)
          .orderBy('lastvisited', descending: true)
          .limit(pageSize);

      // Add pagination if last document provided
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      return query.snapshots().asyncMap((snapshot) async {
        debugPrint('📡 Paginated stream update: ${snapshot.docs.length} users');

        final List<UserModel> users = [];
        final List<String> checkedUserIds =
            await _getCheckedUserIds(currentUser.id!);

        for (var doc in snapshot.docs) {
          try {
            if (checkedUserIds.contains(doc.id)) continue;
            if ((doc.data() as Map<String, dynamic>?)?['isBlocked'] == true) {
              continue;
            }

            final user = UserModel.fromDocument(doc);

            if (!DiscoveryFiltering.matchesGenderPreference(
                user, currentUser)) {
              continue;
            }

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

  /// Get nearby users stream (real-time)
  static Stream<List<UserModel>> getNearbyUsersStream(
    UserModel currentUser,
    double radiusMiles,
  ) {
    try {
      debugPrint('🗺️ Starting nearby users stream (radius: ${radiusMiles}mi)');

      // For nearby users, we need to get all users and filter by distance
      // This is less efficient but necessary for geolocation queries
      final Query query = _firestore
          .collection('users')
          .where('id', isNotEqualTo: currentUser.id)
          .limit(50); // Limit for performance

      return query.snapshots().asyncMap((snapshot) async {
        debugPrint('📡 Nearby stream update: ${snapshot.docs.length} users');

        final List<UserModel> users = [];
        final List<String> checkedUserIds =
            await _getCheckedUserIds(currentUser.id!);

        for (var doc in snapshot.docs) {
          try {
            if (checkedUserIds.contains(doc.id)) continue;
            if ((doc.data() as Map<String, dynamic>?)?['isBlocked'] == true) {
              continue;
            }

            final user = UserModel.fromDocument(doc);

            if (!DiscoveryFiltering.matchesGenderPreference(
                user, currentUser)) {
              continue;
            }

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
          '✅ Nearby stream processed: ${users.length} users within ${radiusMiles}mi',
        );
        return users;
      });
    } catch (e) {
      debugPrint('❌ Error creating nearby stream: $e');
      return Stream.value([]);
    }
  }

  /// Get discovery statistics stream
  static Stream<Map<String, dynamic>> getDiscoveryStatsStream(
    UserModel currentUser,
  ) {
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
