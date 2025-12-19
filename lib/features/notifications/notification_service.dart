import 'notification_model.dart';

/// Service class to handle notifications
class NotificationService {
  factory NotificationService() => _instance;

  NotificationService._internal();
  // Singleton instance
  static final NotificationService _instance = NotificationService._internal();

  // In-memory storage for notifications
  final List<AppNotification> _notifications = [];

  /// Get all notifications
  List<AppNotification> getAllNotifications() {
    if (_notifications.isEmpty) {
      _loadDummyNotifications();
    }

    // Sort by timestamp (newest first)
    _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return _notifications;
  }

  /// Get unread notifications count
  int getUnreadCount() =>
      _notifications.where((notification) => !notification.isRead).length;

  /// Mark a notification as read
  void markAsRead(String id) {
    final index =
        _notifications.indexWhere((notification) => notification.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
  }

  /// Delete a notification
  void deleteNotification(String id) {
    _notifications.removeWhere((notification) => notification.id == id);
  }

  /// Add a new notification
  void addNotification(AppNotification notification) {
    _notifications.add(notification);
  }

  /// Load dummy notifications for demo purposes
  void _loadDummyNotifications() {
    final now = DateTime.now();

    _notifications.addAll([
      AppNotification(
        id: '1',
        title: 'New Match!',
        message: 'You and Ada are a match! Start a conversation now.',
        timestamp: now.subtract(const Duration(minutes: 5)),
        type: 'match',
        avatarUrl: 'assets/images/placeholder_profile.jpg',
        actionId: 'user_123',
      ),
      AppNotification(
        id: '2',
        title: 'Tunde liked your profile',
        message: 'Someone new is interested in you!',
        timestamp: now.subtract(const Duration(hours: 2)),
        type: 'like',
        avatarUrl: 'assets/images/placeholder_profile.jpg',
        actionId: 'user_456',
      ),
      AppNotification(
        id: '3',
        title: 'New message from Thea',
        message: 'Hey, how are you doing today?',
        timestamp: now.subtract(const Duration(hours: 5)),
        type: 'message',
        avatarUrl: 'assets/images/placeholder_profile.jpg',
        actionId: 'chat_789',
        isRead: true,
      ),
      AppNotification(
        id: '4',
        title: 'You were invited to Nairobi Professionals group',
        message: 'Join 120+ professionals in your area',
        timestamp: now.subtract(const Duration(days: 1)),
        type: 'invite',
        actionId: 'group_101',
      ),
      AppNotification(
        id: '5',
        title: 'Ngozi liked your profile',
        message: 'Someone new is interested in you!',
        timestamp: now.subtract(const Duration(days: 2)),
        type: 'like',
        avatarUrl: 'assets/images/placeholder_profile.jpg',
        actionId: 'user_202',
        isRead: true,
      ),
      AppNotification(
        id: '6',
        title: 'New message from Kwame',
        message: 'Looking forward to meeting you!',
        timestamp: now.subtract(const Duration(days: 3)),
        type: 'message',
        avatarUrl: 'assets/images/placeholder_profile.jpg',
        actionId: 'chat_303',
      ),
      AppNotification(
        id: '7',
        title: 'You were invited to Lagos Tech Event',
        message: 'Join other tech enthusiasts this weekend',
        timestamp: now.subtract(const Duration(days: 4)),
        type: 'invite',
        isRead: true,
        actionId: 'event_404',
      ),
      AppNotification(
        id: '8',
        title: 'Profile view notification',
        message: '5 people viewed your profile this week',
        timestamp: now.subtract(const Duration(days: 5)),
        type: 'view',
        isRead: true,
      ),
    ]);
  }
}
