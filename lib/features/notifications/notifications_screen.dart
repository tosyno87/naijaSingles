// ⚠️ DEPRECATED: Use ModernNotificationsScreen from
// modern_notifications_screen.dart instead.
// This is the original basic implementation. The modern version has
// skeleton loading, filtering, pull-to-refresh, and better UX.
// TODO: Migrate callers to ModernNotificationsScreen, then delete this file.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data/services/notification_service.dart';
import 'notification_model.dart';

@Deprecated('Use ModernNotificationsScreen from modern_notifications_screen.dart')
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();

    return StreamBuilder<List<AppNotification>>(
      stream: notificationService.notificationsStream,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final notifications = snapshot.data ?? [];

        return _NotificationsContent(
          notifications: notifications,
          isLoading: isLoading,
          notificationService: notificationService,
        );
      },
    );
  }
}

class _NotificationsContent extends StatelessWidget {
  const _NotificationsContent({
    required this.notifications,
    required this.isLoading,
    required this.notificationService,
  });

  final List<AppNotification> notifications;
  final bool isLoading;
  final NotificationService notificationService;

  Future<void> _markAsRead(String id) async {
    await notificationService.markAsRead(id);
  }

  Future<void> _deleteNotification(String id) async {
    await notificationService.deleteNotification(id);
  }

  Future<void> _markAllAsRead() async {
    await notificationService.markAllAsRead();
  }

  void _handleNotificationTap(
    BuildContext context,
    AppNotification notification,
  ) {
    // Mark as read when tapped
    unawaited(_markAsRead(notification.id));

    // In a real app, navigate to the appropriate screen based on notification type
    switch (notification.type) {
      case 'match':
      case 'like':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigating to profile: ${notification.actionId}'),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case 'message':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigating to chat: ${notification.actionId}'),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case 'invite':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigating to invitation: ${notification.actionId}'),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Background color for the app
    const Color backgroundColor = Colors.white;

    // Deep green color for accents
    const Color deepGreen = Color(0xFF008037);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.brown.shade800,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: deepGreen),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!isLoading && notifications.isNotEmpty)
            TextButton(
              onPressed: () => unawaited(_markAllAsRead()),
              child: Text(
                'Mark all read',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: deepGreen,
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? _buildLoadingState()
          : notifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationsList(context),
    );
  }

  Widget _buildLoadingState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF008037),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading notifications...',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We\'ll notify you when something happens',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildNotificationsList(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return Dismissible(
            key: Key(notification.id),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              unawaited(_deleteNotification(notification.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification removed'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: _buildNotificationItem(context, notification),
          );
        },
      );

  Widget _buildNotificationItem(
    BuildContext context,
    AppNotification notification,
  ) {
    final bool isRead = notification.isRead;

    return InkWell(
      onTap: () => _handleNotificationTap(context, notification),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFE8F5E9),
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar or icon
            if (notification.avatarUrl != null)
              CircleAvatar(
                radius: 24,
                backgroundImage: notification.avatarUrl!.startsWith('http')
                    ? NetworkImage(notification.avatarUrl!)
                    : AssetImage(notification.avatarUrl!) as ImageProvider,
                backgroundColor: Colors.grey[300],
              )
            else
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: notification.typeColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notification.typeIcon,
                  color: notification.typeColor,
                  size: 24,
                ),
              ),

            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: isRead ? Colors.grey[600] : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.getRelativeTime(),
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),

            // Unread indicator
            if (!isRead)
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF008037),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
