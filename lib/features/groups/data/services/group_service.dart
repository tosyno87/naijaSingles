import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../models/group_model.dart';

/// Service for managing cultural groups
class GroupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Create a new group
  Future<String?> createGroup({
    required String name,
    required String description,
    required String category,
    String? imageUrl,
    bool isPublic = true,
    int maxMembers = 100,
    String? location,
    List<String> tags = const [],
    Map<String, dynamic>? culturalInfo,
    Map<String, dynamic>? settings,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final group = GroupModel(
        name: name,
        description: description,
        category: category,
        imageUrl: imageUrl,
        creatorId: currentUserId!,
        memberIds: [currentUserId!], // Creator is automatically a member
        adminIds: [currentUserId!], // Creator is automatically an admin
        culturalInfo: culturalInfo,
        isPublic: isPublic,
        maxMembers: maxMembers,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        location: location,
        tags: tags,
        settings: settings,
      );

      final docRef = await _firestore.collection('groups').add(group.toMap());

      debugPrint('✅ Group created successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating group: $e');
      return null;
    }
  }

  /// Get all public groups
  Future<List<GroupModel>> getPublicGroups({
    String? category,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('groups')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (category != null && category != 'All') {
        query = query.where('category', isEqualTo: category);
      }

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final groups = snapshot.docs.map(GroupModel.fromDocument).toList();

      debugPrint('✅ Retrieved ${groups.length} public groups');
      return groups;
    } catch (e) {
      debugPrint('❌ Error getting public groups: $e');
      return [];
    }
  }

  /// Get groups that user is a member of
  Future<List<GroupModel>> getUserGroups() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _firestore
          .collection('groups')
          .where('memberIds', arrayContains: currentUserId)
          .orderBy('updatedAt', descending: true)
          .get();

      final groups = snapshot.docs.map(GroupModel.fromDocument).toList();

      debugPrint('✅ Retrieved ${groups.length} user groups');
      return groups;
    } catch (e) {
      debugPrint('❌ Error getting user groups: $e');
      return [];
    }
  }

  /// Get groups created by user
  Future<List<GroupModel>> getUserCreatedGroups() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _firestore
          .collection('groups')
          .where('creatorId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      final groups = snapshot.docs.map(GroupModel.fromDocument).toList();

      debugPrint('✅ Retrieved ${groups.length} user created groups');
      return groups;
    } catch (e) {
      debugPrint('❌ Error getting user created groups: $e');
      return [];
    }
  }

  /// Join a group
  Future<bool> joinGroup(String groupId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final groupRef = _firestore.collection('groups').doc(groupId);

      // Use transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        final groupDoc = await transaction.get(groupRef);

        if (!groupDoc.exists) {
          throw Exception('Group not found');
        }

        final group = GroupModel.fromDocument(groupDoc);

        if (group.isMember(currentUserId!)) {
          throw Exception('User is already a member');
        }

        if (group.isFull) {
          throw Exception('Group is full');
        }

        // Add user to memberIds
        final updatedMemberIds = List<String>.from(group.memberIds)
          ..add(currentUserId!);

        transaction.update(groupRef, {
          'memberIds': updatedMemberIds,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      });

      debugPrint('✅ User joined group: $groupId');
      return true;
    } catch (e) {
      debugPrint('❌ Error joining group: $e');
      return false;
    }
  }

  /// Leave a group
  Future<bool> leaveGroup(String groupId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final groupRef = _firestore.collection('groups').doc(groupId);

      // Use transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        final groupDoc = await transaction.get(groupRef);

        if (!groupDoc.exists) {
          throw Exception('Group not found');
        }

        final group = GroupModel.fromDocument(groupDoc);

        if (!group.isMember(currentUserId!)) {
          throw Exception('User is not a member');
        }

        // Remove user from memberIds and adminIds
        final updatedMemberIds = List<String>.from(group.memberIds)
          ..remove(currentUserId);
        final updatedAdminIds = List<String>.from(group.adminIds)
          ..remove(currentUserId);

        // If user is the creator, transfer ownership to first admin or delete group
        if (group.isCreator(currentUserId!)) {
          if (updatedAdminIds.isNotEmpty) {
            // Transfer ownership to first admin
            transaction.update(groupRef, {
              'creatorId': updatedAdminIds.first,
              'memberIds': updatedMemberIds,
              'adminIds': updatedAdminIds,
              'updatedAt': Timestamp.fromDate(DateTime.now()),
            });
          } else {
            // No admins left, delete the group
            transaction.delete(groupRef);
          }
        } else {
          // Regular member leaving
          transaction.update(groupRef, {
            'memberIds': updatedMemberIds,
            'adminIds': updatedAdminIds,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
        }
      });

      debugPrint('✅ User left group: $groupId');
      return true;
    } catch (e) {
      debugPrint('❌ Error leaving group: $e');
      return false;
    }
  }

  /// Get group by ID
  Future<GroupModel?> getGroup(String groupId) async {
    try {
      final doc = await _firestore.collection('groups').doc(groupId).get();

      if (!doc.exists) {
        return null;
      }

      return GroupModel.fromDocument(doc);
    } catch (e) {
      debugPrint('❌ Error getting group: $e');
      return null;
    }
  }

  /// Update group
  Future<bool> updateGroup(String groupId, Map<String, dynamic> updates) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final groupRef = _firestore.collection('groups').doc(groupId);

      // Check if user has permission to update
      final group = await getGroup(groupId);
      if (group == null) {
        throw Exception('Group not found');
      }

      if (!group.isAdmin(currentUserId!)) {
        throw Exception('User does not have permission to update group');
      }

      // Add updatedAt timestamp
      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());

      await groupRef.update(updates);

      debugPrint('✅ Group updated successfully: $groupId');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating group: $e');
      return false;
    }
  }

  /// Delete group
  Future<bool> deleteGroup(String groupId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final group = await getGroup(groupId);
      if (group == null) {
        throw Exception('Group not found');
      }

      if (!group.isCreator(currentUserId!)) {
        throw Exception('Only group creator can delete group');
      }

      await _firestore.collection('groups').doc(groupId).delete();

      debugPrint('✅ Group deleted successfully: $groupId');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting group: $e');
      return false;
    }
  }

  /// Search groups
  Future<List<GroupModel>> searchGroups({
    required String query,
    String? category,
    int limit = 20,
  }) async {
    try {
      Query firestoreQuery = _firestore
          .collection('groups')
          .where('isPublic', isEqualTo: true)
          .limit(limit);

      if (category != null && category != 'All') {
        firestoreQuery = firestoreQuery.where('category', isEqualTo: category);
      }

      final snapshot = await firestoreQuery.get();
      final allGroups = snapshot.docs.map(GroupModel.fromDocument).toList();

      // Filter by search query (Firestore doesn't support full-text search)
      final filteredGroups = allGroups.where((group) {
        final searchLower = query.toLowerCase();
        return group.name.toLowerCase().contains(searchLower) ||
            group.description.toLowerCase().contains(searchLower) ||
            group.tags.any((tag) => tag.toLowerCase().contains(searchLower));
      }).toList();

      debugPrint('✅ Found ${filteredGroups.length} groups matching "$query"');
      return filteredGroups;
    } catch (e) {
      debugPrint('❌ Error searching groups: $e');
      return [];
    }
  }

  /// Get group members
  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
    try {
      final group = await getGroup(groupId);
      if (group == null) {
        return [];
      }

      // Get user details for each member
      final members = <Map<String, dynamic>>[];

      for (final memberId in group.memberIds) {
        final userDoc =
            await _firestore.collection('users').doc(memberId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          members.add({
            'id': memberId,
            'name': userData['name'] ?? 'Unknown User',
            'imageUrl': userData['profilePicture'] ?? userData['photos']?[0],
            'isAdmin': group.isAdmin(memberId),
            'isCreator': group.isCreator(memberId),
            'joinedAt':
                userData['createdAt'] ?? DateTime.now().toIso8601String(),
          });
        }
      }

      return members;
    } catch (e) {
      debugPrint('❌ Error getting group members: $e');
      return [];
    }
  }

  /// Add admin to group
  Future<bool> addAdmin(String groupId, String userId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final group = await getGroup(groupId);
      if (group == null) {
        throw Exception('Group not found');
      }

      if (!group.isCreator(currentUserId!)) {
        throw Exception('Only group creator can add admins');
      }

      if (!group.isMember(userId)) {
        throw Exception('User must be a member to become an admin');
      }

      if (group.isAdmin(userId)) {
        throw Exception('User is already an admin');
      }

      final updatedAdminIds = List<String>.from(group.adminIds)..add(userId);

      await _firestore.collection('groups').doc(groupId).update({
        'adminIds': updatedAdminIds,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      debugPrint('✅ Admin added to group: $groupId');
      return true;
    } catch (e) {
      debugPrint('❌ Error adding admin: $e');
      return false;
    }
  }

  /// Remove admin from group
  Future<bool> removeAdmin(String groupId, String userId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final group = await getGroup(groupId);
      if (group == null) {
        throw Exception('Group not found');
      }

      if (!group.isCreator(currentUserId!)) {
        throw Exception('Only group creator can remove admins');
      }

      if (group.isCreator(userId)) {
        throw Exception('Cannot remove group creator from admins');
      }

      if (!group.isAdmin(userId)) {
        throw Exception('User is not an admin');
      }

      final updatedAdminIds = List<String>.from(group.adminIds)..remove(userId);

      await _firestore.collection('groups').doc(groupId).update({
        'adminIds': updatedAdminIds,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      debugPrint('✅ Admin removed from group: $groupId');
      return true;
    } catch (e) {
      debugPrint('❌ Error removing admin: $e');
      return false;
    }
  }
}
