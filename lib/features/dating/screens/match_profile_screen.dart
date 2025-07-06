import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// For MVP, we'll use a simple model class for matched users
class MatchedUser {
  final String id;
  final String name;
  final int age;
  final String location;
  final String profileImage;
  final String tribe;
  final String profession;
  final List<String> personality;
  final String bio;
  final List<String> interests;

  MatchedUser({
    required this.id,
    required this.name,
    required this.age,
    required this.location,
    required this.profileImage,
    required this.tribe,
    required this.profession,
    required this.personality,
    required this.bio,
    required this.interests,
  });
}

class MatchProfileScreen extends StatefulWidget {
  final MatchedUser user;

  const MatchProfileScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<MatchProfileScreen> createState() => _MatchProfileScreenState();
}

class _MatchProfileScreenState extends State<MatchProfileScreen>
    with SingleTickerProviderStateMixin {
  // Animation controller for like labelLarge
  late AnimationController _animationController;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Background color for the dating screens
    const Color backgroundColor = Color(0xFFFDF6EC);

    // Deep green color for accents
    const Color deepGreen = Color(0xFF008037);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: deepGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Match Profile',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.brown.shade800,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Profile Card
            _buildProfileHeader(),

            // About Section
            _buildAboutSection(),

            // Interests Section
            _buildInterestsSection(),

            // Action Buttons
            _buildActionButtons(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Top profile card with image, name, age, location, and tags
  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile image
          Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Hero(
              tag: 'profile-${widget.user.id}',
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF008037),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(75),
                  child: Image.asset(
                    widget.user.profileImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Name and age
          Text(
            '${widget.user.name}, ${widget.user.age}',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.brown.shade800,
            ),
          ),

          const SizedBox(height: 4),

          // Location
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                widget.user.location,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Tags
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTag(widget.user.tribe, true),
                _buildTag(widget.user.profession, false),
                ...widget.user.personality
                    .map((trait) => _buildTag(trait, false))
                    .toList(),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // About section with bio
  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About Me',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.brown.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              widget.user.bio,
              style: GoogleFonts.poppins(
                fontSize: 15,
                height: 1.5,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Interests section
  Widget _buildInterestsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interests',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.brown.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.user.interests.map((interest) {
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
                    side:
                        const BorderSide(color: Color(0xFF008037), width: 0.5),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Action labelLarges (Like, Pass, Message)
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Pass labelLarge
          _buildCircleButton(
            icon: Icons.close,
            color: Colors.red.shade400,
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
            },
            label: 'Pass',
          ),

          // Like labelLarge
          _buildCircleButton(
            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
            color: const Color(0xFF008037),
            onTap: () {
              HapticFeedback.mediumImpact();
              setState(() {
                _isLiked = !_isLiked;
              });
              _animationController.reset();
              _animationController.forward();

              // Show a snackbar when liked
              if (_isLiked) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'You liked ${widget.user.name}!',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: const Color(0xFF008037),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            label: 'Like',
            isAnimated: true,
          ),

          // Message labelLarge
          _buildCircleButton(
            icon: Icons.chat_bubble_outline,
            color: Colors.blue.shade400,
            onTap: () {
              HapticFeedback.mediumImpact();
              // Navigate to message thread (to be implemented)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Message feature coming soon!',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: Colors.blue.shade400,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            label: 'Message',
          ),
        ],
      ),
    );
  }

  // Circle labelLarge with icon and label
  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String label,
    bool isAnimated = false,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: isAnimated
                  ? AnimatedScale(
                      scale: _isLiked ? 1.2 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        icon,
                        color: color,
                        size: 30,
                      ),
                    )
                  : Icon(
                      icon,
                      color: color,
                      size: 30,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  // Tag widget for profile attributes
  Widget _buildTag(String label, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary
            ? const Color(0xFF008037).withValues(alpha: 0.1)
            : Colors.grey[200],
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
