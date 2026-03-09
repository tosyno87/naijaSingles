// ignore_for_file: avoid_positional_boolean_parameters

import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing group notification preferences
/// Handles mute/unmute functionality per group
class GroupNotificationService {
  factory GroupNotificationService() => _instance;
  GroupNotificationService._internal();
  static final GroupNotificationService _instance =
      GroupNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get user's notification preferences for a specific group
  Future<bool> isGroupMuted(String groupId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      final doc = await _firestore
          .collection('user_group_notifications')
          .doc('${currentUserId}_$groupId')
          .get();

      if (doc.exists) {
        return doc.data()?['isMuted'] ?? false;
      }
      return false; // Default to not muted
    } on Object catch (e) {
      log('Error checking group mute status: $e');
      return false;
    }
  }

  /// Toggle mute status for a group
  Future<void> toggleGroupMute(String groupId, bool isMuted) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('user_group_notifications')
          .doc('${currentUserId}_$groupId')
          .set(
        {
          'userId': currentUserId,
          'groupId': groupId,
          'isMuted': isMuted,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      log('✅ Group mute status updated: $groupId -> $isMuted');
    } on Object catch (e) {
      log('❌ Error updating group mute status: $e');
      throw Exception('Failed to update notification settings');
    }
  }

  /// Get all muted groups for current user
  Future<List<String>> getMutedGroups() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return [];

      final querySnapshot = await _firestore
          .collection('user_group_notifications')
          .where('userId', isEqualTo: currentUserId)
          .where('isMuted', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data()['groupId'] as String)
          .toList();
    } on Object catch (e) {
      log('Error getting muted groups: $e');
      return [];
    }
  }

  /// Check if user should receive notifications for a group
  Future<bool> shouldReceiveNotifications(String groupId) async =>
      !(await isGroupMuted(groupId));

  /// Stream of mute status for a specific group
  Stream<bool> getGroupMuteStatusStream(String groupId) {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value(false);
    }

    return _firestore
        .collection('user_group_notifications')
        .doc('${currentUserId}_$groupId')
        .snapshots()
        .map((doc) => doc.data()?['isMuted'] ?? false);
  }
}
