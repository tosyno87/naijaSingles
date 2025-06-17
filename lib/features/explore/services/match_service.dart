import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naijasingles/features/explore/models/liked_user.dart';

class MatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save a like to Firestore
  Future<void> saveLike(String currentUserId, String likedUserId) async {
    final timestamp = DateTime.now();
    
    // Save the like in the current user's likes collection
    await _firestore
        .collection('likes')
        .doc(currentUserId)
        .collection('likedUsers')
        .doc(likedUserId)
        .set({
      'timestamp': timestamp,
    });
  }

  // Check if there's a match (mutual like)
  Future<bool> checkForMatch(String currentUserId, String likedUserId) async {
    final likeDoc = await _firestore
        .collection('likes')
        .doc(likedUserId)
        .collection('likedUsers')
        .doc(currentUserId)
        .get();
    
    return likeDoc.exists;
  }

  // Create a message thread between matched users
  Future<String> createMessageThread(String currentUserId, String matchedUserId) async {
    // Create a unique thread ID by combining both user IDs (sorted to ensure consistency)
    final List<String> userIds = [currentUserId, matchedUserId];
    userIds.sort(); // Sort to ensure the same thread ID regardless of who initiates
    final String threadId = userIds.join('_');
    
    // Check if thread already exists
    final threadDoc = await _firestore.collection('messageThreads').doc(threadId).get();
    
    if (!threadDoc.exists) {
      // Create new thread
      await _firestore.collection('messageThreads').doc(threadId).set({
        'participants': userIds,
        'createdAt': DateTime.now(),
        'lastMessageAt': DateTime.now(),
        'lastMessage': 'You matched! Start a conversation.',
      });
      
      // Add welcome message
      await _firestore
          .collection('messageThreads')
          .doc(threadId)
          .collection('messages')
          .add({
        'senderId': 'system', // System message
        'text': 'You both liked each other. Start the conversation!',
        'timestamp': DateTime.now(),
        'read': false,
      });
    }
    
    return threadId;
  }
  
  // Mark users as matched
  Future<void> markAsMatched(String currentUserId, String matchedUserId) async {
    // Update both users' match collections
    await _firestore
        .collection('matches')
        .doc(currentUserId)
        .collection('userMatches')
        .doc(matchedUserId)
        .set({
      'matchedAt': DateTime.now(),
      'isNew': true,
    });
    
    await _firestore
        .collection('matches')
        .doc(matchedUserId)
        .collection('userMatches')
        .doc(currentUserId)
        .set({
      'matchedAt': DateTime.now(),
      'isNew': true,
    });
  }
}
