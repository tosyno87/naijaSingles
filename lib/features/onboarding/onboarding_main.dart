import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../user/controllers/onboarding_controller.dart';
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
    final controller =
        Provider.of<OnboardingController>(context, listen: false);

    // Debug: Print current controller state
    debugPrint('🔍 OnboardingMain: Current page: $_currentPage');
    debugPrint(
        '🔍 OnboardingMain: Controller instance: ${controller.hashCode}',);
    debugPrint('🔍 OnboardingMain: Controller state:');
    debugPrint(
        '   Name: "${controller.fullName}" (length: ${controller.fullName.length})',);
    debugPrint('   DOB: ${controller.dateOfBirth}');
    debugPrint(
        '   Gender: "${controller.gender}" (length: ${controller.gender.length})',);
    debugPrint('   Location: "${controller.locationName ?? 'Not set'}"');
    debugPrint(
        '   Tribe: "${controller.tribe}" (length: ${controller.tribe.length})',);
    debugPrint(
        '   Bio: "${controller.bio}" (length: ${controller.bio.length})',);
    debugPrint('   Interests: ${controller.interests}');
    debugPrint(
        '   Photos uploaded: ${controller.profilePhotos.where((photo) => photo != null).length}/5',);
    debugPrint('   Photo validation: ${controller.isPhotoUploaded()}');
    debugPrint('   Height: ${controller.heightDisplay}');
    debugPrint('   Looking For: ${controller.lookingFor}');
    debugPrint('   Relationship Intent: ${controller.relationshipIntent}');
    debugPrint('   Interested In: ${controller.interestedIn}');
    debugPrint('   Age Range: ${controller.ageRange}');

    // Re-enable validation now that data flow works
    if (_currentPage == 0) {
      // Basic Info page
      if (controller.fullName.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your full name')),
        );
        return;
      }
      if (controller.dateOfBirth == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your date of birth')),
        );
        return;
      }
      if (controller.gender.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your gender')),
        );
        return;
      }
    } else if (_currentPage == 1) {
      // Photo upload page (MOVED TO STEP 2) - Tinder requires at least 1 photo
      if (!controller.isPhotoUploaded()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload at least 1 photo')),
        );
        return;
      }
    } else if (_currentPage == 2) {
      // Location page
      if (controller.locationName == null ||
          controller.locationName!.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your location')),
        );
        return;
      }
    } else if (_currentPage == 3) {
      // Nationality selection page (tribe optional)
      if (controller.nationality == null || controller.nationality!.trim().isEmpty) {
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
      if (controller.interestedIn.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Please select who you're interested in"),),
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
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Complete onboarding
      debugPrint('✅ Completing onboarding');
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding() {
    // Save all data and navigate to main app
    final controller =
        Provider.of<OnboardingController>(context, listen: false);

    // Debug: Print what we're about to save
    debugPrint('🔍 About to save user data:');
    debugPrint('   Name: ${controller.fullName}');
    debugPrint('   Age: ${controller.age}');
    debugPrint('   Gender: ${controller.gender}');
    debugPrint('   Location: ${controller.locationName ?? 'Not set'}');
    debugPrint('   Tribe: ${controller.tribe}');
    debugPrint('   Bio: ${controller.bio}');
    debugPrint('   Interests: ${controller.interests}');
    debugPrint(
        '   Photos uploaded: ${controller.profilePhotos.where((photo) => photo != null).length}/5',);
    debugPrint('   Height: ${controller.heightDisplay}');
    debugPrint('   Looking For: ${controller.lookingFor}');
    debugPrint('   Relationship Intent: ${controller.relationshipIntent}');
    debugPrint('   Interested In: ${controller.interestedIn}');
    debugPrint('   Age Range: ${controller.ageRange}');

    // Show completion success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Profile Complete! 🎉 Welcome to Afropeep!',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    // Use the optimized save method that handles navigation
    controller.saveUserData(context: context).catchError((error) {
      debugPrint('❌ Error saving user data: $error');
      if (mounted) {
        // Check if widget is still mounted before showing snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    });

    // Note: Navigation is now handled inside the saveUserData method
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
          // Skip button (like Tinder) - only show on optional screens
          // Required screens: 0 (Basic Info), 1 (Photos), 2 (Location), 3 (Nationality), 6 (Preferences)
          // Optional screens: 4 (Bio), 5 (Interests), 7 (Additional Info)
          if (_currentPage == 4 || _currentPage == 5 || _currentPage == 7)
            TextButton(
              onPressed: () {
                // Skip onboarding - complete it immediately
                _completeOnboarding();
              },
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
                child: Consumer<OnboardingController>(
                  builder: (context, controller, _) {
                    bool canContinue = false;

                    switch (_currentPage) {
                      case 0:
                        canContinue = controller.isBasicInfoComplete();
                        break;
                      case 1: // Photo page (MOVED TO STEP 2)
                        canContinue = controller.isPhotoUploaded();
                        break;
                      case 2: // Location page
                        canContinue = controller.locationName != null &&
                            controller.locationName!.trim().isNotEmpty;
                        break;
                      case 3: // Nationality page (tribe optional)
                        canContinue = controller.nationality != null &&
                            controller.nationality!.isNotEmpty;
                        break;
                      case 4: // Bio page - Optional (Tinder standard)
                        canContinue = true; // Bio is optional
                        break;
                      case 5: // Interests page - Optional (Tinder standard)
                        canContinue = true; // Interests are optional
                        break;
                      case 6: // Dating preferences page
                        canContinue = controller.interestedIn.isNotEmpty;
                        break;
                      case 7: // Enhanced additional info page - OPTIONAL
                        // Always allow continuing - this step is optional
                        // Users can complete additional info later in profile settings
                        canContinue = true;
                        break;
                    }

                    // Debug logging for continue labelLarge state
                    if (_currentPage >= 5) {
                      debugPrint(
                          '🔍 Continue labelLarge state for page $_currentPage:',);
                      debugPrint('   canContinue: $canContinue');
                      if (_currentPage == 5) {
                        debugPrint(
                            '   interestedIn: "${controller.interestedIn}"',);
                        debugPrint('   ageRange: ${controller.ageRange}');
                      } else if (_currentPage == 6) {
                        debugPrint('   height: ${controller.height}');
                        debugPrint('   lookingFor: "${controller.lookingFor}"');
                        debugPrint(
                            '   relationshipIntent: "${controller.relationshipIntent}"',);
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
                          _currentPage < _totalPages - 1
                              ? 'Next'
                              : 'Finish',
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
