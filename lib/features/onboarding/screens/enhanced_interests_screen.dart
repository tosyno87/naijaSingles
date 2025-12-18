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

  // Theme colors - Tinder style
  static const Color afropeepGreen = Color(0xFF008037); // MVP green

  // Track expanded state for each category (Tinder-style show more/less)
  final Map<String, bool> _categoryExpanded = {
    'creativity': false,
    'entertainment': false,
    'sports': false,
    'food': false,
    'culture': false,
    'lifestyle': false,
    'travel': false,
  };

  // Categorized interests (Tinder-style organization)
  final Map<String, Map<String, dynamic>> _categories = {
    'creativity': {
      'title': 'Creativity',
      'emoji': '🎨',
      'interests': [
        'Photography',
        'Drawing',
        'Painting',
        'Singing',
        'Dancing',
        'Music Production',
        'Fashion Design',
        'Writing',
        'Content Creation',
        'Cosplay',
      ],
      'initialCount': 7, // Show first 7 by default
    },
    'entertainment': {
      'title': 'Fan favorites',
      'emoji': '⭐',
      'interests': [
        'Movies',
        'Music',
        'Concerts',
        'Comedy Shows',
        'Netflix',
        'Podcasts',
        'Gaming',
        'Karaoke',
        'NBA',
        'Marvel',
        'Manga',
      ],
      'initialCount': 8,
    },
    'sports': {
      'title': 'Sports & Fitness',
      'emoji': '⚽',
      'interests': [
        'Football',
        'Basketball',
        'Tennis',
        'Swimming',
        'Running',
        'Cycling',
        'Volleyball',
        'Fitness',
        'Yoga',
      ],
      'initialCount': 7,
    },
    'food': {
      'title': 'Food and drink',
      'emoji': '🍽️',
      'interests': [
        'Foodie',
        'Cooking',
        'Fine Dining',
        'Street Food',
        'Baking',
        'Wine Tasting',
        'Coffee',
        'Brunch',
        'Sweet treats',
        'Mocktails',
        'Plant-based',
      ],
      'initialCount': 8,
    },
    'culture': {
      'title': 'African Culture',
      'emoji': '🌍',
      'interests': [
        'Afrobeats',
        'Highlife Music',
        'Nollywood',
        'Jollof Rice',
        'Suya',
        'Owanbe Parties',
        'Traditional Weddings',
        'Ankara Fashion',
        'Nigerian Comedy',
        'Pidgin English',
      ],
      'initialCount': 7,
    },
    'lifestyle': {
      'title': 'Lifestyle',
      'emoji': '✨',
      'interests': [
        'Fashion',
        'Reading',
        'Personal Development',
        'Church Activities',
        'Family Time',
        'Volunteering',
        'Community Service',
      ],
      'initialCount': 5,
    },
    'travel': {
      'title': 'Travel & Adventure',
      'emoji': '✈️',
      'interests': [
        'Travel',
        'Hiking',
        'Beach Activities',
        'Road Trips',
        'City Exploration',
        'Food Tourism',
      ],
      'initialCount': 6,
    },
  };

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
        // No limit - users can select as many interests as they want
        _selectedInterests.add(interest);
        Provider.of<OnboardingController>(context, listen: false)
            .addInterest(interest);
      }
    });
  }

  void _toggleCategoryExpansion(String categoryKey) {
    setState(() {
      _categoryExpanded[categoryKey] = !_categoryExpanded[categoryKey]!;
    });
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Tinder style
          Text(
            'What are you into?',
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You like what you like. Now, let everyone know.',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 32),

          // Categorized interests - Tinder style
          ..._categories.entries.map((entry) {
            final categoryKey = entry.key;
            final category = entry.value;
            final title = category['title'] as String;
            final emoji = category['emoji'] as String;
            final interests = category['interests'] as List<String>;
            final initialCount = category['initialCount'] as int;
            final isExpanded = _categoryExpanded[categoryKey] ?? false;
            final displayedInterests = isExpanded
                ? interests
                : interests.take(initialCount).toList();
            final hasMore = interests.length > initialCount;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category header with emoji
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Text(
                        emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Interest tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: displayedInterests.map((interest) {
                    final isSelected = _selectedInterests.contains(interest);
                    
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

                // Show more/less button
                if (hasMore)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    child: TextButton(
                      onPressed: () => _toggleCategoryExpansion(categoryKey),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isExpanded ? 'Show less' : 'Show more',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: afropeepGreen,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isExpanded 
                                ? Icons.keyboard_arrow_up 
                                : Icons.keyboard_arrow_down,
                            color: afropeepGreen,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 24),
              ],
            );
          }),
        ],
      ),
    );
}
