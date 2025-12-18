import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import 'modern_profile_card.dart';

class HorizontalProfileViewer extends StatefulWidget {

  const HorizontalProfileViewer({
    required this.users, required this.currentUser, required this.onConnect, required this.onPass, required this.onViewProfile, super.key,
    this.onAllProfilesViewed,
  });
  final List<UserModel> users;
  final UserModel currentUser;
  final Function(UserModel) onConnect;
  final Function(UserModel) onPass;
  final Function(UserModel) onViewProfile;
  final VoidCallback? onAllProfilesViewed;

  @override
  State<HorizontalProfileViewer> createState() =>
      _HorizontalProfileViewerState();
}

class _HorizontalProfileViewerState extends State<HorizontalProfileViewer> {
  late PageController _pageController;
  int _currentIndex = 0;
  List<UserModel> _remainingUsers = [];

  @override
  void initState() {
    super.initState();
    _remainingUsers = List.from(widget.users);
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(HorizontalProfileViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.users != widget.users) {
      _remainingUsers = List.from(widget.users);
      _currentIndex = 0;
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _removeCurrentProfile() {
    if (_remainingUsers.isEmpty) return;

    setState(() {
      _remainingUsers.removeAt(_currentIndex);

      // Adjust current index if needed
      if (_currentIndex >= _remainingUsers.length &&
          _remainingUsers.isNotEmpty) {
        _currentIndex = _remainingUsers.length - 1;
      }
    });

    // Check if all profiles are viewed
    if (_remainingUsers.isEmpty) {
      widget.onAllProfilesViewed?.call();
    } else {
      // Navigate to the next profile
      if (_currentIndex < _remainingUsers.length) {
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _handleConnect(UserModel user) {
    widget.onConnect(user);
    _removeCurrentProfile();
  }

  void _handlePass(UserModel user) {
    widget.onPass(user);
    _removeCurrentProfile();
  }

  @override
  Widget build(BuildContext context) {
    if (_remainingUsers.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Profile counter
        _buildProfileCounter(),

        // PageView for horizontal scrolling
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: _remainingUsers.length,
            itemBuilder: (context, index) {
              final user = _remainingUsers[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ModernProfileCard(
                  user: user,
                  onConnect: () => _handleConnect(user),
                  onTap: () => widget.onViewProfile(user),
                ),
              );
            },
          ),
        ),

        // Action buttons
        _buildActionButtons(),

        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildProfileCounter() => Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF008037).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF008037).withOpacity(0.3),
        ),
      ),
      child: Text(
        '${_currentIndex + 1} of ${_remainingUsers.length} profiles',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF008037),
        ),
      ),
    );

  Widget _buildActionButtons() {
    if (_remainingUsers.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Pass button
          _buildActionButton(
            icon: Icons.close,
            color: Colors.red,
            onTap: () {
              if (_remainingUsers.isNotEmpty) {
                _handlePass(_remainingUsers[_currentIndex]);
              }
            },
          ),

          // Connect button
          _buildActionButton(
            icon: Icons.favorite,
            color: const Color(0xFF008037),
            onTap: () {
              if (_remainingUsers.isNotEmpty) {
                _handleConnect(_remainingUsers[_currentIndex]);
              }
            },
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) => GestureDetector(
      onTap: onTap,
      child: Container(
        width: isPrimary ? 70 : 60,
        height: isPrimary ? 70 : 60,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: isPrimary ? 32 : 28,
        ),
      ),
    );

  Widget _buildEmptyState() => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: const Color(0xFF008037).withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          const Text(
            'No More Profiles',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Check back later for new connections!',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
}
