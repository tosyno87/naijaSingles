import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/constants/app_colors.dart';
import '../../../common/data/repo/user_search_repo.dart';
import '../../../common/widgets/custom_3d_icons.dart';
import '../../../models/user_model.dart';
import '../widgets/match_confirmation_modal.dart';
import '../widgets/hinge_profile_card.dart';

class TribeConnectScreen extends StatefulWidget {

  const TribeConnectScreen({
    required this.currentUser, required this.users, super.key,
  });
  final UserModel currentUser;
  final List<UserModel> users;

  @override
  State<TribeConnectScreen> createState() => _TribeConnectScreenState();
}

class _TribeConnectScreenState extends State<TribeConnectScreen> {
  // Track which users have been passed/connected to avoid showing them again
  final Set<String> _processedUserIds = <String>{};
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );

  PreferredSizeWidget _buildAppBar() => AppBar(
      backgroundColor: AppColors.backgroundColor,
      elevation: 0,
      title: Text(
        'Connect',
        style: GoogleFonts.montserrat(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: _showFilters,
          icon: Custom3DIcons.filter(),
        ),
        const SizedBox(width: 8),
      ],
    );

  Widget _buildBody() {
    if (widget.users.isEmpty) {
      return _buildEmptyState();
    }

    // Filter out processed users
    final availableUsers = widget.users
        .where((user) => !_processedUserIds.contains(user.id))
        .toList();

    if (availableUsers.isEmpty) {
      return _buildEmptyState();
    }

    // Hinge-style vertical scrollable feed
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: availableUsers.length,
      itemBuilder: (context, index) {
        final user = availableUsers[index];
        return HingeProfileCard(
          user: user,
          onConnect: () => _handleConnect(user),
          onPass: () => _handlePass(user),
        );
      },
    );
  }

  Widget _buildEmptyState() => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Custom3DIcons.communities(size: 80, color: AppColors.primaryGreen),
          const SizedBox(height: 24),
          Text(
            'No More Profiles',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You\'ve seen all available profiles in your area.\nCheck back later for new connections!',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _refreshUsers,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(
              'Refresh',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

  Future<void> _refreshUsers() async {
    // TODO: Implement refresh logic
    // Simulate loading
    await Future.delayed(const Duration(seconds: 1));
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterSheet(),
    );
  }

  Widget _buildFilterSheet() => Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Your Tribe',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _buildFilterOption('Age Range', '18-35'),
          _buildFilterOption('Heritage', 'Any'),
          _buildFilterOption('Location', 'Within 50km'),
          _buildFilterOption('Languages', 'Any'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Apply Filters',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );

  Widget _buildFilterOption(String title, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );

  Future<void> _handleConnect(UserModel user) async {
    try {
      // Mark user as processed
      setState(() {
        _processedUserIds.add(user.id ?? '');
      });

      final matchId = await UserSearchRepo.rightSwipe(widget.currentUser, user);

      if (matchId != null) {
        _showMatchConfirmation(user);
      } else {
        _showConnectConfirmation(user);
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _processedUserIds.remove(user.id ?? '');
      });
      _showError('Failed to connect. Please try again.');
    }
  }

  Future<void> _handlePass(UserModel user) async {
    try {
      // Mark user as processed
      setState(() {
        _processedUserIds.add(user.id ?? '');
      });

      await UserSearchRepo.leftSwipe(widget.currentUser, user);
      _showPassConfirmation(user);
    } catch (e) {
      // Revert on error
      setState(() {
        _processedUserIds.remove(user.id ?? '');
      });
      _showError('Failed to pass. Please try again.');
    }
  }

  void _showMatchConfirmation(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => MatchConfirmationModal(
        currentUserImageUrl: widget.currentUser.imageUrl?.isNotEmpty ?? false
            ? widget.currentUser.imageUrl![0]
            : 'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg',
        matchedUserImageUrl:
            user.imageUrl?.isNotEmpty ?? false ? user.imageUrl![0] : '',
        matchedUserName: user.name ?? 'Unknown',
        matchedUserId: user.id ?? '',
      ),
    );
  }

  void _showConnectConfirmation(UserModel user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connection request sent to ${user.name}! 💕'),
        backgroundColor: AppColors.primaryGreen,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showPassConfirmation(UserModel user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Passed on ${user.name}'),
        backgroundColor: Colors.grey[600],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
