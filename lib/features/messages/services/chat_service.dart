import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../common/utils/app_logger.dart';
import '../../../common/utils/firestore_helpers.dart';
import '../../../features/match/data/analytics/match_quality_reporter.dart';
import '../../../services/performance_monitor.dart';
import '../message_model.dart';
import 'conversation_quality_metrics.dart';

class ChatService {
  ChatService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _chatThreadsCollection =
            (firestore ?? FirebaseFirestore.instance).collection('chatThreads');

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  final CollectionReference _chatThreadsCollection;

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
      AppLogger.error(
        'Firebase error checking for chat thread: ${e.code} - ${e.message}',
        error: e,
      );
      return null;
    } on Object catch (e) {
      AppLogger.error('Unexpected error checking for chat thread', error: e);
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

      // Fetch both users' profiles in parallel for names and avatars
      String currentUserName = 'User';
      String? currentUserAvatar;
      String? otherUserAvatar;
      try {
        final results = await Future.wait([
          _firestore.collection('users').doc(currentUserId).get(),
          _firestore.collection('users').doc(otherUserId).get(),
        ]);

        final currentUserDoc = results[0];
        if (currentUserDoc.exists) {
          final data = currentUserDoc.data();
          currentUserName = data?['name'] as String? ?? 'User';
          final photos = data?['photos'] as List<dynamic>?;
          if (photos != null && photos.isNotEmpty) {
            currentUserAvatar = photos.first as String?;
          }
        }

        final otherUserDoc = results[1];
        if (otherUserDoc.exists) {
          final data = otherUserDoc.data();
          final photos = data?['photos'] as List<dynamic>?;
          if (photos != null && photos.isNotEmpty) {
            otherUserAvatar = photos.first as String?;
          }
        }
      } on FirebaseException catch (e) {
        AppLogger.error(
          'Firebase error getting user profiles: ${e.code} - ${e.message}',
          error: e,
        );
      } on Object catch (e) {
        AppLogger.error('Unexpected error getting user profiles', error: e);
      }

      // Build avatar map (only include non-null entries)
      final Map<String, String> userAvatars = {
        if (currentUserAvatar != null) currentUserId!: currentUserAvatar,
        if (otherUserAvatar != null) otherUserId: otherUserAvatar,
      };

      // Create thread data with denormalized avatars
      await threadRef.set({
        'threadId': threadId,
        'userIds': [currentUserId, otherUserId],
        'userNames': {
          currentUserId: currentUserName,
          otherUserId: otherUserName,
        },
        if (userAvatars.isNotEmpty) 'userAvatars': userAvatars,
        'lastMessage': null,
        'lastMessageText': 'Say hi to $otherUserName!',
        'lastMessageSenderId': null,
        'lastUpdated': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'unreadCount': {currentUserId: 0, otherUserId: 0},
      });

      return threadId;
    } on FirebaseException catch (e) {
      AppLogger.error(
        'Firebase error creating chat thread: ${e.code} - ${e.message}',
        error: e,
      );

      // Handle specific security rule violations
      if (e.code == 'permission-denied') {
        throw Exception(
          'Unable to start conversation. Please try again later.',
        );
      }

      throw Exception('Failed to create chat: ${e.message}');
    } on Object catch (e) {
      AppLogger.error('Error creating chat thread', error: e);
      // Re-throw our custom exceptions
      if (e.toString().contains('You can only chat with users') ||
          e.toString().contains('This conversation is not available')) {
        rethrow;
      }
      return null;
    }
  }

  /// Updates typing indicator for the current user in a thread.
  Future<void> setTyping(String threadId, {required bool isTyping}) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _chatThreadsCollection
        .doc(threadId)
        .collection('typing')
        .doc(uid)
        .set(
      {
        'isTyping': isTyping,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Emits user IDs currently typing (excluding current user).
  Stream<List<String>> watchOtherUsersTyping(String threadId) {
    final uid = currentUserId;
    if (uid == null) return const Stream<List<String>>.empty();

    return _chatThreadsCollection
        .doc(threadId)
        .collection('typing')
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      return snapshot.docs
          .where((doc) => doc.id != uid)
          .where((doc) {
            final data = doc.data();
            if (data['isTyping'] != true) return false;
            final updatedAt = parseDateTime(data['updatedAt']);
            return now.difference(updatedAt).inSeconds < 8;
          })
          .map((doc) => doc.id)
          .toList();
    });
  }

  Future<void> addReaction({
    required String threadId,
    required String messageId,
    required String emoji,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _chatThreadsCollection
        .doc(threadId)
        .collection('messages')
        .doc(messageId)
        .set(
      {
        'reactions': {uid: emoji},
      },
      SetOptions(merge: true),
    );
  }

  Future<bool> sendMessage(
    String threadId,
    String text, {
    String? replyToMessageId,
  }) =>
      PerformanceMonitor.measure('send_message', () async {
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
          DateTime? threadCreatedAt;
          bool isConversationStart = false;
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
              threadCreatedAt = parseDateTime(data?['createdAt']);
              isConversationStart = data?['lastMessageSenderId'] == null;
            }
          } on FirebaseException catch (e) {
            AppLogger.error(
              'Firebase error getting thread document: ${e.code} - ${e.message}',
              error: e,
            );
            // Continue with empty otherUserId
          } on Object catch (e) {
            AppLogger.error(
              'Unexpected error getting thread document',
              error: e,
            );
            // Continue with empty otherUserId
          }

          // Create message data
          final messageData = {
            'senderId': currentUserId,
            'text': text.trim(),
            'messageType': 'text',
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
            'deliveredAt': FieldValue.serverTimestamp(),
            if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
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

          if (isConversationStart && otherUserId.isNotEmpty) {
            final createdAt = threadCreatedAt ?? DateTime.now();
            final within24Hours =
                DateTime.now().difference(createdAt).inHours <= 24;
            // TODO(product-excellence): store conversation mode on chatThreads
            // so conversation analytics are not hardcoded to 'Dating'.
            unawaited(
              MatchQualityReporter.instance.recordConversationStart(
                userId: currentUserId!,
                candidateId: otherUserId,
                mode: 'Dating',
                within24Hours: within24Hours,
              ),
            );
          }

          return true;
        } on FirebaseException catch (e) {
          AppLogger.error(
            'Firebase error sending message: ${e.code} - ${e.message}',
            error: e,
          );

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
          AppLogger.error('Error sending message', error: e);
          return false;
        }
      });

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
        AppLogger.error(
          'Firebase error updating unread count: ${e.code} - ${e.message}',
          error: e,
        );
        // Continue to try marking messages as read
      } on Object catch (e) {
        AppLogger.error('Unexpected error updating unread count', error: e);
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
        AppLogger.error(
          'Firebase error marking messages as read: ${e.code} - ${e.message}',
          error: e,
        );
      } on Object catch (e) {
        AppLogger.error('Unexpected error marking messages as read', error: e);
      }
    } on FirebaseException catch (e) {
      AppLogger.error(
        'Firebase error in markThreadAsRead: ${e.code} - ${e.message}',
        error: e,
      );
    } on Object catch (e) {
      AppLogger.error('Unexpected error in markThreadAsRead', error: e);
    }
  }

  /// Stream of messages for a specific thread.
  ///
  /// When a user has cleared the chat, only messages sent *after* the
  /// `clearedAt.<uid>` timestamp on the thread document are returned.
  ///
  /// The thread document (which holds `clearedAt`) is observed via its own
  /// snapshot listener rather than fetched on every message emission. Because
  /// `clearedAt` changes extremely rarely, the `.distinct()` filter ensures
  /// re-filtering only happens when the value actually changes.
  Stream<List<Message>> getMessagesStream(String threadId) {
    final uid = currentUserId;
    final threadOpenTimer = Stopwatch()..start();
    var openLatencyTracked = false;
    var qualityTracked = false;

    final messagesQuery = _chatThreadsCollection
        .doc(threadId)
        .collection('messages')
        .orderBy('timestamp', descending: false);

    if (uid == null) {
      return messagesQuery.snapshots().map(
            (snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return Message(
                id: doc.id,
                senderId: data['senderId'] ?? '',
                text: data['text'] ?? '',
                timestamp: parseDateTime(data['timestamp']),
                isRead: data['read'] ?? false,
                imageUrl:
                    data['imageUrl'] as String? ?? data['mediaUrl'] as String?,
                messageType: data['messageType'] as String? ?? 'text',
              );
            }).toList(),
          );
    }

    final clearedAtStream =
        _chatThreadsCollection.doc(threadId).snapshots().map((snap) {
      final data = snap.data() as Map<String, dynamic>?;
      final clearedAtMap = data?['clearedAt'] as Map<String, dynamic>?;
      final raw = clearedAtMap?[uid];
      if (raw is Timestamp) {
        return raw.toDate();
      }
      if (raw is String) {
        return DateTime.tryParse(raw);
      }
      return null;
    }).distinct();

    final controller = StreamController<List<Message>>();
    DateTime? clearedAt;
    String? otherUserId;
    List<Message>? latestMessages;
    bool clearedAtReady = false;

    unawaited(
      _chatThreadsCollection.doc(threadId).get().then<void>(
        (doc) {
          final data = doc.data() as Map<String, dynamic>?;
          final userIds = (data?['userIds'] as List<dynamic>?)
              ?.map((id) => id.toString())
              .toList(growable: false);
          if (userIds != null) {
            otherUserId = userIds.firstWhere(
              (id) => id != uid,
              orElse: () => '',
            );
          }
        },
        onError: (Object e) {
          AppLogger.warning(
            'Unable to resolve thread participants for quality event',
            error: e,
          );
        },
      ),
    );

    void emitFiltered() {
      if (latestMessages == null || !clearedAtReady || controller.isClosed) {
        return;
      }
      final filtered = clearedAt == null
          ? latestMessages!
          : latestMessages!
              .where((m) => m.timestamp.isAfter(clearedAt!))
              .toList();
      controller.add(filtered);
    }

    // One-shot fallback: if the real-time listener fails before delivering
    // a first value, attempt a single get() so the privacy invariant is
    // preserved. Only degrades to unfiltered when Firestore is truly
    // unreachable.
    void fetchClearedAtFallback() {
      if (clearedAtReady || controller.isClosed) {
        return;
      }
      unawaited(
        _chatThreadsCollection.doc(threadId).get().then<void>(
          (doc) {
            if (clearedAtReady || controller.isClosed) {
              return;
            }
            final data = doc.data() as Map<String, dynamic>?;
            final clearedAtMap = data?['clearedAt'] as Map<String, dynamic>?;
            final raw = clearedAtMap?[uid];
            if (raw is Timestamp) {
              clearedAt = raw.toDate();
            } else if (raw is String) {
              clearedAt = DateTime.tryParse(raw);
            }
            clearedAtReady = true;
            emitFiltered();
          },
          onError: (Object fallbackError) {
            AppLogger.error(
              'Fallback clearedAt fetch failed for thread $threadId',
              error: fallbackError,
            );
            if (!clearedAtReady && !controller.isClosed) {
              clearedAtReady = true;
              emitFiltered();
            }
          },
        ),
      );
    }

    final threadSub = clearedAtStream.listen(
      (value) {
        clearedAt = value;
        clearedAtReady = true;
        emitFiltered();
      },
      onError: (Object e) {
        AppLogger.error(
          'Error listening to clearedAt for thread $threadId',
          error: e,
        );
        fetchClearedAtFallback();
      },
      onDone: fetchClearedAtFallback,
    );

    final msgSub = messagesQuery.snapshots().listen(
      (snapshot) {
        if (!openLatencyTracked) {
          openLatencyTracked = true;
          threadOpenTimer.stop();
          unawaited(
            MatchQualityReporter.instance.recordLatency(
              operation: 'thread_open',
              latencyMs: threadOpenTimer.elapsedMilliseconds,
              // TODO(product-excellence): source mode from thread metadata.
              mode: 'Dating',
              userId: uid,
            ),
          );
        }
        latestMessages = snapshot.docs.map((doc) {
          final data = doc.data();
          return Message(
            id: doc.id,
            senderId: data['senderId'] ?? '',
            text: data['text'] ?? '',
            timestamp: parseDateTime(data['timestamp']),
            isRead: data['read'] ?? false,
            imageUrl:
                data['imageUrl'] as String? ?? data['mediaUrl'] as String?,
            messageType: data['messageType'] as String? ?? 'text',
          );
        }).toList();
        if (!qualityTracked && latestMessages!.length >= 2) {
          qualityTracked = true;
          final quality = calculateConversationQualityMetrics(
            latestMessages!,
            currentUserId: uid,
          );
          unawaited(
            MatchQualityReporter.instance.recordConversationQuality(
              userId: uid,
              // TODO(product-excellence): source mode from thread metadata.
              mode: 'Dating',
              conversationDepth: quality.conversationDepth,
              responseRate: quality.responseRate,
              medianReplyDelayMs: quality.medianReplyDelayMs,
              candidateId: otherUserId,
            ),
          );
        }
        emitFiltered();
      },
      onError: (Object e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      },
    );

    controller.onCancel = () async {
      await Future.wait([threadSub.cancel(), msgSub.cancel()]);
      await controller.close();
    };

    return controller.stream;
  }

  // Stream of all chat threads for current user with enhanced error handling.
  // Threads involving blocked users are filtered out as defense in depth
  // (the block flow also deletes the thread document).
  Stream<List<MessageThreadInfo>> getChatThreadsStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _chatThreadsCollection
        .where('userIds', arrayContains: currentUserId)
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .handleError((error) {
      AppLogger.error('Error in getChatThreadsStream', error: error);
      return [];
    }).asyncMap((snapshot) async {
      try {
        // Fetch blocked user IDs so we can hide their threads even if the
        // thread document was not yet deleted (race condition / legacy data).
        final blockedSnapshot = await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('blockedlist')
            .get();
        final blockedIds = blockedSnapshot.docs.map((doc) => doc.id).toSet();

        return snapshot.docs
            .map((doc) {
              try {
                final data = doc.data() as Map<String, dynamic>;

                final userIds = List<String>.from(data['userIds'] ?? []);
                final otherUserId = userIds.firstWhere(
                  (id) => id != currentUserId,
                  orElse: () => '',
                );

                final userNames = data['userNames'] as Map<String, dynamic>?;
                final otherUserName = userNames?[otherUserId] ?? 'User';

                final userAvatars =
                    data['userAvatars'] as Map<String, dynamic>?;
                final avatarUrl = userAvatars?[otherUserId] as String?;

                final unreadCount =
                    data['unreadCount'] as Map<String, dynamic>?;
                final unread = (unreadCount?[currentUserId] ?? 0) > 0;

                return MessageThreadInfo(
                  threadId: doc.id,
                  otherUserId: otherUserId,
                  otherUserName: otherUserName,
                  lastMessage: data['lastMessageText'] ?? 'Say hello!',
                  lastMessageSenderId: data['lastMessageSenderId'],
                  timestamp: parseDateTime(data['lastUpdated']),
                  unread: unread,
                  avatarUrl: avatarUrl,
                );
              } on FirebaseException catch (e) {
                AppLogger.error(
                  'Firebase error processing individual thread: ${e.code} - ${e.message}',
                  error: e,
                );
                return MessageThreadInfo(
                  threadId: doc.id,
                  otherUserId: '',
                  otherUserName: 'Unknown User',
                  lastMessage: 'Error loading message',
                  timestamp: DateTime.now(),
                  unread: false,
                );
              } on Object catch (e) {
                AppLogger.error(
                  'Unexpected error processing individual thread',
                  error: e,
                );
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
            .where(
              (thread) =>
                  thread.otherUserId.isNotEmpty &&
                  !blockedIds.contains(thread.otherUserId),
            )
            .toList();
      } on FirebaseException catch (e) {
        AppLogger.error(
          'Firebase error mapping chat threads: ${e.code} - ${e.message}',
          error: e,
        );
        return <MessageThreadInfo>[];
      } on Object catch (e) {
        AppLogger.error('Unexpected error mapping chat threads', error: e);
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
      AppLogger.error(
        'Firebase error checking if users are matched: ${e.code} - ${e.message}',
        error: e,
      );
      return false;
    } on Object catch (e) {
      AppLogger.error(
        'Unexpected error checking if users are matched',
        error: e,
      );
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
      AppLogger.error(
        'Firebase error checking if user is blocked: ${e.code} - ${e.message}',
        error: e,
      );
      return false;
    } on Object catch (e) {
      AppLogger.error('Unexpected error checking if user is blocked', error: e);
      return false;
    }
  }

  // Delete a chat thread and all its messages, and unmatch users
  Future<bool> deleteChatThread(String threadId) async {
    try {
      if (currentUserId == null) {
        AppLogger.debug('Cannot delete chat: No current user');
        return false;
      }

      // Get thread info to find the other user
      final threadDoc = await _chatThreadsCollection.doc(threadId).get();
      if (!threadDoc.exists) {
        AppLogger.debug('Chat thread not found: $threadId');
        return false;
      }

      final threadData = threadDoc.data() as Map<String, dynamic>;
      final userIds = List<String>.from(threadData['userIds'] ?? []);

      if (userIds.length != 2) {
        AppLogger.debug(
          'Invalid chat thread: Expected 2 users, got ${userIds.length}',
        );
        return false;
      }

      // Verify current user is part of this chat
      if (!userIds.contains(currentUserId)) {
        AppLogger.debug(
          'Permission denied: User $currentUserId not part of chat $threadId',
        );
        return false;
      }

      final otherUserId = userIds.firstWhere((id) => id != currentUserId);
      AppLogger.debug('Deleting chat between $currentUserId and $otherUserId');

      // Delete all messages in the thread first
      await _deleteAllMessagesInThread(threadId);

      // Delete the thread document
      await _chatThreadsCollection.doc(threadId).delete();
      AppLogger.debug('Chat thread deleted: $threadId');

      // Unmatch users - remove from both users' matches collections
      await _unmatchUsers(currentUserId!, otherUserId);

      AppLogger.debug(
        'Chat deleted and users unmatched: $currentUserId <-> $otherUserId',
      );
      return true;
    } on FirebaseException catch (e) {
      AppLogger.error(
        'Firebase error deleting chat thread: ${e.code} - ${e.message}',
        error: e,
      );
      return false;
    } on Object catch (e) {
      AppLogger.error('Unexpected error deleting chat thread', error: e);
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
        AppLogger.debug('No messages to delete in thread $threadId');
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
        AppLogger.debug(
          'Deleted ${endIndex - i} messages from thread $threadId',
        );
      }

      AppLogger.debug('All messages deleted from thread $threadId');
    } on FirebaseException catch (e) {
      AppLogger.error(
        'Firebase error deleting messages: ${e.code} - ${e.message}',
        error: e,
      );
      // Don't throw - continue with thread deletion even if message deletion fails
    } on Object catch (e) {
      AppLogger.error('Unexpected error deleting messages', error: e);
      // Don't throw - continue with thread deletion even if message deletion fails
    }
  }

  // Unmatch two users by removing their match records
  Future<void> _unmatchUsers(String userId1, String userId2) async {
    try {
      AppLogger.debug('Unmatching users: $userId1 <-> $userId2');

      // Use separate operations instead of batch to handle permission issues better
      await _removeFromMatchesCollection(userId1, userId2);
      await _removeFromLegacyMatchesCollection(userId1, userId2);
      await _removeFromUserSubcollections(userId1, userId2);
      await _removeLikesForUnmatch(userId1, userId2);

      AppLogger.debug('Users successfully unmatched');
    } on FirebaseException catch (e) {
      AppLogger.error(
        'Firebase error unmatching users: ${e.code} - ${e.message}',
        error: e,
      );
      // Don't throw - unmatching is secondary to chat deletion
    } on Object catch (e) {
      AppLogger.error('Unexpected error unmatching users', error: e);
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
          AppLogger.debug('Deleted match: ${doc.id}');
        }
      }
    } on FirebaseException catch (e) {
      AppLogger.error(
        'Firebase error removing from matches collection: ${e.code} - ${e.message}',
        error: e,
      );
    } on Object catch (e) {
      AppLogger.error(
        'Unexpected error removing from matches collection',
        error: e,
      );
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
          AppLogger.debug('Deleted legacy match: ${doc.id}');
        }
      }
    } on FirebaseException catch (e) {
      AppLogger.error(
        'Firebase error removing from legacy matches collection: ${e.code} - ${e.message}',
        error: e,
      );
    } on Object catch (e) {
      AppLogger.error(
        'Unexpected error removing from legacy matches collection',
        error: e,
      );
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
        AppLogger.debug('Removed $userId2 from $userId1 matches subcollection');
      } on FirebaseException catch (e) {
        AppLogger.warning(
          'Firebase error removing from $userId1 matches subcollection: ${e.code} - ${e.message}',
          error: e,
        );
      } on Object catch (e) {
        AppLogger.warning(
          'Could not remove from $userId1 matches subcollection',
          error: e,
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
        AppLogger.debug('Removed $userId1 from $userId2 matches subcollection');
      } on FirebaseException catch (e) {
        AppLogger.warning(
          'Firebase error removing from $userId2 matches subcollection: ${e.code} - ${e.message}',
          error: e,
        );
      } on Object catch (e) {
        AppLogger.warning(
          'Could not remove from $userId2 matches subcollection',
          error: e,
        );
      }
    } on FirebaseException catch (e) {
      AppLogger.error(
        'Firebase error removing from user subcollections: ${e.code} - ${e.message}',
        error: e,
      );
    } on Object catch (e) {
      AppLogger.error(
        'Unexpected error removing from user subcollections',
        error: e,
      );
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
        AppLogger.debug('Removed like: $userId2 -> $userId1');
      } on FirebaseException catch (e) {
        AppLogger.warning(
          'Firebase error removing like $userId2 -> $userId1: ${e.code} - ${e.message}',
          error: e,
        );
      } on Object catch (e) {
        AppLogger.warning(
          'Could not remove like $userId2 -> $userId1',
          error: e,
        );
      }

      // Remove user1 from user2's LikedBy collection
      try {
        await _firestore
            .collection('users')
            .doc(userId2)
            .collection('LikedBy')
            .doc(userId1)
            .delete();
        AppLogger.debug('Removed like: $userId1 -> $userId2');
      } on FirebaseException catch (e) {
        AppLogger.warning(
          'Firebase error removing like $userId1 -> $userId2: ${e.code} - ${e.message}',
          error: e,
        );
      } on Object catch (e) {
        AppLogger.warning(
          'Could not remove like $userId1 -> $userId2',
          error: e,
        );
      }
    } on FirebaseException catch (e) {
      AppLogger.error(
        'Firebase error removing likes: ${e.code} - ${e.message}',
        error: e,
      );
    } on Object catch (e) {
      AppLogger.error('Unexpected error removing likes', error: e);
    }
  }
}
