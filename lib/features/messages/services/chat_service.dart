import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  final CollectionReference _chatThreadsCollection =
      FirebaseFirestore.instance.collection('chatThreads');

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Check if a chat thread exists between two users
  Future<String?> getChatThreadId(String otherUserId) async {
    try {
      if (currentUserId == null) return null;

      // Query for threads containing both users
      final querySnapshot = await _chatThreadsCollection
          .where('userIds', arrayContains: currentUserId)
          .get();

      // Find the thread that contains the other user
      for (var doc in querySnapshot.docs) {
        final List<dynamic> userIds = doc['userIds'];
        if (userIds.contains(otherUserId)) {
          return doc.id;
        }
      }

      // No thread found
      return null;
    } on FirebaseException catch (e) {
      debugPrint(
        'Firebase error checking for chat thread: ${e.code} - ${e.message}',
      );
      return null;
    } on Object catch (e) {
      debugPrint('Unexpected error checking for chat thread: $e');
      return null;
    }
  }

  // Create a new chat thread between two users
  Future<String?> createChatThread(
    String otherUserId,
    String otherUserName,
  ) async {
    try {
      if (currentUserId == null) return null;

      // Check if thread already exists
      final existingThreadId = await getChatThreadId(otherUserId);
      if (existingThreadId != null) {
        return existingThreadId;
      }

      // Check if users are blocked
      final isBlocked = await isUserBlocked(currentUserId!, otherUserId);
      if (isBlocked) {
        throw Exception('This conversation is not available.');
      }

      // Verify users are matched before creating chat
      final isMatched = await areUsersMatched(currentUserId!, otherUserId);
      if (!isMatched) {
        throw Exception(
          'You can only chat with users you\'ve matched with. Keep swiping to find more matches!',
        );
      }

      // Create a new thread document
      final threadRef = _chatThreadsCollection.doc();
      final threadId = threadRef.id;

      // Get current user's name - handle case where document doesn't exist
      String currentUserName = 'User';
      try {
        final currentUserDoc =
            await _firestore.collection('users').doc(currentUserId).get();
        if (currentUserDoc.exists) {
          final data = currentUserDoc.data();
          if (data != null && data.containsKey('name')) {
            currentUserName = data['name'] as String? ?? 'User';
          }
        }
      } on FirebaseException catch (e) {
        debugPrint(
          'Firebase error getting current user name: ${e.code} - ${e.message}',
        );
        // Continue with default name
      } on Object catch (e) {
        debugPrint('Unexpected error getting current user name: $e');
        // Continue with default name
      }

      // Create thread data
      await threadRef.set({
        'threadId': threadId,
        'userIds': [currentUserId, otherUserId],
        'userNames': {
          currentUserId: currentUserName,
          otherUserId: otherUserName,
        },
        'lastMessage': null,
        'lastMessageText': 'Say hi to $otherUserName!',
        'lastMessageSenderId': null,
        'lastUpdated': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'unreadCount': {currentUserId: 0, otherUserId: 0},
      });

      return threadId;
    } on FirebaseException catch (e) {
      debugPrint(
        'Firebase error creating chat thread: ${e.code} - ${e.message}',
      );

      // Handle specific security rule violations
      if (e.code == 'permission-denied') {
        throw Exception(
          'Unable to start conversation. Please try again later.',
        );
      }

      throw Exception('Failed to create chat: ${e.message}');
    } on Object catch (e) {
      debugPrint('Error creating chat thread: $e');
      // Re-throw our custom exceptions
      if (e.toString().contains('You can only chat with users') ||
          e.toString().contains('This conversation is not available')) {
        rethrow;
      }
      return null;
    }
  }

  // Send a message in a thread
  Future<bool> sendMessage(String threadId, String text) async {
    try {
      if (currentUserId == null) return false;

      // Validate message content locally first
      if (text.trim().isEmpty) {
        throw Exception('Message cannot be empty.');
      }

      if (text.length > 1000) {
        throw Exception(
          'Message is too long. Please keep messages under 1000 characters.',
        );
      }

      // Reference to the messages subcollection
      final messagesRef =
          _chatThreadsCollection.doc(threadId).collection('messages');

      // Get the thread document to find the other user's ID
      String otherUserId = '';
      try {
        final threadDoc = await _chatThreadsCollection.doc(threadId).get();
        if (threadDoc.exists) {
          final data = threadDoc.data() as Map<String, dynamic>?;
          if (data != null && data.containsKey('userIds')) {
            final userIds = List<String>.from(data['userIds']);
            otherUserId = userIds.firstWhere(
              (id) => id != currentUserId,
              orElse: () => '',
            );
          }
        }
      } on FirebaseException catch (e) {
        debugPrint(
          'Firebase error getting thread document: ${e.code} - ${e.message}',
        );
        // Continue with empty otherUserId
      } on Object catch (e) {
        debugPrint('Unexpected error getting thread document: $e');
        // Continue with empty otherUserId
      }

      // Create message data
      final messageData = {
        'senderId': currentUserId,
        'text': text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      };

      // Add the message
      await messagesRef.add(messageData);

      // Update the thread with last message info
      final updateData = {
        'lastMessage': messageData,
        'lastMessageText': text.trim(),
        'lastMessageSenderId': currentUserId,
        'lastUpdated': FieldValue.serverTimestamp(),
        'unreadCount.$currentUserId': 0,
      };

      // Only update the other user's unread count if we found their ID
      if (otherUserId.isNotEmpty) {
        updateData['unreadCount.$otherUserId'] = FieldValue.increment(1);
      }

      await _chatThreadsCollection.doc(threadId).update(updateData);

      return true;
    } on FirebaseException catch (e) {
      debugPrint('Firebase error sending message: ${e.code} - ${e.message}');

      // Handle specific security rule violations
      if (e.code == 'permission-denied') {
        if (e.message?.contains('text.size()') ?? false) {
          throw Exception(
            'Message is too long. Please keep messages under 1000 characters.',
          );
        } else if (e.message?.contains('isUserBlocked') ?? false) {
          throw Exception('This conversation is no longer available.');
        } else {
          throw Exception('Unable to send message. Please try again.');
        }
      }

      throw Exception('Failed to send message: ${e.message}');
    } on Object catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  // Mark messages as read
  Future<void> markThreadAsRead(String threadId) async {
    try {
      if (currentUserId == null) return;

      try {
        // Update the unread count for current user to 0
        await _chatThreadsCollection
            .doc(threadId)
            .update({'unreadCount.$currentUserId': 0});
      } on FirebaseException catch (e) {
        debugPrint(
          'Firebase error updating unread count: ${e.code} - ${e.message}',
        );
        // Continue to try marking messages as read
      } on Object catch (e) {
        debugPrint('Unexpected error updating unread count: $e');
        // Continue to try marking messages as read
      }

      try {
        // Mark all unread messages as read
        final messagesRef =
            _chatThreadsCollection.doc(threadId).collection('messages');

        final unreadMessages = await messagesRef
            .where('senderId', isNotEqualTo: currentUserId)
            .where('read', isEqualTo: false)
            .get();

        // Batch update all unread messages
        if (unreadMessages.docs.isNotEmpty) {
          final batch = _firestore.batch();
          for (var doc in unreadMessages.docs) {
            batch.update(doc.reference, {'read': true});
          }

          await batch.commit();
        }
      } on FirebaseException catch (e) {
        debugPrint(
          'Firebase error marking messages as read: ${e.code} - ${e.message}',
        );
      } on Object catch (e) {
        debugPrint('Unexpected error marking messages as read: $e');
      }
    } on FirebaseException catch (e) {
      debugPrint(
        'Firebase error in markThreadAsRead: ${e.code} - ${e.message}',
      );
    } on Object catch (e) {
      debugPrint('Unexpected error in markThreadAsRead: $e');
    }
  }

  // Stream of messages for a specific thread
  Stream<List<Message>> getMessagesStream(String threadId) =>
      _chatThreadsCollection
          .doc(threadId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return Message(
                id: doc.id,
                senderId: data['senderId'] ?? '',
                text: data['text'] ?? '',
                timestamp: (data['timestamp'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                isRead: data['read'] ?? false,
              );
            }).toList(),
          );

  // Stream of all chat threads for current user with enhanced error handling
  Stream<List<MessageThreadInfo>> getChatThreadsStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _chatThreadsCollection
        .where('userIds', arrayContains: currentUserId)
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .handleError((error) {
      debugPrint('Error in getChatThreadsStream: $error');
      // Return empty list on error to prevent UI crashes
      return [];
    }).map((snapshot) {
      try {
        return snapshot.docs
            .map((doc) {
              try {
                final data = doc.data() as Map<String, dynamic>;

                // Find the other user's ID
                final userIds = List<String>.from(data['userIds'] ?? []);
                final otherUserId = userIds.firstWhere(
                  (id) => id != currentUserId,
                  orElse: () => '',
                );

                // Get user names
                final userNames = data['userNames'] as Map<String, dynamic>?;
                final otherUserName = userNames?[otherUserId] ?? 'User';

                // Get unread count for current user
                final unreadCount =
                    data['unreadCount'] as Map<String, dynamic>?;
                final unread = (unreadCount?[currentUserId] ?? 0) > 0;

                return MessageThreadInfo(
                  threadId: doc.id,
                  otherUserId: otherUserId,
                  otherUserName: otherUserName,
                  lastMessage: data['lastMessageText'] ?? 'Say hello!',
                  lastMessageSenderId: data['lastMessageSenderId'],
                  timestamp: (data['lastUpdated'] as Timestamp?)?.toDate() ??
                      DateTime.now(),
                  unread: unread,
                );
              } on FirebaseException catch (e) {
                debugPrint(
                  'Firebase error processing individual thread: ${e.code} - ${e.message}',
                );
                // Return a placeholder thread to avoid breaking the entire list
                return MessageThreadInfo(
                  threadId: doc.id,
                  otherUserId: '',
                  otherUserName: 'Unknown User',
                  lastMessage: 'Error loading message',
                  timestamp: DateTime.now(),
                  unread: false,
                );
              } on Object catch (e) {
                debugPrint('Unexpected error processing individual thread: $e');
                // Return a placeholder thread to avoid breaking the entire list
                return MessageThreadInfo(
                  threadId: doc.id,
                  otherUserId: '',
                  otherUserName: 'Unknown User',
                  lastMessage: 'Error loading message',
                  timestamp: DateTime.now(),
                  unread: false,
                );
              }
            })
            .where((thread) => thread.otherUserId.isNotEmpty)
            .toList();
      } on FirebaseException catch (e) {
        debugPrint(
          'Firebase error mapping chat threads: ${e.code} - ${e.message}',
        );
        return <MessageThreadInfo>[];
      } on Object catch (e) {
        debugPrint('Unexpected error mapping chat threads: $e');
        return <MessageThreadInfo>[];
      }
    });
  }

  // Check if two users are matched
  Future<bool> areUsersMatched(String userId1, String userId2) async {
    try {
      // Check in matches collection
      final matchQuery = await _firestore
          .collection('matches')
          .where('users', arrayContains: userId1)
          .get();

      for (var doc in matchQuery.docs) {
        final users = List<String>.from(doc.data()['users'] ?? []);
        if (users.contains(userId2)) {
          return true;
        }
      }

      // Check legacy Matches collection
      final legacyMatchQuery = await _firestore
          .collection('Matches')
          .where('users', arrayContains: userId1)
          .get();

      for (var doc in legacyMatchQuery.docs) {
        final data = doc.data();
        final users = List<String>.from(data['users'] ?? []);
        if (users.contains(userId2)) {
          return true;
        }

        // Also check user1/user2 fields for backward compatibility
        if ((data['user1'] == userId1 && data['user2'] == userId2) ||
            (data['user1'] == userId2 && data['user2'] == userId1)) {
          return true;
        }
      }

      return false;
    } on FirebaseException catch (e) {
      debugPrint(
        'Firebase error checking if users are matched: ${e.code} - ${e.message}',
      );
      return false;
    } on Object catch (e) {
      debugPrint('Unexpected error checking if users are matched: $e');
      return false;
    }
  }

  // Check if a user is blocked by another user
  Future<bool> isUserBlocked(String userId, String blockedUserId) async {
    try {
      // Check if userId has blocked blockedUserId
      final userBlockDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('blockedlist')
          .doc(blockedUserId)
          .get();

      if (userBlockDoc.exists) {
        return true;
      }

      // Check if blockedUserId has blocked userId
      final blockedUserBlockDoc = await _firestore
          .collection('users')
          .doc(blockedUserId)
          .collection('blockedlist')
          .doc(userId)
          .get();

      return blockedUserBlockDoc.exists;
    } on FirebaseException catch (e) {
      debugPrint(
        'Firebase error checking if user is blocked: ${e.code} - ${e.message}',
      );
      return false;
    } on Object catch (e) {
      debugPrint('Unexpected error checking if user is blocked: $e');
      return false;
    }
  }

  // Delete a chat thread and all its messages, and unmatch users
  Future<bool> deleteChatThread(String threadId) async {
    try {
      if (currentUserId == null) {
        debugPrint('❌ Cannot delete chat: No current user');
        return false;
      }

      // Get thread info to find the other user
      final threadDoc = await _chatThreadsCollection.doc(threadId).get();
      if (!threadDoc.exists) {
        debugPrint('❌ Chat thread not found: $threadId');
        return false;
      }

      final threadData = threadDoc.data() as Map<String, dynamic>;
      final userIds = List<String>.from(threadData['userIds'] ?? []);

      if (userIds.length != 2) {
        debugPrint(
          '❌ Invalid chat thread: Expected 2 users, got ${userIds.length}',
        );
        return false;
      }

      // Verify current user is part of this chat
      if (!userIds.contains(currentUserId)) {
        debugPrint(
          '❌ Permission denied: User $currentUserId not part of chat $threadId',
        );
        return false;
      }

      final otherUserId = userIds.firstWhere((id) => id != currentUserId);
      debugPrint('🗑️ Deleting chat between $currentUserId and $otherUserId');

      // Delete all messages in the thread first
      await _deleteAllMessagesInThread(threadId);

      // Delete the thread document
      await _chatThreadsCollection.doc(threadId).delete();
      debugPrint('✅ Chat thread deleted: $threadId');

      // Unmatch users - remove from both users' matches collections
      await _unmatchUsers(currentUserId!, otherUserId);

      debugPrint(
        '✅ Chat deleted and users unmatched: $currentUserId <-> $otherUserId',
      );
      return true;
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ Firebase error deleting chat thread: ${e.code} - ${e.message}',
      );
      return false;
    } on Object catch (e) {
      debugPrint('❌ Unexpected error deleting chat thread: $e');
      return false;
    }
  }

  // Helper method to delete all messages in a thread
  Future<void> _deleteAllMessagesInThread(String threadId) async {
    try {
      final messagesRef =
          _chatThreadsCollection.doc(threadId).collection('messages');
      final messagesSnapshot = await messagesRef.get();

      if (messagesSnapshot.docs.isEmpty) {
        debugPrint('📭 No messages to delete in thread $threadId');
        return;
      }

      // Delete messages in batches to avoid hitting Firestore limits
      const batchSize = 500;
      final docs = messagesSnapshot.docs;

      for (int i = 0; i < docs.length; i += batchSize) {
        final batch = _firestore.batch();
        final endIndex =
            (i + batchSize < docs.length) ? i + batchSize : docs.length;

        for (int j = i; j < endIndex; j++) {
          batch.delete(docs[j].reference);
        }

        await batch.commit();
        debugPrint(
          '🗑️ Deleted ${endIndex - i} messages from thread $threadId',
        );
      }

      debugPrint('✅ All messages deleted from thread $threadId');
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ Firebase error deleting messages: ${e.code} - ${e.message}',
      );
      // Don't throw - continue with thread deletion even if message deletion fails
    } on Object catch (e) {
      debugPrint('❌ Unexpected error deleting messages: $e');
      // Don't throw - continue with thread deletion even if message deletion fails
    }
  }

  // Unmatch two users by removing their match records
  Future<void> _unmatchUsers(String userId1, String userId2) async {
    try {
      debugPrint('🔄 Unmatching users: $userId1 <-> $userId2');

      // Use separate operations instead of batch to handle permission issues better
      await _removeFromMatchesCollection(userId1, userId2);
      await _removeFromLegacyMatchesCollection(userId1, userId2);
      await _removeFromUserSubcollections(userId1, userId2);
      await _removeLikesForUnmatch(userId1, userId2);

      debugPrint('✅ Users successfully unmatched');
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ Firebase error unmatching users: ${e.code} - ${e.message}',
      );
      // Don't throw - unmatching is secondary to chat deletion
    } on Object catch (e) {
      debugPrint('❌ Unexpected error unmatching users: $e');
      // Don't throw - unmatching is secondary to chat deletion
    }
  }

  // Remove from new matches collection
  Future<void> _removeFromMatchesCollection(
    String userId1,
    String userId2,
  ) async {
    try {
      final matchesQuery = await _firestore
          .collection('matches')
          .where('users', arrayContains: userId1)
          .get();

      for (var doc in matchesQuery.docs) {
        final users = List<String>.from(doc.data()['users'] ?? []);
        if (users.contains(userId2)) {
          await doc.reference.delete();
          debugPrint('🗑️ Deleted match: ${doc.id}');
        }
      }
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ Firebase error removing from matches collection: ${e.code} - ${e.message}',
      );
    } on Object catch (e) {
      debugPrint('❌ Unexpected error removing from matches collection: $e');
    }
  }

  // Remove from legacy Matches collection
  Future<void> _removeFromLegacyMatchesCollection(
    String userId1,
    String userId2,
  ) async {
    try {
      final legacyMatchesQuery = await _firestore
          .collection('Matches')
          .where('users', arrayContains: userId1)
          .get();

      for (var doc in legacyMatchesQuery.docs) {
        final users = List<String>.from(doc.data()['users'] ?? []);
        if (users.contains(userId2)) {
          await doc.reference.delete();
          debugPrint('🗑️ Deleted legacy match: ${doc.id}');
        }
      }
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ Firebase error removing from legacy matches collection: ${e.code} - ${e.message}',
      );
    } on Object catch (e) {
      debugPrint(
          '❌ Unexpected error removing from legacy matches collection: $e');
    }
  }

  // Remove from user subcollections
  Future<void> _removeFromUserSubcollections(
    String userId1,
    String userId2,
  ) async {
    try {
      // Remove from user1's matches subcollection
      try {
        await _firestore
            .collection('users')
            .doc(userId1)
            .collection('Matches')
            .doc(userId2)
            .delete();
        debugPrint('🗑️ Removed $userId2 from $userId1 matches subcollection');
      } on FirebaseException catch (e) {
        debugPrint(
          '⚠️ Firebase error removing from $userId1 matches subcollection: ${e.code} - ${e.message}',
        );
      } on Object catch (e) {
        debugPrint(
          '⚠️ Could not remove from $userId1 matches subcollection: $e',
        );
      }

      // Remove from user2's matches subcollection
      try {
        await _firestore
            .collection('users')
            .doc(userId2)
            .collection('Matches')
            .doc(userId1)
            .delete();
        debugPrint('🗑️ Removed $userId1 from $userId2 matches subcollection');
      } on FirebaseException catch (e) {
        debugPrint(
          '⚠️ Firebase error removing from $userId2 matches subcollection: ${e.code} - ${e.message}',
        );
      } on Object catch (e) {
        debugPrint(
          '⚠️ Could not remove from $userId2 matches subcollection: $e',
        );
      }
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ Firebase error removing from user subcollections: ${e.code} - ${e.message}',
      );
    } on Object catch (e) {
      debugPrint('❌ Unexpected error removing from user subcollections: $e');
    }
  }

  // Remove likes to prevent immediate re-matching
  Future<void> _removeLikesForUnmatch(String userId1, String userId2) async {
    try {
      // Remove user2 from user1's LikedBy collection
      try {
        await _firestore
            .collection('users')
            .doc(userId1)
            .collection('LikedBy')
            .doc(userId2)
            .delete();
        debugPrint('🗑️ Removed like: $userId2 -> $userId1');
      } on FirebaseException catch (e) {
        debugPrint(
          '⚠️ Firebase error removing like $userId2 -> $userId1: ${e.code} - ${e.message}',
        );
      } on Object catch (e) {
        debugPrint('⚠️ Could not remove like $userId2 -> $userId1: $e');
      }

      // Remove user1 from user2's LikedBy collection
      try {
        await _firestore
            .collection('users')
            .doc(userId2)
            .collection('LikedBy')
            .doc(userId1)
            .delete();
        debugPrint('🗑️ Removed like: $userId1 -> $userId2');
      } on FirebaseException catch (e) {
        debugPrint(
          '⚠️ Firebase error removing like $userId1 -> $userId2: ${e.code} - ${e.message}',
        );
      } on Object catch (e) {
        debugPrint('⚠️ Could not remove like $userId1 -> $userId2: $e');
      }
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ Firebase error removing likes: ${e.code} - ${e.message}',
      );
    } on Object catch (e) {
      debugPrint('❌ Unexpected error removing likes: $e');
    }
  }
}
