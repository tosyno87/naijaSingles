import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../user/controllers/onboarding_controller.dart';
import '../../common/constants/colors.dart';
import '../../common/widgets/custom_button.dart';

/// Third step of onboarding focusing on personal values.
///
/// This screen collects information about what matters to the user
/// in a partner and their dealbreakers.
class OnboardingStepCValues extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback finishOnboarding;
  final Color backgroundColor;

  const OnboardingStepCValues({
    Key? key,
    required this.onBack,
    required this.finishOnboarding,
    this.backgroundColor = const Color(0xFFFDF6EC),
  }) : super(key: key);

  @override
  State<OnboardingStepCValues> createState() => _OnboardingStepCValuesState();
}

class _OnboardingStepCValuesState extends State<OnboardingStepCValues> {
  // Values that might matter in a partner
  final List<Map<String, dynamic>> _partnerValues = [
    {'id': 'family', 'label': 'Family-oriented'},
    {'id': 'religion', 'label': 'Religious values'},
    {'id': 'ambition', 'label': 'Ambition & drive'},
    {'id': 'education', 'label': 'Education'},
    {'id': 'humor', 'label': 'Sense of humor'},
    {'id': 'kindness', 'label': 'Kindness & empathy'},
    {'id': 'loyalty', 'label': 'Loyalty & honesty'},
    {'id': 'financial', 'label': 'Financial stability'},
    {'id': 'culture', 'label': 'Cultural connection'},
    {'id': 'communication', 'label': 'Communication skills'},
    {'id': 'independence', 'label': 'Independence'},
    {'id': 'adventure', 'label': 'Adventurous spirit'},
  ];
  
  // Potential dealbreakers
  final List<Map<String, dynamic>> _dealbreakers = [
    {'id': 'smoking', 'label': 'Smoking'},
    {'id': 'drinking', 'label': 'Heavy drinking'},
    {'id': 'different_religion', 'label': 'Different religious beliefs'},
    {'id': 'different_tribe', 'label': 'Different tribe/ethnicity'},
    {'id': 'no_career', 'label': 'Lack of career ambition'},
    {'id': 'no_education', 'label': 'Lack of formal education'},
    {'id': 'distance', 'label': 'Long distance relationship'},
    {'id': 'children', 'label': 'Has children from previous relationship'},
    {'id': 'no_family', 'label': 'Doesn\'t want family/children'},
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<OnboardingController>(context);
    
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Your Values & Preferences',
                style: GoogleFonts.montserrat(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tell us what matters most to you in relationships.',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: Colors.brown.shade600,
                ),
              ),
              const SizedBox(height: 32),
              
              // Partner values
              _buildSectionTitle('What matters most in a partner?'),
              const SizedBox(height: 8),
              Text(
                'Select at least 3 values that are important to you',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 12,
                children: _partnerValues.map((value) {
                  final isSelected = controller.values.contains(value['id']);
                  return _buildValueCheckbox(
                    label: value['label'],
                    isSelected: isSelected,
                    onChanged: (selected) {
                      List<String> updatedValues = [...controller.values];
                      if (selected) {
                        updatedValues.add(value['id']);
                      } else {
                        updatedValues.remove(value['id']);
                      }
                      controller.updateValues(updatedValues);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              
              // Dealbreakers (optional)
              _buildSectionTitle('Any dealbreakers? (Optional)'),
              const SizedBox(height: 8),
              Text(
                'Select any absolute dealbreakers for you',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 12,
                children: _dealbreakers.map((dealbreaker) {
                  final isSelected = controller.dealbreakers.contains(dealbreaker['id']);
                  return _buildValueCheckbox(
                    label: dealbreaker['label'],
                    isSelected: isSelected,
                    onChanged: (selected) {
                      List<String> updatedDealbreakers = [...controller.dealbreakers];
                      if (selected) {
                        updatedDealbreakers.add(dealbreaker['id']);
                      } else {
                        updatedDealbreakers.remove(dealbreaker['id']);
                      }
                      controller.updateDealbreakers(updatedDealbreakers);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              
              // Navigation buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: widget.onBack,
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_back, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Back',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 150,
                    child: CustomButton(
                      text: 'Finish',
                      onTap: _isStepValid(controller) ? widget.finishOnboarding : () {},
                      color: primaryColor,
                      active: _isStepValid(controller),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Builds a section title with consistent styling
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
  
  /// Builds a custom checkbox for values selection
  Widget _buildValueCheckbox({
    required String label,
    required bool isSelected,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!isSelected),
      child: Container(
        width: (MediaQuery.of(context).size.width - 64) / 2,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: isSelected,
                onChanged: (value) => onChanged(value ?? false),
                activeColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? primaryColor : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Validates if all required fields are filled
  bool _isStepValid(OnboardingController controller) {
    // Require at least 3 values
    return controller.values.length >= 3;
  }
}
