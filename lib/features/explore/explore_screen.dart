import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swipe_cards/swipe_cards.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:naijasingles/common/providers/user_provider.dart';
import 'package:naijasingles/features/explore/widgets/match_confirmation_modal.dart';
import 'package:naijasingles/features/explore/widgets/mode_action_buttons.dart';
import 'package:naijasingles/features/dating/screens/user_detail_screen.dart';
import 'package:naijasingles/models/user_model.dart';
import 'package:naijasingles/common/data/repo/user_search_repo.dart';
import 'package:naijasingles/services/super_like_service.dart';
import 'package:naijasingles/services/undo_service.dart';

// Afropeep MVP Color Scheme
const Color kBackgroundColor = Color(0xFFFFF6E5); // Light cream
const Color kPrimaryColor = Color(0xFF008037); // Deep green
const Color kTextPrimary = Color(0xFF5D4037); // Brown
const Color kTextSecondary = Color(0xFF444444); // Dark gray
const Color kBorderColor = Color(0xFFDADADA); // Light gray border
const Color kRedColor = Color(0xFFFF5A5F); // Red for dislike

class ExploreScreen extends StatefulWidget {
  // Add a parameter to track if this screen was navigated from Messages
  final bool showBackButton;

  const ExploreScreen({
    Key? key,
    this.showBackButton = false, // Default to false (no back labelLarge)
  }) : super(key: key);

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with AutomaticKeepAliveClientMixin<ExploreScreen> {
  @override
  bool get wantKeepAlive => true; // Keep state alive to prevent rebuilds

  // Intent options
  final List<String> _intentOptions = ['Dating', 'Friendship', 'Networking'];
  String _selectedIntent = 'Dating';

  // Swipe card controller
  late MatchEngine _matchEngine;
  List<SwipeItem> _swipeItems = [];

  // List of users to display - now fetched from Firebase
  List<UserModel> _users = [];
  UserModel? _currentUser;
  bool _isLoading = true;
  String? _error;

  // Services
  final SuperLikeService _superLikeService = SuperLikeService();
  final UndoService _undoService = UndoService();

  // Undo state
  bool _canUndo = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    // Initialize undo state after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateUndoState();
    });
    log("ExploreScreen initialized");
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.currentUser != null) {
        _currentUser = userProvider.currentUser;
        // Ensure maxDistance is reasonable for testing
        if (_currentUser!.maxDistance == null ||
            _currentUser!.maxDistance! < 100) {
          _currentUser!.maxDistance = 1000; // Set to 1000km for testing
        }
        await _loadUsers();
      } else {
        // Try to get current user from Firebase Auth
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Load user data from Firestore
          await _loadUserFromFirestore(user.uid);
        } else {
          setState(() {
            _error = 'No authenticated user found';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      log('Error loading current user: $e');
      setState(() {
        _error = 'Failed to load user data';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserFromFirestore(String userId) async {
    try {
      // This would need to be implemented based on your user loading logic
      // For now, we'll create a basic user model with increased max distance for testing
      _currentUser = UserModel(
        id: userId,
        name: 'Current User',
        age: 25,
        showGender: 'everyone',
        ageRange: {'min': '18', 'max': '50'},
        maxDistance:
            1000, // Increased for testing - allows users up to 1000km away
        latitude: 6.5244, // Lagos coordinates as default
        longitude: 3.3792,
      );
      await _loadUsers();
    } catch (e) {
      log('Error loading user from Firestore: $e');
      setState(() {
        _error = 'Failed to load user profile';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUsers() async {
    if (_currentUser == null) return;

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Debug: Check authentication status
      final currentUser = FirebaseAuth.instance.currentUser;
      log('Current Firebase user: ${currentUser?.uid}');
      log('Current user model: ${_currentUser?.id}');
      log('Selected intent filter: $_selectedIntent');

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Pass the selected intent as a filter
      final users = await UserSearchRepo.getUserList(
        _currentUser!,
        intentFilter: _selectedIntent,
      );

      setState(() {
        _users = users;
        _isLoading = false;
      });

      _loadSwipeItems();
      log("Loaded ${users.length} users from Firebase with intent filter: $_selectedIntent");
      
      // Initialize undo state
      _updateUndoState();
    } catch (e) {
      log('Error loading users: $e');
      setState(() {
        _error = 'Failed to load users: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _loadSwipeItems() {
    if (_users.isEmpty) return;

    _swipeItems = _users.map((user) {
      return SwipeItem(
        content: user,
        likeAction: () {
          handleLike(user);
        },
        nopeAction: () {
          handlePass(user);
        },
        superlikeAction: () {
          handleSave(user);
        },
      );
    }).toList();

    _matchEngine = MatchEngine(swipeItems: _swipeItems);
  }

  void handleLike(UserModel user) async {
    if (_currentUser == null) return;

    log('🔥 LIKE ACTION: ${_currentUser!.name} (${_currentUser!.id}) likes ${user.name} (${user.id})');

    try {
      // Use the real match service to handle the like
      final matchId = await UserSearchRepo.rightSwipe(_currentUser!, user);

      // ❌ DON'T record likes for undo - likes should be permanent commitments
      // This follows proper dating app logic (like Bumble/Tinder)
      // Only passes (left swipes) can be undone

      log('🔍 Match result: ${matchId ?? "No match"}');

      if (matchId != null) {
        log('🎉 MATCH DETECTED! Match ID: $matchId');
        // Show match confirmation modal
        _showMatchConfirmation(
          _currentUser!.imageUrl?.isNotEmpty == true
              ? _currentUser!.imageUrl![0]
              : 'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg',
          user.imageUrl?.isNotEmpty == true ? user.imageUrl![0] : '',
          user.name ?? 'Unknown',
          user.id,
        );
      } else {
        log('💔 No match yet. ${user.name} needs to like you back.');
        // Show a subtle notification that the like was saved
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You liked ${user.name}! 💕'),
            backgroundColor: kPrimaryColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      log('❌ Error handling like: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Like saved! 💕'),
          backgroundColor: kPrimaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void handlePass(UserModel user) async {
    if (_currentUser == null) return;

    log('Passed: ${user.name}');

    try {
      await UserSearchRepo.leftSwipe(_currentUser!, user);

      // Record swipe action for undo functionality
      await _undoService.recordSwipeAction(
        userId: _currentUser!.id!,
        targetUserId: user.id!,
        direction: SwipeDirection.left,
      );

      // Update undo state
      _updateUndoState();
    } catch (e) {
      log('Error handling pass: $e');
    }
  }

  void handleSave(UserModel user) {
    log('Saved: ${user.name}');
    // Bookmark to saved list
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${user.name} saved to bookmarks'),
        backgroundColor: Colors.amber,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void handleSuperLike(UserModel user) async {
    if (_currentUser == null) return;

    log('⭐ SUPER LIKE ACTION: ${_currentUser!.name} super likes ${user.name}');

    try {
      // Check if user can send super like
      final eligibility = await _superLikeService.canSendSuperLike(_currentUser!.id!);
      
      if (!eligibility.canSend) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(eligibility.reason ?? 'Cannot send super like'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Send super like
      final result = await _superLikeService.sendSuperLike(
        fromUserId: _currentUser!.id!,
        toUserId: user.id!,
      );

      if (result.isSuccess) {
        // ❌ DON'T record Super Likes for undo - premium actions should be permanent
        // Super Likes are paid/limited features and should be final commitments

        if (result.isInstantMatch) {
          log('🎉 SUPER LIKE INSTANT MATCH! Match ID: ${result.matchId}');
          _showMatchConfirmation(
            _currentUser!.imageUrl?.isNotEmpty == true
                ? _currentUser!.imageUrl![0]
                : 'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg',
            user.imageUrl?.isNotEmpty == true ? user.imageUrl![0] : '',
            user.name ?? 'Unknown',
            user.id,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⭐ Super liked ${user.name}!'),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Failed to send super like'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      log('❌ Error handling super like: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Super like saved! ⭐'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void handleUndo() async {
    if (_currentUser == null) return;

    log('↩️ UNDO ACTION');

    try {
      final result = await _undoService.undoLastSwipe(_currentUser!.id!);

      if (result.isSuccess) {
        // Reload users to show the undone user again
        await _loadUsers();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('↩️ Pass undone! You\'ll see them again.'),
            backgroundColor: Colors.purple,
            duration: const Duration(seconds: 2),
          ),
        );

        // Update undo state
        _updateUndoState();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Cannot undo'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      log('❌ Error handling undo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot undo at this time'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _updateUndoState() async {
    if (_currentUser?.id != null) {
      final canUndo = await _undoService.canUndoLastSwipe(_currentUser!.id!);
      log('🔄 Undo state updated: canUndo = $canUndo');
      if (mounted) {
        setState(() {
          _canUndo = canUndo;
        });
      }
    } else {
      log('⚠️ Cannot update undo state: no current user');
    }
  }

  void _showIntentSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white, // Use white background instead of cream
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'What are you looking for?',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            color: kTextPrimary, // Dark brown text
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _intentOptions.map((intent) => 
            RadioListTile<String>(
              title: Text(
                intent,
                style: GoogleFonts.montserrat(
                  color: kTextPrimary, // Dark brown text
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                _getIntentDescription(intent),
                style: GoogleFonts.montserrat(
                  color: kTextSecondary,
                  fontSize: 12,
                ),
              ),
              value: intent,
              groupValue: _selectedIntent,
              activeColor: kPrimaryColor, // Green radio button
              onChanged: (value) {
                if (value != null && value != _selectedIntent) {
                  setState(() => _selectedIntent = value);
                  Navigator.pop(context);
                  
                  // Show loading indicator and reload users with new filter
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Filtering for $value...'),
                      backgroundColor: kPrimaryColor,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  
                  // Reload users with the new intent filter
                  _loadUsers();
                } else if (value != null) {
                  // Same intent selected, just close dialog
                  Navigator.pop(context);
                }
              },
            ),
          ).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(
                color: kTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show match confirmation modal
  void _showMatchConfirmation(
    String currentUserImageUrl,
    String matchedUserImageUrl,
    String matchedUserName,
    String? matchedUserId,
  ) {
    // Debug log to confirm this method is being called
    log('Showing match confirmation for: $matchedUserName');

    // Show the redesigned match confirmation modal
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (BuildContext context) {
        return MatchConfirmationModal(
          currentUserImageUrl: currentUserImageUrl,
          matchedUserImageUrl: matchedUserImageUrl,
          matchedUserName: matchedUserName,
          matchedUserId: matchedUserId ?? '',
        );
      },
    );

    // Also show a snackbar notification when the modal is dismissed
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("You and $matchedUserName matched!"),
            backgroundColor: kPrimaryColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _undoService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Clean header with undo and filter
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Undo button (always show if user is loaded)
                      _currentUser != null
                          ? IconButton(
                              icon: Icon(
                                Icons.undo, 
                                color: _canUndo ? Colors.purple : Colors.grey, 
                                size: 24
                              ),
                              onPressed: _canUndo ? handleUndo : null,
                              tooltip: _canUndo ? 'Undo last pass' : 'No pass to undo',
                            )
                          : const SizedBox(width: 48),

                      // Title
                      Text(
                        'Explore',
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: kTextPrimary,
                        ),
                      ),

                      // Filter button with indicator
                      Stack(
                        children: [
                          IconButton(
                            icon: Icon(Icons.tune, color: kTextPrimary),
                            onPressed: () {
                              _showIntentSelector();
                            },
                            tooltip: 'Filter preferences',
                          ),
                          // Active filter indicator
                          if (_selectedIntent != 'Dating')
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: kPrimaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  
                  // Current filter indicator
                  if (_selectedIntent != 'Dating')
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kPrimaryColor, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _selectedIntent == 'Friendship' 
                                  ? Icons.people 
                                  : _selectedIntent == 'Networking'
                                      ? Icons.business_center
                                      : Icons.favorite,
                              size: 16,
                              color: kPrimaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Looking for $_selectedIntent',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: kPrimaryColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                setState(() => _selectedIntent = 'Dating');
                                _loadUsers();
                              },
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: kPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content area with simple overlay
            Expanded(
              child: Stack(
                children: [
                  // Main swipe content
                  _buildContent(),
                  
                  // Mode-specific action buttons - only show if not loading and have users
                  if (!_isLoading && _users.isNotEmpty && _error == null)
                    Positioned(
                      bottom: 30,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ModeActionButtons(
                          selectedMode: _selectedIntent,
                          currentUser: _currentUser,
                          onSuperLike: () {
                            if (_matchEngine.currentItem != null) {
                              final user = _matchEngine.currentItem?.content as UserModel;
                              handleSuperLike(user);
                              _matchEngine.currentItem?.superLike();
                            }
                          },
                          onPass: () {
                            if (_matchEngine.currentItem != null) {
                              _matchEngine.currentItem?.nope();
                            }
                          },
                          onLike: () {
                            if (_matchEngine.currentItem != null) {
                              final user = _matchEngine.currentItem?.content as UserModel;
                              handleLike(user);
                              _matchEngine.currentItem?.like();
                            }
                          },
                          onModeSpecificAction: () {
                            if (_matchEngine.currentItem != null) {
                              final user = _matchEngine.currentItem?.content as UserModel;
                              _showModeActionSheet(user);
                            }
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: kPrimaryColor),
            const SizedBox(height: 16),
            Text(
              'Loading users...',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: kTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: kRedColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: kTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCurrentUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 60,
              color: kPrimaryColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No more profiles to show',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your preferences',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: kTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0), // Remove bottom padding
      child: SwipeCards(
        matchEngine: _matchEngine,
        itemBuilder: (BuildContext context, int index) {
          final user = _swipeItems[index].content as UserModel;
          return ProfileCard(user: user, selectedMode: _selectedIntent);
        },
        onStackFinished: () {
          log('Stack is finished');
          // Reload users when stack is finished
          _loadUsers();
        },
        itemChanged: (SwipeItem item, int index) {
          log('Item changed: ${index}');
        },
        upSwipeAllowed: true,
        fillSpace: true,
      ),
    );
  }

  String _getIntentDescription(String intent) {
    switch (intent) {
      case 'Dating':
        return 'Looking for romantic connections and relationships';
      case 'Friendship':
        return 'Making new friends and expanding social circles';
      case 'Networking':
        return 'Career connections and business opportunities';
      default:
        return 'Connect with people';
    }
  }

  void _showModeActionSheet(UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ModeActionSheet(
        selectedMode: _selectedIntent,
        user: user,
      ),
    );
  }

}

// Profile Card Widget with fade-in animation
class ProfileCard extends StatefulWidget {
  final UserModel user;
  final String? selectedMode;

  const ProfileCard({
    Key? key,
    required this.user,
    this.selectedMode,
  }) : super(key: key);

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeIn,
      ),
    );

    // Start the animation
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardPadding = 16.0;
    final photos = widget.user.imageUrl ?? [];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 12.0,
        ),
        child: Material(
          elevation: 0,
          borderRadius: BorderRadius.circular(20),
          color: kBackgroundColor,
          child: GestureDetector(
            onTap: () {
              // Navigate to detailed profile view
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserDetailScreen(
                    user: widget.user,
                    selectedMode: widget.selectedMode,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile image with photo indicators
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20)),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: photos.isNotEmpty
                              ? Image.network(
                                  photos[0], // Show first photo
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: Colors.grey[300],
                                    child: Icon(
                                      Icons.person,
                                      size: 80,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[300],
                                  child: Icon(
                                    Icons.person,
                                    size: 80,
                                    color: Colors.grey[500],
                                  ),
                                ),
                        ),
                      ),

                      // Photo count indicator
                      if (photos.length > 1)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.photo_library,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${photos.length}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Tap to view indicator
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: kPrimaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.visibility,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),

                      // Photo dots indicator (if multiple photos)
                      if (photos.length > 1)
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Row(
                            children: List.generate(
                              photos.length > 5
                                  ? 5
                                  : photos.length, // Show max 5 dots
                              (index) => Container(
                                margin: const EdgeInsets.only(right: 4),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: index == 0
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // User info
                  Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and age
                        Text(
                          "${widget.user.name ?? 'Unknown'}, ${widget.user.age ?? 'N/A'}",
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Location
                        if (widget.user.address != null)
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: kTextSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.user.address!,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    color: kTextSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),

                        // Distance
                        if (widget.user.distanceBW != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: kPrimaryColor, width: 1.5),
                            ),
                            child: Text(
                              '${widget.user.distanceBW} km away',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: kPrimaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Bio or interests
                        if (widget.user.editInfo != null &&
                            widget.user.editInfo!['userBio'] != null &&
                            widget.user.editInfo!['userBio']
                                .toString()
                                .isNotEmpty)
                          Text(
                            widget.user.editInfo!['userBio'].toString(),
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: kTextSecondary,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          Text(
                            'Looking to connect with new people',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: kTextSecondary,
                              height: 1.4,
                            ),
                          ),

                        const SizedBox(height: 12),

                        // Simple tap hint
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.touch_app,
                              size: 16,
                              color: kPrimaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Tap to view profile',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: kPrimaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ), // Close Container
          ), // Close GestureDetector
        ), // Close Material
      ), // Close Padding
    ); // Close FadeTransition
  }
}
