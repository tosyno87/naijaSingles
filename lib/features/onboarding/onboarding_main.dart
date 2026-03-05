import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bloc/onboarding_bloc.dart';
import 'screens/basic_info_screen.dart';
import 'screens/enhanced_additional_info_screen.dart';
import 'screens/enhanced_bio_screen.dart';
import 'screens/enhanced_interests_screen.dart';
import 'screens/enhanced_photo_upload_screen.dart';
import 'screens/location_screen.dart';
import 'screens/preferences_onboarding_screen.dart';
import 'screens/tribe_selection_screen.dart';

class OnboardingMain extends StatefulWidget {
  const OnboardingMain({super.key});

  @override
  State<OnboardingMain> createState() => _OnboardingMainState();
}

class _OnboardingMainState extends State<OnboardingMain> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 8; // Updated to include location screen

  // Reordered based on industry best practices: Photos should be Step 2
  final List<String> _pageNames = [
    'Basic Info',
    'Profile Photo', // MOVED UP - Industry standard (Tinder, Bumble, Hinge)
    'Your Location',
    'Nationality',
    'Tell Your Story',
    'Your Interests',
    'Dating Preferences',
    'Additional Info',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    final bloc = context.read<OnboardingBloc>();
    final data = bloc.state.data;

    if (data == null) return;

    // Re-enable validation now that data flow works
    if (_currentPage == 0) {
      // Basic Info page
      if (data.fullName.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your full name')),
        );
        return;
      }
      if (data.dateOfBirth == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your date of birth')),
        );
        return;
      }
      if (data.gender.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your gender')),
        );
        return;
      }
    } else if (_currentPage == 1) {
      // Photo upload page (MOVED TO STEP 2) - Tinder requires at least 1 photo
      if (!data.isPhotoUploaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload at least 1 photo')),
        );
        return;
      }
    } else if (_currentPage == 2) {
      // Location page
      if (data.locationName == null || data.locationName!.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your location')),
        );
        return;
      }
    } else if (_currentPage == 3) {
      // Nationality selection page (tribe optional)
      if (data.nationality == null || data.nationality!.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your nationality')),
        );
        return;
      }
    } else if (_currentPage == 4) {
      // Bio page - Optional (Tinder standard: bio can be empty)
      // No validation - users can skip bio
    } else if (_currentPage == 5) {
      // Enhanced Interests page - Optional (Tinder standard: passions are optional)
      // No validation - users can skip or select any number of interests
    } else if (_currentPage == 6) {
      // Dating preferences page
      // Basic validation - these have defaults so they should always be set
      if (data.interestedIn.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select who you're interested in"),
          ),
        );
        return;
      }
    } else if (_currentPage == 7) {
      // Enhanced additional info page - OPTIONAL (can be skipped)
      // No validation required - users can complete this later in profile settings
      // This follows industry best practices (progressive disclosure)
    }

    if (_currentPage < _totalPages - 1) {
      debugPrint('✅ Moving to next page');
      unawaited(
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
      );
    } else {
      // Complete onboarding
      debugPrint('✅ Completing onboarding');
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      unawaited(
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
      );
    }
  }

  void _completeOnboarding() {
    // Save all data and navigate to main app
    final bloc = context.read<OnboardingBloc>();

    // Show completion success message - Short and concise
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Profile Complete! 🎉',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    bloc.add(OnboardingSaveUserData(context));
  }

  @override
  Widget build(BuildContext context) {
    // Define colors
    const Color backgroundColor = Colors.white; // Clean white
    const Color primaryColor = Color(0xFF008037); // Deep Green

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: primaryColor),
                onPressed: _previousPage,
              )
            : null,
        title: Text(
          _pageNames[_currentPage],
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
        centerTitle: true,
        actions: [
          // Skip button — only on optional screens (4: Bio, 5: Interests, 7: Additional Info).
          // Pages 4/5 advance to the next page so required page 6 (Preferences) is never bypassed.
          // Page 7 is the final step, so Skip there completes onboarding.
          if (_currentPage == 4 || _currentPage == 5)
            TextButton(
              onPressed: _nextPage,
              child: Text(
                'Skip',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            )
          else if (_currentPage == 7)
            TextButton(
              onPressed: _completeOnboarding,
              child: Text(
                'Skip',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
          if (_currentPage == 4 || _currentPage == 5 || _currentPage == 7)
            const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Background texture watermark
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),

          // Main content
          Column(
            children: [
              // Progress indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LinearProgressIndicator(
                  value: (_currentPage + 1) / _totalPages,
                  backgroundColor: Colors.grey.shade300,
                  color: primaryColor,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // Page content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: const [
                    BasicInfoScreen(),
                    EnhancedPhotoUploadScreen(), // MOVED TO STEP 2 - Industry best practice
                    LocationScreen(),
                    TribeSelectionScreen(),
                    EnhancedBioScreen(),
                    EnhancedInterestsScreen(),
                    PreferencesOnboardingScreen(),
                    EnhancedAdditionalInfoScreen(),
                  ],
                ),
              ),

              // Next labelLarge
              Padding(
                padding: const EdgeInsets.all(24),
                child: BlocBuilder<OnboardingBloc, OnboardingState>(
                  buildWhen: (prev, curr) =>
                      prev.data != curr.data || prev != curr,
                  builder: (context, state) {
                    final data = state.data;
                    bool canContinue = false;

                    if (data != null) {
                      switch (_currentPage) {
                        case 0:
                          canContinue = data.isBasicInfoComplete;
                          break;
                        case 1:
                          canContinue = data.isPhotoUploaded;
                          break;
                        case 2:
                          canContinue = data.locationName != null &&
                              data.locationName!.trim().isNotEmpty;
                          break;
                        case 3:
                          canContinue = data.nationality != null &&
                              data.nationality!.isNotEmpty;
                          break;
                        case 4:
                        case 5:
                        case 7:
                          canContinue = true;
                          break;
                        case 6:
                          canContinue = data.interestedIn.isNotEmpty;
                          break;
                      }
                    }

                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: canContinue ? _nextPage : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              primaryColor.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          _currentPage < _totalPages - 1 ? 'Next' : 'Finish',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
