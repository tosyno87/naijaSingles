import 'package:flutter/foundation.dart';
import 'package:naijasingles/models/user_model.dart';

import '../common/data/repo/user_search_repo.dart';
import '../common/data/repo/privacy_aware_user_search_repo.dart';
import 'privacy_migration_service.dart';
import 'user_privacy_service.dart';

/// Service that handles user discovery with privacy awareness
/// Automatically switches between old and new systems based on migration status
class DiscoveryService {
  static final PrivacyMigrationService _migrationService =
      PrivacyMigrationService();

  /// Get user list for discovery (privacy-aware)
  static Future<List<UserModel>> getUsersForDiscovery(
      UserModel currentUser) async {
    try {
      debugPrint('🔍 Starting user discovery for: ${currentUser.name}');
      debugPrint('🔍 Current user ID: ${currentUser.id}');
      debugPrint('🔍 Current user gender: ${currentUser.userGender}');
      debugPrint('🔍 Current user age range: ${currentUser.ageRange}');
      debugPrint('🔍 Current user max distance: ${currentUser.maxDistance}');

      // Check if current user has been migrated to privacy system
      final isMigrated =
          await _migrationService.isUserMigrated(currentUser.id!);
      debugPrint('🔍 User migration status: $isMigrated');

      if (isMigrated) {
        debugPrint('🔒 Using privacy-aware discovery');
        final users = await PrivacyAwareUserSearchRepo.getUserList(currentUser);
        debugPrint(
            '🔒 Privacy-aware discovery returned: ${users.length} users');
        return users;
      } else {
        debugPrint('📋 Using traditional discovery (user not migrated)');
        final users = await UserSearchRepo.getUserList(currentUser);
        debugPrint('📋 Traditional discovery returned: ${users.length} users');
        return users;
      }
    } catch (e) {
      debugPrint('❌ Error in getUsersForDiscovery: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');

      // Fallback to traditional method if privacy-aware fails
      try {
        debugPrint('🔄 Falling back to traditional discovery');
        final users = await UserSearchRepo.getUserList(currentUser);
        debugPrint('🔄 Fallback returned: ${users.length} users');
        return users;
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
            currentUser, radiusMiles);
      } else {
        debugPrint('📋 Privacy system not available, using traditional search');
        // Fallback to traditional getUserList with distance filtering
        final allUsers = await UserSearchRepo.getUserList(currentUser);
        return allUsers
            .where((user) =>
                user.distanceBW != null && user.distanceBW! <= radiusMiles)
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
            '📋 Using traditional matches - loading from user subcollection');
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
      UserModel currentUser) async {
    try {
      final snapshot = await PrivacyAwareUserSearchRepo.docRef
          .doc(currentUser.id)
          .collection("Matches")
          .get();

      List<UserModel> matchesList = [];
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
      UserModel currentUser) async {
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
        'discoveryMethod': isMigrated ? 'privacy-aware' : 'traditional',
      };
    } catch (e) {
      debugPrint('❌ Error getting discovery stats: $e');
      return {
        'isMigrated': false,
        'swipedToday': 0,
        'privacyEnabled': false,
        'discoveryMethod': 'traditional',
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
            '✅ Migration successful, discovery will now use privacy-aware system');
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
        // This would require implementing a method to get single user from traditional repo
        debugPrint('📋 User not migrated, using traditional data access');
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting privacy-aware user data: $e');
      return null;
    }
  }
}
