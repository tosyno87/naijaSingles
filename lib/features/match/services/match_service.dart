import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class MatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
  
  // Collection references
  CollectionReference get _matchesCollection => _firestore.collection('matches');
  
  // Create a new match between two users
  Future<String?> createMatch({required String otherUserId}) async {
    try {
      if (currentUserId == null) return null;
      
      // Check if match already exists
      final existingMatch = await getMatchBetweenUsers(otherUserId);
      if (existingMatch != null) {
        return existingMatch;
      }
      
      // Create a new match document
      final matchRef = _matchesCollection.doc();
      final matchId = matchRef.id;
      
      await matchRef.set({
        'matchId': matchId,
        'users': [currentUserId, otherUserId],
        'timestamp': FieldValue.serverTimestamp(),
        'matchStatus': 'matched',
      });
      
      return matchId;
    } catch (e) {
      debugPrint('Error creating match: $e');
      return null;
    }
  }
  
  // Get a match between current user and another user
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
      debugPrint('Error getting match: $e');
      return null;
    }
  }
  
  // Get all matches for current user
  Future<List<Map<String, dynamic>>> getUserMatches() async {
    try {
      if (currentUserId == null) return [];
      
      final querySnapshot = await _matchesCollection
          .where('users', arrayContains: currentUserId!)
          .orderBy('timestamp', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      debugPrint('Error getting user matches: $e');
      return [];
    }
  }
  
  // Update match status
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
  
  // Delete a match
  Future<bool> deleteMatch(String matchId) async {
    try {
      await _matchesCollection.doc(matchId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting match: $e');
      return false;
    }
  }
}
