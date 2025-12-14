import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../user/controllers/onboarding_controller.dart';

class EnhancedInterestsScreen extends StatefulWidget {
  const EnhancedInterestsScreen({super.key});

  @override
  State<EnhancedInterestsScreen> createState() =>
      _EnhancedInterestsScreenState();
}

class _EnhancedInterestsScreenState extends State<EnhancedInterestsScreen> {
  List<String> _selectedInterests = [];

  // MVP theme colors
  static const Color afropeepGreen = Color(0xFF008037); // MVP green
  static const Color cardBackground = Color(0xFFF7E8DA);
  static const Color textDarkBrown = Color(0xFF3A1D0F);
  static const Color textLightBrown = Color(0xFF8B6C59);

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
        _selectedInterests.add(interest);
        Provider.of<OnboardingController>(context, listen: false)
            .addInterest(interest);
      }
    });
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'What are your interests?',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textDarkBrown,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Select at least 5 interests to help us find your perfect matches',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: textLightBrown,
            ),
          ),

          const SizedBox(height: 32),

          // Tag-based interests selection (industry standard - Tinder, Bumble, Hinge style)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _allInterests.map((interest) {
              final isSelected = _selectedInterests.contains(interest);
              
              return FilterChip(
                label: Text(
                  interest,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.white : textDarkBrown,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) => _toggleInterest(interest),
                selectedColor: afropeepGreen,
                checkmarkColor: Colors.white,
                backgroundColor: cardBackground,
                side: BorderSide(
                  color: isSelected 
                      ? afropeepGreen 
                      : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                visualDensity: VisualDensity.comfortable,
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Selected interests count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _selectedInterests.length >= 5
                  ? afropeepGreen.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _selectedInterests.length >= 5
                    ? afropeepGreen.withOpacity(0.3)
                    : Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _selectedInterests.length >= 5
                      ? Icons.check_circle
                      : Icons.info_outline,
                  color: _selectedInterests.length >= 5
                      ? afropeepGreen
                      : Colors.orange.shade700,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  "${_selectedInterests.length} interests selected ${_selectedInterests.length >= 5 ? '✓' : '(minimum 5)'}",
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _selectedInterests.length >= 5
                        ? afropeepGreen
                        : Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Selected interests display
          if (_selectedInterests.isNotEmpty) ...[
            Text(
              'Your selected interests:',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textDarkBrown,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedInterests.map((interest) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: afropeepGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: afropeepGreen.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        interest,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: afropeepGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _toggleInterest(interest),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: afropeepGreen,
                        ),
                      ),
                    ],
                  ),
                ),).toList(),
            ),
          ],
        ],
      ),
    );
}
