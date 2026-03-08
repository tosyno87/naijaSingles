import 'package:cloud_firestore/cloud_firestore.dart';

import '../common/utils/app_logger.dart';
import '../common/utils/firestore_helpers.dart';
import '../features/match/data/services/likes_service.dart';
import '../features/match/data/services/match_service.dart';
import 'performance_monitor.dart';

/// Super like service that provides premium highlighting and instant notifications
/// Implements Priority 3: User Experience Enhancements
class SuperLikeService {
  static const int freeSuperLikesPerDay = 1;
  static const int premiumSuperLikesPerDay = 5;
  static const Duration superLikeCooldown = Duration(hours: 24);
  static const Duration superLikeHighlightDuration = Duration(days: 3);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MatchService _matchService = MatchService();
  final LikesService _likesService = LikesService();

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _superLikesCollection =>
      _firestore.collection('superLikes');
  CollectionReference get _likesCollection => _firestore.collection('likes');

  // In-memory cache: avoids re-querying Firestore for the daily count within
  // the same session. Firestore remains the source of truth — the cache is
  // populated on first read and incremented optimistically on each send.
  final Map<String, int> _dailyCountCache = {};
  DateTime _dailyCountCacheDate = DateTime(0);

  int? _getCachedDailyCount(String userId) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (_dailyCountCacheDate != todayDate) {
      _dailyCountCache.clear();
      _dailyCountCacheDate = todayDate;
      return null;
    }
    return _dailyCountCache[userId];
  }

  void _setCachedDailyCount(String userId, int count) {
    final today = DateTime.now();
    _dailyCountCacheDate = DateTime(today.year, today.month, today.day);
    _dailyCountCache[userId] = count;
  }

  /// Send a super like to another user.
  ///
  /// [fromUserName] / [fromUserImageUrl] / [toUserName] allow the caller to
  /// supply data it already holds (e.g. from the discovery feed's UserModel)
  /// so we avoid re-fetching user documents — which can fail if Firestore
  /// security rules restrict cross-user profile reads.
  Future<SuperLikeResult> sendSuperLike({
    required String fromUserId,
    required String toUserId,
    String? fromUserName,
    String? fromUserImageUrl,
    String? toUserName,
  }) async =>
      PerformanceMonitor.measure('send_super_like', () async {
        try {
          AppLogger.debug('Sending super like: $fromUserId → $toUserId');

          // ── Phase 1: parallel prerequisite checks ──
          final checks = await Future.wait<Object?>([
            canSendSuperLike(fromUserId),
            _getExistingSuperLike(fromUserId, toUserId),
            _hasAlreadyLiked(fromUserId, toUserId),
          ]);

          final canSend = checks[0]! as SuperLikeEligibility;
          if (!canSend.canSend) {
            return SuperLikeResult.failed(
              canSend.reason ?? 'Cannot send super like',
            );
          }

          if (checks[1] != null) {
            return SuperLikeResult.failed(
              'You have already super liked this user',
            );
          }

          if (checks[2] == true) {
            return SuperLikeResult.failed(
              'You have already liked this user',
            );
          }

          // ── Phase 2: resolve user metadata ──
          Map<String, dynamic> fromUserData;
          Map<String, dynamic> toUserData;

          if (fromUserName != null && toUserName != null) {
            fromUserData = {
              'name': fromUserName,
              'imageUrl':
                  fromUserImageUrl != null ? [fromUserImageUrl] : <String>[],
            };
            toUserData = {'name': toUserName};
          } else {
            try {
              final docs = await Future.wait([
                _usersCollection.doc(fromUserId).get(),
                _usersCollection.doc(toUserId).get(),
              ]);

              if (!docs[0].exists || !docs[1].exists) {
                return SuperLikeResult.failed('User not found');
              }
              fromUserData = docs[0].data() as Map<String, dynamic>;
              toUserData = docs[1].data() as Map<String, dynamic>;
            } on FirebaseException catch (e) {
              AppLogger.warning(
                'Could not fetch user docs for super like metadata: '
                '${e.code} — using fallback names',
                error: e,
              );
              fromUserData = {'name': 'Someone', 'imageUrl': <String>[]};
              toUserData = {'name': 'Someone'};
            }
          }

          // ── Phase 3: batched write (super like + usage in one round-trip) ──
          final superLikeRef = _superLikesCollection.doc();
          final usageRef = _firestore.collection('superLikeUsage').doc();
          final cachedCount = _getCachedDailyCount(fromUserId) ?? 0;

          final batch = _firestore.batch();
          batch.set(superLikeRef, {
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
              DateTime.now().add(superLikeHighlightDuration),
            ),
          });
          batch.update(_usersCollection.doc(fromUserId), {
            'lastSuperLikeUsed': FieldValue.serverTimestamp(),
          });
          batch.set(usageRef, {
            'userId': fromUserId,
            'timestamp': FieldValue.serverTimestamp(),
            'dailyCount': cachedCount + 1,
          });
          await batch.commit();

          _setCachedDailyCount(fromUserId, cachedCount + 1);

          // Notification delivery is handled by the onSuperLikeCreated
          // Cloud Function that triggers on the /superLikes doc we just wrote.
          _logNotificationDelegation(toUserId);

          // ── Phase 4: instant match check (post-write) ──
          final instantMatch =
              await _checkForInstantMatch(fromUserId, toUserId);
          AppLogger.debug('Super like sent: ${superLikeRef.id}');

          return SuperLikeResult.success(
            superLikeId: superLikeRef.id,
            isInstantMatch: instantMatch != null,
            matchId: instantMatch,
          );
        } on FirebaseException catch (e) {
          AppLogger.error('Firebase error sending super like', error: e);
          return SuperLikeResult.failed('Error: ${e.toString()}');
        } on Object catch (e) {
          AppLogger.error('Unexpected error sending super like', error: e);
          return SuperLikeResult.failed('Error: ${e.toString()}');
        }
      });

  /// Check if user can send a super like
  Future<SuperLikeEligibility> canSendSuperLike(String userId) async {
    try {
      final results = await Future.wait([
        getDailySuperLikeCount(userId),
        _isPremiumUser(userId),
      ]);
      final dailyCount = results[0] as int;
      final isPremium = results[1] as bool;
      final dailyLimit =
          isPremium ? premiumSuperLikesPerDay : freeSuperLikesPerDay;

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
      AppLogger.error('Firebase error checking super like eligibility', error: e);
      return SuperLikeEligibility(
        canSend: false,
        reason: 'Error checking eligibility',
        remainingCount: 0,
        nextResetTime: _getNextResetTime(),
      );
    } on Object catch (e) {
      AppLogger.error('Unexpected error checking super like eligibility', error: e);
      return SuperLikeEligibility(
        canSend: false,
        reason: 'Error checking eligibility',
        remainingCount: 0,
        nextResetTime: _getNextResetTime(),
      );
    }
  }

  /// Get daily super like count for a user.
  ///
  /// Returns a session-cached value when available (same calendar day).
  /// Falls back to a Firestore query and populates the cache on miss.
  Future<int> getDailySuperLikeCount(String userId) async {
    final cached = _getCachedDailyCount(userId);
    if (cached != null) {
      return cached;
    }

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

      final count = querySnapshot.docs.length;
      _setCachedDailyCount(userId, count);
      return count;
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error getting daily super like count', error: e);
      return 0;
    } on Object catch (e) {
      AppLogger.error('Unexpected error getting daily super like count', error: e);
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

          AppLogger.debug('Found ${superLikes.length} super likes for user $userId');
          return superLikes;
        } on FirebaseException catch (e) {
          AppLogger.error('Firebase error getting received super likes', error: e);
          return [];
        } on Object catch (e) {
          AppLogger.error('Unexpected error getting received super likes', error: e);
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

          AppLogger.debug('Found ${superLikes.length} sent super likes for user $userId');
          return superLikes;
        } on FirebaseException catch (e) {
          AppLogger.error('Firebase error getting sent super likes', error: e);
          return [];
        } on Object catch (e) {
          AppLogger.error('Unexpected error getting sent super likes', error: e);
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
          AppLogger.debug('Responding to super like: $superLikeId (like: $isLike)');

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
              AppLogger.debug('Super like resulted in match: $matchId');

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
            AppLogger.debug('User passed on super like: $superLikeId');
            return SuperLikeResponse.success();
          }
        } on FirebaseException catch (e) {
          AppLogger.error('Firebase error responding to super like', error: e);
          return SuperLikeResponse.failed('Error: ${e.toString()}');
        } on Object catch (e) {
          AppLogger.error('Unexpected error responding to super like', error: e);
          return SuperLikeResponse.failed('Error: ${e.toString()}');
        }
      });

  /// Notification delivery is handled server-side by the Cloud Function
  /// `onSuperLikeCreated` (triggers on `/superLikes/{id}` creation).
  /// It sends both the FCM push and the in-app notification via Admin SDK,
  /// which avoids Firestore rule limitations on cross-user writes.
  void _logNotificationDelegation(String toUserId) {
    AppLogger.debug('Super-like notification for $toUserId delegated to Cloud Function');
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
      AppLogger.error('Firebase error checking for instant match', error: e);
      return null;
    } on Object catch (e) {
      AppLogger.error('Unexpected error checking for instant match', error: e);
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
      AppLogger.error('Firebase error getting existing super like', error: e);
      return null;
    } on Object catch (e) {
      AppLogger.error('Unexpected error getting existing super like', error: e);
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
      AppLogger.error('Firebase error checking existing like', error: e);
      return false;
    } on Object catch (e) {
      AppLogger.error('Unexpected error checking existing like', error: e);
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
      AppLogger.error('Firebase error checking premium status', error: e);
      return false;
    } on Object catch (e) {
      AppLogger.error('Unexpected error checking premium status', error: e);
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
            isPremium ? premiumSuperLikesPerDay : freeSuperLikesPerDay,
        responseRate: responseRate,
        matchRate: matchRate,
        isPremium: isPremium,
        nextResetTime: _getNextResetTime(),
      );
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error getting super like stats', error: e);
      return SuperLikeStats.empty();
    } on Object catch (e) {
      AppLogger.error('Unexpected error getting super like stats', error: e);
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
        AppLogger.debug('Cleaned up ${expiredQuery.docs.length} expired super like highlights');
      }
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error cleaning up expired highlights', error: e);
    } on Object catch (e) {
      AppLogger.error('Unexpected error cleaning up expired highlights', error: e);
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
      timestamp: parseDateTime(data['timestamp']),
      isActive: data['isActive'] ?? false,
      responded: data['responded'] ?? false,
      responseType: data['responseType'],
      respondedAt: parseDateTimeOrNull(data['respondedAt']),
      highlightUntil: parseDateTimeOrNull(data['highlightUntil']),
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
        dailyLimit: SuperLikeService.freeSuperLikesPerDay,
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
