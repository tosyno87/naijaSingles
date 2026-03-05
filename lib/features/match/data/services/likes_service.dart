import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../models/match_model.dart';

/// Optimized likes service that handles like actions and match creation
/// Features:
/// - Caching for like checks (reduces Firestore reads)
/// - Batch operations for match creation (reduces writes)
/// - Optimized queries (2-3 reads max per match operation)
/// - Backward compatibility with legacy match collections
class LikesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Collection references
  CollectionReference get _likesCollection => _firestore.collection('likes');
  CollectionReference get _matchesCollection =>
      _firestore.collection('matches');
  CollectionReference get _chatThreadsCollection =>
      _firestore.collection('chatThreads');
  CollectionReference get _usersCollection => _firestore.collection('users');

  // In-memory cache for recent operations
  static final Map<String, bool> _recentLikeChecks = {};
  static final Map<String, DateTime> _likeCheckTimestamps = {};
  static const Duration _likeCheckCacheDuration = Duration(minutes: 5);

  /// Handle like action with mutual like detection (optimized)
  /// Returns the match ID if a mutual match is created, null otherwise
  /// Optimized to use 2-3 Firestore reads maximum
  Future<String?> handleLike(String fromUserId, String toUserId) async {
    try {
      if (fromUserId.isEmpty || toUserId.isEmpty) {
        debugPrint('Invalid user IDs provided');
        return null;
      }

      debugPrint('💝 Processing like: $fromUserId → $toUserId');

      // Step 1: Check if match already exists or mutual like (optimized - 1-2 reads)
      final mutualLikeResult = await _checkMutualLikeOptimized(
        fromUserId,
        toUserId,
      );

      if (mutualLikeResult.isExistingMatch) {
        debugPrint('✅ Match already exists: ${mutualLikeResult.matchId}');
        return mutualLikeResult.matchId;
      }

      // Step 2: Save the current like (1 write)
      await _saveLike(fromUserId, toUserId);

      if (mutualLikeResult.isMutualLike) {
        debugPrint('🎉 Mutual like detected! Creating match...');

        // Step 3: Create match with batch operation (1 write batch)
        final matchId = await _createMatchOptimized(fromUserId, toUserId);

        if (matchId != null) {
          debugPrint('✅ Match created successfully: $matchId');
          await _triggerMatchNotification(fromUserId, toUserId);
          return matchId;
        } else {
          debugPrint('❌ Failed to create match');
          return null;
        }
      } else {
        debugPrint('💌 Like saved, waiting for mutual like');
        return null;
      }
    } on Object catch (e) {
      debugPrint('❌ Error handling like: $e');

      // Provide more specific error messages
      if (e.toString().contains('permission-denied')) {
        debugPrint('🔒 Permission denied - check Firestore rules');
      } else if (e.toString().contains('not-found')) {
        debugPrint('👤 User not found');
      } else if (e.toString().contains('network')) {
        debugPrint('🌐 Network error - check connection');
      }

      return null;
    }
  }

  /// Optimized mutual like check with caching and single query
  /// Returns information about existing matches and mutual likes
  /// Uses 1-2 reads maximum (cached or concurrent queries)
  Future<MutualLikeCheckResult> _checkMutualLikeOptimized(
    String fromUserId,
    String toUserId,
  ) async {
    try {
      // Use cached result if available and recent
      final cacheKey = '${fromUserId}_$toUserId';
      if (_isLikeCheckCached(cacheKey)) {
        debugPrint('🗄️ Using cached like check result');
        return MutualLikeCheckResult(
          isMutualLike: _recentLikeChecks[cacheKey] ?? false,
          isExistingMatch: false,
        );
      }

      // Check if toUser has already liked fromUser.
      // Primary path uses deterministic like document ID for O(1) lookup.
      final reverseLikeDocId = '${toUserId}_likes_$fromUserId';
      final reverseLikeRef = _likesCollection.doc(reverseLikeDocId);

      bool isMutualLike = false;
      try {
        final reverseLikeDoc = await reverseLikeRef.get();
        isMutualLike = reverseLikeDoc.exists;
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          // Fallback query if direct doc read is blocked by stricter rules.
          // This keeps behavior resilient while still scoped to this user pair.
          final reverseLikeQuery = await _likesCollection
              .where('to', isEqualTo: fromUserId)
              .where('from', isEqualTo: toUserId)
              .limit(1)
              .get();
          isMutualLike = reverseLikeQuery.docs.isNotEmpty;
        } else {
          rethrow;
        }
      }

      // Check if match already exists.
      // If rules deny this read, continue with mutual-like result so swipes still work.
      QuerySnapshot? existingMatchSnapshot;
      try {
        existingMatchSnapshot = await _matchesCollection
            .where('users', arrayContains: fromUserId)
            .limit(50)
            .get();
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          debugPrint(
            '⚠️ Permission denied checking existing matches; continuing with like check only',
          );
        } else {
          rethrow;
        }
      }

      // Check for existing match
      if (existingMatchSnapshot != null) {
        for (final doc in existingMatchSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final users = List<String>.from(data['users'] ?? []);

          if (users.contains(fromUserId) && users.contains(toUserId)) {
            debugPrint('🔍 Found existing match: ${doc.id}');
            return MutualLikeCheckResult(
              isMutualLike: false,
              isExistingMatch: true,
              matchId: doc.id,
            );
          }
        }
      }

      // Cache the result
      _recentLikeChecks[cacheKey] = isMutualLike;
      _likeCheckTimestamps[cacheKey] = DateTime.now();

      debugPrint('🔍 Mutual like check: $isMutualLike');

      return MutualLikeCheckResult(
        isMutualLike: isMutualLike,
        isExistingMatch: false,
      );
    } on Object catch (e) {
      debugPrint('❌ Error checking mutual like: $e');
      return const MutualLikeCheckResult(
        isMutualLike: false,
        isExistingMatch: false,
      );
    }
  }

  /// Save like with optimized write
  Future<void> _saveLike(String fromUserId, String toUserId) async {
    final likeDocId = '${fromUserId}_likes_$toUserId';

    await _likesCollection.doc(likeDocId).set({
      'from': fromUserId,
      'to': toUserId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    debugPrint('💾 Like saved: $likeDocId');
  }

  /// Create match with optimized batch operation
  /// Combines match creation, chat thread creation, and legacy updates in single batch
  /// Reduces writes from 4-5 separate operations to 1 batch operation
  Future<String?> _createMatchOptimized(
    String userAId,
    String userBId,
  ) async {
    try {
      // Get user data for match creation (concurrent reads - 2 reads)
      final userDataResults = await Future.wait([
        _usersCollection.doc(userAId).get(),
        _usersCollection.doc(userBId).get(),
      ]);

      final userADoc = userDataResults[0];
      final userBDoc = userDataResults[1];

      if (!userADoc.exists || !userBDoc.exists) {
        debugPrint('❌ One or both users do not exist');
        return null;
      }

      // Prevent match creation if either user is deactivated/incognito
      final userAStatus = (userADoc.data()
              as Map<String, dynamic>?)?['accountStatus'] as String? ??
          'active';
      final userBStatus = (userBDoc.data()
              as Map<String, dynamic>?)?['accountStatus'] as String? ??
          'active';
      if (userAStatus != 'active' || userBStatus != 'active') {
        debugPrint(
          '⏸️ Skipping match creation — userA status: $userAStatus, userB status: $userBStatus',
        );
        return null;
      }

      final userAData = userADoc.data() as Map<String, dynamic>;
      final userBData = userBDoc.data() as Map<String, dynamic>;

      final userAName = userAData['name'] ?? 'User';
      final userBName = userBData['name'] ?? 'User';

      // Create all documents in a single batch operation (1 write batch)
      final batch = _firestore.batch();

      // 1. Create chat thread
      final chatThreadRef = _chatThreadsCollection.doc();
      final chatThreadId = chatThreadRef.id;

      batch.set(chatThreadRef, {
        'userIds': [userAId, userBId],
        'userNames': {
          userAId: userAName,
          userBId: userBName,
        },
        'lastMessage': null,
        'lastMessageText': 'You matched! Say hello!',
        'lastMessageSenderId': null,
        'lastUpdated': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'unreadCount': {
          userAId: 0,
          userBId: 0,
        },
      });

      // 2. Create match document
      final matchRef = _matchesCollection.doc();
      final matchId = matchRef.id;

      batch.set(matchRef, {
        'users': [userAId, userBId],
        'matchedAt': FieldValue.serverTimestamp(),
        'chatThreadId': chatThreadId,
        'matchStatus': 'matched',
      });

      // 3. Update legacy match collections for backward compatibility
      final userAImageUrl =
          (userAData['imageUrl'] as List?)?.isNotEmpty ?? false
              ? userAData['imageUrl'][0]
              : '';
      final userBImageUrl =
          (userBData['imageUrl'] as List?)?.isNotEmpty ?? false
              ? userBData['imageUrl'][0]
              : '';

      // User A's matches
      batch.set(
        _usersCollection.doc(userAId).collection('Matches').doc(userBId),
        {
          'Matches': userBId,
          'isRead': false,
          'userName': userBName,
          'pictureUrl': userBImageUrl,
          'timestamp': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // User B's matches
      batch.set(
        _usersCollection.doc(userBId).collection('Matches').doc(userAId),
        {
          'Matches': userAId,
          'userName': userAName,
          'pictureUrl': userAImageUrl,
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Execute all operations in single batch (1 write batch)
      await batch.commit();

      debugPrint('✅ Match created with batch operation: $matchId');

      // Clear relevant caches
      _clearRelevantCaches(userAId, userBId);

      return matchId;
    } on Object catch (e) {
      debugPrint('❌ Error creating optimized match: $e');
      return null;
    }
  }

  /// Check if like check result is cached and valid
  bool _isLikeCheckCached(String cacheKey) {
    if (!_likeCheckTimestamps.containsKey(cacheKey)) return false;

    final cacheAge = DateTime.now().difference(_likeCheckTimestamps[cacheKey]!);
    return cacheAge < _likeCheckCacheDuration;
  }

  /// Clear relevant caches after match creation
  void _clearRelevantCaches(String userAId, String userBId) {
    final keysToRemove = <String>[];

    for (var key in _likeCheckTimestamps.keys) {
      if (key.contains(userAId) || key.contains(userBId)) {
        keysToRemove.add(key);
      }
    }

    for (final key in keysToRemove) {
      _recentLikeChecks.remove(key);
      _likeCheckTimestamps.remove(key);
    }

    if (keysToRemove.isNotEmpty) {
      debugPrint('🧹 Cleared ${keysToRemove.length} cache entries');
    }
  }

  /// Trigger match notification (Cloud Function handles automatically)
  Future<void> _triggerMatchNotification(
    String userAId,
    String userBId,
  ) async {
    try {
      debugPrint(
        '🎉 Match created! Cloud Function will handle notifications automatically',
      );
      debugPrint('   User A: $userAId');
      debugPrint('   User B: $userBId');

      // The Cloud Function (onMatchCreated) will automatically trigger
      // when the match document is created in _createMatchOptimized()
      // No manual intervention needed - it's fully automated!

      // Optional: Add immediate local feedback for the current user
      await _showLocalMatchFeedback(userAId, userBId);
    } on Object catch (e) {
      debugPrint('❌ Error in match notification trigger: $e');
    }
  }

  /// Show immediate local feedback for match (before push notification arrives)
  Future<void> _showLocalMatchFeedback(String userAId, String userBId) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      // Determine the other user
      final otherUserId = currentUserId == userAId ? userBId : userAId;

      // Get other user's data for immediate feedback
      final otherUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .get();

      if (!otherUserDoc.exists) return;

      final otherUserData = otherUserDoc.data()!;
      final otherUserName = otherUserData['name'] ?? 'Someone';

      debugPrint('✨ Showing immediate match feedback for $otherUserName');

      // You can add a local notification or UI feedback here
      // This provides instant gratification while the push notification is being sent
    } on Object catch (e) {
      debugPrint('Error showing local match feedback: $e');
    }
  }

  /// Check if user has already liked another user (with caching)
  Future<bool> hasUserLiked(String fromUserId, String toUserId) async {
    try {
      final cacheKey = 'has_liked_${fromUserId}_$toUserId';

      if (_isLikeCheckCached(cacheKey)) {
        return _recentLikeChecks[cacheKey] ?? false;
      }

      final likeDocId = '${fromUserId}_likes_$toUserId';
      final likeDoc = await _likesCollection.doc(likeDocId).get();

      final hasLiked = likeDoc.exists;

      // Cache result
      _recentLikeChecks[cacheKey] = hasLiked;
      _likeCheckTimestamps[cacheKey] = DateTime.now();

      return hasLiked;
    } on Object catch (e) {
      debugPrint('Error checking if user has liked: $e');
      return false;
    }
  }

  /// Get all users who liked the current user
  Future<List<String>> getUsersWhoLikedMe(String userId) async {
    try {
      final querySnapshot =
          await _likesCollection.where('to', isEqualTo: userId).get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .map((data) => data['from'] as String)
          .toList();
    } on Object catch (e) {
      debugPrint('Error getting users who liked me: $e');
      return [];
    }
  }

  /// Get all users that the current user has liked
  Future<List<String>> getUsersILiked(String userId) async {
    try {
      final querySnapshot =
          await _likesCollection.where('from', isEqualTo: userId).get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .map((data) => data['to'] as String)
          .toList();
    } on Object catch (e) {
      debugPrint('Error getting users I liked: $e');
      return [];
    }
  }

  /// Get all matches for a user (with limit for performance)
  Future<List<MatchModel>> getUserMatches(String userId) async {
    try {
      final querySnapshot = await _matchesCollection
          .where('users', arrayContains: userId)
          .orderBy('matchedAt', descending: true)
          .limit(50) // Limit for performance
          .get();

      return querySnapshot.docs.map(MatchModel.fromDocument).toList();
    } on Object catch (e) {
      debugPrint('Error getting user matches: $e');
      return [];
    }
  }

  /// Remove a like (for unlike functionality)
  Future<bool> removeLike(String fromUserId, String toUserId) async {
    try {
      final likeDocId = '${fromUserId}_likes_$toUserId';
      await _likesCollection.doc(likeDocId).delete();

      // Clear cache
      final cacheKey = '${fromUserId}_$toUserId';
      _recentLikeChecks.remove(cacheKey);
      _likeCheckTimestamps.remove(cacheKey);

      debugPrint('Like removed: $fromUserId unliked $toUserId');
      return true;
    } on Object catch (e) {
      debugPrint('Error removing like: $e');
      return false;
    }
  }

  /// Get match by ID
  Future<MatchModel?> getMatchById(String matchId) async {
    try {
      final doc = await _matchesCollection.doc(matchId).get();
      if (doc.exists) {
        return MatchModel.fromDocument(doc);
      }
      return null;
    } on Object catch (e) {
      debugPrint('Error getting match by ID: $e');
      return null;
    }
  }

  /// Stream of matches for real-time updates
  Stream<List<MatchModel>> getMatchesStream(String userId) => _matchesCollection
      .where('users', arrayContains: userId)
      .orderBy('matchedAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(MatchModel.fromDocument).toList(),
      );

  /// Get cache statistics (for debugging/monitoring)
  Map<String, dynamic> getCacheStats() => {
        'likeCheckCacheSize': _recentLikeChecks.length,
        'oldestCacheEntry': _likeCheckTimestamps.values.isNotEmpty
            ? _likeCheckTimestamps.values
                .reduce((a, b) => a.isBefore(b) ? a : b)
                .toString()
            : 'None',
      };

  /// Clear all caches (useful for testing or memory management)
  void clearCache() {
    _recentLikeChecks.clear();
    _likeCheckTimestamps.clear();
    debugPrint('🗑️ Likes service cache cleared');
  }
}

/// Result class for mutual like checks
class MutualLikeCheckResult {
  const MutualLikeCheckResult({
    required this.isMutualLike,
    required this.isExistingMatch,
    this.matchId,
  });
  final bool isMutualLike;
  final bool isExistingMatch;
  final String? matchId;
}
