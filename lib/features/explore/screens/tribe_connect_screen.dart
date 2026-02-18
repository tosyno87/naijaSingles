import 'package:cloud_firestore/cloud_firestore.dart';
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
    required this.currentUser,
    required this.users,
    this.onFiltersApplied,
    super.key,
  });
  final UserModel currentUser;
  final List<UserModel> users;
  final VoidCallback? onFiltersApplied;

  @override
  State<TribeConnectScreen> createState() => _TribeConnectScreenState();
}

class _TribeConnectScreenState extends State<TribeConnectScreen> {
  // Track which users have been passed/connected to avoid showing them again
  final Set<String> _processedUserIds = <String>{};
  int _currentProfileIndex = 0;

  // Get current profile being shown
  UserModel? get _currentProfile {
    final availableUsers = widget.users
        .where((user) => !_processedUserIds.contains(user.id))
        .toList();
    if (_currentProfileIndex < availableUsers.length) {
      return availableUsers[_currentProfileIndex];
    }
    return null;
  }

  // Get all available (not yet processed) users
  List<UserModel> get _availableUsers {
    return widget.users
        .where((user) => !_processedUserIds.contains(user.id))
        .toList();
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

    final currentProfile = _currentProfile;

    if (currentProfile == null || _availableUsers.isEmpty) {
      return _buildEmptyState();
    }

    // Hinge-style: Show ONE profile at a time, scrollable vertically for details
    // Pass/Connect buttons move to next profile
    return SingleChildScrollView(
      child: HingeProfileCard(
        user: currentProfile,
        onConnect: () => _handleConnect(currentProfile),
        onPass: () => _handlePass(currentProfile),
      ),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
      builder: (context) => _ConnectFilterSheet(
        currentUser: widget.currentUser,
        onApply: () {
          setState(() {
            _processedUserIds.clear();
            _currentProfileIndex = 0;
          });
          widget.onFiltersApplied?.call();
        },
      ),
    );
  }

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

      // Move to next profile after a brief delay
      _moveToNextProfile();
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

      // Move to next profile after a brief delay
      _moveToNextProfile();
    } catch (e) {
      // Revert on error
      setState(() {
        _processedUserIds.remove(user.id ?? '');
      });
      _showError('Failed to pass. Please try again.');
    }
  }

  void _moveToNextProfile() {
    // Small delay to show confirmation, then move to next
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          // Move to next available profile
          // The available users list is recalculated each time, so we just increment index
          final availableCount = _availableUsers.length;
          if (availableCount > 0 && _currentProfileIndex < availableCount - 1) {
            _currentProfileIndex++;
          } else {
            // All profiles processed, reset or show empty state
            _currentProfileIndex = 0;
          }
        });
      }
    });
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

/// Bottom-sheet filter for the Connect screen.
/// Reads the user's current `lookingFor` and persists changes to Firestore
/// before triggering a data reload via [onApply].
class _ConnectFilterSheet extends StatefulWidget {
  const _ConnectFilterSheet({
    required this.currentUser,
    required this.onApply,
  });

  final UserModel currentUser;
  final VoidCallback onApply;

  @override
  State<_ConnectFilterSheet> createState() => _ConnectFilterSheetState();
}

class _ConnectFilterSheetState extends State<_ConnectFilterSheet> {
  static const _modes = <String, _ModeOption>{
    'Dating': _ModeOption('Dating & Romance', Icons.favorite_outline),
    'Friendship': _ModeOption('Friendship & Social', Icons.people_outline),
    'Networking': _ModeOption('Professional Networking', Icons.work_outline),
    'Mixed': _ModeOption('All of the Above', Icons.explore_outlined),
  };

  late String _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentUser.lookingFor ?? 'Dating';
    if (!_modes.containsKey(_selected)) _selected = 'Dating';
  }

  Future<void> _applyFilters() async {
    final changed = _selected != (widget.currentUser.lookingFor ?? 'Dating');

    if (changed) {
      setState(() => _saving = true);

      widget.currentUser.lookingFor = _selected;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.id)
          .set({'lookingFor': _selected}, SetOptions(merge: true));

      if (!mounted) return;
      setState(() => _saving = false);
    }

    if (!mounted) return;
    Navigator.pop(context);
    widget.onApply();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
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
            const SizedBox(height: 8),
            Text(
              'Show me people looking for:',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ..._modes.entries.map(
              (e) => _buildModeOption(e.key, e.value),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primaryGreen.withAlpha(120),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
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

  Widget _buildModeOption(String key, _ModeOption option) {
    final isSelected = _selected == key;
    return GestureDetector(
      onTap: () => setState(() => _selected = key),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen.withAlpha(25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              option.icon,
              color: isSelected ? AppColors.primaryGreen : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.label,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AppColors.primaryGreen
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primaryGreen,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _ModeOption {
  const _ModeOption(this.label, this.icon);
  final String label;
  final IconData icon;
}
