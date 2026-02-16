// ⚠️ DEPRECATED: Use ModernNotificationBadge (or AppBarNotificationBadge /
// BottomNavNotificationBadge) from modern_notification_badge.dart instead.
// TODO: Remove this file once no callers remain.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data/services/notification_service.dart';
import 'notifications_screen.dart';

/// A widget that displays a notification icon with a badge for unread notifications
@Deprecated('Use ModernNotificationBadge from modern_notification_badge.dart')
class NotificationBadge extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final notificationService = NotificationService();

    return StreamBuilder<int>(
      stream: notificationService.unreadCountStream,
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return InkWell(
          onTap: () {
            unawaited(Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),);
          },
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.notifications_outlined,
                  color: iconColor,
                  size: iconSize,
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: badgeColor,
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
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
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
      },
    );
  }
}
