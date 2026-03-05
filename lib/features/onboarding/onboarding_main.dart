import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bloc/onboarding_bloc.dart';
import 'onboarding_theme.dart';
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
  final int _totalPages = 8;

  final List<String> _pageNames = [
    'Basic Info',
    'Profile Photo',
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

    if (_currentPage == 0) {
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
      if (!data.isPhotoUploaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload at least 1 photo')),
        );
        return;
      }
    } else if (_currentPage == 2) {
      if (data.locationName == null || data.locationName!.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your location')),
        );
        return;
      }
    } else if (_currentPage == 3) {
      if (data.nationality == null || data.nationality!.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your nationality')),
        );
        return;
      }
    } else if (_currentPage == 6) {
      if (data.interestedIn.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select who you're interested in"),
          ),
        );
        return;
      }
    }

    if (_currentPage < _totalPages - 1) {
      unawaited(
        _pageController.nextPage(
          duration: OnboardingTheme.stepTransition,
          curve: OnboardingTheme.stepCurve,
        ),
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      unawaited(
        _pageController.previousPage(
          duration: OnboardingTheme.stepTransition,
          curve: OnboardingTheme.stepCurve,
        ),
      );
    }
  }

  void _completeOnboarding() {
    final bloc = context.read<OnboardingBloc>();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Profile Complete!',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        backgroundColor: OnboardingTheme.primaryGreen,
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
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final bottomPadding = math.max(16.0, bottomSafe);

    return Scaffold(
      backgroundColor: OnboardingTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: OnboardingTheme.primaryGreen,
                ),
                onPressed: _previousPage,
              )
            : null,
        title: Text(
          _pageNames[_currentPage],
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: OnboardingTheme.primaryGreen,
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
                  color: OnboardingTheme.primaryGreen,
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
                  color: OnboardingTheme.primaryGreen,
                ),
              ),
            ),
          if (_currentPage == 4 || _currentPage == 5 || _currentPage == 7)
            const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: OnboardingTheme.horizontalPadding,
            ),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / _totalPages,
              backgroundColor: OnboardingTheme.progressTrack,
              color: OnboardingTheme.primaryGreen,
              minHeight: OnboardingTheme.progressHeight,
              borderRadius: BorderRadius.circular(OnboardingTheme.progressRadius),
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
                EnhancedPhotoUploadScreen(),
                LocationScreen(),
                TribeSelectionScreen(),
                EnhancedBioScreen(),
                EnhancedInterestsScreen(),
                PreferencesOnboardingScreen(),
                EnhancedAdditionalInfoScreen(),
              ],
            ),
          ),

          // Bottom CTA
          Padding(
            padding: EdgeInsets.only(
              left: OnboardingTheme.horizontalPadding,
              right: OnboardingTheme.horizontalPadding,
              top: 16,
              bottom: bottomPadding,
            ),
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
                    case 1:
                      canContinue = data.isPhotoUploaded;
                    case 2:
                      canContinue = data.locationName != null &&
                          data.locationName!.trim().isNotEmpty;
                    case 3:
                      canContinue = data.nationality != null &&
                          data.nationality!.isNotEmpty;
                    case 4:
                    case 5:
                    case 7:
                      canContinue = true;
                    case 6:
                      canContinue = data.interestedIn.isNotEmpty;
                  }
                }

                return SizedBox(
                  width: double.infinity,
                  height: OnboardingTheme.buttonHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: canContinue ? OnboardingTheme.buttonGradient : null,
                      color: canContinue ? null : OnboardingTheme.primaryGreen.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(OnboardingTheme.buttonRadius),
                    ),
                    child: ElevatedButton(
                      onPressed: canContinue ? _nextPage : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.transparent,
                        disabledForegroundColor: Colors.white60,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(OnboardingTheme.buttonRadius),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage < _totalPages - 1 ? 'Next' : 'Finish',
                        style: OnboardingTheme.buttonTextStyle,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
