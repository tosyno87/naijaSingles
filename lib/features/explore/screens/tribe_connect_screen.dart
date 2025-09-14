import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../common/constants/app_colors.dart';
import '../../../common/widgets/custom_3d_icons.dart';
import '../../../models/user_model.dart';
import '../widgets/tribe_connect_card.dart';
import '../widgets/modern_profile_card.dart';
import '../widgets/match_confirmation_modal.dart';
import '../../../common/data/repo/user_search_repo.dart';
import '../../../services/super_like_service.dart';

class TribeConnectScreen extends StatefulWidget {
  final UserModel currentUser;
  final List<UserModel> users;

  const TribeConnectScreen({
    super.key,
    required this.currentUser,
    required this.users,
  });

  @override
  State<TribeConnectScreen> createState() => _TribeConnectScreenState();
}

class _TribeConnectScreenState extends State<TribeConnectScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.backgroundColor,
      elevation: 0,
      title: Text(
        'Tribe Connect',
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
          icon: Custom3DIcons.filter(size: 24),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    if (widget.users.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshUsers,
      color: AppColors.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: widget.users.length,
        itemBuilder: (context, index) {
          final user = widget.users[index];
          return ModernProfileCard(
            user: user,
            onConnect: () => _handleConnect(user),
            onTap: () => _handleViewProfile(user),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
  }

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

  Widget _buildFilterSheet() {
    return Container(
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
  }

  Widget _buildFilterOption(String title, String value) {
    return Padding(
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
  }

  Future<void> _handleConnect(UserModel user) async {
    try {
      final matchId = await UserSearchRepo.rightSwipe(widget.currentUser, user);
      
      if (matchId != null) {
        _showMatchConfirmation(user);
      } else {
        _showConnectConfirmation(user);
      }
    } catch (e) {
      _showError('Failed to connect. Please try again.');
    }
  }

  void _handleViewProfile(UserModel user) {
    // Navigate to user detail screen
    Navigator.pushNamed(
      context,
      '/user_detail',
      arguments: user,
    );
  }

  void _handleMessage(UserModel user) {
    // Navigate to message screen or show profile preview
    Navigator.pushNamed(
      context,
      '/user_detail',
      arguments: user,
    );
  }

  Future<void> _handleSave(UserModel user) async {
    try {
      await SuperLikeService().sendSuperLike(
        fromUserId: widget.currentUser.id ?? '',
        toUserId: user.id ?? '',
      );
      _showSuccess('${user.name} saved to your favorites!');
    } catch (e) {
      _showError('Failed to save user. Please try again.');
    }
  }

  Future<void> _handleBlock(UserModel user) async {
    final confirmed = await _showBlockConfirmation(user);
    if (confirmed == true) {
      try {
        await UserSearchRepo.leftSwipe(widget.currentUser, user);
        _showSuccess('${user.name} has been blocked.');
      } catch (e) {
        _showError('Failed to block user. Please try again.');
      }
    }
  }

  void _showMatchConfirmation(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => MatchConfirmationModal(
        currentUserImageUrl: widget.currentUser.imageUrl?.isNotEmpty == true
            ? widget.currentUser.imageUrl![0]
            : 'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg',
        matchedUserImageUrl: user.imageUrl?.isNotEmpty == true ? user.imageUrl![0] : '',
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

  Future<bool?> _showBlockConfirmation(UserModel user) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Block ${user.name}?',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'This will prevent ${user.name} from appearing in your feed and block all communication.',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Block',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
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
