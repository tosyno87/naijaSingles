import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for handling group reporting functionality
class GroupReportingService {
  static final GroupReportingService _instance = GroupReportingService._internal();
  factory GroupReportingService() => _instance;
  GroupReportingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Report reasons enum
  static const List<String> reportReasons = [
    'Inappropriate Content',
    'Spam or Scam',
    'Harassment or Bullying',
    'Hate Speech',
    'Violence or Threats',
    'Fake or Misleading',
    'Underage Users',
    'Other',
  ];

  /// Report a group with reason and details
  Future<void> reportGroup({
    required String groupId,
    required String reason,
    String? details,
  }) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Get group details
      final groupDoc = await _firestore
          .collection('unifiedGroups')
          .doc(groupId)
          .get();

      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final groupData = groupDoc.data()!;

      // Create report document
      await _firestore.collection('group_reports').add({
        'groupId': groupId,
        'groupName': groupData['name'],
        'groupCreatorId': groupData['creatorId'],
        'reporterId': currentUserId,
        'reason': reason,
        'details': details ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log the report for security monitoring
      await _logReportEvent(
        groupId: groupId,
        reporterId: currentUserId,
        reason: reason,
      );

      log('✅ Group report submitted: $groupId');
    } catch (e) {
      log('❌ Error reporting group: $e');
      throw Exception('Failed to submit report');
    }
  }

  /// Get reports for a specific group (admin/creator only)
  Future<List<Map<String, dynamic>>> getGroupReports(String groupId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return [];

      // Check if user is group creator or admin
      final groupDoc = await _firestore
          .collection('unifiedGroups')
          .doc(groupId)
          .get();

      if (!groupDoc.exists) return [];

      final groupData = groupDoc.data()!;
      final isCreator = groupData['creatorId'] == currentUserId;
      final isAdmin = (groupData['adminIds'] as List<dynamic>?)?.contains(currentUserId) ?? false;

      if (!isCreator && !isAdmin) {
        throw Exception('Unauthorized to view group reports');
      }

      final querySnapshot = await _firestore
          .collection('group_reports')
          .where('groupId', isEqualTo: groupId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      log('Error getting group reports: $e');
      return [];
    }
  }

  /// Get all reports made by current user
  Future<List<Map<String, dynamic>>> getUserReports() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return [];

      final querySnapshot = await _firestore
          .collection('group_reports')
          .where('reporterId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      log('Error getting user reports: $e');
      return [];
    }
  }

  /// Update report status (admin/moderator only)
  Future<void> updateReportStatus({
    required String reportId,
    required String status,
    String? adminNotes,
  }) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) throw Exception('User not authenticated');

      // TODO: Add admin/moderator permission check
      // For now, allowing any authenticated user to update status
      // In production, this should check user roles

      await _firestore
          .collection('group_reports')
          .doc(reportId)
          .update({
        'status': status,
        'adminNotes': adminNotes,
        'reviewedBy': currentUserId,
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      log('✅ Report status updated: $reportId -> $status');
    } catch (e) {
      log('❌ Error updating report status: $e');
      throw Exception('Failed to update report status');
    }
  }

  /// Log report event for security monitoring
  Future<void> _logReportEvent({
    required String groupId,
    required String reporterId,
    required String reason,
  }) async {
    try {
      await _firestore.collection('security_logs').add({
        'type': 'group_report',
        'groupId': groupId,
        'reporterId': reporterId,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'severity': 'medium',
      });
    } catch (e) {
      log('Error logging report event: $e');
    }
  }

  /// Check if user has already reported this group
  Future<bool> hasUserReportedGroup(String groupId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      final querySnapshot = await _firestore
          .collection('group_reports')
          .where('groupId', isEqualTo: groupId)
          .where('reporterId', isEqualTo: currentUserId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      log('Error checking if user reported group: $e');
      return false;
    }
  }
}
