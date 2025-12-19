import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Simple debug functions to test database connectivity and user discovery
class SimpleDebug {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Test basic database connectivity
  static Future<void> testDatabaseConnection() async {
    try {
      debugPrint('🔍 Testing database connection...');

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No authenticated user');
        return;
      }

      debugPrint('✅ Current user: ${currentUser.uid}');

      // Test reading users collection
      final usersQuery = await _firestore.collection('users').limit(5).get();
      debugPrint('📊 Found ${usersQuery.docs.length} users in database');

      for (final doc in usersQuery.docs) {
        final data = doc.data();
        debugPrint('👤 User: ${doc.id} - ${data['name'] ?? 'No name'}');
      }
    } catch (e) {
      debugPrint('❌ Database connection error: $e');
    }
  }

  /// Clear user's swipe history to see users again
  static Future<void> clearSwipeHistory(String userId) async {
    try {
      debugPrint('🧹 Clearing swipe history for user: $userId');

      // Clear CheckedUser collection
      final checkedUsers = await _firestore
          .collection('users')
          .doc(userId)
          .collection('CheckedUser')
          .get();

      final batch = _firestore.batch();
      for (final doc in checkedUsers.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('✅ Cleared ${checkedUsers.docs.length} checked users');
    } catch (e) {
      debugPrint('❌ Error clearing swipe history: $e');
    }
  }

  /// Test like functionality
  static Future<void> testLikeCreation(
    String fromUserId,
    String toUserId,
  ) async {
    try {
      debugPrint('💝 Testing like creation: $fromUserId → $toUserId');

      final likeDocId = '${fromUserId}_likes_$toUserId';

      await _firestore.collection('likes').doc(likeDocId).set({
        'from': fromUserId,
        'to': toUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Like created successfully');
    } catch (e) {
      debugPrint('❌ Error creating like: $e');
    }
  }

  /// Get current user's excluded users
  static Future<void> showExcludedUsers(String userId) async {
    try {
      debugPrint('🚫 Checking excluded users for: $userId');

      // Check CheckedUser collection
      final checkedUsers = await _firestore
          .collection('users')
          .doc(userId)
          .collection('CheckedUser')
          .get();

      debugPrint('👀 Already checked users: ${checkedUsers.docs.length}');
      for (final doc in checkedUsers.docs) {
        debugPrint('   - ${doc.id}');
      }

      // Check blocked users
      final blockedUsers = await _firestore
          .collection('users')
          .doc(userId)
          .collection('blockedlist')
          .get();

      debugPrint('🚫 Blocked users: ${blockedUsers.docs.length}');
      for (final doc in blockedUsers.docs) {
        debugPrint('   - ${doc.id}');
      }
    } catch (e) {
      debugPrint('❌ Error checking excluded users: $e');
    }
  }
}
