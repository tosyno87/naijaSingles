import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../user/controllers/onboarding_controller.dart';
import '../../../common/routes/route_name.dart';
import 'onboarding_step_a_roots.dart';
import 'onboarding_step_b_expression.dart';
import 'onboarding_step_c_values.dart';

/// Main onboarding flow that manages the three onboarding steps.
///
/// This widget provides a container for the onboarding process,
/// handling navigation between steps and completion of the onboarding flow.
class OnboardingMain extends StatefulWidget {
  const OnboardingMain({Key? key}) : super(key: key);

  @override
  State<OnboardingMain> createState() => _OnboardingMainState();
}

class _OnboardingMainState extends State<OnboardingMain> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // Warm Afrocentric background color
  static const Color afrocentricBackground = Color(0xFFFDF6EC);
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  void _goToNextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  void _finishOnboarding() {
    // Complete onboarding and navigate to the next screen
    Navigator.pushReplacementNamed(
      context, 
      RouteName.userNameScreen,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: afrocentricBackground,
      body: Column(
        children: [
          // Progress indicator
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: List.generate(
                  3,
                  (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      decoration: BoxDecoration(
                        color: _currentPage >= index 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // PageView for onboarding screens
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                // Step 1: Cultural Roots
                OnboardingStepARoots(
                  onNext: _goToNextPage,
                  backgroundColor: afrocentricBackground,
                ),
                
                // Step 2: Expression
                OnboardingStepBExpression(
                  onNext: _goToNextPage,
                  onBack: _goToPreviousPage,
                  backgroundColor: afrocentricBackground,
                ),
                
                // Step 3: Values
                OnboardingStepCValues(
                  onBack: _goToPreviousPage,
                  finishOnboarding: _finishOnboarding,
                  backgroundColor: afrocentricBackground,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
