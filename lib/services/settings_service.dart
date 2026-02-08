import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service for managing user settings, blocked users, and preferences
class SettingsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  static CollectionReference get _usersCollection =>
      _firestore.collection('users');
  static CollectionReference get _reportsCollection =>
      _firestore.collection('reports');
  static CollectionReference get _feedbackCollection =>
      _firestore.collection('feedback');

  /// Get current user ID
  static String? get _currentUserId => _auth.currentUser?.uid;

  // BLOCKED USERS MANAGEMENT

  /// Get list of blocked user IDs for current user
  static Future<List<String>> getBlockedUserIds(String userId) async {
    try {
      final blockedSnapshot =
          await _usersCollection.doc(userId).collection('blockedlist').get();

      return blockedSnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('❌ Error getting blocked user IDs: $e');
      return [];
    }
  }

  /// Get detailed information about blocked users
  static Future<List<BlockedUser>> getBlockedUsers(String userId) async {
    try {
      final blockedIds = await getBlockedUserIds(userId);
      if (blockedIds.isEmpty) return [];

      final List<BlockedUser> blockedUsers = [];

      // Get user details for each blocked user
      for (final blockedId in blockedIds) {
        try {
          final userDoc = await _usersCollection.doc(blockedId).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;

            // Get block timestamp
            final blockDoc = await _usersCollection
                .doc(userId)
                .collection('blockedlist')
                .doc(blockedId)
                .get();

            final blockData = blockDoc.data();
            final blockedAt =
                (blockData?['blockedAt'] as Timestamp?)?.toDate() ??
                    DateTime.now();

            blockedUsers.add(
              BlockedUser(
                id: blockedId,
                name: userData['name'] ?? 'Unknown User',
                imageUrl: userData['imageUrl']?[0] ?? '',
                blockedAt: blockedAt,
                reason: blockData?['reason'] ?? 'No reason provided',
              ),
            );
          }
        } catch (e) {
          debugPrint('❌ Error getting blocked user details for $blockedId: $e');
        }
      }

      // Sort by most recently blocked
      blockedUsers.sort((a, b) => b.blockedAt.compareTo(a.blockedAt));
      return blockedUsers;
    } catch (e) {
      debugPrint('❌ Error getting blocked users: $e');
      return [];
    }
  }

  /// Block a user
  static Future<bool> blockUser(
    String userId,
    String blockedUserId, {
    String? reason,
  }) async {
    try {
      debugPrint('🚫 Blocking user: $userId blocks $blockedUserId');

      final batch = _firestore.batch();

      // Add to current user's blocked list only (can't write to other user's collection due to security rules)
      batch.set(
        _usersCollection
            .doc(userId)
            .collection('blockedlist')
            .doc(blockedUserId),
        {
          'blockedAt': FieldValue.serverTimestamp(),
          'reason': reason ?? 'User blocked',
          'blockedUserId': blockedUserId,
        },
      );

      // Remove any existing matches where both users are involved
      final matchQuery = await _firestore
          .collection('matches')
          .where('users', arrayContains: userId)
          .get();

      for (final matchDoc in matchQuery.docs) {
        final matchData = matchDoc.data();
        final users = List<String>.from(matchData['users'] ?? []);
        if (users.contains(blockedUserId)) {
          batch.delete(matchDoc.reference);
        }
      }

      // Remove from each other's liked lists (only if we have permission)
      try {
        batch.delete(
          _usersCollection.doc(userId).collection('LikedBy').doc(blockedUserId),
        );
        batch.delete(
          _usersCollection
              .doc(userId)
              .collection('CheckedUser')
              .doc(blockedUserId),
        );
      } catch (e) {
        debugPrint('⚠️ Could not remove from liked/checked lists: $e');
        // Continue with blocking even if this fails
      }

      await batch.commit();

      debugPrint('✅ Successfully blocked user: $blockedUserId');
      return true;
    } catch (e) {
      debugPrint('❌ Error blocking user: $e');
      return false;
    }
  }

  /// Unblock a user
  static Future<bool> unblockUser(String userId, String blockedUserId) async {
    try {
      debugPrint('✅ Unblocking user: $userId unblocks $blockedUserId');

      final batch = _firestore.batch();

      // Remove from current user's blocked list only
      batch.delete(
        _usersCollection
            .doc(userId)
            .collection('blockedlist')
            .doc(blockedUserId),
      );

      await batch.commit();

      debugPrint('✅ Successfully unblocked user: $blockedUserId');
      return true;
    } catch (e) {
      debugPrint('❌ Error unblocking user: $e');
      return false;
    }
  }

  /// Check if a user is blocked
  static Future<bool> isUserBlocked(String userId, String otherUserId) async {
    try {
      final blockDoc = await _usersCollection
          .doc(userId)
          .collection('blockedlist')
          .doc(otherUserId)
          .get();

      return blockDoc.exists;
    } catch (e) {
      debugPrint('❌ Error checking if user is blocked: $e');
      return false;
    }
  }

  // NOTIFICATION SETTINGS

  /// Get notification settings for a user
  static Future<NotificationSettings> getNotificationSettings(
    String userId,
  ) async {
    try {
      final settingsDoc =
          await _firestore.collection('notificationSettings').doc(userId).get();

      if (settingsDoc.exists) {
        return NotificationSettings.fromMap(settingsDoc.data()!);
      } else {
        // Return default settings
        return NotificationSettings.defaultSettings();
      }
    } catch (e) {
      debugPrint('❌ Error getting notification settings: $e');
      return NotificationSettings.defaultSettings();
    }
  }

  /// Update notification settings
  static Future<bool> updateNotificationSettings(
    String userId,
    NotificationSettings settings,
  ) async {
    try {
      await _firestore
          .collection('notificationSettings')
          .doc(userId)
          .set(settings.toMap(), SetOptions(merge: true));

      debugPrint('✅ Notification settings updated for user $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating notification settings: $e');
      return false;
    }
  }

  // FEEDBACK AND REPORTING

  /// Submit user feedback
  static Future<bool> submitFeedback({
    required String userId,
    required String feedback,
    required String category,
    String? email,
  }) async {
    try {
      await _feedbackCollection.add({
        'userId': userId,
        'feedback': feedback,
        'category': category,
        'email': email,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'platform': 'mobile',
      });

      debugPrint('✅ Feedback submitted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error submitting feedback: $e');
      return false;
    }
  }

  /// Report a user
  static Future<bool> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    String? description,
  }) async {
    try {
      await _reportsCollection.add({
        'reporterId': reporterId,
        'reportedUserId': reportedUserId,
        'reason': reason,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'reviewed': false,
      });

      debugPrint('✅ User report submitted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error reporting user: $e');
      return false;
    }
  }

  // ACCOUNT MANAGEMENT

  /// Get account deletion eligibility
  static Future<AccountDeletionInfo> getAccountDeletionInfo(
    String userId,
  ) async {
    try {
      // Check for active subscriptions, pending matches, etc.
      final userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) {
        return const AccountDeletionInfo(
          canDelete: false,
          reason: 'User not found',
        );
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final isPremium = userData['isPremium'] == true;

      // Check for active matches
      final matchesQuery = await _firestore
          .collection('matches')
          .where('users', arrayContains: userId)
          .limit(1)
          .get();

      final hasActiveMatches = matchesQuery.docs.isNotEmpty;

      return AccountDeletionInfo(
        canDelete: true,
        hasActiveSubscription: isPremium,
        hasActiveMatches: hasActiveMatches,
      );
    } catch (e) {
      debugPrint('❌ Error getting account deletion info: $e');
      return const AccountDeletionInfo(
        canDelete: false,
        reason: 'Error checking account status',
      );
    }
  }

  /// Delete user account (soft delete - mark as deleted)
  static Future<bool> deleteUserAccount(String userId, String reason) async {
    try {
      debugPrint('🗑️ Deleting user account: $userId');

      final batch = _firestore.batch();

      // Mark user as deleted instead of actually deleting
      batch.update(_usersCollection.doc(userId), {
        'deleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletionReason': reason,
        'email': FieldValue.delete(), // Remove PII
        'phoneNumber': FieldValue.delete(),
        'name': 'Deleted User',
        'imageUrl': [],
      });

      // Remove from all matches
      final matchesQuery = await _firestore
          .collection('matches')
          .where('users', arrayContains: userId)
          .get();

      for (final matchDoc in matchesQuery.docs) {
        batch.delete(matchDoc.reference);
      }

      await batch.commit();

      // Sign out the user
      await _auth.signOut();

      debugPrint('✅ User account deleted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting user account: $e');
      return false;
    }
  }
}

/// Model for blocked user information
class BlockedUser {
  const BlockedUser({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.blockedAt,
    required this.reason,
  });
  final String id;
  final String name;
  final String imageUrl;
  final DateTime blockedAt;
  final String reason;

  @override
  String toString() => 'BlockedUser(id: $id, name: $name)';
}

/// Model for notification settings
class NotificationSettings {
  const NotificationSettings({
    required this.matchNotifications,
    required this.messageNotifications,
    required this.likeNotifications,
    required this.superLikeNotifications,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.quietHoursStart,
    required this.quietHoursEnd,
    required this.quietHoursEnabled,
  });

  factory NotificationSettings.defaultSettings() => const NotificationSettings(
        matchNotifications: true,
        messageNotifications: true,
        likeNotifications: true,
        superLikeNotifications: true,
        soundEnabled: true,
        vibrationEnabled: true,
        quietHoursStart: '22:00',
        quietHoursEnd: '08:00',
        quietHoursEnabled: false,
      );

  factory NotificationSettings.fromMap(Map<String, dynamic> map) =>
      NotificationSettings(
        matchNotifications: map['matchNotifications'] ?? true,
        messageNotifications: map['messageNotifications'] ?? true,
        likeNotifications: map['likeNotifications'] ?? true,
        superLikeNotifications: map['superLikeNotifications'] ?? true,
        soundEnabled: map['soundEnabled'] ?? true,
        vibrationEnabled: map['vibrationEnabled'] ?? true,
        quietHoursStart: map['quietHoursStart'] ?? '22:00',
        quietHoursEnd: map['quietHoursEnd'] ?? '08:00',
        quietHoursEnabled: map['quietHoursEnabled'] ?? false,
      );
  final bool matchNotifications;
  final bool messageNotifications;
  final bool likeNotifications;
  final bool superLikeNotifications;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;
  final bool quietHoursEnabled;

  Map<String, dynamic> toMap() => {
        'matchNotifications': matchNotifications,
        'messageNotifications': messageNotifications,
        'likeNotifications': likeNotifications,
        'superLikeNotifications': superLikeNotifications,
        'soundEnabled': soundEnabled,
        'vibrationEnabled': vibrationEnabled,
        'quietHoursStart': quietHoursStart,
        'quietHoursEnd': quietHoursEnd,
        'quietHoursEnabled': quietHoursEnabled,
      };

  NotificationSettings copyWith({
    bool? matchNotifications,
    bool? messageNotifications,
    bool? likeNotifications,
    bool? superLikeNotifications,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? quietHoursEnabled,
  }) =>
      NotificationSettings(
        matchNotifications: matchNotifications ?? this.matchNotifications,
        messageNotifications: messageNotifications ?? this.messageNotifications,
        likeNotifications: likeNotifications ?? this.likeNotifications,
        superLikeNotifications:
            superLikeNotifications ?? this.superLikeNotifications,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
        quietHoursStart: quietHoursStart ?? this.quietHoursStart,
        quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
        quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      );
}

/// Model for account deletion information
class AccountDeletionInfo {
  const AccountDeletionInfo({
    required this.canDelete,
    this.hasActiveSubscription = false,
    this.hasActiveMatches = false,
    this.reason,
  });
  final bool canDelete;
  final bool hasActiveSubscription;
  final bool hasActiveMatches;
  final String? reason;
}
