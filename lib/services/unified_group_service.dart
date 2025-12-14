import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group_join_exception.dart';
import 'content_moderation_service.dart';

/// Unified Group Service that combines Cultural Groups and Group Chats
/// This eliminates redundancy and creates synergy between features
class UnifiedGroupService {
  factory UnifiedGroupService() => _instance;
  UnifiedGroupService._internal();
  static final UnifiedGroupService _instance = UnifiedGroupService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a unified group that supports both cultural community and chat functionality
  Future<UnifiedGroup> createGroup({
    required String name,
    required String description,
    required GroupType type,
    String? imageUrl,
    String? location,
    List<String> tags = const [],
    Map<String, dynamic>? culturalInfo,
    bool enableChat = true,
    bool isPublic = true,
    int maxMembers = 100,
    List<String>? initialMembers,
  }) async {
    try {
      log('🏘️ Creating unified group: $name');

      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Content moderation for group name and description
      final moderationService = ContentModerationService();
      final nameModeration = await moderationService.moderateText(name);
      final descriptionModeration = await moderationService.moderateText(description);

      // Reject if content is inappropriate
      if (nameModeration.action == ModerationAction.reject ||
          descriptionModeration.action == ModerationAction.reject) {
        throw Exception(
          'Group content contains inappropriate material. Please revise your group name and description.',
        );
      }

      // Warn but allow if content needs review
      if (nameModeration.action == ModerationAction.review ||
          descriptionModeration.action == ModerationAction.review) {
        log('⚠️ Group content flagged for review: $name');
      }

      // Ensure creator is included in members and remove duplicates
      final allMembers = <String>{
        ...(initialMembers ?? []),
        currentUserId,
      }.toList();

      log('👥 createUnifiedGroup: Creator $currentUserId added to members: $allMembers');

      // Create unified group document
      final groupData = {
        'name': name,
        'description': description,
        'type': type.name,
        'imageUrl': imageUrl,
        'location': location,
        'tags': tags,
        'culturalInfo': culturalInfo,
        'creatorId': currentUserId,
        'adminIds': [currentUserId],
        'memberIds': allMembers,
        'memberCount': allMembers.length,
        'maxMembers': maxMembers,
        'isPublic': isPublic,
        'enableChat': enableChat,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastActivityAt': FieldValue.serverTimestamp(),
        'lastMessageAt': enableChat ? FieldValue.serverTimestamp() : null,
        'lastMessageText': enableChat ? 'Group "$name" was created' : null,
        'lastMessageSenderId': enableChat ? currentUserId : null,
      };

      final docRef =
          await _firestore.collection('unifiedGroups').add(groupData);
      final groupId = docRef.id;

      // Create initial chat message if chat is enabled
      if (enableChat) {
        await _sendGroupMessage(
          groupId: groupId,
          text: 'Group "$name" was created',
          messageType: MessageType.system,
        );
      }

      // Send notifications to members
      await _notifyGroupMembers(groupId, 'You were added to group "$name"');

      final group = UnifiedGroup(
        id: groupId,
        name: name,
        description: description,
        type: type,
        imageUrl: imageUrl,
        location: location,
        tags: tags,
        culturalInfo: culturalInfo,
        creatorId: currentUserId,
        adminIds: [currentUserId],
        memberIds: allMembers,
        memberCount: allMembers.length,
        maxMembers: maxMembers,
        isPublic: isPublic,
        enableChat: enableChat,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastActivityAt: DateTime.now(),
        lastMessageAt: enableChat ? DateTime.now() : null,
        lastMessageText: enableChat ? 'Group "$name" was created' : null,
        lastMessageSenderId: enableChat ? currentUserId : null,
      );

      log('✅ Unified group created successfully: $groupId');
      log('📊 Group data: memberIds=${groupData['memberIds']}, isActive=${groupData['isActive']}');
      return group;
    } catch (e) {
      log('❌ Error creating unified group: $e');
      rethrow;
    }
  }

  /// Join a group with enhanced validation and error handling
  Future<GroupJoinResult> joinGroup(String groupId) async {
    try {
      log('👥 Joining group: $groupId');

      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw GroupJoinException(
            'User not authenticated', GroupJoinErrorType.notAuthenticated,);
      }

      // Pre-join validation
      final groupDoc =
          await _firestore.collection('unifiedGroups').doc(groupId).get();
      if (!groupDoc.exists) {
        throw GroupJoinException(
            'Group not found', GroupJoinErrorType.groupNotFound,);
      }

      final groupData = groupDoc.data()!;

      // Check if user is already a member
      if (groupData['memberIds']?.contains(currentUserId) == true) {
        throw GroupJoinException(
            'Already a member', GroupJoinErrorType.alreadyMember,);
      }

      // Check group capacity
      final memberCount = groupData['memberCount'] ?? 0;
      final maxMembers = groupData['maxMembers'] ?? 1000;
      if (memberCount >= maxMembers) {
        throw GroupJoinException('Group is full', GroupJoinErrorType.groupFull);
      }

      // Check if group is active
      if (groupData['isActive'] != true) {
        throw GroupJoinException(
            'Group is not active', GroupJoinErrorType.groupInactive,);
      }

      // Perform join operation
      await _firestore.collection('unifiedGroups').doc(groupId).update({
        'memberIds': FieldValue.arrayUnion([currentUserId]),
        'memberCount': FieldValue.increment(1),
        'lastActivityAt': FieldValue.serverTimestamp(),
      });

      // Send system message if chat is enabled
      if (groupData['enableChat'] == true) {
        await _sendGroupMessage(
          groupId: groupId,
          text: 'joined the group',
          messageType: MessageType.system,
        );
      }

      // Notify group members
      await _notifyGroupMembers(groupId, 'A new member joined the group');

      log('✅ Successfully joined group: $groupId');
      return GroupJoinResult.success(groupData['name'] ?? 'Unknown Group');
    } catch (e) {
      log('❌ Error joining group: $e');
      if (e is GroupJoinException) rethrow;

      // Handle Firebase-specific errors
      if (e.toString().contains('permission-denied')) {
        throw GroupJoinException(
            'Permission denied', GroupJoinErrorType.permissionDenied,);
      } else if (e.toString().contains('network')) {
        throw GroupJoinException(
            'Network error', GroupJoinErrorType.networkError,);
      } else {
        throw GroupJoinException(
            'Failed to join group', GroupJoinErrorType.unknown,);
      }
    }
  }

  /// Leave a group
  Future<void> leaveGroup(String groupId) async {
    try {
      log('👥 Leaving group: $groupId');

      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Remove user from group members
      await _firestore.collection('unifiedGroups').doc(groupId).update({
        'memberIds': FieldValue.arrayRemove([currentUserId]),
        'adminIds': FieldValue.arrayRemove([currentUserId]),
        'memberCount': FieldValue.increment(-1),
        'lastActivityAt': FieldValue.serverTimestamp(),
      });

      // Send leave message if chat is enabled
      final groupDoc =
          await _firestore.collection('unifiedGroups').doc(groupId).get();
      if (groupDoc.exists) {
        final groupData = groupDoc.data()!;
        final enableChat = groupData['enableChat'] ?? false;

        if (enableChat) {
          await _sendGroupMessage(
            groupId: groupId,
            text: 'left the group',
            messageType: MessageType.system,
          );
        }
      }

      log('✅ Successfully left group: $groupId');
    } catch (e) {
      log('❌ Error leaving group: $e');
      rethrow;
    }
  }

  /// Send message to group (if chat is enabled)
  Future<GroupMessage?> sendGroupMessage({
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

      // Check if group exists and chat is enabled
      final groupDoc =
          await _firestore.collection('unifiedGroups').doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final groupData = groupDoc.data()!;
      final enableChat = groupData['enableChat'] ?? false;

      if (!enableChat) {
        throw Exception('Chat is not enabled for this group');
      }

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
        'lastActivityAt': FieldValue.serverTimestamp(),
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

  /// Get group messages (if chat is enabled)
  Stream<List<GroupMessage>> getGroupMessages(String groupId) => _firestore
        .collection('unifiedGroups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => GroupMessage.fromMap(doc.id, doc.data())).toList(),);

  /// Get user's groups
  Stream<List<UnifiedGroup>> getUserGroups() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      log('⚠️ getUserGroups: No current user');
      return Stream.value([]);
    }

    log('🔍 getUserGroups: Loading groups for user: $currentUserId');

    return _firestore
        .collection('unifiedGroups')
        .where('memberIds', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      log('📊 getUserGroups: Found ${snapshot.docs.length} groups in query');

      // Filter and sort in memory to avoid complex index requirements
      final groups = snapshot.docs.map((doc) {
        final data = doc.data();
        final memberIds = List<String>.from(data['memberIds'] ?? []);

        // Check for duplicates and clean up if found
        final uniqueMembers = <String>[];
        for (final member in memberIds) {
          if (!uniqueMembers.contains(member)) {
            uniqueMembers.add(member);
          }
        }

        if (uniqueMembers.length != memberIds.length) {
          log('🧹 Found duplicates in group ${doc.id}, cleaning up...');
          // Clean up duplicates asynchronously
          cleanupDuplicateMembers(doc.id);
        }

        log('📋 getUserGroups: Group ${doc.id} - isActive: ${data['isActive']}, memberIds: $uniqueMembers');
        return UnifiedGroup.fromMap(doc.id, data);
      }).toList();

      // Filter active groups and sort by last activity
      final activeGroups = groups.where((group) => group.isActive).toList();
      log('✅ getUserGroups: ${activeGroups.length} active groups after filtering');

      activeGroups.sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));

      return activeGroups;
    });
  }

  /// Get public groups for discovery
  Stream<List<UnifiedGroup>> getPublicGroups({
    GroupType? type,
    String? location,
    List<String>? tags,
  }) {
    Query query = _firestore
        .collection('unifiedGroups')
        .where('isPublic', isEqualTo: true);

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    if (location != null) {
      query = query.where('location', isEqualTo: location);
    }

    return query.snapshots().map((snapshot) {
      // Filter and sort in memory to avoid complex index requirements
      final groups = snapshot.docs.map((doc) => UnifiedGroup.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();

      // Filter active groups and sort by last activity
      groups.removeWhere((group) => !group.isActive);
      groups.sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));

      return groups;
    });
  }

  /// Search groups
  Future<List<UnifiedGroup>> searchGroups({
    required String query,
    GroupType? type,
    String? location,
  }) async {
    try {
      final groups = await _firestore
          .collection('unifiedGroups')
          .where('isPublic', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .get();

      final results = groups.docs
          .map((doc) => UnifiedGroup.fromMap(doc.id, doc.data()))
          .where((group) {
        final matchesQuery = group.name
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            group.description.toLowerCase().contains(query.toLowerCase()) ||
            group.tags
                .any((tag) => tag.toLowerCase().contains(query.toLowerCase()));

        final matchesType = type == null || group.type == type;
        final matchesLocation = location == null || group.location == location;

        return matchesQuery && matchesType && matchesLocation;
      }).toList();

      return results;
    } catch (e) {
      log('❌ Error searching groups: $e');
      return [];
    }
  }

  /// Get group details
  Future<UnifiedGroup?> getGroupDetails(String groupId) async {
    try {
      final doc =
          await _firestore.collection('unifiedGroups').doc(groupId).get();
      if (!doc.exists) return null;

      return UnifiedGroup.fromMap(doc.id, doc.data()!);
    } catch (e) {
      log('❌ Error getting group details: $e');
      return null;
    }
  }

  /// Clean up duplicate members in a group (one-time fix)
  Future<void> cleanupDuplicateMembers(String groupId) async {
    try {
      log('🧹 Cleaning up duplicate members in group: $groupId');

      final doc =
          await _firestore.collection('unifiedGroups').doc(groupId).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final memberIds = List<String>.from(data['memberIds'] ?? []);

      // Remove duplicates while preserving order
      final uniqueMembers = <String>[];
      for (final member in memberIds) {
        if (!uniqueMembers.contains(member)) {
          uniqueMembers.add(member);
        }
      }

      if (uniqueMembers.length != memberIds.length) {
        log('🔧 Found ${memberIds.length - uniqueMembers.length} duplicate members, cleaning up...');

        await _firestore.collection('unifiedGroups').doc(groupId).update({
          'memberIds': uniqueMembers,
          'memberCount': uniqueMembers.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        log('✅ Cleaned up duplicate members: ${uniqueMembers.length} unique members');
      }
    } catch (e) {
      log('❌ Error cleaning up duplicate members: $e');
    }
  }

  /// Update group settings
  Future<void> updateGroupSettings({
    required String groupId,
    String? name,
    String? description,
    String? imageUrl,
    String? location,
    GroupType? type,
    List<String>? tags,
    Map<String, dynamic>? culturalInfo,
    bool? enableChat,
    bool? isPublic,
    int? maxMembers,
  }) async {
    try {
      log('⚙️ Updating group settings: $groupId');

      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Check if user is admin
      final groupDoc =
          await _firestore.collection('unifiedGroups').doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final groupData = groupDoc.data()!;
      final adminIds = List<String>.from(groupData['adminIds'] ?? []);

      if (!adminIds.contains(currentUserId)) {
        throw Exception('Only admins can update group settings');
      }

      // Content moderation for name and description if provided
      final moderationService = ContentModerationService();
      if (name != null) {
        final nameModeration = await moderationService.moderateText(name);
        if (nameModeration.action == ModerationAction.reject) {
          throw Exception(
            'Group name contains inappropriate material. Please revise.',
          );
        }
      }
      if (description != null) {
        final descModeration = await moderationService.moderateText(description);
        if (descModeration.action == ModerationAction.reject) {
          throw Exception(
            'Group description contains inappropriate material. Please revise.',
          );
        }
      }

      // Update group settings
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
        'lastActivityAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (imageUrl != null) updateData['imageUrl'] = imageUrl;
      if (location != null) updateData['location'] = location;
      if (type != null) updateData['type'] = type.name;
      if (tags != null) updateData['tags'] = tags;
      if (culturalInfo != null) updateData['culturalInfo'] = culturalInfo;
      if (enableChat != null) updateData['enableChat'] = enableChat;
      if (isPublic != null) updateData['isPublic'] = isPublic;
      if (maxMembers != null) updateData['maxMembers'] = maxMembers;

      await _firestore
          .collection('unifiedGroups')
          .doc(groupId)
          .update(updateData);

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
      final groupDoc =
          await _firestore.collection('unifiedGroups').doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final groupData = groupDoc.data()!;
      final creatorId = groupData['creatorId'] as String?;

      if (creatorId != currentUserId) {
        throw Exception('Only the group creator can delete the group');
      }

      // Mark group as inactive
      await _firestore.collection('unifiedGroups').doc(groupId).update({
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
      log('💬 Sending group message: $groupId');
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        log('❌ User not authenticated for sending message');
        return;
      }

      // First check if the group exists
      final groupDoc =
          await _firestore.collection('unifiedGroups').doc(groupId).get();
      if (!groupDoc.exists) {
        log('❌ Group not found: $groupId');
        throw Exception('Group not found');
      }

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
          .collection('unifiedGroups')
          .doc(groupId)
          .collection('messages')
          .add(messageData);

      log('✅ Group message sent successfully: $groupId');
    } catch (e) {
      log('❌ Error sending group message: $e');
      rethrow;
    }
  }

  /// Notify group members (internal method)
  Future<void> _notifyGroupMembers(String groupId, String message,
      {String? excludeUserId,}) async {
    try {
      final groupDoc =
          await _firestore.collection('unifiedGroups').doc(groupId).get();
      if (!groupDoc.exists) return;

      final groupData = groupDoc.data()!;
      final memberIds = List<String>.from(groupData['memberIds'] ?? []);
      final groupName = groupData['name'] as String? ?? 'Group';

      // Send notifications to all members except excluded user
      for (final memberId in memberIds) {
        if (memberId != excludeUserId) {
          await _firestore.collection('notifications').add({
            'userId': memberId,
            'type': 'group_activity',
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

  /// Add member to group (admin/creator only)
  Future<bool> addMemberToGroup({
    required String groupId,
    required String userId,
    String? invitedBy,
  }) async {
    try {
      log('👥 Adding member to group: $groupId');

      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Check if current user has permission to add members
      final groupDoc =
          await _firestore.collection('unifiedGroups').doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final groupData = groupDoc.data()!;
      final adminIds = List<String>.from(groupData['adminIds'] ?? []);
      final creatorId = groupData['creatorId'] as String?;

      if (creatorId != currentUserId && !adminIds.contains(currentUserId)) {
        throw Exception('Only group creators and admins can add members');
      }

      // Check if user is already a member
      final memberIds = List<String>.from(groupData['memberIds'] ?? []);
      if (memberIds.contains(userId)) {
        throw Exception('User is already a member of this group');
      }

      // Check group capacity
      final maxMembers = groupData['maxMembers'] as int? ?? 100;
      if (memberIds.length >= maxMembers) {
        throw Exception('Group has reached maximum capacity');
      }

      // Add user to group
      await _firestore.collection('unifiedGroups').doc(groupId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
        'memberCount': FieldValue.increment(1),
        'lastActivityAt': FieldValue.serverTimestamp(),
      });

      // Send notification to the new member
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'group_invitation',
        'title': 'Added to Group',
        'message': 'You were added to "${groupData['name']}"',
        'groupId': groupId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Notify other group members
      await _notifyGroupMembers(groupId, 'A new member joined the group',
          excludeUserId: userId,);

      log('✅ Successfully added member to group: $groupId');
      return true;
    } catch (e) {
      log('❌ Error adding member to group: $e');
      rethrow;
    }
  }

  /// Remove member from group (admin/creator only)
  Future<bool> removeMemberFromGroup({
    required String groupId,
    required String userId,
    String? reason,
  }) async {
    try {
      log('👥 Removing member from group: $groupId');

      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Check if current user has permission to remove members
      final groupDoc =
          await _firestore.collection('unifiedGroups').doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final groupData = groupDoc.data()!;
      final adminIds = List<String>.from(groupData['adminIds'] ?? []);
      final creatorId = groupData['creatorId'] as String?;

      if (creatorId != currentUserId && !adminIds.contains(currentUserId)) {
        throw Exception('Only group creators and admins can remove members');
      }

      // Check if user is a member
      final memberIds = List<String>.from(groupData['memberIds'] ?? []);
      if (!memberIds.contains(userId)) {
        throw Exception('User is not a member of this group');
      }

      // Remove user from group
      await _firestore.collection('unifiedGroups').doc(groupId).update({
        'memberIds': FieldValue.arrayRemove([userId]),
        'adminIds': FieldValue.arrayRemove(
            [userId],), // Also remove from admins if they were one
        'memberCount': FieldValue.increment(-1),
        'lastActivityAt': FieldValue.serverTimestamp(),
      });

      // Send notification to the removed member
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'group_removal',
        'title': 'Removed from Group',
        'message':
            'You were removed from "${groupData['name']}"${reason != null ? ': $reason' : ''}',
        'groupId': groupId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Notify other group members
      await _notifyGroupMembers(groupId, 'A member left the group',
          excludeUserId: userId,);

      log('✅ Successfully removed member from group: $groupId');
      return true;
    } catch (e) {
      log('❌ Error removing member from group: $e');
      rethrow;
    }
  }

  /// Promote member to admin (creator only)
  Future<bool> promoteMemberToAdmin({
    required String groupId,
    required String userId,
  }) async {
    try {
      log('👑 Promoting member to admin: $groupId');

      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Check if current user is the creator
      final groupDoc =
          await _firestore.collection('unifiedGroups').doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final groupData = groupDoc.data()!;
      final creatorId = groupData['creatorId'] as String?;

      if (creatorId != currentUserId) {
        throw Exception('Only group creators can promote members to admin');
      }

      // Check if user is a member
      final memberIds = List<String>.from(groupData['memberIds'] ?? []);
      if (!memberIds.contains(userId)) {
        throw Exception('User is not a member of this group');
      }

      // Check if user is already an admin
      final adminIds = List<String>.from(groupData['adminIds'] ?? []);
      if (adminIds.contains(userId)) {
        throw Exception('User is already an admin');
      }

      // Promote user to admin
      await _firestore.collection('unifiedGroups').doc(groupId).update({
        'adminIds': FieldValue.arrayUnion([userId]),
        'lastActivityAt': FieldValue.serverTimestamp(),
      });

      // Send notification to the promoted member
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'group_promotion',
        'title': 'Promoted to Admin',
        'message': 'You were promoted to admin in "${groupData['name']}"',
        'groupId': groupId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Notify other group members
      await _notifyGroupMembers(groupId, 'A member was promoted to admin',
          excludeUserId: userId,);

      log('✅ Successfully promoted member to admin: $groupId');
      return true;
    } catch (e) {
      log('❌ Error promoting member to admin: $e');
      rethrow;
    }
  }

  /// Demote admin to member (creator only)
  Future<bool> demoteAdminToMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      log('👑 Demoting admin to member: $groupId');

      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Check if current user is the creator
      final groupDoc =
          await _firestore.collection('unifiedGroups').doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final groupData = groupDoc.data()!;
      final creatorId = groupData['creatorId'] as String?;

      if (creatorId != currentUserId) {
        throw Exception('Only group creators can demote admins');
      }

      // Check if user is an admin
      final adminIds = List<String>.from(groupData['adminIds'] ?? []);
      if (!adminIds.contains(userId)) {
        throw Exception('User is not an admin');
      }

      // Don't allow demoting the creator
      if (creatorId == userId) {
        throw Exception('Cannot demote the group creator');
      }

      // Demote admin to member
      await _firestore.collection('unifiedGroups').doc(groupId).update({
        'adminIds': FieldValue.arrayRemove([userId]),
        'lastActivityAt': FieldValue.serverTimestamp(),
      });

      // Send notification to the demoted member
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'group_demotion',
        'title': 'Demoted from Admin',
        'message': 'You were demoted from admin in "${groupData['name']}"',
        'groupId': groupId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Notify other group members
      await _notifyGroupMembers(groupId, 'An admin was demoted to member',
          excludeUserId: userId,);

      log('✅ Successfully demoted admin to member: $groupId');
      return true;
    } catch (e) {
      log('❌ Error demoting admin to member: $e');
      rethrow;
    }
  }

  /// Search users for group invitation
  Future<List<Map<String, dynamic>>> searchUsersForInvitation({
    required String query,
    required String groupId,
    int limit = 20,
  }) async {
    try {
      log('🔍 Searching users for group invitation: $query');

      // Get current group members to exclude them from search
      final groupDoc =
          await _firestore.collection('unifiedGroups').doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final groupData = groupDoc.data()!;
      final memberIds = List<String>.from(groupData['memberIds'] ?? []);

      // Search users by name, email, or username
      final usersQuery = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThan: '${query}z')
          .limit(limit)
          .get();

      final users = <Map<String, dynamic>>[];

      for (final doc in usersQuery.docs) {
        final userData = doc.data();
        final userId = doc.id;

        // Skip if user is already a member
        if (memberIds.contains(userId)) continue;

        users.add({
          'id': userId,
          'displayName': userData['displayName'] ?? 'Unknown User',
          'email': userData['email'] ?? '',
          'photoUrl': userData['photoUrl'] ?? '',
          'isOnline': userData['isOnline'] ?? false,
          'lastSeen': userData['lastSeen'],
        });
      }

      log('✅ Found ${users.length} users for invitation');
      return users;
    } catch (e) {
      log('❌ Error searching users for invitation: $e');
      rethrow;
    }
  }

  /// Send group invitation
  Future<bool> sendGroupInvitation({
    required String groupId,
    required String userId,
    String? message,
  }) async {
    try {
      log('📧 Sending group invitation: $groupId to $userId');

      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Check if current user has permission to send invitations
      final groupDoc =
          await _firestore.collection('unifiedGroups').doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final groupData = groupDoc.data()!;
      final adminIds = List<String>.from(groupData['adminIds'] ?? []);
      final creatorId = groupData['creatorId'] as String?;

      if (creatorId != currentUserId && !adminIds.contains(currentUserId)) {
        throw Exception('Only group creators and admins can send invitations');
      }

      // Check if user is already a member
      final memberIds = List<String>.from(groupData['memberIds'] ?? []);
      if (memberIds.contains(userId)) {
        throw Exception('User is already a member of this group');
      }

      // Create invitation
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 7));

      await _firestore.collection('groupInvitations').add({
        'groupId': groupId,
        'invitedUserId': userId,
        'invitedByUserId': currentUserId,
        'message': message ?? 'You are invited to join "${groupData['name']}"',
        'status': 'pending', // pending, accepted, declined
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
      });

      // Send notification to the invited user
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'group_invitation',
        'title': 'Group Invitation',
        'message': message ?? 'You are invited to join "${groupData['name']}"',
        'groupId': groupId,
        'invitationId': '', // Will be set when we get the doc ID
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      log('✅ Successfully sent group invitation');
      return true;
    } catch (e) {
      log('❌ Error sending group invitation: $e');
      rethrow;
    }
  }

  /// Accept group invitation
  Future<bool> acceptGroupInvitation(String invitationId) async {
    try {
      log('✅ Accepting group invitation: $invitationId');

      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get invitation
      final invitationDoc = await _firestore
          .collection('groupInvitations')
          .doc(invitationId)
          .get();
      if (!invitationDoc.exists) {
        throw Exception('Invitation not found');
      }

      final invitationData = invitationDoc.data()!;
      final groupId = invitationData['groupId'] as String;
      final invitedUserId = invitationData['invitedUserId'] as String;
      final status = invitationData['status'] as String;

      // Check if invitation is for current user
      if (invitedUserId != currentUserId) {
        throw Exception('This invitation is not for you');
      }

      // Check if invitation is still pending
      if (status != 'pending') {
        throw Exception('This invitation has already been $status');
      }

      // Check if invitation has expired
      final expiresAt = invitationData['expiresAt'] as Timestamp?;
      if (expiresAt != null && expiresAt.toDate().isBefore(DateTime.now())) {
        throw Exception('This invitation has expired');
      }

      // Update invitation status
      await _firestore.collection('groupInvitations').doc(invitationId).update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Add user to group
      await _firestore.collection('unifiedGroups').doc(groupId).update({
        'memberIds': FieldValue.arrayUnion([currentUserId]),
        'memberCount': FieldValue.increment(1),
        'lastActivityAt': FieldValue.serverTimestamp(),
      });

      // Send notification to group members
      await _notifyGroupMembers(groupId, 'A new member joined the group');

      log('✅ Successfully accepted group invitation');
      return true;
    } catch (e) {
      log('❌ Error accepting group invitation: $e');
      rethrow;
    }
  }

  /// Decline group invitation
  Future<bool> declineGroupInvitation(String invitationId) async {
    try {
      log('❌ Declining group invitation: $invitationId');

      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get invitation
      final invitationDoc = await _firestore
          .collection('groupInvitations')
          .doc(invitationId)
          .get();
      if (!invitationDoc.exists) {
        throw Exception('Invitation not found');
      }

      final invitationData = invitationDoc.data()!;
      final invitedUserId = invitationData['invitedUserId'] as String;
      final status = invitationData['status'] as String;

      // Check if invitation is for current user
      if (invitedUserId != currentUserId) {
        throw Exception('This invitation is not for you');
      }

      // Check if invitation is still pending
      if (status != 'pending') {
        throw Exception('This invitation has already been $status');
      }

      // Update invitation status
      await _firestore.collection('groupInvitations').doc(invitationId).update({
        'status': 'declined',
        'declinedAt': FieldValue.serverTimestamp(),
      });

      log('✅ Successfully declined group invitation');
      return true;
    } catch (e) {
      log('❌ Error declining group invitation: $e');
      rethrow;
    }
  }

  /// Get user's pending group invitations
  Stream<List<Map<String, dynamic>>> getUserInvitations() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('groupInvitations')
        .where('invitedUserId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList(),);
  }
}

/// Industry-standard group types for better user experience
enum GroupType {
  // Interest & Hobby Groups
  music, // Music lovers, artists, concerts
  sports, // Sports fans, fitness, teams
  travel, // Travelers, explorers, destinations
  food, // Foodies, cooking, restaurants
  art, // Artists, creators, galleries

  // Lifestyle & Career Groups
  career, // Professional networking, job opportunities
  fitness, // Workout buddies, health, wellness
  gaming, // Gamers, esports, tournaments
  reading, // Book clubs, literature, authors
  movies, // Film buffs, cinema, streaming

  // Social & Community Groups
  events, // Local events, parties
  networking, // Business networking, connections
  support, // Help groups, advice, mentorship
  study, // Study groups, education, learning
  local, // Neighborhood, city, regional

  // Special Interest Groups
  tech, // Technology, startups, innovation
  fashion, // Style, trends, shopping
  pets, // Pet owners, animal lovers
  parenting, // Parents, family, children
  seniors, // Older adults, retirement
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

/// Unified Group model that combines cultural groups and chat functionality
class UnifiedGroup {

  const UnifiedGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.tags, required this.creatorId, required this.adminIds, required this.memberIds, required this.memberCount, required this.maxMembers, required this.isPublic, required this.enableChat, required this.isActive, required this.createdAt, required this.updatedAt, required this.lastActivityAt, this.imageUrl,
    this.location,
    this.culturalInfo,
    this.lastMessageAt,
    this.lastMessageText,
    this.lastMessageSenderId,
  });

  factory UnifiedGroup.fromMap(String id, Map<String, dynamic> data) => UnifiedGroup(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: GroupType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => GroupType.local,
      ),
      imageUrl: data['imageUrl'],
      location: data['location'],
      tags: List<String>.from(data['tags'] ?? []),
      culturalInfo: data['culturalInfo'],
      creatorId: data['creatorId'] ?? '',
      adminIds: List<String>.from(data['adminIds'] ?? []),
      memberIds: List<String>.from(data['memberIds'] ?? []),
      memberCount: data['memberCount'] ?? 0,
      maxMembers: data['maxMembers'] ?? 100,
      isPublic: data['isPublic'] ?? true,
      enableChat: data['enableChat'] ?? true,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActivityAt:
          (data['lastActivityAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      lastMessageText: data['lastMessageText'],
      lastMessageSenderId: data['lastMessageSenderId'],
    );
  final String id;
  final String name;
  final String description;
  final GroupType type;
  final String? imageUrl;
  final String? location;
  final List<String> tags;
  final Map<String, dynamic>? culturalInfo;
  final String creatorId;
  final List<String> adminIds;
  final List<String> memberIds;
  final int memberCount;
  final int maxMembers;
  final bool isPublic;
  final bool enableChat;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastActivityAt;
  final DateTime? lastMessageAt;
  final String? lastMessageText;
  final String? lastMessageSenderId;

  /// Check if user is admin
  bool isAdmin(String userId) => adminIds.contains(userId);

  /// Check if user is member
  bool isMember(String userId) => memberIds.contains(userId);

  /// Check if user is creator
  bool isCreator(String userId) => creatorId == userId;

  /// Check if group has chat enabled
  bool get hasChat => enableChat;

  /// Get group type display name
  String get typeDisplayName {
    switch (type) {
      // Interest & Hobby Groups
      case GroupType.music:
        return 'Music';
      case GroupType.sports:
        return 'Sports';
      case GroupType.travel:
        return 'Travel';
      case GroupType.food:
        return 'Food';
      case GroupType.art:
        return 'Art';

      // Lifestyle & Career Groups
      case GroupType.career:
        return 'Career';
      case GroupType.fitness:
        return 'Fitness';
      case GroupType.gaming:
        return 'Gaming';
      case GroupType.reading:
        return 'Reading';
      case GroupType.movies:
        return 'Movies';

      // Social & Community Groups
      case GroupType.events:
        return 'Events';
      case GroupType.networking:
        return 'Networking';
      case GroupType.support:
        return 'Support';
      case GroupType.study:
        return 'Study';
      case GroupType.local:
        return 'Local';

      // Special Interest Groups
      case GroupType.tech:
        return 'Technology';
      case GroupType.fashion:
        return 'Fashion';
      case GroupType.pets:
        return 'Pets';
      case GroupType.parenting:
        return 'Parenting';
      case GroupType.seniors:
        return 'Seniors';
    }
  }

  @override
  String toString() => 'UnifiedGroup($name: $memberCount/$maxMembers members, ${enableChat ? 'with chat' : 'no chat'})';
}

/// Group message model
class GroupMessage {

  const GroupMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.text,
    required this.messageType,
    required this.timestamp, required this.isRead, required this.readBy, this.mediaUrl,
    this.mediaType,
    this.replyToMessageId,
  });

  factory GroupMessage.fromMap(String id, Map<String, dynamic> data) => GroupMessage(
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

  /// Check if message is read by user
  bool isReadBy(String userId) => readBy.contains(userId);

  @override
  String toString() => 'GroupMessage($text: ${messageType.name})';
}
