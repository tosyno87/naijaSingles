import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Model class for app notifications
class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String? avatarUrl; // optional
  final String type; // 'like', 'match', 'message', 'invite', etc.
  final bool isRead;
  final String? actionId; // ID for the related item (profile, message, etc.)

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.avatarUrl,
    this.isRead = false,
    this.actionId,
  });

  /// Create from Firestore document
  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: data['type'] ?? 'general',
      avatarUrl: data['avatarUrl'],
      isRead: data['isRead'] ?? false,
      actionId: data['actionId'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
      'avatarUrl': avatarUrl,
      'isRead': isRead,
      'actionId': actionId,
    };
  }

  /// Returns the appropriate icon for the notification type
  IconData get typeIcon {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'match':
        return Icons.favorite_border;
      case 'message':
        return Icons.chat_bubble_outline;
      case 'invite':
        return Icons.group_add;
      case 'view':
        return Icons.visibility;
      default:
        return Icons.notifications;
    }
  }

  /// Returns the appropriate color for the notification type
  Color get typeColor {
    switch (type) {
      case 'like':
        return Colors.red;
      case 'match':
        return Colors.pink;
      case 'message':
        return const Color(0xFF008037); // deepGreen
      case 'invite':
        return Colors.blue;
      case 'view':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  /// Returns a formatted relative time string (e.g., "2h ago")
  String getRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      // Format as date if more than a week old
      return '${timestamp.day}/${timestamp.month}';
    } else if (difference.inDays > 0) {
      // Format as days ago
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      // Format as hours ago
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      // Format as minutes ago
      return '${difference.inMinutes}m ago';
    } else {
      // Just now
      return 'Just now';
    }
  }

  /// Create a copy of this notification with updated fields
  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    String? avatarUrl,
    String? type,
    bool? isRead,
    String? actionId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      actionId: actionId ?? this.actionId,
    );
  }
}
