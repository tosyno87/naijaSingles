import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'notification_model.dart';
import 'notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  late List<AppNotification> _notifications;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    // In a real app, this would be an async call to a backend service
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _notifications = _notificationService.getAllNotifications();
        _isLoading = false;
      });
    });
  }

  void _markAsRead(String id) {
    setState(() {
      _notificationService.markAsRead(id);
      _notifications = _notificationService.getAllNotifications();
    });
  }

  void _deleteNotification(String id) {
    setState(() {
      _notificationService.deleteNotification(id);
      _notifications = _notificationService.getAllNotifications();
    });
  }

  void _markAllAsRead() {
    setState(() {
      _notificationService.markAllAsRead();
      _notifications = _notificationService.getAllNotifications();
    });
  }

  void _handleNotificationTap(AppNotification notification) {
    // Mark as read when tapped
    _markAsRead(notification.id);

    // In a real app, navigate to the appropriate screen based on notification type
    switch (notification.type) {
      case 'match':
      case 'like':
        // Navigate to profile
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigating to profile: ${notification.actionId}'),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case 'message':
        // Navigate to chat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigating to chat: ${notification.actionId}'),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case 'invite':
        // Navigate to group or event
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigating to invitation: ${notification.actionId}'),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      default:
        // Default action
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
          style: GoogleFonts.poppins(
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
          if (!_isLoading && _notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Mark all read',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: deepGreen,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _notifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationsList(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF008037),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading notifications...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll notify you when something happens',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
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
            _deleteNotification(notification.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Notification removed'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: _buildNotificationItem(notification),
        );
      },
    );
  }

  Widget _buildNotificationItem(AppNotification notification) {
    final bool isRead = notification.isRead;

    return InkWell(
      onTap: () => _handleNotificationTap(notification),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFE8F5E9),
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withValues(alpha: 0.2),
              width: 1,
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
                backgroundImage: AssetImage(notification.avatarUrl!),
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
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isRead ? Colors.grey[600] : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.getRelativeTime(),
                    style: GoogleFonts.poppins(
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
