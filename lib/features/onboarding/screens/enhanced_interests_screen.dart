import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/onboarding_bloc.dart';
import '../onboarding_theme.dart';

class EnhancedInterestsScreen extends StatefulWidget {
  const EnhancedInterestsScreen({super.key});

  @override
  State<EnhancedInterestsScreen> createState() =>
      _EnhancedInterestsScreenState();
}

class _EnhancedInterestsScreenState extends State<EnhancedInterestsScreen> {
  List<String> _selectedInterests = [];
  static const int _maxSelections = 10;

  final Map<String, bool> _categoryExpanded = {
    'creativity': false,
    'entertainment': false,
    'sports': false,
    'food': false,
    'culture': false,
    'lifestyle': false,
    'travel': false,
  };

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
      'initialCount': 7,
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = context.read<OnboardingBloc>().state.data;

      if (data != null && data.interests.isNotEmpty) {
        setState(() => _selectedInterests = List.from(data.interests));
      }
    });
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
        context.read<OnboardingBloc>().add(
              OnboardingInterestRemoved(interest),
            );
      } else {
        if (_selectedInterests.length >= _maxSelections) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You can select up to $_maxSelections interests',
                style: GoogleFonts.montserrat(),
              ),
              backgroundColor: OnboardingTheme.primaryGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          return;
        }
        _selectedInterests.add(interest);
        context.read<OnboardingBloc>().add(
              OnboardingInterestAdded(interest),
            );
      }
    });
  }

  void _toggleCategoryExpansion(String categoryKey) {
    setState(() {
      _categoryExpanded[categoryKey] = !_categoryExpanded[categoryKey]!;
    });
  }

  @override
  Widget build(BuildContext context) => OnboardingTheme.constrainedContent(
        child: SingleChildScrollView(
          padding: OnboardingTheme.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What are you into?', style: OnboardingTheme.titleStyle),
              const SizedBox(height: OnboardingTheme.titleToSubtitle),
              Text(
                'You like what you like. Now, let everyone know.',
                style: OnboardingTheme.subtitleStyle,
              ),
              const SizedBox(height: 8),
              Text(
                '${_selectedInterests.length} / $_maxSelections selected',
                style: OnboardingTheme.helperStyle.copyWith(
                  color: _selectedInterests.length >= _maxSelections
                      ? Colors.orange
                      : OnboardingTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: OnboardingTheme.subtitleToField),
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
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(
                            title,
                            style: OnboardingTheme.sectionLabelStyle,
                          ),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: displayedInterests.map((interest) {
                        final isSelected =
                            _selectedInterests.contains(interest);
                        final atLimit =
                            _selectedInterests.length >= _maxSelections;

                        return GestureDetector(
                          onTap: () => _toggleInterest(interest),
                          child: Container(
                            constraints: const BoxConstraints(
                              minHeight: OnboardingTheme.minTapTarget,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? OnboardingTheme.primaryGreen
                                  : OnboardingTheme.fieldFill,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? OnboardingTheme.primaryGreen
                                    : OnboardingTheme.fieldBorder,
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
                                    : atLimit
                                        ? OnboardingTheme.subtitleColor
                                        : OnboardingTheme.sectionLabelColor,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (hasMore)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 8,
                          bottom: OnboardingTheme.fieldToSection,
                        ),
                        child: TextButton(
                          onPressed: () =>
                              _toggleCategoryExpansion(categoryKey),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(
                              0,
                              OnboardingTheme.minTapTarget,
                            ),
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
                                  color: OnboardingTheme.primaryGreen,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: OnboardingTheme.primaryGreen,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: OnboardingTheme.fieldToSection),
                  ],
                );
              }),
            ],
          ),
        ),
      );
}
