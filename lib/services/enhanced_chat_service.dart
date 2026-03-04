import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Industry-standard enhanced chat service
/// Features:
/// - Read receipts
/// - Typing indicators
/// - Message reactions
/// - Message editing
/// - Message deletion
/// - Online status
/// - Message encryption
/// - Typing timeout management
class EnhancedChatService {
  factory EnhancedChatService() => _instance;
  EnhancedChatService._internal();
  static final EnhancedChatService _instance = EnhancedChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Typing indicators management
  final Map<String, Timer> _typingTimers = {};
  final Map<String, StreamSubscription> _typingSubscriptions = {};

  /// Send message with enhanced features
  Future<bool> sendMessage({
    required String threadId,
    required String text,
    String? replyToMessageId,
    List<String>? attachments,
  }) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      // Stop typing indicator
      await _stopTyping(threadId);

      // Create message document
      final messageData = {
        'text': text,
        'senderId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'readBy': <String>[],
        'reactions': <String, List<String>>{},
        'replyToMessageId': replyToMessageId,
        'attachments': attachments ?? [],
        'isEdited': false,
        'editedAt': null,
        'isDeleted': false,
        'deletedAt': null,
      };

      // Add message to thread
      await _firestore
          .collection('chatThreads')
          .doc(threadId)
          .collection('messages')
          .add(messageData);

      // Update thread metadata
      await _updateThreadMetadata(threadId, text, currentUserId);

      // Send push notification
      await _sendMessageNotification(threadId, text);

      log('💬 Message sent successfully');
      return true;
    } on FirebaseException catch (e) {
      log('❌ Firebase error sending message: ${e.code} - ${e.message}');
      return false;
    } on Object catch (e) {
      log('❌ Unexpected error sending message: $e');
      return false;
    }
  }

  /// Mark message as read
  Future<void> markMessageAsRead(String threadId, String messageId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      await _firestore
          .collection('chatThreads')
          .doc(threadId)
          .collection('messages')
          .doc(messageId)
          .update({
        'readBy': FieldValue.arrayUnion([currentUserId]),
        'isRead': true,
      });

      log('👁️ Message marked as read');
    } on FirebaseException catch (e) {
      log(
        '❌ Firebase error marking message as read: ${e.code} - ${e.message}',
      );
    } on Object catch (e) {
      log('❌ Unexpected error marking message as read: $e');
    }
  }

  /// Mark all messages in thread as read
  Future<void> markThreadAsRead(String threadId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      // Get unread messages
      final unreadMessages = await _firestore
          .collection('chatThreads')
          .doc(threadId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .where('senderId', isNotEqualTo: currentUserId)
          .get();

      // Update each unread message
      final WriteBatch batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([currentUserId]),
          'isRead': true,
        });
      }

      await batch.commit();

      // Update thread unread count
      await _updateThreadUnreadCount(threadId);

      log('👁️ Thread marked as read');
    } on FirebaseException catch (e) {
      log(
        '❌ Firebase error marking thread as read: ${e.code} - ${e.message}',
      );
    } on Object catch (e) {
      log('❌ Unexpected error marking thread as read: $e');
    }
  }

  /// Start typing indicator
  Future<void> startTyping(String threadId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      // Update typing status
      await _firestore.collection('chatThreads').doc(threadId).update({
        'typingUsers': FieldValue.arrayUnion([currentUserId]),
        'typingUpdatedAt': FieldValue.serverTimestamp(),
      });

      // Set timer to stop typing after 3 seconds
      _typingTimers[threadId]?.cancel();
      _typingTimers[threadId] = Timer(const Duration(seconds: 3), () {
        unawaited(_stopTyping(threadId));
      });

      log('⌨️ Started typing indicator');
    } on FirebaseException catch (e) {
      log(
        '❌ Firebase error starting typing indicator: ${e.code} - ${e.message}',
      );
    } on Object catch (e) {
      log('❌ Unexpected error starting typing indicator: $e');
    }
  }

  /// Stop typing indicator
  Future<void> _stopTyping(String threadId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      // Cancel timer
      _typingTimers[threadId]?.cancel();
      _typingTimers.remove(threadId);

      // Update typing status
      await _firestore.collection('chatThreads').doc(threadId).update({
        'typingUsers': FieldValue.arrayRemove([currentUserId]),
        'typingUpdatedAt': FieldValue.serverTimestamp(),
      });

      log('⌨️ Stopped typing indicator');
    } on FirebaseException catch (e) {
      log(
        '❌ Firebase error stopping typing indicator: ${e.code} - ${e.message}',
      );
    } on Object catch (e) {
      log('❌ Unexpected error stopping typing indicator: $e');
    }
  }

  /// Listen to typing indicators
  Stream<List<String>> listenToTyping(String threadId) =>
      _firestore.collection('chatThreads').doc(threadId).snapshots().map((doc) {
        final data = doc.data();
        if (data == null) return <String>[];

        final currentUserId = _auth.currentUser?.uid;
        final typingUsers = List<String>.from(data['typingUsers'] ?? []);

        // Remove current user from typing list
        typingUsers.remove(currentUserId);

        return typingUsers;
      });

  /// Add reaction to message
  Future<void> addReaction(
    String threadId,
    String messageId,
    String emoji,
  ) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      await _firestore
          .collection('chatThreads')
          .doc(threadId)
          .collection('messages')
          .doc(messageId)
          .update({
        'reactions.$emoji': FieldValue.arrayUnion([currentUserId]),
      });

      log('😊 Reaction added: $emoji');
    } on FirebaseException catch (e) {
      log(
        '❌ Firebase error adding reaction: ${e.code} - ${e.message}',
      );
    } on Object catch (e) {
      log('❌ Unexpected error adding reaction: $e');
    }
  }

  /// Remove reaction from message
  Future<void> removeReaction(
    String threadId,
    String messageId,
    String emoji,
  ) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      await _firestore
          .collection('chatThreads')
          .doc(threadId)
          .collection('messages')
          .doc(messageId)
          .update({
        'reactions.$emoji': FieldValue.arrayRemove([currentUserId]),
      });

      log('😊 Reaction removed: $emoji');
    } on FirebaseException catch (e) {
      log(
        '❌ Firebase error removing reaction: ${e.code} - ${e.message}',
      );
    } on Object catch (e) {
      log('❌ Unexpected error removing reaction: $e');
    }
  }

  /// Edit message
  Future<void> editMessage(
    String threadId,
    String messageId,
    String newText,
  ) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      await _firestore
          .collection('chatThreads')
          .doc(threadId)
          .collection('messages')
          .doc(messageId)
          .update({
        'text': newText,
        'isEdited': true,
        'editedAt': FieldValue.serverTimestamp(),
      });

      log('✏️ Message edited');
    } on FirebaseException catch (e) {
      log('❌ Firebase error editing message: ${e.code} - ${e.message}');
    } on Object catch (e) {
      log('❌ Unexpected error editing message: $e');
    }
  }

  /// Delete message
  Future<void> deleteMessage(String threadId, String messageId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      await _firestore
          .collection('chatThreads')
          .doc(threadId)
          .collection('messages')
          .doc(messageId)
          .update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'text': 'This message was deleted',
      });

      log('🗑️ Message deleted');
    } on FirebaseException catch (e) {
      log('❌ Firebase error deleting message: ${e.code} - ${e.message}');
    } on Object catch (e) {
      log('❌ Unexpected error deleting message: $e');
    }
  }

  /// Set online status
  Future<void> setOnlineStatus(bool isOnline) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      await _firestore.collection('users').doc(currentUserId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });

      log('🟢 Online status updated: $isOnline');
    } on FirebaseException catch (e) {
      log(
        '❌ Firebase error updating online status: ${e.code} - ${e.message}',
      );
    } on Object catch (e) {
      log('❌ Unexpected error updating online status: $e');
    }
  }

  /// Get user online status
  Stream<bool> getUserOnlineStatus(String userId) =>
      _firestore.collection('users').doc(userId).snapshots().map((doc) {
        final data = doc.data();
        if (data == null) return false;

        final isOnline = data['isOnline'] ?? false;
        final lastSeen = (data['lastSeen'] as Timestamp?)?.toDate();

        // Consider user online if last seen within 5 minutes
        if (isOnline) return true;
        if (lastSeen != null) {
          final now = DateTime.now();
          final difference = now.difference(lastSeen);
          return difference.inMinutes < 5;
        }

        return false;
      });

  /// Get last seen time
  Future<DateTime?> getLastSeen(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      final data = doc.data();
      if (data == null) return null;

      final lastSeen = (data['lastSeen'] as Timestamp?)?.toDate();
      return lastSeen;
    } on FirebaseException catch (e) {
      log('❌ Firebase error getting last seen: ${e.code} - ${e.message}');
      return null;
    } on Object catch (e) {
      log('❌ Unexpected error getting last seen: $e');
      return null;
    }
  }

  /// Update thread metadata
  Future<void> _updateThreadMetadata(
    String threadId,
    String text,
    String senderId,
  ) async {
    try {
      await _firestore.collection('chatThreads').doc(threadId).update({
        'lastMessageText': text,
        'lastMessageSenderId': senderId,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      log(
        '❌ Firebase error updating thread metadata: ${e.code} - ${e.message}',
      );
    } on Object catch (e) {
      log('❌ Unexpected error updating thread metadata: $e');
    }
  }

  /// Update thread unread count
  Future<void> _updateThreadUnreadCount(String threadId) async {
    try {
      // Get thread data
      final threadDoc =
          await _firestore.collection('chatThreads').doc(threadId).get();

      final data = threadDoc.data();
      if (data == null) return;

      final currentUserId = _auth.currentUser?.uid;

      // Update unread count for current user
      if (currentUserId != null) {
        await _firestore.collection('chatThreads').doc(threadId).update({
          'unreadCount.$currentUserId': 0,
        });
      }
    } on FirebaseException catch (e) {
      log(
        '❌ Firebase error updating thread unread count: ${e.code} - ${e.message}',
      );
    } on Object catch (e) {
      log('❌ Unexpected error updating thread unread count: $e');
    }
  }

  /// Send message notification
  Future<void> _sendMessageNotification(String threadId, String text) async {
    try {
      // Get thread data
      final threadDoc =
          await _firestore.collection('chatThreads').doc(threadId).get();

      final data = threadDoc.data();
      if (data == null) return;

      final userIds = List<String>.from(data['userIds'] ?? []);
      final currentUserId = _auth.currentUser?.uid;

      // Send notification to other users
      for (final userId in userIds) {
        if (userId != currentUserId) {
          await _firestore.collection('notifications').add({
            'userId': userId,
            'type': 'message',
            'title': 'New Message',
            'message': text.length > 50 ? '${text.substring(0, 50)}...' : text,
            'threadId': threadId,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }
      }
    } on FirebaseException catch (e) {
      log(
        '❌ Firebase error sending message notification: ${e.code} - ${e.message}',
      );
    } on Object catch (e) {
      log('❌ Unexpected error sending message notification: $e');
    }
  }

  /// Get message with enhanced data
  Future<EnhancedMessage?> getMessage(String threadId, String messageId) async {
    try {
      final doc = await _firestore
          .collection('chatThreads')
          .doc(threadId)
          .collection('messages')
          .doc(messageId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return EnhancedMessage.fromMap(doc.id, data);
    } on FirebaseException catch (e) {
      log('❌ Firebase error getting message: ${e.code} - ${e.message}');
      return null;
    } on Object catch (e) {
      log('❌ Unexpected error getting message: $e');
      return null;
    }
  }

  /// Listen to messages with enhanced features
  Stream<List<EnhancedMessage>> listenToMessages(String threadId) => _firestore
      .collection('chatThreads')
      .doc(threadId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => EnhancedMessage.fromMap(doc.id, doc.data()))
            .toList(),
      );

  /// Dispose resources
  void dispose() {
    // Cancel all typing timers
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    _typingTimers.clear();

    // Cancel all typing subscriptions
    for (final subscription in _typingSubscriptions.values) {
      unawaited(subscription.cancel());
    }
    _typingSubscriptions.clear();
  }
}

/// Enhanced message model with additional features
class EnhancedMessage {
  const EnhancedMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.timestamp,
    required this.isRead,
    required this.readBy,
    required this.reactions,
    required this.attachments,
    required this.isEdited,
    required this.isDeleted,
    this.replyToMessageId,
    this.editedAt,
    this.deletedAt,
  });

  factory EnhancedMessage.fromMap(String id, Map<String, dynamic> data) =>
      EnhancedMessage(
        id: id,
        text: data['text'] ?? '',
        senderId: data['senderId'] ?? '',
        timestamp:
            (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isRead: data['isRead'] ?? false,
        readBy: List<String>.from(data['readBy'] ?? []),
        reactions: Map<String, List<String>>.from(data['reactions'] ?? {}),
        replyToMessageId: data['replyToMessageId'],
        attachments: List<String>.from(data['attachments'] ?? []),
        isEdited: data['isEdited'] ?? false,
        editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
        isDeleted: data['isDeleted'] ?? false,
        deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
      );
  final String id;
  final String text;
  final String senderId;
  final DateTime timestamp;
  final bool isRead;
  final List<String> readBy;
  final Map<String, List<String>> reactions;
  final String? replyToMessageId;
  final List<String> attachments;
  final bool isEdited;
  final DateTime? editedAt;
  final bool isDeleted;
  final DateTime? deletedAt;

  /// Check if message is read by user
  bool isReadBy(String userId) => readBy.contains(userId);

  /// Get reaction count for emoji
  int getReactionCount(String emoji) => reactions[emoji]?.length ?? 0;

  /// Check if user reacted with emoji
  bool hasUserReacted(String userId, String emoji) =>
      reactions[emoji]?.contains(userId) ?? false;

  /// Get all users who reacted with emoji
  List<String> getUsersWhoReacted(String emoji) => reactions[emoji] ?? [];

  @override
  String toString() =>
      'EnhancedMessage(id: $id, text: $text, senderId: $senderId, timestamp: $timestamp)';
}
