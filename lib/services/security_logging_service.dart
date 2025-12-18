import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Types of security events to log
enum SecurityEventType {
  unauthorizedProfileAccess,
  blockedFieldAccess,
  suspiciousActivity,
  ruleViolation,
  massDataAccess,
  locationScraping,
  profileScraping,
  chatSpam,
  reportSubmission,
  blockAction,
}

/// Security event data structure
class SecurityEvent {

  SecurityEvent({
    required this.id,
    required this.type,
    required this.userId,
    required this.description, required this.metadata, required this.timestamp, required this.severity, this.targetUserId,
    this.ipAddress,
    this.userAgent,
  });

  factory SecurityEvent.fromMap(Map<String, dynamic> map, String id) => SecurityEvent(
      id: id,
      type: SecurityEventType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => SecurityEventType.suspiciousActivity,
      ),
      userId: map['userId'] ?? '',
      targetUserId: map['targetUserId'],
      description: map['description'] ?? '',
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      severity: map['severity'] ?? 'medium',
      ipAddress: map['ipAddress'],
      userAgent: map['userAgent'],
    );
  final String id;
  final SecurityEventType type;
  final String userId;
  final String? targetUserId;
  final String description;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final String severity; // 'low', 'medium', 'high', 'critical'
  final String? ipAddress;
  final String? userAgent;

  Map<String, dynamic> toMap() => {
      'id': id,
      'type': type.name,
      'userId': userId,
      'targetUserId': targetUserId,
      'description': description,
      'metadata': metadata,
      'timestamp': Timestamp.fromDate(timestamp),
      'severity': severity,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'processed': false,
      'alertSent': false,
    };
}

/// Service for logging security events and monitoring violations
class SecurityLoggingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Log a security event
  Future<void> logSecurityEvent({
    required SecurityEventType type,
    required String description,
    String? targetUserId,
    Map<String, dynamic>? metadata,
    String severity = 'medium',
  }) async {
    try {
      if (currentUserId == null) return;

      final event = SecurityEvent(
        id: _firestore.collection('security_logs').doc().id,
        type: type,
        userId: currentUserId!,
        targetUserId: targetUserId,
        description: description,
        metadata: metadata ?? {},
        timestamp: DateTime.now(),
        severity: severity,
      );

      await _firestore
          .collection('security_logs')
          .doc(event.id)
          .set(event.toMap());

      // Check if this event should trigger an alert
      await _checkForAlerts(event);
    } catch (e) {
      debugPrint('Error logging security event: $e');
    }
  }

  /// Log unauthorized profile access attempt
  Future<void> logUnauthorizedAccess({
    required String targetUserId,
    required String attemptedField,
    String? reason,
  }) async {
    await logSecurityEvent(
      type: SecurityEventType.unauthorizedProfileAccess,
      description: 'Attempted to access restricted field: $attemptedField',
      targetUserId: targetUserId,
      metadata: {
        'attemptedField': attemptedField,
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
      },
      severity: 'high',
    );
  }

  /// Log blocked field access attempt
  Future<void> logBlockedFieldAccess({
    required String targetUserId,
    required String field,
    required String rule,
  }) async {
    await logSecurityEvent(
      type: SecurityEventType.blockedFieldAccess,
      description: 'Blocked access to field: $field',
      targetUserId: targetUserId,
      metadata: {
        'field': field,
        'rule': rule,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log suspicious activity (mass data access)
  Future<void> logSuspiciousActivity({
    required String activity,
    required int count,
    required Duration timeWindow,
  }) async {
    await logSecurityEvent(
      type: SecurityEventType.suspiciousActivity,
      description: 'Suspicious activity detected: $activity',
      metadata: {
        'activity': activity,
        'count': count,
        'timeWindowMinutes': timeWindow.inMinutes,
        'timestamp': DateTime.now().toIso8601String(),
      },
      severity: count > 50 ? 'critical' : 'high',
    );
  }

  /// Log profile scraping attempt
  Future<void> logProfileScraping({
    required int profilesAccessed,
    required Duration timeWindow,
  }) async {
    await logSecurityEvent(
      type: SecurityEventType.profileScraping,
      description:
          'Potential profile scraping: $profilesAccessed profiles in ${timeWindow.inMinutes} minutes',
      metadata: {
        'profilesAccessed': profilesAccessed,
        'timeWindowMinutes': timeWindow.inMinutes,
        'timestamp': DateTime.now().toIso8601String(),
      },
      severity: profilesAccessed > 100 ? 'critical' : 'high',
    );
  }

  /// Log chat spam
  Future<void> logChatSpam({
    required String targetUserId,
    required int messageCount,
    required Duration timeWindow,
  }) async {
    await logSecurityEvent(
      type: SecurityEventType.chatSpam,
      description:
          'Potential chat spam: $messageCount messages in ${timeWindow.inMinutes} minutes',
      targetUserId: targetUserId,
      metadata: {
        'messageCount': messageCount,
        'timeWindowMinutes': timeWindow.inMinutes,
        'timestamp': DateTime.now().toIso8601String(),
      },
      severity: messageCount > 20 ? 'high' : 'medium',
    );
  }

  /// Log user report submission
  Future<void> logReportSubmission({
    required String reportedUserId,
    required String reason,
    String? description,
  }) async {
    await logSecurityEvent(
      type: SecurityEventType.reportSubmission,
      description: 'User reported: $reason',
      targetUserId: reportedUserId,
      metadata: {
        'reason': reason,
        'description': description,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log block action
  Future<void> logBlockAction({
    required String blockedUserId,
    required String action, // 'blocked' or 'unblocked'
  }) async {
    await logSecurityEvent(
      type: SecurityEventType.blockAction,
      description: 'User $action: $blockedUserId',
      targetUserId: blockedUserId,
      metadata: {
        'action': action,
        'timestamp': DateTime.now().toIso8601String(),
      },
      severity: 'low',
    );
  }

  /// Check if event should trigger alerts
  Future<void> _checkForAlerts(SecurityEvent event) async {
    try {
      // Check for patterns that require immediate attention
      switch (event.type) {
        case SecurityEventType.suspiciousActivity:
        case SecurityEventType.profileScraping:
          if (event.severity == 'critical') {
            await _sendCriticalAlert(event);
          }
          break;

        case SecurityEventType.unauthorizedProfileAccess:
          await _checkForRepeatedViolations(event);
          break;

        default:
          break;
      }

      // Check for user-specific violation patterns
      await _checkUserViolationPattern(event.userId);
    } catch (e) {
      debugPrint('Error checking for alerts: $e');
    }
  }

  /// Send critical alert to admin
  Future<void> _sendCriticalAlert(SecurityEvent event) async {
    try {
      await _firestore.collection('admin_alerts').add({
        'type': 'critical_security_event',
        'eventId': event.id,
        'userId': event.userId,
        'description': event.description,
        'severity': event.severity,
        'timestamp': FieldValue.serverTimestamp(),
        'processed': false,
        'metadata': event.metadata,
      });

      // Mark event as alert sent
      await _firestore
          .collection('security_logs')
          .doc(event.id)
          .update({'alertSent': true});
    } catch (e) {
      debugPrint('Error sending critical alert: $e');
    }
  }

  /// Check for repeated violations by same user
  Future<void> _checkForRepeatedViolations(SecurityEvent event) async {
    try {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));

      final recentViolations = await _firestore
          .collection('security_logs')
          .where('userId', isEqualTo: event.userId)
          .where('type', isEqualTo: event.type.name)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(oneHourAgo))
          .get();

      if (recentViolations.docs.length >= 5) {
        await _sendRepeatedViolationAlert(
            event.userId, event.type, recentViolations.docs.length,);
      }
    } catch (e) {
      debugPrint('Error checking repeated violations: $e');
    }
  }

  /// Send repeated violation alert
  Future<void> _sendRepeatedViolationAlert(
      String userId, SecurityEventType type, int count,) async {
    try {
      await _firestore.collection('admin_alerts').add({
        'type': 'repeated_violations',
        'userId': userId,
        'violationType': type.name,
        'count': count,
        'timeWindow': '1 hour',
        'description':
            'User has $count ${type.name} violations in the last hour',
        'severity': 'high',
        'timestamp': FieldValue.serverTimestamp(),
        'processed': false,
        'recommendedAction': 'Consider temporary suspension',
      });
    } catch (e) {
      debugPrint('Error sending repeated violation alert: $e');
    }
  }

  /// Check overall user violation pattern
  Future<void> _checkUserViolationPattern(String userId) async {
    try {
      final now = DateTime.now();
      final oneDayAgo = now.subtract(const Duration(days: 1));

      final recentEvents = await _firestore
          .collection('security_logs')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(oneDayAgo))
          .get();

      if (recentEvents.docs.length >= 10) {
        await _sendUserPatternAlert(userId, recentEvents.docs.length);
      }
    } catch (e) {
      debugPrint('Error checking user violation pattern: $e');
    }
  }

  /// Send user pattern alert
  Future<void> _sendUserPatternAlert(String userId, int eventCount) async {
    try {
      await _firestore.collection('admin_alerts').add({
        'type': 'user_violation_pattern',
        'userId': userId,
        'eventCount': eventCount,
        'timeWindow': '24 hours',
        'description':
            'User has $eventCount security events in the last 24 hours',
        'severity': 'high',
        'timestamp': FieldValue.serverTimestamp(),
        'processed': false,
        'recommendedAction': 'Review user activity and consider restrictions',
      });
    } catch (e) {
      debugPrint('Error sending user pattern alert: $e');
    }
  }

  /// Get security events for a user (admin function)
  Future<List<SecurityEvent>> getUserSecurityEvents(String userId,
      {int limit = 50,}) async {
    try {
      final query = await _firestore
          .collection('security_logs')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => SecurityEvent.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting user security events: $e');
      return [];
    }
  }

  /// Get security statistics (admin function)
  Future<Map<String, dynamic>> getSecurityStats({int days = 7}) async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));

      final events = await _firestore
          .collection('security_logs')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(startDate))
          .get();

      final Map<String, int> eventCounts = {};
      final Map<String, int> severityCounts = {};

      for (var doc in events.docs) {
        final data = doc.data();
        final type = data['type'] as String;
        final severity = data['severity'] as String;

        eventCounts[type] = (eventCounts[type] ?? 0) + 1;
        severityCounts[severity] = (severityCounts[severity] ?? 0) + 1;
      }

      return {
        'totalEvents': events.docs.length,
        'eventTypes': eventCounts,
        'severityBreakdown': severityCounts,
        'timeRange': '$days days',
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting security stats: $e');
      return {};
    }
  }
}
