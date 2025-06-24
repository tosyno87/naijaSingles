import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../message_model.dart';
import '../message_thread_model.dart';

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
        List<dynamic> userIds = doc['userIds'];
        if (userIds.contains(otherUserId)) {
          return doc.id;
        }
      }
      
      // No thread found
      return null;
    } catch (e) {
      debugPrint('Error checking for chat thread: $e');
      return null;
    }
  }
  
  // Create a new chat thread between two users
  Future<String?> createChatThread(String otherUserId, String otherUserName) async {
    try {
      if (currentUserId == null) return null;
      
      // Check if thread already exists
      final existingThreadId = await getChatThreadId(otherUserId);
      if (existingThreadId != null) {
        return existingThreadId;
      }
      
      // Create a new thread document
      final threadRef = _chatThreadsCollection.doc();
      final threadId = threadRef.id;
      
      // Get current user's name - handle case where document doesn't exist
      String currentUserName = 'User';
      try {
        final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
        if (currentUserDoc.exists) {
          final data = currentUserDoc.data() as Map<String, dynamic>?;
          if (data != null && data.containsKey('name')) {
            currentUserName = data['name'] as String? ?? 'User';
          }
        }
      } catch (e) {
        debugPrint('Error getting current user name: $e');
        // Continue with default name
      }
      
      // Create thread data
      await threadRef.set({
        'threadId': threadId,
        'userIds': [currentUserId, otherUserId],
        'userNames': {
          currentUserId: currentUserName,
          otherUserId: otherUserName
        },
        'lastMessage': null,
        'lastMessageText': "Say hi to $otherUserName!",
        'lastMessageSenderId': null,
        'lastUpdated': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'unreadCount': {
          currentUserId: 0,
          otherUserId: 0
        }
      });
      
      return threadId;
    } catch (e) {
      debugPrint('Error creating chat thread: $e');
      return null;
    }
  }
  
  // Send a message in a thread
  Future<bool> sendMessage(String threadId, String text) async {
    try {
      if (currentUserId == null) return false;
      
      // Reference to the messages subcollection
      final messagesRef = _chatThreadsCollection
          .doc(threadId)
          .collection('messages');
      
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
      } catch (e) {
        debugPrint('Error getting thread document: $e');
        // Continue with empty otherUserId
      }
      
      // Create message data
      final messageData = {
        'senderId': currentUserId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false
      };
      
      // Add the message
      await messagesRef.add(messageData);
      
      // Update the thread with last message info
      final updateData = {
        'lastMessage': messageData,
        'lastMessageText': text,
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
    } catch (e) {
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
        await _chatThreadsCollection.doc(threadId).update({
          'unreadCount.$currentUserId': 0
        });
      } catch (e) {
        debugPrint('Error updating unread count: $e');
        // Continue to try marking messages as read
      }
      
      try {
        // Mark all unread messages as read
        final messagesRef = _chatThreadsCollection
            .doc(threadId)
            .collection('messages');
        
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
      } catch (e) {
        debugPrint('Error marking messages as read: $e');
      }
    } catch (e) {
      debugPrint('Error in markThreadAsRead: $e');
    }
  }
  
  // Stream of messages for a specific thread
  Stream<List<Message>> getMessagesStream(String threadId) {
    return _chatThreadsCollection
        .doc(threadId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Message(
              id: doc.id,
              senderId: data['senderId'] ?? '',
              text: data['text'] ?? '',
              timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
              isRead: data['read'] ?? false,
            );
          }).toList();
        });
  }
  
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
        })
        .map((snapshot) {
          try {
            return snapshot.docs.map((doc) {
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
                final unreadCount = data['unreadCount'] as Map<String, dynamic>?;
                final unread = (unreadCount?[currentUserId] ?? 0) > 0;
                
                return MessageThreadInfo(
                  threadId: doc.id,
                  otherUserId: otherUserId,
                  otherUserName: otherUserName,
                  lastMessage: data['lastMessageText'] ?? 'Say hello!',
                  lastMessageSenderId: data['lastMessageSenderId'],
                  timestamp: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  unread: unread,
                  avatarUrl: null, // Will be fetched separately in the UI
                  isOnline: false, // TODO: Implement online status
                );
              } catch (e) {
                debugPrint('Error processing individual thread: $e');
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
            }).where((thread) => thread.otherUserId.isNotEmpty).toList();
          } catch (e) {
            debugPrint('Error mapping chat threads: $e');
            return <MessageThreadInfo>[];
          }
        });
  }
  
  // Get user details
  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user details: $e');
      return null;
    }
  }
}
