import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swipe_cards/swipe_cards.dart';
import 'package:provider/provider.dart';
import 'package:naijasingles/common/providers/user_provider.dart';
import 'package:naijasingles/common/routes/route_name.dart';
import 'package:naijasingles/features/explore/services/match_service.dart';
import 'package:naijasingles/features/explore/services/mock_match_service.dart';
import 'package:naijasingles/features/explore/widgets/match_confirmation_modal.dart';

// Background color constant
const Color kBackgroundColor = Color(0xFFFDF6EC);
const Color kGreenColor = Color(0xFF008037);
const Color kAccentColor = Color(0xFFFFD700); // Vibrant yellow accent

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
      'test_thread_id',
    );
    
    // The code below would be used in production
    // but is commented out for testing purposes
    
    /*
    // Get current user from provider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    
    if (currentUser != null) {
      final currentUserId = currentUser.id!;
      final likedUserId = user.id;
      
      try {
        // Save the like to Firestore
        await _matchService.saveLike(currentUserId, likedUserId);
        
        // Check if there's a match (mutual like)
        final isMatch = await _matchService.checkForMatch(currentUserId, likedUserId);
        
        if (isMatch) {
          // It's a match! Create message thread
          final threadId = await _matchService.createMessageThread(currentUserId, likedUserId);
          
          // Mark users as matched
          await _matchService.markAsMatched(currentUserId, likedUserId);
          
          // Show match confirmation modal
          if (mounted) {
            _showMatchConfirmation(
              currentUser.imageUrl != null && currentUser.imageUrl!.isNotEmpty 
                  ? currentUser.imageUrl![0] 
                  : '',
              user.imageUrl,
              user.name,
              threadId,
            );
          }
        } else {
          // Just a like, show regular snackbar
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('You liked ${user.name}!'),
                backgroundColor: kGreenColor,
                duration: const Duration(seconds: 1),
              ),
            );
          }
        }
      } catch (e) {
        log('Error handling like: $e');
        // Show error snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Something went wrong. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
    */
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
    String threadId,
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
          threadId: threadId,
        );
      },
    );
    
    // Also show a snackbar notification when the modal is dismissed
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("You and $matchedUserName matched!"),
            backgroundColor: kGreenColor,
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
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF6EC),
        elevation: 0,
        title: Row(
          children: [
            Text(
              'Explore',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.brown[800],
              ),
            ),
            const Spacer(),
            // Intent dropdown (Dating/Friendship/Networking)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedIntent,
                  isDense: false,
                  borderRadius: BorderRadius.circular(16),
                  icon: Icon(Icons.expand_more, color: kGreenColor),
                  dropdownColor: Colors.white,
                  menuMaxHeight: 300,
                  elevation: 8,
                  style: GoogleFonts.poppins(
                    color: Colors.brown[800],
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedIntent = value);
                      log('Selected intent: $value');
                    }
                  },
                  items: _intentOptions.map((intent) => DropdownMenuItem<String>(
                    value: intent,
                    child: Container(
                      width: 120, // Set a fixed width to ensure text fits
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: _selectedIntent == intent ? const Color(0xFFFEEFD8) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        intent, 
                        style: GoogleFonts.poppins(
                          color: Colors.brown[800],
                          fontWeight: _selectedIntent == intent ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Swipe cards area
          Expanded(
            child: _swipeItems.isEmpty
                ? Center(
                    child: Text(
                      'No more profiles to show',
                      style: GoogleFonts.poppins(),
                    ),
                  )
                : SwipeCards(
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
                    upSwipeAllowed: false,
                    fillSpace: true,
                  ),
          ),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 40.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.redAccent.shade200,
                  child: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white, size: 28),
                    onPressed: () {
                      if (_matchEngine.currentItem != null) {
                        _matchEngine.currentItem?.nope();
                      }
                    },
                  ),
                ),
                CircleAvatar(
                  radius: 28,
                  backgroundColor: kAccentColor,
                  child: IconButton(
                    icon: const Icon(Icons.bookmark, color: Colors.white, size: 28),
                    onPressed: () {
                      if (_matchEngine.currentItem != null) {
                        _matchEngine.currentItem?.superLike();
                      }
                    },
                  ),
                ),
                CircleAvatar(
                  radius: 28,
                  backgroundColor: kGreenColor,
                  child: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.white, size: 28),
                    onPressed: () {
                      if (_matchEngine.currentItem != null) {
                        _matchEngine.currentItem?.like();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Profile Card Widget
class ProfileCard extends StatelessWidget {
  final DiscoverUser user;
  
  const ProfileCard({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile image - Fixed with proper sizing and error handling
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                user.imageUrl,
                height: 360,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 100),
              ),
            ),
            
            // User info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${user.name}, ${user.age}",
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        user.city, 
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Fixed chips with better contrast and readability
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.tags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F3F3), // Light grey chip background
                        borderRadius: BorderRadius.circular(20),
                        border: tag == user.tribe 
                            ? Border.all(color: kAccentColor, width: 1.5)
                            : null,
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.bio,
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
