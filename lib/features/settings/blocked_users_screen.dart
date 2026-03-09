import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../common/bloc/theme/theme_bloc.dart';
import '../../common/bloc/user/user_bloc.dart';
import '../../common/constants/app_colors.dart';
import '../../common/constants/app_spacing.dart';
import '../../common/widgets/state_views/state_views.dart';
import '../../services/settings_service.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<BlockedUser> _blockedUsers = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _currentUserId = context.read<UserBloc>().currentUser?.id;
    if (_currentUserId != null) {
      unawaited(_loadBlockedUsers());
    }
  }

  Future<void> _loadBlockedUsers() async {
    if (_currentUserId == null) return;

    setState(() => _isLoading = true);

    try {
      final blockedUsers =
          await SettingsService.getBlockedUsers(_currentUserId!);
      if (!context.mounted) return;
      setState(() {
        _blockedUsers = blockedUsers;
        _isLoading = false;
      });
    } on Object {
      if (!context.mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Error loading blocked users', isError: true);
    }
  }

  Future<void> _unblockUser(BlockedUser user) async {
    if (_currentUserId == null) return;

    // Show confirmation dialog
    final shouldUnblock = await _showUnblockConfirmation(user.name);
    if (!shouldUnblock) return;
    if (!mounted) return;

    // Show loading
    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );

    try {
      final success =
          await SettingsService.unblockUser(_currentUserId!, user.id);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (success) {
        // Remove from local list
        setState(() {
          _blockedUsers.removeWhere((u) => u.id == user.id);
        });

        _showSnackBar('${user.name} has been unblocked', isError: false);
      } else {
        _showSnackBar('Failed to unblock ${user.name}', isError: true);
      }
    } on Object {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _showSnackBar('Error unblocking user', isError: true);
    }
  }

  Future<bool> _showUnblockConfirmation(String userName) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Unblock User',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryGreen,
            ),
          ),
          content: Text(
            'Are you sure you want to unblock $userName? They will be able to see your profile and message you again.',
            style: GoogleFonts.montserrat(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.montserrat(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                ),
              ),
              child: Text(
                'Unblock',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeBloc>().isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Blocked Users',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const AppLoadingView(message: 'Loading blocked users...')
          : _blockedUsers.isEmpty
              ? _buildEmptyState()
              : _buildBlockedUsersList(isDarkMode),
    );
  }

  Widget _buildEmptyState() => AppEmptyView(
        title: 'No Blocked Users',
        subtitle:
            'You haven\'t blocked anyone yet. Blocked users won\'t be able to see your profile or message you.',
        icon: Icons.block,
        actionLabel: 'Refresh',
        onAction: _loadBlockedUsers,
      );

  Widget _buildBlockedUsersList(bool isDarkMode) => Column(
        children: [
          // Header info
          Container(
            width: double.infinity,
            margin: AppSpacing.cardPadding,
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.primaryGreen,
                  size: AppSpacing.iconSm,
                ),
                const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Blocked users can\'t see your profile or message you. You can unblock them anytime.',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Blocked users count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_blockedUsers.length} blocked user${_blockedUsers.length == 1 ? '' : 's'}',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Blocked users list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: _blockedUsers.length,
              itemBuilder: (context, index) {
                final user = _blockedUsers[index];
                return _buildBlockedUserCard(user, isDarkMode);
              },
            ),
          ),
        ],
      );

  Widget _buildBlockedUserCard(BlockedUser user, bool isDarkMode) {
    final timeAgo = _getTimeAgo(user.blockedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + AppSpacing.xs),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            // Profile image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
                image: user.imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(user.imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: user.imageUrl.isEmpty
                  ? Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.grey[600],
                    )
                  : null,
            ),

            const SizedBox(width: AppSpacing.md),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Blocked $timeAgo',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (user.reason.isNotEmpty && user.reason != 'User blocked')
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        'Reason: ${user.reason}',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Unblock button
            TextButton(
              onPressed: () => _unblockUser(user),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  side: const BorderSide(color: AppColors.primaryGreen),
                ),
              ),
              child: Text(
                'Unblock',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
