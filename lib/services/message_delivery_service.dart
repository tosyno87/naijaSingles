import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Service to handle message delivery status and read receipts
class MessageDeliveryService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Updates the delivery status of a specific message.
  static Future<void> updateMessageStatus({
    required String chatId,
    required String messageId,
    required MessageStatus status,
  }) async {
    try {
      await _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'status': status.name,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });
      log('✅ Message $messageId status updated to ${status.name}');
    } on Object catch (e) {
      log('❌ Error updating message status for $messageId: $e');
    }
  }

  /// Marks all unread messages in a chat as read for the current user.
  static Future<void> markMessagesAsRead(String chatId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      log('⚠️ No current user to mark messages as read.');
      return;
    }

    try {
      final unreadMessages = await _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiver_id', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in unreadMessages.docs) {
        await doc.reference.update({
          'isRead': true,
          'status': MessageStatus.read.name,
          'statusUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
      log('✅ Marked ${unreadMessages.docs.length} messages as read in chat $chatId');
    } on Object catch (e) {
      log('❌ Error marking messages as read in chat $chatId: $e');
    }
  }

  /// Returns the appropriate icon for a given message status.
  static IconData getMessageStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return Icons.schedule; // Clock icon for sent
      case MessageStatus.delivered:
        return Icons.done; // Single checkmark for delivered
      case MessageStatus.read:
        return Icons.done_all; // Double checkmark for read
      case MessageStatus.failed:
        return Icons.error_outline; // Error icon for failed
    }
  }

  /// Returns the appropriate color for a given message status.
  static Color getMessageStatusColor(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return Colors.grey;
      case MessageStatus.delivered:
        return Colors.blue;
      case MessageStatus.read:
        return Colors.green;
      case MessageStatus.failed:
        return Colors.red;
    }
  }
}

/// Enum for message delivery status
enum MessageStatus {
  sent,
  delivered,
  read,
  failed,
}
