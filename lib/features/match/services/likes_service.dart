import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/match_model.dart';

class LikesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
  
  // Collection references
  CollectionReference get _likesCollection => _firestore.collection('likes');
  CollectionReference get _matchesCollection => _firestore.collection('matches');
  CollectionReference get _chatThreadsCollection => _firestore.collection('chatThreads');
  CollectionReference get _usersCollection => _firestore.collection('users');
  
  /// Handle like action with mutual like detection
  /// Returns the match ID if a mutual match is created, null otherwise
  Future<String?> handleLike(String fromUserId, String toUserId) async {
    try {
      if (fromUserId.isEmpty || toUserId.isEmpty) {
        debugPrint('Invalid user IDs provided');
        return null;
      }

      // Save the like using the specified document ID format
      final likeDocId = '${fromUserId}_likes_${toUserId}';
      await _likesCollection.doc(likeDocId).set({
        'from': fromUserId,
        'to': toUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('Like saved: $fromUserId likes $toUserId');

      // Check for mutual like
      final reverseLikeDocId = '${toUserId}_likes_${fromUserId}';
      final reverseLike = await _likesCollection.doc(reverseLikeDocId).get();

      if (reverseLike.exists) {
        debugPrint('🎉 Mutual like detected! Creating match...');
        
        // Create match and chat thread
        final matchId = await _createMatch(fromUserId, toUserId);
        
        if (matchId != null) {
          debugPrint('✅ Match created successfully: $matchId');
          
          // Optional: Trigger notification or other side effects here
          await _triggerMatchNotification(fromUserId, toUserId);
        }
        
        return matchId;
      } else {
        debugPrint('No mutual like yet. Waiting for $toUserId to like back.');
        return null;
      }
    } catch (e) {
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

  /// Create a match document and associated chat thread
  Future<String?> _createMatch(String userAId, String userBId) async {
    try {
      // Check if match already exists
      final existingMatch = await _getExistingMatch(userAId, userBId);
      if (existingMatch != null) {
        debugPrint('Match already exists: $existingMatch');
        return existingMatch;
      }

      // Get user details for chat thread creation
      final userADoc = await _usersCollection.doc(userAId).get();
      final userBDoc = await _usersCollection.doc(userBId).get();
      
      if (!userADoc.exists || !userBDoc.exists) {
        debugPrint('One or both users do not exist');
        return null;
      }

      final userAData = userADoc.data() as Map<String, dynamic>;
      final userBData = userBDoc.data() as Map<String, dynamic>;
      
      final userAName = userAData['name'] ?? 'User';
      final userBName = userBData['name'] ?? 'User';

      // Create chat thread first
      final chatThreadRef = _chatThreadsCollection.doc();
      final chatThreadId = chatThreadRef.id;

      await chatThreadRef.set({
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
        }
      });

      debugPrint('Chat thread created: $chatThreadId');

      // Create match document
      final matchRef = _matchesCollection.doc();
      final matchId = matchRef.id;

      await matchRef.set({
        'users': [userAId, userBId],
        'matchedAt': FieldValue.serverTimestamp(),
        'chatThreadId': chatThreadId,
        'matchStatus': 'matched',
      });

      debugPrint('Match document created: $matchId');

      // Update legacy match collections for backward compatibility
      await _updateLegacyMatches(userAId, userBId, userAName, userBName, userAData, userBData);

      return matchId;
    } catch (e) {
      debugPrint('Error creating match: $e');
      return null;
    }
  }

  /// Update legacy match collections for backward compatibility
  Future<void> _updateLegacyMatches(
    String userAId, 
    String userBId, 
    String userAName, 
    String userBName,
    Map<String, dynamic> userAData,
    Map<String, dynamic> userBData,
  ) async {
    try {
      // Get image URLs for legacy format
      final userAImageUrl = (userAData['imageUrl'] as List?)?.isNotEmpty == true 
          ? userAData['imageUrl'][0] 
          : '';
      final userBImageUrl = (userBData['imageUrl'] as List?)?.isNotEmpty == true 
          ? userBData['imageUrl'][0] 
          : '';

      // Update User A's matches collection
      await _usersCollection
          .doc(userAId)
          .collection("Matches")
          .doc(userBId)
          .set({
        'Matches': userBId,
        'isRead': false,
        'userName': userBName,
        'pictureUrl': userBImageUrl,
        'timestamp': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));

      // Update User B's matches collection
      await _usersCollection
          .doc(userBId)
          .collection("Matches")
          .doc(userAId)
          .set({
        'Matches': userAId,
        'userName': userAName,
        'pictureUrl': userAImageUrl,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));

      debugPrint('Legacy match collections updated');
    } catch (e) {
      debugPrint('Error updating legacy matches: $e');
    }
  }

  /// Check if a match already exists between two users
  Future<String?> _getExistingMatch(String userAId, String userBId) async {
    try {
      final querySnapshot = await _matchesCollection
          .where('users', arrayContainsAny: [userAId])
          .get();

      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final users = List<String>.from(data['users'] ?? []);
        
        if (users.contains(userAId) && users.contains(userBId)) {
          return doc.id;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error checking existing match: $e');
      return null;
    }
  }

  /// Trigger match notification (Cloud Function handles automatically)
  Future<void> _triggerMatchNotification(String userAId, String userBId) async {
    try {
      debugPrint('🎉 Match created! Cloud Function will handle notifications automatically');
      debugPrint('   User A: $userAId');
      debugPrint('   User B: $userBId');
      
      // The Cloud Function (onMatchCreated) will automatically trigger
      // when the match document is created in _createMatch()
      // No manual intervention needed - it's fully automated!
      
      // Optional: Add immediate local feedback for the current user
      await _showLocalMatchFeedback(userAId, userBId);
      
    } catch (e) {
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
      
    } catch (e) {
      debugPrint('Error showing local match feedback: $e');
    }
  }

  /// Check if user has already liked another user
  Future<bool> hasUserLiked(String fromUserId, String toUserId) async {
    try {
      final likeDocId = '${fromUserId}_likes_${toUserId}';
      final likeDoc = await _likesCollection.doc(likeDocId).get();
      return likeDoc.exists;
    } catch (e) {
      debugPrint('Error checking if user has liked: $e');
      return false;
    }
  }

  /// Get all users who liked the current user
  Future<List<String>> getUsersWhoLikedMe(String userId) async {
    try {
      final querySnapshot = await _likesCollection
          .where('to', isEqualTo: userId)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .map((data) => data['from'] as String)
          .toList();
    } catch (e) {
      debugPrint('Error getting users who liked me: $e');
      return [];
    }
  }

  /// Get all users that the current user has liked
  Future<List<String>> getUsersILiked(String userId) async {
    try {
      final querySnapshot = await _likesCollection
          .where('from', isEqualTo: userId)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .map((data) => data['to'] as String)
          .toList();
    } catch (e) {
      debugPrint('Error getting users I liked: $e');
      return [];
    }
  }

  /// Get all matches for a user
  Future<List<MatchModel>> getUserMatches(String userId) async {
    try {
      final querySnapshot = await _matchesCollection
          .where('users', arrayContains: userId)
          .orderBy('matchedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MatchModel.fromDocument(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting user matches: $e');
      return [];
    }
  }

  /// Remove a like (for unlike functionality)
  Future<bool> removeLike(String fromUserId, String toUserId) async {
    try {
      final likeDocId = '${fromUserId}_likes_${toUserId}';
      await _likesCollection.doc(likeDocId).delete();
      
      debugPrint('Like removed: $fromUserId unliked $toUserId');
      return true;
    } catch (e) {
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
    } catch (e) {
      debugPrint('Error getting match by ID: $e');
      return null;
    }
  }

  /// Stream of matches for real-time updates
  Stream<List<MatchModel>> getMatchesStream(String userId) {
    return _matchesCollection
        .where('users', arrayContains: userId)
        .orderBy('matchedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MatchModel.fromDocument(doc))
            .toList());
  }
}
