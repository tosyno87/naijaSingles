import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:naijasingles/models/user_model.dart';
import 'package:naijasingles/services/performance_monitor.dart';

/// Undo service that allows users to reverse their last swipe action
/// Implements Priority 3: User Experience Enhancements
class UndoService {
  static const Duration UNDO_WINDOW = Duration(seconds: 10);
  static const int MAX_UNDO_HISTORY = 5; // Keep last 5 swipes for undo
  static const int DAILY_UNDO_LIMIT = 3; // Free users get 3 undos per day
  static const int PREMIUM_UNDO_LIMIT = 20; // Premium users get more undos

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _likesCollection => _firestore.collection('likes');
  CollectionReference get _matchesCollection =>
      _firestore.collection('matches');
  CollectionReference get _swipeHistoryCollection =>
      _firestore.collection('swipeHistory');

  // In-memory cache for recent swipes
  static final Map<String, List<SwipeAction>> _recentSwipes = {};
  static final Map<String, Timer> _undoTimers = {};

  /// Record a swipe action for potential undo
  Future<void> recordSwipeAction({
    required String userId,
    required String targetUserId,
    required SwipeDirection direction,
    String? matchId,
  }) async {
    try {
      final swipeAction = SwipeAction(
        userId: userId,
        targetUserId: targetUserId,
        direction: direction,
        timestamp: DateTime.now(),
        matchId: matchId,
        canUndo: true,
      );

      // Add to in-memory cache
      _recentSwipes.putIfAbsent(userId, () => []);
      _recentSwipes[userId]!.insert(0, swipeAction); // Add to front

      // Keep only recent swipes
      if (_recentSwipes[userId]!.length > MAX_UNDO_HISTORY) {
        _recentSwipes[userId]!.removeLast();
      }

      // Store in Firestore for persistence
      await _swipeHistoryCollection.add({
        'userId': userId,
        'targetUserId': targetUserId,
        'direction': direction.toString(),
        'timestamp': FieldValue.serverTimestamp(),
        'matchId': matchId,
        'canUndo': true,
        'undone': false,
      });

      // Set timer to disable undo after window expires
      _setUndoTimer(userId, swipeAction);

      debugPrint(
          '📝 Recorded swipe: $userId → $targetUserId (${direction.name})');
    } catch (e) {
      debugPrint('❌ Error recording swipe action: $e');
    }
  }

  /// Check if user can undo their last swipe
  Future<bool> canUndoLastSwipe(String userId) async {
    try {
      final lastSwipe = await getLastSwipeAction(userId);

      if (lastSwipe == null) {
        return false;
      }

      // Check if within undo window
      final timeSinceSwipe = DateTime.now().difference(lastSwipe.timestamp);
      if (timeSinceSwipe > UNDO_WINDOW) {
        return false;
      }

      // Check if already undone
      if (!lastSwipe.canUndo) {
        return false;
      }

      // Check daily undo limit
      final undoCount = await getDailyUndoCount(userId);
      final isPremiun = await _isPremiuUser(userId);
      final limit = isPremiun ? PREMIUM_UNDO_LIMIT : DAILY_UNDO_LIMIT;

      if (undoCount >= limit) {
        debugPrint(
            '⚠️ User $userId has reached daily undo limit ($undoCount/$limit)');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error checking undo availability: $e');
      return false;
    }
  }

  /// Get the last swipe action for a user
  Future<SwipeAction?> getLastSwipeAction(String userId) async {
    try {
      // Check in-memory cache first
      final cachedSwipes = _recentSwipes[userId];
      if (cachedSwipes != null && cachedSwipes.isNotEmpty) {
        return cachedSwipes.first;
      }

      // Fallback to Firestore
      final querySnapshot = await _swipeHistoryCollection
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      return SwipeAction.fromDocument(doc);
    } catch (e) {
      debugPrint('❌ Error getting last swipe action: $e');
      return null;
    }
  }

  /// Undo the last swipe action
  Future<UndoResult> undoLastSwipe(String userId) async {
    return await PerformanceMonitor.measure('undo_last_swipe', () async {
      try {
        debugPrint('↩️ Attempting to undo last swipe for user $userId');

        // Check if undo is possible
        if (!await canUndoLastSwipe(userId)) {
          return UndoResult.failed(
              'Cannot undo: outside time window or limit reached');
        }

        final lastSwipe = await getLastSwipeAction(userId);
        if (lastSwipe == null) {
          return UndoResult.failed('No recent swipe found to undo');
        }

        // Perform the undo operation
        final success = await _performUndo(lastSwipe);

        if (success) {
          // Mark as undone in cache
          _markSwipeAsUndone(userId, lastSwipe);

          // Record undo usage
          await _recordUndoUsage(userId);

          debugPrint(
              '✅ Successfully undid swipe: ${lastSwipe.userId} → ${lastSwipe.targetUserId}');

          return UndoResult.success(
            targetUserId: lastSwipe.targetUserId,
            originalDirection: lastSwipe.direction,
            wasMatch: lastSwipe.matchId != null,
          );
        } else {
          return UndoResult.failed('Failed to reverse swipe action');
        }
      } catch (e) {
        debugPrint('❌ Error undoing last swipe: $e');
        return UndoResult.failed('Error: ${e.toString()}');
      }
    });
  }

  /// Perform the actual undo operation
  Future<bool> _performUndo(SwipeAction swipeAction) async {
    try {
      final batch = _firestore.batch();

      if (swipeAction.direction == SwipeDirection.right) {
        // Undo right swipe (like)
        await _undoRightSwipe(swipeAction, batch);
      } else {
        // Undo left swipe (pass)
        await _undoLeftSwipe(swipeAction, batch);
      }

      // Mark swipe as undone in history
      final historyQuery = await _swipeHistoryCollection
          .where('userId', isEqualTo: swipeAction.userId)
          .where('targetUserId', isEqualTo: swipeAction.targetUserId)
          .where('timestamp',
              isEqualTo: Timestamp.fromDate(swipeAction.timestamp))
          .limit(1)
          .get();

      if (historyQuery.docs.isNotEmpty) {
        batch.update(historyQuery.docs.first.reference, {
          'undone': true,
          'undoneAt': FieldValue.serverTimestamp(),
          'canUndo': false,
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('❌ Error performing undo: $e');
      return false;
    }
  }

  /// Undo a right swipe (like)
  Future<void> _undoRightSwipe(
      SwipeAction swipeAction, WriteBatch batch) async {
    final userId = swipeAction.userId;
    final targetUserId = swipeAction.targetUserId;

    // Remove like
    final likeDocId = '${userId}_likes_${targetUserId}';
    batch.delete(_likesCollection.doc(likeDocId));

    // If it was a match, remove the match
    if (swipeAction.matchId != null) {
      batch.delete(_matchesCollection.doc(swipeAction.matchId!));

      // Remove from legacy match collections
      batch.delete(
          _usersCollection.doc(userId).collection('Matches').doc(targetUserId));
      batch.delete(
          _usersCollection.doc(targetUserId).collection('Matches').doc(userId));

      debugPrint('🔥 Undoing match: ${swipeAction.matchId}');
    }

    // Remove from checked users so they can see each other again
    batch.delete(_usersCollection
        .doc(userId)
        .collection('CheckedUser')
        .doc(targetUserId));

    debugPrint('💔 Undoing right swipe (like): $userId → $targetUserId');
  }

  /// Undo a left swipe (pass)
  Future<void> _undoLeftSwipe(SwipeAction swipeAction, WriteBatch batch) async {
    final userId = swipeAction.userId;
    final targetUserId = swipeAction.targetUserId;

    // Remove from checked users so they can see each other again
    batch.delete(_usersCollection
        .doc(userId)
        .collection('CheckedUser')
        .doc(targetUserId));

    debugPrint('👈 Undoing left swipe (pass): $userId → $targetUserId');
  }

  /// Set timer to disable undo after window expires
  void _setUndoTimer(String userId, SwipeAction swipeAction) {
    // Cancel existing timer for this user
    _undoTimers[userId]?.cancel();

    // Set new timer
    _undoTimers[userId] = Timer(UNDO_WINDOW, () {
      _markSwipeAsUndone(userId, swipeAction);
      _undoTimers.remove(userId);
    });
  }

  /// Mark a swipe as no longer undoable
  void _markSwipeAsUndone(String userId, SwipeAction swipeAction) {
    final userSwipes = _recentSwipes[userId];
    if (userSwipes != null) {
      final index = userSwipes.indexWhere((s) =>
          s.targetUserId == swipeAction.targetUserId &&
          s.timestamp == swipeAction.timestamp);

      if (index != -1) {
        userSwipes[index] = userSwipes[index].copyWith(canUndo: false);
      }
    }
  }

  /// Get daily undo count for a user
  Future<int> getDailyUndoCount(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final querySnapshot = await _swipeHistoryCollection
          .where('userId', isEqualTo: userId)
          .where('undone', isEqualTo: true)
          .where('undoneAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      debugPrint('❌ Error getting daily undo count: $e');
      return 0;
    }
  }

  /// Record undo usage for analytics
  Future<void> _recordUndoUsage(String userId) async {
    try {
      await _firestore.collection('undoUsage').add({
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'dailyCount': await getDailyUndoCount(userId) + 1,
      });
    } catch (e) {
      debugPrint('❌ Error recording undo usage: $e');
    }
  }

  /// Check if user is premium (placeholder - implement based on your premium system)
  Future<bool> _isPremiuUser(String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['isPremium'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error checking premium status: $e');
      return false;
    }
  }

  /// Get undo statistics for a user
  Future<UndoStats> getUndoStats(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      // Get daily undo count
      final dailyUndos = await getDailyUndoCount(userId);

      // Get total undo count
      final totalUndosQuery = await _swipeHistoryCollection
          .where('userId', isEqualTo: userId)
          .where('undone', isEqualTo: true)
          .get();

      // Get recent swipe history
      final recentSwipesQuery = await _swipeHistoryCollection
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      final recentSwipes = recentSwipesQuery.docs
          .map((doc) => SwipeAction.fromDocument(doc))
          .toList();

      final isPremiun = await _isPremiuUser(userId);
      final dailyLimit = isPremiun ? PREMIUM_UNDO_LIMIT : DAILY_UNDO_LIMIT;

      return UndoStats(
        dailyUndoCount: dailyUndos,
        dailyUndoLimit: dailyLimit,
        totalUndoCount: totalUndosQuery.docs.length,
        recentSwipes: recentSwipes,
        canUndoMore: dailyUndos < dailyLimit,
        isPremium: isPremiun,
      );
    } catch (e) {
      debugPrint('❌ Error getting undo stats: $e');
      return UndoStats.empty();
    }
  }

  /// Clear expired swipe history
  Future<void> clearExpiredHistory() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));

      final expiredQuery = await _swipeHistoryCollection
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .limit(100)
          .get();

      final batch = _firestore.batch();
      for (final doc in expiredQuery.docs) {
        batch.delete(doc.reference);
      }

      if (expiredQuery.docs.isNotEmpty) {
        await batch.commit();
        debugPrint(
            '🗑️ Cleared ${expiredQuery.docs.length} expired swipe history entries');
      }
    } catch (e) {
      debugPrint('❌ Error clearing expired history: $e');
    }
  }

  /// Dispose of the service and cleanup resources
  void dispose() {
    for (final timer in _undoTimers.values) {
      timer.cancel();
    }
    _undoTimers.clear();
    _recentSwipes.clear();
    debugPrint('🗑️ Undo service disposed');
  }
}

/// Represents a swipe action that can be undone
class SwipeAction {
  final String userId;
  final String targetUserId;
  final SwipeDirection direction;
  final DateTime timestamp;
  final String? matchId;
  final bool canUndo;

  const SwipeAction({
    required this.userId,
    required this.targetUserId,
    required this.direction,
    required this.timestamp,
    this.matchId,
    required this.canUndo,
  });

  factory SwipeAction.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SwipeAction(
      userId: data['userId'] ?? '',
      targetUserId: data['targetUserId'] ?? '',
      direction: SwipeDirection.values.firstWhere(
        (d) => d.toString() == data['direction'],
        orElse: () => SwipeDirection.left,
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      matchId: data['matchId'],
      canUndo: data['canUndo'] ?? false,
    );
  }

  SwipeAction copyWith({
    String? userId,
    String? targetUserId,
    SwipeDirection? direction,
    DateTime? timestamp,
    String? matchId,
    bool? canUndo,
  }) {
    return SwipeAction(
      userId: userId ?? this.userId,
      targetUserId: targetUserId ?? this.targetUserId,
      direction: direction ?? this.direction,
      timestamp: timestamp ?? this.timestamp,
      matchId: matchId ?? this.matchId,
      canUndo: canUndo ?? this.canUndo,
    );
  }

  @override
  String toString() {
    return 'SwipeAction(${direction.name}: $userId → $targetUserId, canUndo: $canUndo)';
  }
}

/// Swipe direction enum
enum SwipeDirection {
  left, // Pass/reject
  right, // Like/accept
}

/// Result of an undo operation
class UndoResult {
  final bool isSuccess;
  final String? targetUserId;
  final SwipeDirection? originalDirection;
  final bool wasMatch;
  final String? error;

  const UndoResult._({
    required this.isSuccess,
    this.targetUserId,
    this.originalDirection,
    this.wasMatch = false,
    this.error,
  });

  factory UndoResult.success({
    required String targetUserId,
    required SwipeDirection originalDirection,
    bool wasMatch = false,
  }) {
    return UndoResult._(
      isSuccess: true,
      targetUserId: targetUserId,
      originalDirection: originalDirection,
      wasMatch: wasMatch,
    );
  }

  factory UndoResult.failed(String error) {
    return UndoResult._(
      isSuccess: false,
      error: error,
    );
  }

  @override
  String toString() {
    return 'UndoResult(success: $isSuccess, error: $error)';
  }
}

/// Statistics about undo usage
class UndoStats {
  final int dailyUndoCount;
  final int dailyUndoLimit;
  final int totalUndoCount;
  final List<SwipeAction> recentSwipes;
  final bool canUndoMore;
  final bool isPremium;

  const UndoStats({
    required this.dailyUndoCount,
    required this.dailyUndoLimit,
    required this.totalUndoCount,
    required this.recentSwipes,
    required this.canUndoMore,
    required this.isPremium,
  });

  factory UndoStats.empty() {
    return const UndoStats(
      dailyUndoCount: 0,
      dailyUndoLimit: 3,
      totalUndoCount: 0,
      recentSwipes: [],
      canUndoMore: true,
      isPremium: false,
    );
  }

  int get remainingUndos =>
      (dailyUndoLimit - dailyUndoCount).clamp(0, dailyUndoLimit);
  double get usagePercentage =>
      dailyUndoLimit > 0 ? dailyUndoCount / dailyUndoLimit : 0.0;

  @override
  String toString() {
    return 'UndoStats(\n'
        '  Daily: $dailyUndoCount/$dailyUndoLimit\n'
        '  Total: $totalUndoCount\n'
        '  Can Undo More: $canUndoMore\n'
        '  Premium: $isPremium\n'
        '  Recent Swipes: ${recentSwipes.length}\n'
        ')';
  }
}
