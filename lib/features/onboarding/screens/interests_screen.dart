import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/onboarding_bloc.dart';

class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key});

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  final List<String> _interests = [
    // Activities
    'Travel', 'Cooking', 'Hiking', 'Photography', 'Dancing',
    'Reading', 'Writing', 'Painting', 'Singing', 'Gaming',

    // Sports
    'Football', 'Basketball', 'Tennis', 'Swimming', 'Yoga',
    'Running', 'Cycling', 'Volleyball', 'Fitness', 'Martial Arts',

    // Entertainment
    'Movies', 'Music', 'Concerts', 'Theatre', 'Comedy',
    'Netflix', 'Podcasts', 'Festivals', 'Clubbing', 'Karaoke',

    // Food & Drink
    'Fine Dining', 'Street Food', 'Baking', 'Wine Tasting', 'Craft Beer',
    'Vegetarian', 'Foodie', 'Coffee', 'Brunch', 'BBQ',

    // Nigerian Specific
    'Afrobeats', 'Nollywood', 'Jollof Rice', 'Traditional Dance',
    'Cultural Events',
    'Local Markets', 'Nigerian Fashion', 'Pidgin', 'Owanbe Parties',
    'Nigerian Literature',
  ];

  List<String> _selectedInterests = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = context.read<OnboardingBloc>().state.data;
      if (data != null && data.interests.isNotEmpty) {
        setState(() {
          _selectedInterests = List.from(data.interests);
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
        context.read<OnboardingBloc>().add(
          OnboardingInterestRemoved(interest),
        );
      } else {
        if (_selectedInterests.length < 10) {
          _selectedInterests.add(interest);
          context.read<OnboardingBloc>().add(
            OnboardingInterestAdded(interest),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You can select up to 10 interests',
                style: GoogleFonts.montserrat(),
              ),
              backgroundColor: Colors.red.shade400,
            ),
          );
        }
      }
    });
  }

  List<String> get _filteredInterests {
    if (_searchQuery.isEmpty) {
      return _interests;
    }

    return _interests
        .where(
          (interest) =>
              interest.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // Define colors
    const Color primaryColor = Color(0xFF008037); // Deep Green
    const Color textColor = Color(0xFF333333);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Your Interests',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Choose up to 10 interests to help us match you with like-minded people',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 16),

              // Search box
              TextField(
                controller: _searchController,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Search interests',
                  hintStyle: GoogleFonts.montserrat(
                    color: Colors.grey.shade400,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.grey,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Selected count
              Text(
                '${_selectedInterests.length}/10 selected',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _selectedInterests.length >= 3
                      ? primaryColor
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ),

        // Interests grid
        Expanded(
          child: _filteredInterests.isEmpty
              ? Center(
                  child: Text(
                    'No interests found',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _filteredInterests.length,
                  itemBuilder: (context, index) {
                    final interest = _filteredInterests[index];
                    final isSelected = _selectedInterests.contains(interest);

                    return InkWell(
                      onTap: () => _toggleInterest(interest),
                      borderRadius: BorderRadius.circular(12),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? primaryColor
                                : Colors.grey.shade300,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              interest,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.white : textColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
