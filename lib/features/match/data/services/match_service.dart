import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../models/match_model.dart';
import 'likes_service.dart';

/// Main match service that provides a clean interface for match operations
/// Delegates core logic to LikesService which handles optimized like/match operations
class MatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LikesService _likesService = LikesService();

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Collection references
  CollectionReference get _matchesCollection =>
      _firestore.collection('matches');

  /// Handle like action with mutual like detection
  /// This is the main method to call when a user likes another user
  /// Returns match ID if mutual match is created, null otherwise
  Future<String?> handleLike(String toUserId) async {
    try {
      if (currentUserId == null) {
        debugPrint('No current user logged in');
        return null;
      }

      return await _likesService.handleLike(currentUserId!, toUserId);
    } catch (e) {
      debugPrint('Error in handleLike: $e');
      return null;
    }
  }

  /// Create a new match between two users (legacy method - now uses LikesService)
  Future<String?> createMatch({required String otherUserId}) async {
    try {
      if (currentUserId == null) return null;

      // Check if match already exists
      final existingMatch = await getMatchBetweenUsers(otherUserId);
      if (existingMatch != null) {
        return existingMatch;
      }

      // Use the optimized likes service to create match
      return await _likesService.handleLike(currentUserId!, otherUserId);
    } catch (e) {
      debugPrint('Error creating match: $e');
      return null;
    }
  }

  /// Get a match between current user and another user
  Future<String?> getMatchBetweenUsers(String otherUserId) async {
    try {
      if (currentUserId == null) return null;

      final querySnapshot = await _matchesCollection
          .where('users', arrayContainsAny: [currentUserId, otherUserId])
          .get();

      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final users = List<String>.from(data['users'] ?? []);

        if (users.contains(currentUserId) && users.contains(otherUserId)) {
          return doc.id;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error getting match between users: $e');
      return null;
    }
  }

  /// Get all matches for current user
  Future<List<MatchModel>> getUserMatches() async {
    try {
      if (currentUserId == null) return [];

      return await _likesService.getUserMatches(currentUserId!);
    } catch (e) {
      debugPrint('Error getting user matches: $e');
      return [];
    }
  }

  /// Get all matches for current user (legacy format for backward compatibility)
  Future<List<Map<String, dynamic>>> getUserMatchesLegacy() async {
    try {
      if (currentUserId == null) return [];

      final querySnapshot = await _matchesCollection
          .where('users', arrayContains: currentUserId)
          .orderBy('matchedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting user matches: $e');
      return [];
    }
  }

  /// Update match status
  Future<bool> updateMatchStatus(String matchId, String status) async {
    try {
      await _matchesCollection.doc(matchId).update({
        'matchStatus': status,
      });
      return true;
    } catch (e) {
      debugPrint('Error updating match status: $e');
      return false;
    }
  }

  /// Delete a match
  Future<bool> deleteMatch(String matchId) async {
    try {
      await _matchesCollection.doc(matchId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting match: $e');
      return false;
    }
  }

  /// Check if user has already liked another user
  Future<bool> hasUserLiked(String toUserId) async {
    try {
      if (currentUserId == null) return false;
      return await _likesService.hasUserLiked(currentUserId!, toUserId);
    } catch (e) {
      debugPrint('Error checking if user has liked: $e');
      return false;
    }
  }

  /// Get users who liked the current user
  Future<List<String>> getUsersWhoLikedMe() async {
    try {
      if (currentUserId == null) return [];
      return await _likesService.getUsersWhoLikedMe(currentUserId!);
    } catch (e) {
      debugPrint('Error getting users who liked me: $e');
      return [];
    }
  }

  /// Stream of matches for real-time updates
  Stream<List<MatchModel>> getMatchesStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }
    return _likesService.getMatchesStream(currentUserId!);
  }

  /// Get match by ID
  Future<MatchModel?> getMatchById(String matchId) async => _likesService.getMatchById(matchId);
}
