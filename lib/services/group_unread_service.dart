import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing unread message counts and indicators for groups
class GroupUnreadService {
  factory GroupUnreadService() => _instance;
  GroupUnreadService._internal();
  static final GroupUnreadService _instance = GroupUnreadService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get unread message count for a specific group
  Future<int> getUnreadCount(String groupId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return 0;

      final doc = await _firestore
          .collection('group_unread_counts')
          .doc('${groupId}_$currentUserId')
          .get();

      if (doc.exists) {
        return doc.data()?['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      log('Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark all messages in a group as read for current user
  Future<void> markGroupAsRead(String groupId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      // Update unread count to 0
      await _firestore
          .collection('group_unread_counts')
          .doc('${groupId}_$currentUserId')
          .set({
        'groupId': groupId,
        'userId': currentUserId,
        'count': 0,
        'lastReadAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true),);

      // Mark all unread messages as read
      final unreadMessages = await _firestore
          .collection('unifiedGroups')
          .doc(groupId)
          .collection('messages')
          .where('readBy.$currentUserId', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'readBy.$currentUserId': true,
          'readAt.$currentUserId': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      log('✅ Marked group as read: $groupId');
    } catch (e) {
      log('❌ Error marking group as read: $e');
    }
  }

  /// Increment unread count for a group (called when new message arrives)
  Future<void> incrementUnreadCount(String groupId,
      {String? excludeUserId,}) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null || currentUserId == excludeUserId) return;

      // Get all group members
      final groupDoc =
          await _firestore.collection('unifiedGroups').doc(groupId).get();

      if (!groupDoc.exists) return;

      final memberIds = List<String>.from(groupDoc.data()?['memberIds'] ?? []);

      // Increment unread count for all members except sender
      final batch = _firestore.batch();
      for (final memberId in memberIds) {
        if (memberId != excludeUserId) {
          final unreadDocRef = _firestore
              .collection('group_unread_counts')
              .doc('${groupId}_$memberId');

          batch.set(
              unreadDocRef,
              {
                'groupId': groupId,
                'userId': memberId,
                'count': FieldValue.increment(1),
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),);
        }
      }
      await batch.commit();

      log('✅ Incremented unread count for group: $groupId');
    } catch (e) {
      log('❌ Error incrementing unread count: $e');
    }
  }

  /// Stream of unread count for a specific group
  Stream<int> getUnreadCountStream(String groupId) {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('group_unread_counts')
        .doc('${groupId}_$currentUserId')
        .snapshots()
        .map((doc) => doc.data()?['count'] ?? 0);
  }

  /// Get total unread count across all groups
  Future<int> getTotalUnreadCount() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return 0;

      final querySnapshot = await _firestore
          .collection('group_unread_counts')
          .where('userId', isEqualTo: currentUserId)
          .get();

      int total = 0;
      for (final doc in querySnapshot.docs) {
        total += (doc.data()['count'] ?? 0) as int;
      }
      return total;
    } catch (e) {
      log('Error getting total unread count: $e');
      return 0;
    }
  }

  /// Stream of total unread count across all groups
  Stream<int> getTotalUnreadCountStream() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('group_unread_counts')
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (final doc in snapshot.docs) {
        total += (doc.data()['count'] ?? 0) as int;
      }
      return total;
    });
  }

  /// Check if user has unread messages in any group
  Future<bool> hasUnreadMessages() async {
    final total = await getTotalUnreadCount();
    return total > 0;
  }
}
