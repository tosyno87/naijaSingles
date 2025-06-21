import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../common/routes/route_name.dart';
import '../user/controllers/onboarding_controller.dart';
import 'screens/basic_info_screen.dart';
import 'screens/bio_screen.dart';
import 'screens/interests_screen.dart';
import 'screens/photo_upload_screen.dart';
import 'screens/tribe_selection_screen.dart';

class OnboardingMain extends StatefulWidget {
  const OnboardingMain({super.key});

  @override
  State<OnboardingMain> createState() => _OnboardingMainState();
}

class _OnboardingMainState extends State<OnboardingMain> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 5;
  
  final List<String> _pageNames = [
    "Basic Info",
    "Your Tribe",
    "About You",
    "Interests",
    "Profile Photo"
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Complete onboarding
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
    controller.saveUserData().then((_) {
      Navigator.pushReplacementNamed(context, RouteName.mainNavigation);
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $error")),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Define colors
    const Color backgroundColor = Color(0xFFFFF6E5); // Warm cream/beige
    const Color primaryColor = Color(0xFF008037); // Deep Green
    const Color accentColor = Color(0xFFE74C3C); // Coral Red
    const Color textColor = Color(0xFF333333);

    return ChangeNotifierProvider(
      create: (_) => OnboardingController(),
      child: Scaffold(
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
                    ],
                  ),
                ),
                
                // Next button
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
                      }
                      
                      return SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: canContinue ? _nextPage : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: primaryColor.withOpacity(0.5),
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
      ),
    );
  }
}
