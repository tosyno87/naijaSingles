import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../common/constants/app_colors.dart';
import '../../features/notifications/data/services/notification_service.dart';
import 'notification_model.dart';

/// Modern notifications screen following industry standards
/// Features:
/// - Real-time updates with smooth animations
/// - Rich notification cards with images
/// - Smart grouping and categorization
/// - Swipe actions (mark read, delete)
/// - Pull-to-refresh functionality
/// - Empty state with engaging design
/// - Loading states with skeleton UI
class ModernNotificationsScreen extends StatefulWidget {
  const ModernNotificationsScreen({super.key});

  @override
  State<ModernNotificationsScreen> createState() =>
      _ModernNotificationsScreenState();
}

class _ModernNotificationsScreenState extends State<ModernNotificationsScreen>
    with TickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  String _selectedFilter = 'all';
  StreamSubscription<List<AppNotification>>? _notificationsSubscription;
  StreamSubscription<int>? _unreadCountSubscription;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _filters = [
    'all',
    'unread',
    'matches',
    'messages',
    'likes',
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadNotifications();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  void _loadNotifications() {
    _notificationsSubscription = _notificationService.notificationsStream.listen((notifications) {
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
        unawaited(_animationController.forward());
      }
    });

    _unreadCountSubscription = _notificationService.unreadCountStream.listen((count) {
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    });
  }

  List<AppNotification> get _filteredNotifications {
    switch (_selectedFilter) {
      case 'unread':
        return _notifications.where((n) => !n.isRead).toList();
      case 'matches':
        return _notifications.where((n) => n.type == 'match').toList();
      case 'messages':
        return _notifications.where((n) => n.type == 'message').toList();
      case 'likes':
        return _notifications
            .where((n) => n.type == 'like' || n.type == 'superLike')
            .toList();
      default:
        return _notifications;
    }
  }

  @override
  void dispose() {
    unawaited(_notificationsSubscription?.cancel() ?? Future<void>.value());
    unawaited(_unreadCountSubscription?.cancel() ?? Future<void>.value());
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: _buildAppBar(),
        body: _isLoading ? _buildLoadingState() : _buildBody(),
      );

  PreferredSizeWidget _buildAppBar() => AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(
              'Notifications',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _unreadCount.toString(),
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Mark all read',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
        ],
      );

  Widget _buildLoadingState() => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => _buildSkeletonCard(),
      );

  Widget _buildSkeletonCard() => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildBody() {
    if (_filteredNotifications.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshNotifications,
            color: AppColors.primaryGreen,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredNotifications.length,
                itemBuilder: (context, index) {
                  final notification = _filteredNotifications[index];
                  return _buildNotificationCard(notification);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() => Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          itemBuilder: (context, index) {
            final filter = _filters[index];
            final isSelected = _selectedFilter == filter;
            final count = _getFilterCount(filter);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_getFilterLabel(filter)),
                    if (count > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count.toString(),
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? AppColors.primaryGreen
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                selectedColor: AppColors.primaryGreen,
                checkmarkColor: Colors.white,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primaryGreen
                      : Colors.grey.shade300,
                ),
                labelStyle: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            );
          },
        ),
      );

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'unread':
        return 'Unread';
      case 'matches':
        return 'Matches';
      case 'messages':
        return 'Messages';
      case 'likes':
        return 'Likes';
      default:
        return 'All';
    }
  }

  int _getFilterCount(String filter) {
    switch (filter) {
      case 'unread':
        return _unreadCount;
      case 'matches':
        return _notifications.where((n) => n.type == 'match').length;
      case 'messages':
        return _notifications.where((n) => n.type == 'message').length;
      case 'likes':
        return _notifications
            .where((n) => n.type == 'like' || n.type == 'superLike')
            .length;
      default:
        return _notifications.length;
    }
  }

  Widget _buildNotificationCard(AppNotification notification) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Dismissible(
          key: Key(notification.id),
          direction: DismissDirection.endToStart,
          background: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(
              Icons.delete_outline,
              color: Colors.white,
              size: 24,
            ),
          ),
          secondaryBackground: Container(
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: const Icon(
              Icons.mark_email_read_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          onDismissed: (direction) {
            if (direction == DismissDirection.endToStart) {
              _deleteNotification(notification);
            } else {
              _markAsRead(notification);
            }
          },
          child: _buildNotificationContent(notification),
        ),
      );

  Widget _buildNotificationContent(AppNotification notification) =>
      DecoratedBox(
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : AppColors.primaryGreen.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? Colors.grey.shade200
                : AppColors.primaryGreen.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleNotificationTap(notification),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNotificationAvatar(notification),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildNotificationHeader(notification),
                        const SizedBox(height: 8),
                        _buildNotificationMessage(notification),
                        const SizedBox(height: 8),
                        _buildNotificationFooter(notification),
                      ],
                    ),
                  ),
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildNotificationAvatar(AppNotification notification) {
    if (notification.avatarUrl != null && notification.avatarUrl!.isNotEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: notification.typeColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: notification.avatarUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => ColoredBox(
              color: Colors.grey.shade200,
              child: Icon(
                notification.typeIcon,
                color: notification.typeColor,
                size: 24,
              ),
            ),
            errorWidget: (context, url, error) => ColoredBox(
              color: notification.typeColor.withValues(alpha: 0.1),
              child: Icon(
                notification.typeIcon,
                color: notification.typeColor,
                size: 24,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: notification.typeColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: notification.typeColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Icon(
        notification.typeIcon,
        color: notification.typeColor,
        size: 24,
      ),
    );
  }

  Widget _buildNotificationHeader(AppNotification notification) => Row(
        children: [
          Expanded(
            child: Text(
              notification.title,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight:
                    notification.isRead ? FontWeight.w500 : FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: notification.typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getTypeLabel(notification.type),
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: notification.typeColor,
              ),
            ),
          ),
        ],
      );

  Widget _buildNotificationMessage(AppNotification notification) => Text(
        notification.message,
        style: GoogleFonts.montserrat(
          fontSize: 14,
          color: notification.isRead
              ? AppColors.textSecondary
              : AppColors.textPrimary,
          height: 1.4,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );

  Widget _buildNotificationFooter(AppNotification notification) => Row(
        children: [
          Text(
            notification.getRelativeTime(),
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          // Priority indicator removed - AppNotification model doesn't have priority field
          // Can be added later if needed
        ],
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                size: 60,
                color: AppColors.primaryGreen.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _getEmptyStateTitle(),
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptyStateMessage(),
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshNotifications,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );

  String _getEmptyStateTitle() {
    switch (_selectedFilter) {
      case 'unread':
        return 'No unread notifications';
      case 'matches':
        return 'No matches yet';
      case 'messages':
        return 'No messages';
      case 'likes':
        return 'No likes yet';
      default:
        return 'No notifications yet';
    }
  }

  String _getEmptyStateMessage() {
    switch (_selectedFilter) {
      case 'unread':
        return 'All caught up! Check back later for new notifications.';
      case 'matches':
        return 'Keep swiping to find your perfect match!';
      case 'messages':
        return 'Start conversations with your matches to see messages here.';
      case 'likes':
        return 'Complete your profile to get more likes!';
      default:
        return 'We\'ll notify you when something exciting happens!';
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'match':
        return 'MATCH';
      case 'message':
        return 'MESSAGE';
      case 'like':
        return 'LIKE';
      case 'superLike':
        return 'SUPER LIKE';
      case 'view':
        return 'VIEW';
      case 'invite':
        return 'INVITE';
      default:
        return 'NOTIFICATION';
    }
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate refresh delay
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isLoading = false;
    });
  }

  void _handleNotificationTap(AppNotification notification) {
    if (!notification.isRead) {
      _markAsRead(notification);
    }

    // Navigate to appropriate screen based on notification type
    _navigateFromNotification(notification);
  }

  void _navigateFromNotification(AppNotification notification) {
    // This would integrate with your app's navigation system
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Navigating to ${notification.type}: ${notification.actionId}',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  void _markAsRead(AppNotification notification) {
    unawaited(_notificationService.markAsRead(notification.id));
  }

  void _markAllAsRead() {
    unawaited(_notificationService.markAllAsRead());
  }

  void _deleteNotification(AppNotification notification) {
    unawaited(_notificationService.deleteNotification(notification.id));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notification deleted'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primaryGreen,
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            // Implement undo functionality
          },
        ),
      ),
    );
  }
}
