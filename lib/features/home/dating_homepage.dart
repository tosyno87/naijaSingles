import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../dating/screens/match_profile_screen.dart';
import '../messages/messages_screen.dart';
import '../notifications/notification_badge.dart';
import '../user/controllers/onboarding_controller.dart';
import '../explore/explore_screen.dart'; // Import the ExploreScreen

// Import the MatchedUser model from match_profile_screen.dart
import '../dating/screens/match_profile_screen.dart' show MatchedUser;

class DatingHomePage extends StatefulWidget {
  const DatingHomePage({Key? key}) : super(key: key);

  @override
  State<DatingHomePage> createState() => _DatingHomePageState();
}

class _DatingHomePageState extends State<DatingHomePage> {
  // Sample data for suggested matches
  final List<MatchedUser> _suggestedMatches = [
    MatchedUser(
      id: '1',
      name: 'Amina',
      age: 26,
      location: 'Lagos',
      profileImage: 'assets/images/placeholder_profile.jpg',
      tribe: 'Hausa',
      profession: 'Doctor',
      personality: ['Outgoing', 'Ambitious'],
      bio: 'I love traveling and experiencing new cultures. When I\'m not at the hospital, you can find me exploring local markets or trying new recipes.',
      interests: ['Cooking', 'Travel', 'Reading', 'Afrobeats'],
    ),
    MatchedUser(
      id: '2',
      name: 'Tunde',
      age: 28,
      location: 'Abuja',
      profileImage: 'assets/images/placeholder_profile.jpg',
      tribe: 'Yoruba',
      profession: 'Software Engineer',
      personality: ['Creative', 'Analytical'],
      bio: 'Tech enthusiast who loves building solutions that make a difference. I enjoy hiking on weekends and playing the guitar when I need to unwind.',
      interests: ['Hiking', 'Music', 'Technology', 'Photography'],
    ),
    MatchedUser(
      id: '3',
      name: 'Ngozi',
      age: 25,
      location: 'Port Harcourt',
      profileImage: 'assets/images/placeholder_profile.jpg',
      tribe: 'Igbo',
      profession: 'Entrepreneur',
      personality: ['Confident', 'Driven'],
      bio: 'Building my fashion brand while exploring life\'s adventures. I believe in hard work and creating meaningful connections with people.',
      interests: ['Fashion', 'Business', 'Dance', 'Cooking'],
    ),
    MatchedUser(
      id: '4',
      name: 'Kwame',
      age: 30,
      location: 'Accra',
      profileImage: 'assets/images/placeholder_profile.jpg',
      tribe: 'Ashanti',
      profession: 'Architect',
      personality: ['Thoughtful', 'Detail-oriented'],
      bio: 'I find beauty in structures and design. My passion is creating spaces that inspire people. I enjoy good conversations over coffee and weekend road trips.',
      interests: ['Architecture', 'Art', 'Coffee', 'Travel'],
    ),
    MatchedUser(
      id: '5',
      name: 'Zainab',
      age: 27,
      location: 'Kano',
      profileImage: 'assets/images/placeholder_profile.jpg',
      tribe: 'Fulani',
      profession: 'Teacher',
      personality: ['Patient', 'Kind'],
      bio: 'I believe education changes lives. When I\'m not teaching, I enjoy writing poetry and volunteering at local community centers.',
      interests: ['Poetry', 'Education', 'Community Service', 'Nature'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<OnboardingController>(context);
    
    // Background color for the dating homepage
    const Color backgroundColor = Color(0xFFFDF6EC);
    
    // Deep green color for accents
    const Color deepGreen = Color(0xFF008037);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Dating',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.brown.shade800,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: deepGreen),
            onPressed: () {
              // Filter functionality to be implemented
            },
          ),
          const NotificationBadge(),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              // Main Profile Card
              _buildMainProfileCard(controller),
              
              const SizedBox(height: 24),
              
              // Suggested Matches Section
              _buildSectionTitle('Suggested Matches'),
              const SizedBox(height: 12),
              _buildSuggestedMatches(),
              
              const SizedBox(height: 24),
              
              // Interests Section
              _buildSectionTitle('Your Interests'),
              const SizedBox(height: 12),
              _buildInterestsChips(controller),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
  
  // Main profile card showing user's photo, name, age, city, and tags
  Widget _buildMainProfileCard(OnboardingController controller) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.asset(
              'assets/images/placeholder_profile.jpg',
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 300,
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.person,
                    size: 100,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
          
          // Profile info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and age
                Row(
                  children: [
                    Text(
                      controller.userName ?? 'Your Name',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '28', // Age would come from user data
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                // Location
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Lagos, Nigeria', // Location would come from user data
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTag('Yoruba', controller.tribe == 'Yoruba'),
                    _buildTag('Nigerian', controller.nationality == 'Nigeria'),
                    _buildTag('Ambitious', controller.values.contains('ambition')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Horizontal scrolling list of suggested matches
  Widget _buildSuggestedMatches() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _suggestedMatches.length,
        itemBuilder: (context, index) {
          final match = _suggestedMatches[index];
          return GestureDetector(
            onTap: () {
              // Navigate to match profile screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MatchProfileScreen(user: match),
                ),
              );
            },
            child: Container(
              width: 150,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile image
                  Hero(
                    tag: 'profile-${match.id}',
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.asset(
                        match.profileImage,
                        width: 150,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 150,
                            height: 120,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  // Name and age
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${match.name}, ${match.age}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          match.location,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  // Chips showing user's interests
  Widget _buildInterestsChips(OnboardingController controller) {
    // Get music genres from controller
    final List<String> interests = controller.genres;
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: interests.map((interest) {
        return Chip(
          label: Text(
            interest,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF008037),
            ),
          ),
          backgroundColor: const Color(0xFFE8F5E9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF008037), width: 0.5),
          ),
        );
      }).toList(),
    );
  }
  
  // Section title widget
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.brown.shade800,
      ),
    );
  }
  
  // Tag widget for profile attributes
  Widget _buildTag(String label, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFF008037).withOpacity(0.1) : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPrimary ? const Color(0xFF008037) : Colors.grey[400]!,
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isPrimary ? const Color(0xFF008037) : Colors.grey[700],
        ),
      ),
    );
  }
}
