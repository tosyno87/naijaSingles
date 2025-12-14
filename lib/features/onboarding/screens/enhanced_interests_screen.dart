import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../user/controllers/onboarding_controller.dart';
import '../../../common/constants/app_colors.dart';

class EnhancedInterestsScreen extends StatefulWidget {
  const EnhancedInterestsScreen({super.key});

  @override
  State<EnhancedInterestsScreen> createState() =>
      _EnhancedInterestsScreenState();
}

class _EnhancedInterestsScreenState extends State<EnhancedInterestsScreen> {
  List<String> _selectedInterests = [];
  static const int _maxInterests = 5; // Tinder standard: 3-5 passions

  // Theme colors - Tinder style
  static const Color afropeepGreen = Color(0xFF008037); // MVP green

  // Simplified interests list - organized by category but presented as flat list
  final List<String> _allInterests = [
    // Lifestyle
    'Fitness', 'Yoga', 'Fashion', 'Photography', 'Reading', 'Writing',
    'Personal Development',

    // Entertainment
    'Movies', 'Music', 'Concerts', 'Comedy Shows', 'Netflix', 'Podcasts',
    'Gaming', 'Karaoke',

    // Sports
    'Football', 'Basketball', 'Tennis', 'Swimming', 'Running', 'Cycling',
    'Volleyball',

    // Food & Dining
    'Cooking', 'Fine Dining', 'Street Food', 'Baking', 'Wine Tasting', 'Coffee',
    'Brunch',

    // Nigerian Culture
    'Afrobeats', 'Highlife Music', 'Nollywood', 'Jollof Rice', 'Suya',
    'Owanbe Parties',
    'Traditional Weddings', 'Ankara Fashion', 'Nigerian Comedy',
    'Pidgin English',

    // Creative Arts
    'Painting', 'Drawing', 'Singing', 'Dancing', 'Music Production',
    'Fashion Design',

    // Social & Community
    'Church Activities', 'Family Time', 'Volunteering', 'Community Service',
    'Religious Studies',

    // Travel & Adventure
    'Travel', 'Hiking', 'Beach Activities', 'Road Trips', 'City Exploration',
    'Food Tourism',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize with existing data if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller =
          Provider.of<OnboardingController>(context, listen: false);

      if (controller.interests.isNotEmpty) {
        setState(() {
          _selectedInterests = List.from(controller.interests);
        });
      }
    });
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
        Provider.of<OnboardingController>(context, listen: false)
            .removeInterest(interest);
      } else {
        // Enforce maximum of 5 (Tinder standard)
        if (_selectedInterests.length < _maxInterests) {
          _selectedInterests.add(interest);
          Provider.of<OnboardingController>(context, listen: false)
              .addInterest(interest);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You can select up to $_maxInterests interests',
                style: GoogleFonts.montserrat(),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Minimal like Tinder
          Text(
            'Your interests',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 24),

          // Tag-based interests selection - Tinder style (compact, clean)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allInterests.map((interest) {
              final isSelected = _selectedInterests.contains(interest);
              
              // Tinder style: Unselected = white/light gray, Selected = solid color
              return GestureDetector(
                onTap: () => _toggleInterest(interest),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? afropeepGreen 
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected 
                          ? afropeepGreen 
                          : Colors.grey.shade300,
                      width: isSelected ? 0 : 1,
                    ),
                  ),
                  child: Text(
                    interest,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected 
                          ? Colors.white 
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
}
