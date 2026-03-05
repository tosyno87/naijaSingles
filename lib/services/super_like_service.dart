import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../features/match/data/services/likes_service.dart';
import '../features/match/data/services/match_service.dart';
import 'performance_monitor.dart';

/// Super like service that provides premium highlighting and instant notifications
/// Implements Priority 3: User Experience Enhancements
class SuperLikeService {
  static const int FREE_SUPER_LIKES_PER_DAY = 1;
  static const int PREMIUM_SUPER_LIKES_PER_DAY = 5;
  static const Duration SUPER_LIKE_COOLDOWN = Duration(hours: 24);
  static const Duration SUPER_LIKE_HIGHLIGHT_DURATION = Duration(days: 3);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MatchService _matchService = MatchService();
  final LikesService _likesService = LikesService();

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _superLikesCollection =>
      _firestore.collection('superLikes');
  CollectionReference get _likesCollection => _firestore.collection('likes');

  /// Send a super like to another user
  Future<SuperLikeResult> sendSuperLike({
    required String fromUserId,
    required String toUserId,
  }) async =>
      PerformanceMonitor.measure('send_super_like', () async {
        try {
          debugPrint('⭐ Sending super like: $fromUserId → $toUserId');

          // Check if user can send super like
          final canSend = await canSendSuperLike(fromUserId);
          if (!canSend.canSend) {
            return SuperLikeResult.failed(
              canSend.reason ?? 'Cannot send super like',
            );
          }

          // Check if already super liked this user
          final existingSuperLike =
              await _getExistingSuperLike(fromUserId, toUserId);
          if (existingSuperLike != null) {
            return SuperLikeResult.failed(
              'You have already super liked this user',
            );
          }

          // Check if already liked this user normally
          final existingLike = await _hasAlreadyLiked(fromUserId, toUserId);
          if (existingLike) {
            return SuperLikeResult.failed('You have already liked this user');
          }

          // Get user data for notifications
          final fromUserDoc = await _usersCollection.doc(fromUserId).get();
          final toUserDoc = await _usersCollection.doc(toUserId).get();

          if (!fromUserDoc.exists || !toUserDoc.exists) {
            return SuperLikeResult.failed('User not found');
          }

          final fromUserData = fromUserDoc.data() as Map<String, dynamic>;
          final toUserData = toUserDoc.data() as Map<String, dynamic>;

          // Create super like document
          final superLikeId = await _createSuperLike(
            fromUserId: fromUserId,
            toUserId: toUserId,
            fromUserData: fromUserData,
            toUserData: toUserData,
          );

          if (superLikeId == null) {
            return SuperLikeResult.failed('Failed to create super like');
          }

          // Update user's daily super like count
          await _updateSuperLikeUsage(fromUserId);

          // Send instant notification to recipient
          await _sendSuperLikeNotification(
            fromUserId: fromUserId,
            toUserId: toUserId,
            fromUserName: fromUserData['name'] ?? 'Someone',
            superLikeId: superLikeId,
          );

          // Check for instant match (if recipient has already liked sender)
          final instantMatch =
              await _checkForInstantMatch(fromUserId, toUserId);

          debugPrint('✅ Super like sent successfully: $superLikeId');

          return SuperLikeResult.success(
            superLikeId: superLikeId,
            isInstantMatch: instantMatch != null,
            matchId: instantMatch,
          );
        } on FirebaseException catch (e) {
          debugPrint(
            '❌ Firebase error sending super like: ${e.code} - ${e.message}',
          );
          return SuperLikeResult.failed('Error: ${e.toString()}');
        } on Object catch (e) {
          debugPrint('❌ Unexpected error sending super like: $e');
          return SuperLikeResult.failed('Error: ${e.toString()}');
        }
      });

  /// Check if user can send a super like
  Future<SuperLikeEligibility> canSendSuperLike(String userId) async {
    try {
      // Check daily limit
      final dailyCount = await getDailySuperLikeCount(userId);
      final isPremium = await _isPremiumUser(userId);
      final dailyLimit =
          isPremium ? PREMIUM_SUPER_LIKES_PER_DAY : FREE_SUPER_LIKES_PER_DAY;

      if (dailyCount >= dailyLimit) {
        return SuperLikeEligibility(
          canSend: false,
          reason: 'Daily super like limit reached ($dailyCount/$dailyLimit)',
          remainingCount: 0,
          nextResetTime: _getNextResetTime(),
        );
      }

      return SuperLikeEligibility(
        canSend: true,
        remainingCount: dailyLimit - dailyCount,
        nextResetTime: _getNextResetTime(),
      );
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ Firebase error checking super like eligibility: ${e.code} - ${e.message}',
      );
      return SuperLikeEligibility(
        canSend: false,
        reason: 'Error checking eligibility',
        remainingCount: 0,
        nextResetTime: _getNextResetTime(),
      );
    } on Object catch (e) {
      debugPrint('❌ Unexpected error checking super like eligibility: $e');
      return SuperLikeEligibility(
        canSend: false,
        reason: 'Error checking eligibility',
        remainingCount: 0,
        nextResetTime: _getNextResetTime(),
      );
    }
  }

  /// Get daily super like count for a user
  Future<int> getDailySuperLikeCount(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final querySnapshot = await _superLikesCollection
          .where('fromUserId', isEqualTo: userId)
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .get();

      return querySnapshot.docs.length;
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ Firebase error getting daily super like count: ${e.code} - ${e.message}',
      );
      return 0;
    } on Object catch (e) {
      debugPrint('❌ Unexpected error getting daily super like count: $e');
      return 0;
    }
  }

  /// Get super likes received by a user
  Future<List<SuperLike>> getReceivedSuperLikes(String userId) async =>
      PerformanceMonitor.measure('get_received_super_likes', () async {
        try {
          final querySnapshot = await _superLikesCollection
              .where('toUserId', isEqualTo: userId)
              .where('isActive', isEqualTo: true)
              .orderBy('timestamp', descending: true)
              .limit(50)
              .get();

          final superLikes =
              querySnapshot.docs.map(SuperLike.fromDocument).toList();

          debugPrint(
            '📬 Found ${superLikes.length} super likes for user $userId',
          );
          return superLikes;
        } on FirebaseException catch (e) {
          debugPrint(
            '❌ Firebase error getting received super likes: ${e.code} - ${e.message}',
          );
          return [];
        } on Object catch (e) {
          debugPrint('❌ Unexpected error getting received super likes: $e');
          return [];
        }
      });

  /// Get super likes sent by a user
  Future<List<SuperLike>> getSentSuperLikes(String userId) async =>
      PerformanceMonitor.measure('get_sent_super_likes', () async {
        try {
          final querySnapshot = await _superLikesCollection
              .where('fromUserId', isEqualTo: userId)
              .orderBy('timestamp', descending: true)
              .limit(50)
              .get();

          final superLikes =
              querySnapshot.docs.map(SuperLike.fromDocument).toList();

          debugPrint(
            '📤 Found ${superLikes.length} sent super likes for user $userId',
          );
          return superLikes;
        } on FirebaseException catch (e) {
          debugPrint(
            '❌ Firebase error getting sent super likes: ${e.code} - ${e.message}',
          );
          return [];
        } on Object catch (e) {
          debugPrint('❌ Unexpected error getting sent super likes: $e');
          return [];
        }
      });

  /// Respond to a super like (like back or pass)
  Future<SuperLikeResponse> respondToSuperLike({
    required String superLikeId,
    required String respondingUserId,
    required bool isLike,
  }) async =>
      PerformanceMonitor.measure('respond_to_super_like', () async {
        try {
          debugPrint(
            '💫 Responding to super like: $superLikeId (like: $isLike)',
          );

          final superLikeDoc =
              await _superLikesCollection.doc(superLikeId).get();
          if (!superLikeDoc.exists) {
            return SuperLikeResponse.failed('Super like not found');
          }

          final superLike = SuperLike.fromDocument(superLikeDoc);

          // Verify the responding user is the recipient
          if (superLike.toUserId != respondingUserId) {
            return SuperLikeResponse.failed('Unauthorized response');
          }

          // Update super like with response
          await _superLikesCollection.doc(superLikeId).update({
            'responded': true,
            'responseType': isLike ? 'like' : 'pass',
            'respondedAt': FieldValue.serverTimestamp(),
          });

          if (isLike) {
            // Create match since both users liked each other
            // Note: MatchService.handleLike requires currentUserId, so we need to use LikesService directly
            final matchId = await _matchService.createMatch(
              otherUserId: superLike.fromUserId,
            );

            if (matchId != null) {
              debugPrint(
                '🎉 Super like resulted in match: $matchId',
              );

              return SuperLikeResponse.success(
                isMatch: true,
                matchId: matchId,
              );
            } else {
              // Just record the like
              await _likesCollection
                  .doc('${respondingUserId}_likes_${superLike.fromUserId}')
                  .set({
                'from': respondingUserId,
                'to': superLike.fromUserId,
                'timestamp': FieldValue.serverTimestamp(),
                'isSuperLikeResponse': true,
              });

              return SuperLikeResponse.success();
            }
          } else {
            // User passed on the super like
            debugPrint('👎 User passed on super like: $superLikeId');
            return SuperLikeResponse.success();
          }
        } on FirebaseException catch (e) {
          debugPrint(
            '❌ Firebase error responding to super like: ${e.code} - ${e.message}',
          );
          return SuperLikeResponse.failed('Error: ${e.toString()}');
        } on Object catch (e) {
          debugPrint('❌ Unexpected error responding to super like: $e');
          return SuperLikeResponse.failed('Error: ${e.toString()}');
        }
      });

  /// Create a super like document
  Future<String?> _createSuperLike({
    required String fromUserId,
    required String toUserId,
    required Map<String, dynamic> fromUserData,
    required Map<String, dynamic> toUserData,
  }) async {
    try {
      final superLikeRef = _superLikesCollection.doc();

      await superLikeRef.set({
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'fromUserName': fromUserData['name'] ?? 'Unknown',
        'fromUserImageUrl':
            (fromUserData['imageUrl'] as List?)?.isNotEmpty ?? false
                ? fromUserData['imageUrl'][0]
                : '',
        'toUserName': toUserData['name'] ?? 'Unknown',
        'timestamp': FieldValue.serverTimestamp(),
        'isActive': true,
        'responded': false,
        'highlightUntil': Timestamp.fromDate(
          DateTime.now().add(SUPER_LIKE_HIGHLIGHT_DURATION),
        ),
      });

      return superLikeRef.id;
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ Firebase error creating super like: ${e.code} - ${e.message}',
      );
      return null;
    } on Object catch (e) {
      debugPrint('❌ Unexpected error creating super like: $e');
      return null;
    }
  }

  /// Update user's super like usage count
  Future<void> _updateSuperLikeUsage(String userId) async {
    try {
      await _usersCollection.doc(userId).update({
        'lastSuperLikeUsed': FieldValue.serverTimestamp(),
      });

      // Record usage for analytics
      await _firestore.collection('superLikeUsage').add({
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'dailyCount': await getDailySuperLikeCount(userId),
      });
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ Firebase error updating super like usage: ${e.code} - ${e.message}',
      );
    } on Object catch (e) {
      debugPrint('❌ Unexpected error updating super like usage: $e');
    }
  }

  /// Send instant notification for super like
  Future<void> _sendSuperLikeNotification({
    required String fromUserId,
    required String toUserId,
    required String fromUserName,
    required String superLikeId,
  }) async {
    try {
      // Create notification document
      await _firestore.collection('notifications').add({
        'type': 'super_like',
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'fromUserName': fromUserName,
        'superLikeId': superLikeId,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'priority': 'high',
      });

      // TODO: Send push notification
      // This would integrate with your push notification service
      debugPrint('📱 Super like notification sent to $toUserId');
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ Firebase error sending super like notification: ${e.code} - ${e.message}',
      );
    } on Object catch (e) {
      debugPrint('❌ Unexpected error sending super like notification: $e');
    }
  }

  /// Check for instant match when super like is sent
  Future<String?> _checkForInstantMatch(
    String fromUserId,
    String toUserId,
  ) async {
    try {
      // Check if recipient has already liked the sender
      final reverseLikeDoc =
          await _likesCollection.doc('${toUserId}_likes_$fromUserId').get();

      if (reverseLikeDoc.exists) {
        // Create match using LikesService directly (needs both user IDs)
        final matchId = await _likesService.handleLike(fromUserId, toUserId);
        return matchId;
      }

      return null;
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ Firebase error checking for instant match: ${e.code} - ${e.message}',
      );
      return null;
    } on Object catch (e) {
      debugPrint('❌ Unexpected error checking for instant match: $e');
      return null;
    }
  }

  /// Get existing super like between two users
  Future<SuperLike?> _getExistingSuperLike(
    String fromUserId,
    String toUserId,
  ) async {
    try {
      final querySnapshot = await _superLikesCollection
          .where('fromUserId', isEqualTo: fromUserId)
          .where('toUserId', isEqualTo: toUserId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return SuperLike.fromDocument(querySnapshot.docs.first);
      }

      return null;
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ Firebase error getting existing super like: ${e.code} - ${e.message}',
      );
      return null;
    } on Object catch (e) {
      debugPrint('❌ Unexpected error getting existing super like: $e');
      return null;
    }
  }

  /// Check if user has already liked another user normally
  Future<bool> _hasAlreadyLiked(String fromUserId, String toUserId) async {
    try {
      final likeDoc =
          await _likesCollection.doc('${fromUserId}_likes_$toUserId').get();
      return likeDoc.exists;
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ Firebase error checking existing like: ${e.code} - ${e.message}',
      );
      return false;
    } on Object catch (e) {
      debugPrint('❌ Unexpected error checking existing like: $e');
      return false;
    }
  }

  /// Check if user is premium
  Future<bool> _isPremiumUser(String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['isPremium'] == true;
      }
      return false;
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ Firebase error checking premium status: ${e.code} - ${e.message}',
      );
      return false;
    } on Object catch (e) {
      debugPrint('❌ Unexpected error checking premium status: $e');
      return false;
    }
  }

  /// Get next reset time for super likes
  DateTime _getNextResetTime() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  /// Get super like statistics for a user
  Future<SuperLikeStats> getSuperLikeStats(String userId) async {
    try {
      final sent = await getSentSuperLikes(userId);
      final received = await getReceivedSuperLikes(userId);
      final dailyCount = await getDailySuperLikeCount(userId);
      final isPremium = await _isPremiumUser(userId);

      // Calculate response rate
      final respondedSent = sent.where((sl) => sl.responded).length;
      final responseRate = sent.isNotEmpty ? respondedSent / sent.length : 0.0;

      // Calculate match rate from super likes
      final matchedSent = sent.where((sl) => sl.responseType == 'like').length;
      final matchRate = sent.isNotEmpty ? matchedSent / sent.length : 0.0;

      return SuperLikeStats(
        sentCount: sent.length,
        receivedCount: received.length,
        dailyUsedCount: dailyCount,
        dailyLimit:
            isPremium ? PREMIUM_SUPER_LIKES_PER_DAY : FREE_SUPER_LIKES_PER_DAY,
        responseRate: responseRate,
        matchRate: matchRate,
        isPremium: isPremium,
        nextResetTime: _getNextResetTime(),
      );
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ Firebase error getting super like stats: ${e.code} - ${e.message}',
      );
      return SuperLikeStats.empty();
    } on Object catch (e) {
      debugPrint('❌ Unexpected error getting super like stats: $e');
      return SuperLikeStats.empty();
    }
  }

  /// Clean up expired super like highlights
  Future<void> cleanupExpiredHighlights() async {
    try {
      final expiredQuery = await _superLikesCollection
          .where('highlightUntil', isLessThan: Timestamp.now())
          .where('isActive', isEqualTo: true)
          .limit(100)
          .get();

      final batch = _firestore.batch();
      for (final doc in expiredQuery.docs) {
        batch.update(doc.reference, {'isActive': false});
      }

      if (expiredQuery.docs.isNotEmpty) {
        await batch.commit();
        debugPrint(
          '🧹 Cleaned up ${expiredQuery.docs.length} expired super like highlights',
        );
      }
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ Firebase error cleaning up expired highlights: ${e.code} - ${e.message}',
      );
    } on Object catch (e) {
      debugPrint('❌ Unexpected error cleaning up expired highlights: $e');
    }
  }
}

/// Represents a super like between two users
class SuperLike {
  const SuperLike({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.fromUserName,
    required this.fromUserImageUrl,
    required this.toUserName,
    required this.timestamp,
    required this.isActive,
    required this.responded,
    this.responseType,
    this.respondedAt,
    this.highlightUntil,
  });

  factory SuperLike.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SuperLike(
      id: doc.id,
      fromUserId: data['fromUserId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      fromUserName: data['fromUserName'] ?? '',
      fromUserImageUrl: data['fromUserImageUrl'] ?? '',
      toUserName: data['toUserName'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? false,
      responded: data['responded'] ?? false,
      responseType: data['responseType'],
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
      highlightUntil: (data['highlightUntil'] as Timestamp?)?.toDate(),
    );
  }
  final String id;
  final String fromUserId;
  final String toUserId;
  final String fromUserName;
  final String fromUserImageUrl;
  final String toUserName;
  final DateTime timestamp;
  final bool isActive;
  final bool responded;
  final String? responseType;
  final DateTime? respondedAt;
  final DateTime? highlightUntil;

  bool get isHighlighted =>
      highlightUntil != null && DateTime.now().isBefore(highlightUntil!);
  bool get wasLikedBack => responseType == 'like';
  bool get wasPassed => responseType == 'pass';

  @override
  String toString() =>
      'SuperLike($fromUserName → $toUserName, responded: $responded, active: $isActive)';
}

/// Result of sending a super like
class SuperLikeResult {
  const SuperLikeResult._({
    required this.isSuccess,
    this.superLikeId,
    this.isInstantMatch = false,
    this.matchId,
    this.error,
  });

  factory SuperLikeResult.success({
    required String superLikeId,
    bool isInstantMatch = false,
    String? matchId,
  }) =>
      SuperLikeResult._(
        isSuccess: true,
        superLikeId: superLikeId,
        isInstantMatch: isInstantMatch,
        matchId: matchId,
      );

  factory SuperLikeResult.failed(String error) => SuperLikeResult._(
        isSuccess: false,
        error: error,
      );
  final bool isSuccess;
  final String? superLikeId;
  final bool isInstantMatch;
  final String? matchId;
  final String? error;

  @override
  String toString() =>
      'SuperLikeResult(success: $isSuccess, instantMatch: $isInstantMatch, error: $error)';
}

/// Response to a super like
class SuperLikeResponse {
  const SuperLikeResponse._({
    required this.isSuccess,
    this.isMatch = false,
    this.matchId,
    this.error,
  });

  factory SuperLikeResponse.success({
    bool isMatch = false,
    String? matchId,
  }) =>
      SuperLikeResponse._(
        isSuccess: true,
        isMatch: isMatch,
        matchId: matchId,
      );

  factory SuperLikeResponse.failed(String error) => SuperLikeResponse._(
        isSuccess: false,
        error: error,
      );
  final bool isSuccess;
  final bool isMatch;
  final String? matchId;
  final String? error;

  @override
  String toString() =>
      'SuperLikeResponse(success: $isSuccess, match: $isMatch, error: $error)';
}

/// Super like eligibility check result
class SuperLikeEligibility {
  const SuperLikeEligibility({
    required this.canSend,
    required this.remainingCount,
    required this.nextResetTime,
    this.reason,
  });
  final bool canSend;
  final String? reason;
  final int remainingCount;
  final DateTime nextResetTime;

  Duration get timeUntilReset => nextResetTime.difference(DateTime.now());

  @override
  String toString() =>
      'SuperLikeEligibility(canSend: $canSend, remaining: $remainingCount, reason: $reason)';
}

/// Statistics about super like usage
class SuperLikeStats {
  const SuperLikeStats({
    required this.sentCount,
    required this.receivedCount,
    required this.dailyUsedCount,
    required this.dailyLimit,
    required this.responseRate,
    required this.matchRate,
    required this.isPremium,
    required this.nextResetTime,
  });

  factory SuperLikeStats.empty() => SuperLikeStats(
        sentCount: 0,
        receivedCount: 0,
        dailyUsedCount: 0,
        dailyLimit: SuperLikeService.FREE_SUPER_LIKES_PER_DAY,
        responseRate: 0,
        matchRate: 0,
        isPremium: false,
        nextResetTime: DateTime.now().add(const Duration(days: 1)),
      );
  final int sentCount;
  final int receivedCount;
  final int dailyUsedCount;
  final int dailyLimit;
  final double responseRate;
  final double matchRate;
  final bool isPremium;
  final DateTime nextResetTime;

  int get remainingToday => (dailyLimit - dailyUsedCount).clamp(0, dailyLimit);
  bool get canSendMore => remainingToday > 0;

  @override
  String toString() => 'SuperLikeStats(\n'
      '  Sent: $sentCount\n'
      '  Received: $receivedCount\n'
      '  Daily Used: $dailyUsedCount/$dailyLimit\n'
      '  Response Rate: ${(responseRate * 100).toStringAsFixed(1)}%\n'
      '  Match Rate: ${(matchRate * 100).toStringAsFixed(1)}%\n'
      '  Premium: $isPremium\n'
      ')';
}
