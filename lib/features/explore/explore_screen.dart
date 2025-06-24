import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swipe_cards/swipe_cards.dart';
import 'package:provider/provider.dart';
import 'package:naijasingles/common/providers/user_provider.dart';
import 'package:naijasingles/common/routes/route_name.dart';
import 'package:naijasingles/features/explore/services/match_service.dart';
import 'package:naijasingles/features/explore/services/mock_match_service.dart';
import 'package:naijasingles/features/explore/widgets/match_confirmation_modal.dart';

// Afropeep MVP Color Scheme
const Color kBackgroundColor = Color(0xFFFFF6E5); // Light cream
const Color kPrimaryColor = Color(0xFF008037); // Deep green
const Color kTextPrimary = Color(0xFF5D4037); // Brown
const Color kTextSecondary = Color(0xFF444444); // Dark gray
const Color kBorderColor = Color(0xFFDADADA); // Light gray border
const Color kRedColor = Color(0xFFFF5A5F); // Red for dislike

// User Model
class DiscoverUser {
  final String id;
  final String name;
  final int age;
  final String city;
  final String tribe;
  final String bio;
  final String imageUrl;
  final List<String> interests;

  const DiscoverUser({
    required this.id,
    required this.name,
    required this.age,
    required this.city,
    required this.tribe,
    required this.bio,
    required this.imageUrl,
    required this.interests,
  });
  
  // Getter to combine tribe and interests as tags for display
  List<String> get tags {
    return [tribe, ...interests];
  }
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // Intent options
  final List<String> _intentOptions = ['Dating', 'Friendship', 'Networking'];
  String _selectedIntent = 'Dating';
  
  // Swipe card controller
  late MatchEngine _matchEngine;
  List<SwipeItem> _swipeItems = [];
  
  // Match service for handling likes and matches
  // Use MockMatchService for testing, MatchService for production
  final MatchService _matchService = MockMatchService(); // For testing
  
  // List of users to display
  final List<DiscoverUser> _users = const [
    DiscoverUser(
      id: '1',
      name: 'Amara',
      age: 28,
      city: 'Lagos',
      tribe: 'Yoruba',
      bio: 'Passionate about art and cultural heritage. Love to travel and explore new cuisines.',
      imageUrl: 'https://images.pexels.com/photos/733872/pexels-photo-733872.jpeg',
      interests: ['Art', 'Travel', 'Cooking'],
    ),
    DiscoverUser(
      id: '2',
      name: 'Kofi',
      age: 32,
      city: 'Accra',
      tribe: 'Ashanti',
      bio: 'Tech entrepreneur with a passion for African innovation. Basketball player and coffee enthusiast.',
      imageUrl: 'https://images.pexels.com/photos/2379004/pexels-photo-2379004.jpeg',
      interests: ['Tech', 'Basketball', 'Coffee'],
    ),
    DiscoverUser(
      id: '3',
      name: 'Zainab',
      age: 26,
      city: 'Abuja',
      tribe: 'Hausa',
      bio: 'Medical doctor by day, poet by night. Looking to connect with like-minded individuals.',
      imageUrl: 'https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg',
      interests: ['Medicine', 'Poetry', 'Hiking'],
    ),
    DiscoverUser(
      id: '4',
      name: 'Kwame',
      age: 30,
      city: 'Kumasi',
      tribe: 'Akan',
      bio: 'Music producer and cultural advocate. Passionate about preserving traditional sounds.',
      imageUrl: 'https://images.pexels.com/photos/1681010/pexels-photo-1681010.jpeg',
      interests: ['Music', 'Culture', 'Photography'],
    ),
    DiscoverUser(
      id: '5',
      name: 'Nneka',
      age: 27,
      city: 'Port Harcourt',
      tribe: 'Igbo',
      bio: 'Environmental scientist working on sustainable solutions for African cities.',
      imageUrl: 'https://images.pexels.com/photos/1382731/pexels-photo-1382731.jpeg',
      interests: ['Environment', 'Sustainability', 'Reading'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSwipeItems();
    log("ExploreScreen initialized");
  }

  void _loadSwipeItems() {
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

  void handleLike(DiscoverUser user) {
    log('Liked: ${user.name}');
    
    // Force show match confirmation for every like during testing
    _showMatchConfirmation(
      'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg',
      user.imageUrl,
      user.name,
      user.id,
    );
  }

  void handlePass(DiscoverUser user) {
    log('Passed: ${user.name}');
  }

  void handleSave(DiscoverUser user) {
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
      barrierColor: Colors.black.withOpacity(0.6),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Simpler header layout with Row inside Padding
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: kTextPrimary),
                    onPressed: () => Navigator.of(context).pushReplacementNamed('/main_navigation'),
                  ),
                  Text(
                    'Explore',
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: kTextPrimary,
                    ),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedIntent,
                      dropdownColor: kBackgroundColor,
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: kPrimaryColor),
                      style: GoogleFonts.montserrat(
                        color: kTextPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedIntent = value);
                        }
                      },
                      items: _intentOptions
                          .map((intent) => DropdownMenuItem(
                                value: intent,
                                child: Text(intent),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            
            // Swipe cards area
            Expanded(
              child: _swipeItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 60,
                            color: kPrimaryColor.withOpacity(0.5),
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
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: SwipeCards(
                        matchEngine: _matchEngine,
                        itemBuilder: (BuildContext context, int index) {
                          final user = _swipeItems[index].content as DiscoverUser;
                          return ProfileCard(user: user);
                        },
                        onStackFinished: () {
                          log('Stack is finished');
                          // Handle when all cards are swiped
                          setState(() {
                            // Reload cards for demo purposes
                            _loadSwipeItems();
                          });
                        },
                        itemChanged: (SwipeItem item, int index) {
                          log('Item changed: ${index}');
                        },
                        upSwipeAllowed: true, // Allow down swipe for "save for later"
                        fillSpace: true,
                      ),
                    ),
            ),
            
            // Action buttons - only two buttons: dislike and like
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // Center the buttons
                children: [
                  // Dislike button (❌)
                  _buildActionButton(
                    icon: Icons.close_rounded,
                    color: kRedColor,
                    tooltip: 'Dislike',
                    onPressed: () {
                      if (_matchEngine.currentItem != null) {
                        _matchEngine.currentItem?.nope();
                      }
                    },
                    size: 56, // Fixed size
                  ),
                  
                  const SizedBox(width: 60), // Fixed space between buttons
                  
                  // Like button (✅)
                  _buildActionButton(
                    icon: Icons.favorite_rounded,
                    color: kPrimaryColor,
                    tooltip: 'Like',
                    onPressed: () {
                      if (_matchEngine.currentItem != null) {
                        _matchEngine.currentItem?.like();
                      }
                    },
                    size: 56, // Fixed size
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to build consistent action buttons with ripple effect
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
    required double size,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        elevation: 4,
        shadowColor: color.withOpacity(0.3),
        shape: const CircleBorder(),
        color: color,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          splashColor: Colors.white.withOpacity(0.3),
          highlightColor: Colors.white.withOpacity(0.1),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              icon,
              color: Colors.white,
              size: size * 0.55, // Slightly larger icon size
            ),
          ),
        ),
      ),
    );
  }
}

// Profile Card Widget with fade-in animation
class ProfileCard extends StatefulWidget {
  final DiscoverUser user;
  
  const ProfileCard({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> with SingleTickerProviderStateMixin {
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
    final cardPadding = 16.0; // Fixed 16px padding
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 12.0,
        ),
        child: Material(
          elevation: 0, // No default elevation
          borderRadius: BorderRadius.circular(20),
          color: kBackgroundColor, // Match background color
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
                // Profile image with proper sizing and error handling
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: AspectRatio(
                    aspectRatio: 4/3, // Fixed aspect ratio for consistent sizing
                    child: Image.network(
                      widget.user.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // User info
                Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and age
                      Text(
                        "${widget.user.name}, ${widget.user.age}",
                        style: GoogleFonts.montserrat(
                          fontSize: 20, // Fixed size for consistency
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      
                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: kTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.user.city, 
                            style: GoogleFonts.montserrat(
                              fontSize: 14, 
                              color: kTextSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Tribe (emphasized) and interests (limited to 3)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // Primary tribe (emphasized badge)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: kPrimaryColor, width: 1.5),
                            ),
                            child: Text(
                              widget.user.tribe,
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: kPrimaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          
                          // Up to 3 interests
                          ...widget.user.interests.take(3).map((interest) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              interest,
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: kTextSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Bio (max 2 lines)
                      Text(
                        widget.user.bio,
                        style: GoogleFonts.montserrat(
                          fontSize: 14, 
                          color: kTextSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
