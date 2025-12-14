import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../common/constants/app_colors.dart';
import '../../services/industry_notification_service.dart';
import 'modern_notifications_screen.dart';

/// Modern notification badge with industry-standard features
/// Features:
/// - Real-time unread count updates
/// - Smooth animations and transitions
/// - Customizable appearance
/// - Haptic feedback
/// - Badge pulsing animation for new notifications
class ModernNotificationBadge extends StatefulWidget {

  const ModernNotificationBadge({
    super.key,
    this.iconColor = AppColors.textPrimary,
    this.iconSize = 24.0,
    this.badgeColor = Colors.red,
    this.showBadge = true,
    this.enableHapticFeedback = true,
    this.onTap,
  });
  final Color iconColor;
  final double iconSize;
  final Color badgeColor;
  final bool showBadge;
  final bool enableHapticFeedback;
  final VoidCallback? onTap;

  @override
  State<ModernNotificationBadge> createState() =>
      _ModernNotificationBadgeState();
}

class _ModernNotificationBadgeState extends State<ModernNotificationBadge>
    with TickerProviderStateMixin {
  final IndustryNotificationService _notificationService =
      IndustryNotificationService();

  int _unreadCount = 0;
  bool _hasNewNotifications = false;

  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startListening();
  }

  void _setupAnimations() {
    // Pulse animation for new notifications
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ),);

    // Scale animation for tap feedback
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ),);
  }

  void _startListening() {
    _notificationService.unreadCountStream.listen((count) {
      if (mounted) {
        final previousCount = _unreadCount;
        setState(() {
          _unreadCount = count;
          _hasNewNotifications = count > previousCount;
        });

        // Start pulse animation for new notifications
        if (_hasNewNotifications && count > 0) {
          _pulseController.repeat(reverse: true);

          // Stop pulsing after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              _pulseController.stop();
              _pulseController.reset();
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTapDown: (_) {
        if (widget.enableHapticFeedback) {
          // Haptic feedback for tap
          // HapticFeedback.lightImpact();
        }
        _scaleController.forward();
      },
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
        builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Notification icon
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: widget.iconColor,
                    size: widget.iconSize,
                  ),
                ),

                // Badge with pulse animation
                if (widget.showBadge && _unreadCount > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Transform.scale(
                      scale: _pulseAnimation.value,
                      child: _buildBadge(),
                    ),
                  ),
              ],
            ),
          ),
      ),
    );

  Widget _buildBadge() => Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: widget.badgeColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.badgeColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      constraints: const BoxConstraints(
        minWidth: 20,
        minHeight: 20,
      ),
      child: Center(
        child: Text(
          _unreadCount > 99 ? '99+' : _unreadCount.toString(),
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      _navigateToNotifications();
    }
  }

  Future<void> _navigateToNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ModernNotificationsScreen(),
        fullscreenDialog: true,
      ),
    );
  }
}

/// Floating notification badge for overlay use
class FloatingNotificationBadge extends StatefulWidget {

  const FloatingNotificationBadge({
    required this.child, super.key,
    this.badgeColor = Colors.red,
    this.showBadge = true,
    this.badgePosition,
  });
  final Widget child;
  final Color badgeColor;
  final bool showBadge;
  final Offset? badgePosition;

  @override
  State<FloatingNotificationBadge> createState() =>
      _FloatingNotificationBadgeState();
}

class _FloatingNotificationBadgeState extends State<FloatingNotificationBadge> {
  final IndustryNotificationService _notificationService =
      IndustryNotificationService();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _notificationService.unreadCountStream.listen((count) {
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) => Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (widget.showBadge && _unreadCount > 0)
          Positioned(
            top: widget.badgePosition?.dy ?? 0,
            right: widget.badgePosition?.dx ?? 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: widget.badgeColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.badgeColor.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Center(
                child: Text(
                  _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
}

/// Notification badge for app bar
class AppBarNotificationBadge extends StatelessWidget {

  const AppBarNotificationBadge({
    super.key,
    this.onTap,
    this.iconColor = AppColors.textPrimary,
    this.iconSize = 24.0,
  });
  final VoidCallback? onTap;
  final Color iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) => ModernNotificationBadge(
      iconColor: iconColor,
      iconSize: iconSize,
      onTap: onTap,
    );
}

/// Notification badge for bottom navigation
class BottomNavNotificationBadge extends StatelessWidget {

  const BottomNavNotificationBadge({
    super.key,
    this.onTap,
    this.iconColor = AppColors.textPrimary,
    this.iconSize = 24.0,
  });
  final VoidCallback? onTap;
  final Color iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) => ModernNotificationBadge(
      iconColor: iconColor,
      iconSize: iconSize,
      onTap: onTap,
    );
}
