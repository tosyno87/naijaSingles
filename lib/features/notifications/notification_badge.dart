import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'notification_service.dart';
import 'notifications_screen.dart';

/// A widget that displays a notification icon with a badge for unread notifications
class NotificationBadge extends StatefulWidget {

  const NotificationBadge({
    super.key,
    this.iconColor = const Color(0xFF008037),
    this.iconSize = 24.0,
    this.badgeColor = Colors.red,
  });
  final Color iconColor;
  final double iconSize;
  final Color badgeColor;

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _updateUnreadCount();
  }

  void _updateUnreadCount() {
    setState(() {
      _unreadCount = _notificationService.getUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) => InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );

        // Update unread count when returning from notifications screen
        _updateUnreadCount();
      },
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.notifications_outlined,
              color: widget.iconColor,
              size: widget.iconSize,
            ),
          ),
          if (_unreadCount > 0)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: widget.badgeColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Center(
                  child: Text(
                    _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
}
