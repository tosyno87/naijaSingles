import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../features/match/models/match_model.dart';

/// Optimized match service that reduces Firestore reads from 5-10 to 2-3 per match
/// Uses efficient query patterns and batch operations
class OptimizedMatchService {
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
  static const Duration LIKE_CHECK_CACHE_DURATION = Duration(minutes: 5);

  /// Optimized like handling with minimal Firestore reads
  /// Target: 2-3 reads maximum per match operation
  Future<OptimizedMatchResult> handleLike(
      String fromUserId, String toUserId,) async {
    try {
      if (fromUserId.isEmpty || toUserId.isEmpty) {
        return OptimizedMatchResult.error('Invalid user IDs provided');
      }

      debugPrint('💝 Processing like: $fromUserId → $toUserId');

      // Step 1: Check if users have already liked each other (1 read)
      final mutualLikeResult = await _checkMutualLike(fromUserId, toUserId);

      if (mutualLikeResult.isExistingMatch) {
        debugPrint('✅ Match already exists: ${mutualLikeResult.matchId}');
        return OptimizedMatchResult.existingMatch(mutualLikeResult.matchId!);
      }

      // Step 2: Save the current like (1 write)
      await _saveLike(fromUserId, toUserId);

      if (mutualLikeResult.isMutualLike) {
        debugPrint('🎉 Mutual like detected! Creating match...');

        // Step 3: Create match with batch operation (1 write batch)
        final matchId = await _createMatchOptimized(fromUserId, toUserId);

        if (matchId != null) {
          debugPrint('✅ Match created: $matchId');
          return OptimizedMatchResult.newMatch(matchId, toUserId);
        } else {
          return OptimizedMatchResult.error('Failed to create match');
        }
      } else {
        debugPrint('💌 Like saved, waiting for mutual like');
        return OptimizedMatchResult.likeSaved();
      }
    } catch (e) {
      debugPrint('❌ Error in optimized handleLike: $e');
      return OptimizedMatchResult.error(e.toString());
    }
  }

  /// Check for mutual like with single optimized query
  /// Returns information about existing matches and mutual likes
  Future<MutualLikeCheckResult> _checkMutualLike(
      String fromUserId, String toUserId,) async {
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

      // Single batch read to check both directions and existing matches
      final batch = _firestore.batch();

      // Check if toUser has already liked fromUser
      final reverseLikeDocId = '${toUserId}_likes_$fromUserId';
      final reverseLikeRef = _likesCollection.doc(reverseLikeDocId);

      // Check if match already exists using optimized query
      final existingMatchQuery = _matchesCollection
          .where('users', arrayContains: fromUserId)
          .where('users', arrayContains: toUserId)
          .limit(1);

      // Execute queries concurrently
      final results = await Future.wait([
        reverseLikeRef.get(),
        existingMatchQuery.get(),
      ]);

      final reverseLikeDoc = results[0] as DocumentSnapshot;
      final existingMatchSnapshot = results[1] as QuerySnapshot;

      // Check for existing match
      if (existingMatchSnapshot.docs.isNotEmpty) {
        final matchId = existingMatchSnapshot.docs.first.id;
        debugPrint('🔍 Found existing match: $matchId');
        return MutualLikeCheckResult(
          isMutualLike: false,
          isExistingMatch: true,
          matchId: matchId,
        );
      }

      // Check for mutual like
      final isMutualLike = reverseLikeDoc.exists;

      // Cache the result
      _recentLikeChecks[cacheKey] = isMutualLike;
      _likeCheckTimestamps[cacheKey] = DateTime.now();

      debugPrint('🔍 Mutual like check: $isMutualLike');

      return MutualLikeCheckResult(
        isMutualLike: isMutualLike,
        isExistingMatch: false,
      );
    } catch (e) {
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
  Future<String?> _createMatchOptimized(String userAId, String userBId) async {
    try {
      // Get user data for match creation (1 read - batch)
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

      final userAData = userADoc.data() as Map<String, dynamic>;
      final userBData = userBDoc.data() as Map<String, dynamic>;

      final userAName = userAData['name'] ?? 'User';
      final userBName = userBData['name'] ?? 'User';

      // Create all documents in a single batch operation
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
      final userAImageUrl = (userAData['imageUrl'] as List?)?.isNotEmpty ?? false
          ? userAData['imageUrl'][0]
          : '';
      final userBImageUrl = (userBData['imageUrl'] as List?)?.isNotEmpty ?? false
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
    } catch (e) {
      debugPrint('❌ Error creating optimized match: $e');
      return null;
    }
  }

  /// Check if like check result is cached and valid
  bool _isLikeCheckCached(String cacheKey) {
    if (!_likeCheckTimestamps.containsKey(cacheKey)) return false;

    final cacheAge = DateTime.now().difference(_likeCheckTimestamps[cacheKey]!);
    return cacheAge < LIKE_CHECK_CACHE_DURATION;
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

    debugPrint('🧹 Cleared ${keysToRemove.length} cache entries');
  }

  /// Get user matches with optimized query
  Future<List<MatchModel>> getUserMatches(String userId) async {
    try {
      final querySnapshot = await _matchesCollection
          .where('users', arrayContains: userId)
          .orderBy('matchedAt', descending: true)
          .limit(50) // Limit for performance
          .get();

      return querySnapshot.docs
          .map(MatchModel.fromDocument)
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting user matches: $e');
      return [];
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
    } catch (e) {
      debugPrint('❌ Error checking if user has liked: $e');
      return false;
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() => {
      'likeCheckCacheSize': _recentLikeChecks.length,
      'oldestCacheEntry': _likeCheckTimestamps.values.isNotEmpty
          ? _likeCheckTimestamps.values
              .reduce((a, b) => a.isBefore(b) ? a : b)
              .toString()
          : 'None',
    };

  /// Clear all caches
  void clearCache() {
    _recentLikeChecks.clear();
    _likeCheckTimestamps.clear();
    debugPrint('🗑️ Optimized match service cache cleared');
  }
}

/// Result class for optimized match operations
class OptimizedMatchResult {

  const OptimizedMatchResult._({
    required this.isSuccess,
    required this.isMatch,
    required this.isExistingMatch,
    this.matchId,
    this.otherUserId,
    this.error,
  });

  factory OptimizedMatchResult.newMatch(String matchId, String otherUserId) => OptimizedMatchResult._(
      isSuccess: true,
      isMatch: true,
      isExistingMatch: false,
      matchId: matchId,
      otherUserId: otherUserId,
    );

  factory OptimizedMatchResult.existingMatch(String matchId) => OptimizedMatchResult._(
      isSuccess: true,
      isMatch: true,
      isExistingMatch: true,
      matchId: matchId,
    );

  factory OptimizedMatchResult.likeSaved() => const OptimizedMatchResult._(
      isSuccess: true,
      isMatch: false,
      isExistingMatch: false,
    );

  factory OptimizedMatchResult.error(String error) => OptimizedMatchResult._(
      isSuccess: false,
      isMatch: false,
      isExistingMatch: false,
      error: error,
    );
  final bool isSuccess;
  final bool isMatch;
  final bool isExistingMatch;
  final String? matchId;
  final String? otherUserId;
  final String? error;

  @override
  String toString() => 'OptimizedMatchResult(isSuccess: $isSuccess, isMatch: $isMatch, isExistingMatch: $isExistingMatch, matchId: $matchId, error: $error)';
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
