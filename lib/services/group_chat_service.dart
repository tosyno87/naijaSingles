import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Industry-standard group chat service
/// Features:
/// - Group creation and management
/// - Member invitation and removal
/// - Group messaging with media sharing
/// - Group settings and permissions
/// - Group moderation and reporting
/// - Group events
class GroupChatService {
  static final GroupChatService _instance = GroupChatService._internal();
  factory GroupChatService() => _instance;
  GroupChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a new group chat
  Future<GroupChat> createGroup({
    required String name,
    required String description,
    required List<String> memberIds,
    GroupType type = GroupType.custom,
    String? location,
    String? eventId,
  }) async {
    try {
      log('👥 Creating group chat: $name');

      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Ensure creator is included in members
      final allMembers = [...memberIds];
      if (!allMembers.contains(currentUserId)) {
        allMembers.add(currentUserId);
      }

      // Create group document
      final groupData = {
        'name': name,
        'description': description,
        'type': type.name,
        'location': location,
        'eventId': eventId,
        'creatorId': currentUserId,
        'adminIds': [currentUserId],
        'memberIds': allMembers,
        'memberCount': allMembers.length,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageText': 'Group created',
        'lastMessageSenderId': currentUserId,
      };

      final docRef = await _firestore.collection('groupChats').add(groupData);
      final groupId = docRef.id;

      // Create initial message
      await _sendGroupMessage(
        groupId: groupId,
        text: 'Group "$name" was created',
        messageType: MessageType.system,
      );

      // Send notifications to members
      await _notifyGroupMembers(groupId, 'You were added to group "$name"');

      final group = GroupChat(
        id: groupId,
        name: name,
        description: description,
        type: type,
        location: location,
        eventId: eventId,
        creatorId: currentUserId,
        adminIds: [currentUserId],
        memberIds: allMembers,
        memberCount: allMembers.length,
        isActive: true,
        createdAt: DateTime.now(),
        lastMessageAt: DateTime.now(),
        lastMessageText: 'Group created',
        lastMessageSenderId: currentUserId,
      );

      log('✅ Group chat created successfully: $groupId');
      return group;
    } catch (e) {
      log('❌ Error creating group chat: $e');
      rethrow;
    }
  }

  /// Join a group chat
  Future<void> joinGroup(String groupId) async {
    try {
      log('👥 Joining group: $groupId');

      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Add user to group members
      await _firestore.collection('groupChats').doc(groupId).update({
        'memberIds': FieldValue.arrayUnion([currentUserId]),
        'memberCount': FieldValue.increment(1),
      });

      // Send join message
      await _sendGroupMessage(
        groupId: groupId,
        text: 'joined the group',
        messageType: MessageType.system,
      );

      // Notify group members
      await _notifyGroupMembers(groupId, 'A new member joined the group');

      log('✅ Successfully joined group: $groupId');
    } catch (e) {
      log('❌ Error joining group: $e');
      rethrow;
    }
  }

  /// Leave a group chat
  Future<void> leaveGroup(String groupId) async {
    try {
      log('👥 Leaving group: $groupId');

      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Remove user from group members
      await _firestore.collection('groupChats').doc(groupId).update({
        'memberIds': FieldValue.arrayRemove([currentUserId]),
        'adminIds': FieldValue.arrayRemove([currentUserId]),
        'memberCount': FieldValue.increment(-1),
      });

      // Send leave message
      await _sendGroupMessage(
        groupId: groupId,
        text: 'left the group',
        messageType: MessageType.system,
      );

      log('✅ Successfully left group: $groupId');
    } catch (e) {
      log('❌ Error leaving group: $e');
      rethrow;
    }
  }

  /// Invite users to group
  Future<void> inviteUsersToGroup(String groupId, List<String> userIds) async {
    try {
      log('👥 Inviting users to group: $groupId');

      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Check if user is admin
      final groupDoc = await _firestore.collection('groupChats').doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final groupData = groupDoc.data()!;
      final adminIds = List<String>.from(groupData['adminIds'] ?? []);
      
      if (!adminIds.contains(currentUserId)) {
        throw Exception('Only admins can invite users');
      }

      // Add users to group
      await _firestore.collection('groupChats').doc(groupId).update({
        'memberIds': FieldValue.arrayUnion(userIds),
        'memberCount': FieldValue.increment(userIds.length),
      });

      // Send invitation messages
      for (final userId in userIds) {
        await _sendGroupMessage(
          groupId: groupId,
          text: 'invited to the group',
          messageType: MessageType.system,
          targetUserId: userId,
        );
      }

      // Notify invited users
      await _notifyGroupMembers(groupId, 'You were invited to join a group');

      log('✅ Successfully invited users to group: $groupId');
    } catch (e) {
      log('❌ Error inviting users to group: $e');
      rethrow;
    }
  }

  /// Remove user from group
  Future<void> removeUserFromGroup(String groupId, String userId) async {
    try {
      log('👥 Removing user from group: $groupId');

      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Check if user is admin
      final groupDoc = await _firestore.collection('groupChats').doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final groupData = groupDoc.data()!;
      final adminIds = List<String>.from(groupData['adminIds'] ?? []);
      
      if (!adminIds.contains(currentUserId)) {
        throw Exception('Only admins can remove users');
      }

      // Remove user from group
      await _firestore.collection('groupChats').doc(groupId).update({
        'memberIds': FieldValue.arrayRemove([userId]),
        'adminIds': FieldValue.arrayRemove([userId]),
        'memberCount': FieldValue.increment(-1),
      });

      // Send removal message
      await _sendGroupMessage(
        groupId: groupId,
        text: 'was removed from the group',
        messageType: MessageType.system,
        targetUserId: userId,
      );

      log('✅ Successfully removed user from group: $groupId');
    } catch (e) {
      log('❌ Error removing user from group: $e');
      rethrow;
    }
  }

  /// Promote user to admin
  Future<void> promoteUserToAdmin(String groupId, String userId) async {
    try {
      log('👥 Promoting user to admin: $groupId');

      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Check if user is admin
      final groupDoc = await _firestore.collection('groupChats').doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final groupData = groupDoc.data()!;
      final adminIds = List<String>.from(groupData['adminIds'] ?? []);
      
      if (!adminIds.contains(currentUserId)) {
        throw Exception('Only admins can promote users');
      }

      // Promote user to admin
      await _firestore.collection('groupChats').doc(groupId).update({
        'adminIds': FieldValue.arrayUnion([userId]),
      });

      // Send promotion message
      await _sendGroupMessage(
        groupId: groupId,
        text: 'was promoted to admin',
        messageType: MessageType.system,
        targetUserId: userId,
      );

      log('✅ Successfully promoted user to admin: $groupId');
    } catch (e) {
      log('❌ Error promoting user to admin: $e');
      rethrow;
    }
  }

  /// Send message to group
  Future<GroupMessage> sendGroupMessage({
    required String groupId,
    required String text,
    MessageType messageType = MessageType.text,
    String? mediaUrl,
    String? mediaType,
    String? replyToMessageId,
  }) async {
    try {
      log('💬 Sending group message: $groupId');

      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Check if user is member of group
      final groupDoc = await _firestore.collection('unifiedGroups').doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final groupData = groupDoc.data()!;
      final memberIds = List<String>.from(groupData['memberIds'] ?? []);
      
      if (!memberIds.contains(currentUserId)) {
        throw Exception('You are not a member of this group');
      }

      // Create message
      final messageData = {
        'groupId': groupId,
        'senderId': currentUserId,
        'text': text,
        'messageType': messageType.name,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'replyToMessageId': replyToMessageId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'readBy': [currentUserId],
      };

      final docRef = await _firestore
          .collection('unifiedGroups')
          .doc(groupId)
          .collection('messages')
          .add(messageData);

      // Update group last message info
      await _firestore.collection('unifiedGroups').doc(groupId).update({
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageText': text,
        'lastMessageSenderId': currentUserId,
      });

      // Send notifications to other members
      await _notifyGroupMembers(groupId, text, excludeUserId: currentUserId);

      final message = GroupMessage(
        id: docRef.id,
        groupId: groupId,
        senderId: currentUserId,
        text: text,
        messageType: messageType,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        replyToMessageId: replyToMessageId,
        timestamp: DateTime.now(),
        isRead: false,
        readBy: [currentUserId],
      );

      log('✅ Group message sent successfully: ${docRef.id}');
      return message;
    } catch (e) {
      log('❌ Error sending group message: $e');
      rethrow;
    }
  }

  /// Get group messages
  Stream<List<GroupMessage>> getGroupMessages(String groupId) {
    // Use unifiedGroups collection since that's where our groups are stored
    return _firestore
        .collection('unifiedGroups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return GroupMessage.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  /// Get user's groups
  Stream<List<GroupChat>> getUserGroups() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('groupChats')
        .where('memberIds', arrayContains: currentUserId)
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return GroupChat.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  /// Get group details
  Future<GroupChat?> getGroupDetails(String groupId) async {
    try {
      log('🔍 GroupChatService: Looking for group in groupChats collection: $groupId');
      final doc = await _firestore.collection('groupChats').doc(groupId).get();
      if (!doc.exists) {
        log('🔍 GroupChatService: Group not found in groupChats, trying unifiedGroups');
        // Try unifiedGroups collection as fallback
        final unifiedDoc = await _firestore.collection('unifiedGroups').doc(groupId).get();
        if (!unifiedDoc.exists) {
          log('❌ GroupChatService: Group not found in either collection');
          return null;
        }
        
        // Convert UnifiedGroup to GroupChat format
        final data = unifiedDoc.data()!;
        return GroupChat.fromMap(unifiedDoc.id, {
          'name': data['name'],
          'description': data['description'],
          'creatorId': data['creatorId'],
          'memberIds': data['memberIds'],
          'memberCount': data['memberCount'],
          'isActive': data['isActive'],
          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],
          'lastActivityAt': data['lastActivityAt'],
        });
      }

      return GroupChat.fromMap(doc.id, doc.data()!);
    } catch (e) {
      log('❌ Error getting group details: $e');
      return null;
    }
  }

  /// Update group settings
  Future<void> updateGroupSettings({
    required String groupId,
    String? name,
    String? description,
    bool? isActive,
  }) async {
    try {
      log('⚙️ Updating group settings: $groupId');

      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Check if user is admin
      final groupDoc = await _firestore.collection('groupChats').doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final groupData = groupDoc.data()!;
      final adminIds = List<String>.from(groupData['adminIds'] ?? []);
      
      if (!adminIds.contains(currentUserId)) {
        throw Exception('Only admins can update group settings');
      }

      // Update group settings
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (isActive != null) updateData['isActive'] = isActive;

      if (updateData.isNotEmpty) {
        await _firestore.collection('groupChats').doc(groupId).update(updateData);
      }

      log('✅ Group settings updated successfully: $groupId');
    } catch (e) {
      log('❌ Error updating group settings: $e');
      rethrow;
    }
  }

  /// Delete group
  Future<void> deleteGroup(String groupId) async {
    try {
      log('🗑️ Deleting group: $groupId');

      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Check if user is creator
      final groupDoc = await _firestore.collection('groupChats').doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final groupData = groupDoc.data()!;
      final creatorId = groupData['creatorId'] as String?;
      
      if (creatorId != currentUserId) {
        throw Exception('Only the group creator can delete the group');
      }

      // Mark group as inactive
      await _firestore.collection('groupChats').doc(groupId).update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': currentUserId,
      });

      log('✅ Group deleted successfully: $groupId');
    } catch (e) {
      log('❌ Error deleting group: $e');
      rethrow;
    }
  }

  /// Send group message (internal method)
  Future<void> _sendGroupMessage({
    required String groupId,
    required String text,
    required MessageType messageType,
    String? targetUserId,
  }) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      final messageData = {
        'groupId': groupId,
        'senderId': currentUserId,
        'text': text,
        'messageType': messageType.name,
        'targetUserId': targetUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'readBy': [currentUserId],
      };

      await _firestore
          .collection('groupChats')
          .doc(groupId)
          .collection('messages')
          .add(messageData);
    } catch (e) {
      log('❌ Error sending group message: $e');
    }
  }

  /// Notify group members (internal method)
  Future<void> _notifyGroupMembers(String groupId, String message, {String? excludeUserId}) async {
    try {
      final groupDoc = await _firestore.collection('unifiedGroups').doc(groupId).get();
      if (!groupDoc.exists) return;

      final groupData = groupDoc.data()!;
      final memberIds = List<String>.from(groupData['memberIds'] ?? []);
      final groupName = groupData['name'] as String? ?? 'Group';

      // Send notifications to all members except excluded user
      for (final memberId in memberIds) {
        if (memberId != excludeUserId) {
          await _firestore.collection('notifications').add({
            'userId': memberId,
            'type': 'group_message',
            'title': groupName,
            'message': message,
            'groupId': groupId,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }
      }
    } catch (e) {
      log('❌ Error notifying group members: $e');
    }
  }
}

/// Group types
enum GroupType {
  custom,
  event,
  interest,
  location,
  tribe,
}

/// Message types
enum MessageType {
  text,
  image,
  video,
  audio,
  file,
  system,
}

/// Group chat model
class GroupChat {
  final String id;
  final String name;
  final String description;
  final GroupType type;
  final String? location;
  final String? eventId;
  final String creatorId;
  final List<String> adminIds;
  final List<String> memberIds;
  final int memberCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final String lastMessageText;
  final String lastMessageSenderId;

  const GroupChat({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.location,
    this.eventId,
    required this.creatorId,
    required this.adminIds,
    required this.memberIds,
    required this.memberCount,
    required this.isActive,
    required this.createdAt,
    required this.lastMessageAt,
    required this.lastMessageText,
    required this.lastMessageSenderId,
  });

  factory GroupChat.fromMap(String id, Map<String, dynamic> data) {
    return GroupChat(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: GroupType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => GroupType.custom,
      ),
      location: data['location'],
      eventId: data['eventId'],
      creatorId: data['creatorId'] ?? '',
      adminIds: List<String>.from(data['adminIds'] ?? []),
      memberIds: List<String>.from(data['memberIds'] ?? []),
      memberCount: data['memberCount'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageText: data['lastMessageText'] ?? '',
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
    );
  }

  /// Check if user is admin
  bool isAdmin(String userId) {
    return adminIds.contains(userId);
  }

  /// Check if user is member
  bool isMember(String userId) {
    return memberIds.contains(userId);
  }

  /// Check if user is creator
  bool isCreator(String userId) {
    return creatorId == userId;
  }

  @override
  String toString() {
    return 'GroupChat($name: $memberCount members)';
  }
}

/// Group message model
class GroupMessage {
  final String id;
  final String groupId;
  final String senderId;
  final String text;
  final MessageType messageType;
  final String? mediaUrl;
  final String? mediaType;
  final String? replyToMessageId;
  final DateTime timestamp;
  final bool isRead;
  final List<String> readBy;

  const GroupMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.text,
    required this.messageType,
    this.mediaUrl,
    this.mediaType,
    this.replyToMessageId,
    required this.timestamp,
    required this.isRead,
    required this.readBy,
  });

  factory GroupMessage.fromMap(String id, Map<String, dynamic> data) {
    return GroupMessage(
      id: id,
      groupId: data['groupId'] ?? '',
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      messageType: MessageType.values.firstWhere(
        (e) => e.name == data['messageType'],
        orElse: () => MessageType.text,
      ),
      mediaUrl: data['mediaUrl'],
      mediaType: data['mediaType'],
      replyToMessageId: data['replyToMessageId'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      readBy: List<String>.from(data['readBy'] ?? []),
    );
  }

  /// Check if message is read by user
  bool isReadBy(String userId) {
    return readBy.contains(userId);
  }

  @override
  String toString() {
    return 'GroupMessage($text: ${messageType.name})';
  }
}
