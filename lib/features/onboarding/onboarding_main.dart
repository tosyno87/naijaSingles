import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../user/controllers/onboarding_controller.dart';
import 'screens/basic_info_screen.dart';
import 'screens/bio_screen.dart';
import 'screens/interests_screen.dart';
import 'screens/photo_upload_screen.dart';
import 'screens/tribe_selection_screen.dart';
import 'screens/preferences_onboarding_screen.dart';
import 'screens/additional_info_onboarding_screen.dart';

class OnboardingMain extends StatefulWidget {
  const OnboardingMain({super.key});

  @override
  State<OnboardingMain> createState() => _OnboardingMainState();
}

class _OnboardingMainState extends State<OnboardingMain> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 7; // Updated to include new screens
  
  final List<String> _pageNames = [
    "Basic Info",
    "Your Tribe", 
    "About You",
    "Interests",
    "Profile Photo",
    "Dating Preferences", // New screen
    "Additional Info"     // New screen
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    final controller = Provider.of<OnboardingController>(context, listen: false);
    
    // Debug: Print current controller state
    print('🔍 OnboardingMain: Current page: $_currentPage');
    print('🔍 OnboardingMain: Controller instance: ${controller.hashCode}');
    print('🔍 OnboardingMain: Controller state:');
    print('   Name: "${controller.fullName}" (length: ${controller.fullName.length})');
    print('   DOB: ${controller.dateOfBirth}');
    print('   Gender: "${controller.gender}" (length: ${controller.gender.length})');
    print('   Tribe: "${controller.tribe}" (length: ${controller.tribe.length})');
    print('   Bio: "${controller.bio}" (length: ${controller.bio.length})');
    print('   Interests: ${controller.interests}');
    print('   Photos uploaded: ${controller.profilePhotos.where((photo) => photo != null).length}/5');
    print('   Photo validation: ${controller.isPhotoUploaded()}');
    print('   Height: ${controller.heightDisplay}');
    print('   Looking For: ${controller.lookingFor}');
    print('   Relationship Intent: ${controller.relationshipIntent}');
    print('   Interested In: ${controller.interestedIn}');
    print('   Age Range: ${controller.ageRange}');
    
    // Re-enable validation now that data flow works
    if (_currentPage == 0) { // Basic Info page
      if (controller.fullName.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter your full name")),
        );
        return;
      }
      if (controller.dateOfBirth == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select your date of birth")),
        );
        return;
      }
      if (controller.gender.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select your gender")),
        );
        return;
      }
    } else if (_currentPage == 1) { // Tribe selection page
      if (controller.tribe.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select your tribe")),
        );
        return;
      }
    } else if (_currentPage == 2) { // Bio page
      if (controller.bio.trim().isEmpty || controller.bio.trim().length < 20) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please write a bio (at least 20 characters)")),
        );
        return;
      }
    } else if (_currentPage == 3) { // Interests page
      if (controller.interests.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select at least one interest")),
        );
        return;
      }
    } else if (_currentPage == 4) { // Photo upload page
      if (!controller.isPhotoUploaded()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please upload at least 3 photos")),
        );
        return;
      }
    } else if (_currentPage == 5) { // Dating preferences page
      // Basic validation - these have defaults so they should always be set
      if (controller.interestedIn.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select who you're interested in")),
        );
        return;
      }
    } else if (_currentPage == 6) { // Additional preferences page
      // Basic validation for height and other fields
      if (controller.height <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please set your height")),
        );
        return;
      }
    }
    
    if (_currentPage < _totalPages - 1) {
      print('✅ Moving to next page');
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Complete onboarding
      print('✅ Completing onboarding');
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
    final controller = Provider.of<OnboardingController>(context, listen: false);
    
    // Debug: Print what we're about to save
    print('🔍 About to save user data:');
    print('   Name: ${controller.fullName}');
    print('   Age: ${controller.age}');
    print('   Gender: ${controller.gender}');
    print('   Tribe: ${controller.tribe}');
    print('   Bio: ${controller.bio}');
    print('   Interests: ${controller.interests}');
    print('   Photos uploaded: ${controller.profilePhotos.where((photo) => photo != null).length}/5');
    print('   Height: ${controller.heightDisplay}');
    print('   Looking For: ${controller.lookingFor}');
    print('   Relationship Intent: ${controller.relationshipIntent}');
    print('   Interested In: ${controller.interestedIn}');
    print('   Age Range: ${controller.ageRange}');
    
    // Use the optimized save method that handles navigation
    controller.saveUserData(context: context).catchError((error) {
      print('❌ Error saving user data: $error');
      if (mounted) { // Check if widget is still mounted before showing snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $error")),
        );
      }
    });
    
    // Note: Navigation is now handled inside the saveUserData method
  }

  @override
  Widget build(BuildContext context) {
    // Define colors
    const Color backgroundColor = Color(0xFFFFF6E5); // Warm cream/beige
    const Color primaryColor = Color(0xFF008037); // Deep Green
    const Color accentColor = Color(0xFFE74C3C); // Coral Red
    const Color textColor = Color(0xFF333333);

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
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: _currentPage < _totalPages - 1
                  ? () {
                      // Skip to main app
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            "Skip Onboarding?",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          content: Text(
                            "You can always complete your profile later, but a complete profile gets more matches!",
                            style: GoogleFonts.poppins(),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                "Continue Setup",
                                style: GoogleFonts.poppins(
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _completeOnboarding();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                              ),
                              child: Text(
                                "Skip",
                                style: GoogleFonts.poppins(),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  : null,
              child: Text(
                "Skip",
                style: GoogleFonts.poppins(
                  color: _currentPage < _totalPages - 1
                      ? accentColor
                      : Colors.transparent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                      TribeSelectionScreen(),
                      BioScreen(),
                      InterestsScreen(),
                      PhotoUploadScreen(),
                      PreferencesOnboardingScreen(),
                      AdditionalInfoOnboardingScreen(),
                    ],
                  ),
                ),
                
                // Next labelLarge
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Consumer<OnboardingController>(
                    builder: (context, controller, _) {
                      bool canContinue = false;
                      
                      switch (_currentPage) {
                        case 0:
                          canContinue = controller.isBasicInfoComplete();
                          break;
                        case 1:
                          canContinue = controller.isTribeSelected();
                          break;
                        case 2:
                          canContinue = controller.isBioComplete();
                          break;
                        case 3:
                          canContinue = controller.areInterestsSelected();
                          break;
                        case 4:
                          canContinue = controller.isPhotoUploaded();
                          break;
                        case 5: // Dating preferences page
                          canContinue = controller.interestedIn.isNotEmpty;
                          break;
                        case 6: // Additional info page
                          canContinue = controller.height > 0 && 
                                       controller.lookingFor.isNotEmpty && 
                                       controller.relationshipIntent.isNotEmpty;
                          break;
                      }
                      
                      // Debug logging for continue labelLarge state
                      if (_currentPage >= 5) {
                        print('🔍 Continue labelLarge state for page $_currentPage:');
                        print('   canContinue: $canContinue');
                        if (_currentPage == 5) {
                          print('   interestedIn: "${controller.interestedIn}"');
                          print('   ageRange: ${controller.ageRange}');
                        } else if (_currentPage == 6) {
                          print('   height: ${controller.height}');
                          print('   lookingFor: "${controller.lookingFor}"');
                          print('   relationshipIntent: "${controller.relationshipIntent}"');
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
                            disabledBackgroundColor: primaryColor.withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            _currentPage < _totalPages - 1 ? "Continue" : "Finish",
                            style: GoogleFonts.poppins(
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
