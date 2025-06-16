import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../user/controllers/onboarding_controller.dart';
import '../../common/constants/colors.dart';
import '../../common/widgets/custom_button.dart';
import 'shared_styles.dart';

/// First step of onboarding focusing on cultural roots.
///
/// This screen collects information about the user's tribe,
/// languages spoken, and their intent for using the app.
class OnboardingStepARoots extends StatefulWidget {
  final VoidCallback onNext;
  final Color backgroundColor;

  OnboardingStepARoots({
    Key? key,
    required this.onNext,
    this.backgroundColor = OnboardingStyles.backgroundColor,
  }) : super(key: key);

  @override
  State<OnboardingStepARoots> createState() => _OnboardingStepARootsState();
}

class _OnboardingStepARootsState extends State<OnboardingStepARoots> {
  // Keys for accessibility and testing
  final GlobalKey<FormFieldState> _tribeFieldKey = GlobalKey<FormFieldState>();
  final GlobalKey _languagesKey = GlobalKey();
  final GlobalKey _continueButtonKey = GlobalKey();
  
  final TextEditingController _tribeController = TextEditingController();
  
  // List of Nigerian tribes
  final List<String> _suggestedTribes = [
    'Yoruba', 'Igbo', 'Hausa', 'Fulani', 'Ijaw', 'Kanuri', 
    'Ibibio', 'Tiv', 'Edo', 'Nupe', 'Urhobo', 'Igala'
  ];
  
  // List of languages commonly spoken in Nigeria
  final List<String> _availableLanguages = [
    'English', 'Yoruba', 'Igbo', 'Hausa', 'Pidgin', 
    'French', 'Arabic', 'Efik', 'Ibibio', 'Tiv', 'Urhobo'
  ];
  
  // Intent options with icons, titles and descriptions
  final List<Map<String, dynamic>> _intentOptions = [
    {
      'value': 'dating',
      'icon': Icons.favorite,
      'title': 'Dating',
      'description': 'I want to find a romantic partner',
    },
    {
      'value': 'friendship',
      'icon': Icons.people,
      'title': 'Friendship',
      'description': 'I want to make new friends',
    },
    {
      'value': 'networking',
      'icon': Icons.business_center,
      'title': 'Networking',
      'description': 'I want to expand my professional network',
    },
  ];

  @override
  void dispose() {
    _tribeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<OnboardingController>(context);
    
    // Deep green color for selected elements
    const Color deepGreen = Color(0xFF008037);
    
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: deepGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Step 1 of 3',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: deepGreen,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Header section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Cultural Roots',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade800,
                    ),
                    semanticsLabel: 'Your Cultural Roots, Step 1 of 3',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tell us about your cultural background to help us connect you with like-minded people.',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.brown.shade600,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // White card container for all input fields
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tribe input
                    _buildSectionTitle('What is your tribe or ethnic group?'),
                    const SizedBox(height: 12),
                    TextField(
                      key: _tribeFieldKey,
                      controller: _tribeController,
                      autofocus: true,
                      textInputAction: TextInputAction.next,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Tribe',
                        hintText: 'Enter your tribe',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey[800],
                          fontSize: 16,
                        ),
                        labelStyle: GoogleFonts.poppins(
                          color: deepGreen,
                          fontSize: 16,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[400]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[400]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: deepGreen, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (value) {
                        controller.updateTribe(value.trim());
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Suggested tribes
                    Text(
                      'Suggestions:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Hardcoded chip for testing visibility
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              _tribeController.text = "Yoruba";
                              controller.updateTribe("Yoruba");
                              HapticFeedback.lightImpact();
                            },
                            splashColor: const Color(0xFF008037).withOpacity(0.1),
                            highlightColor: const Color(0xFF008037).withOpacity(0.05),
                            child: Ink(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey[400]!),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Text(
                                  "Yoruba",
                                  style: GoogleFonts.poppins(
                                    color: Colors.black87,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Dynamic chips from the list
                        ..._suggestedTribes.where((tribe) => tribe != "Yoruba").map((tribe) {
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                _tribeController.text = tribe;
                                controller.updateTribe(tribe.trim());
                                HapticFeedback.lightImpact();
                              },
                              splashColor: const Color(0xFF008037).withOpacity(0.1),
                              highlightColor: const Color(0xFF008037).withOpacity(0.05),
                              child: Ink(
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.grey[400]!),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Text(
                                    tribe,
                                    style: GoogleFonts.poppins(
                                      color: Colors.black87,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Languages selection
                    _buildSectionTitle('Which languages do you speak?'),
                    const SizedBox(height: 8),
                    Text(
                      'Select all that apply',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Semantics(
                      label: 'Language selection',
                      hint: 'Select one or more languages that you speak',
                      child: Wrap(
                        key: _languagesKey,
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableLanguages.map((language) {
                          final isSelected = controller.languages.contains(language);
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                List<String> updatedLanguages = [...controller.languages];
                                if (!isSelected) {
                                  updatedLanguages.add(language);
                                } else {
                                  updatedLanguages.remove(language);
                                }
                                controller.updateLanguages(updatedLanguages);
                                HapticFeedback.selectionClick();
                              },
                              splashColor: deepGreen.withOpacity(0.1),
                              highlightColor: deepGreen.withOpacity(0.05),
                              child: Ink(
                                decoration: BoxDecoration(
                                  color: isSelected ? deepGreen : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? deepGreen : Colors.grey[400]!,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        language,
                                        style: GoogleFonts.poppins(
                                          color: isSelected ? Colors.white : Colors.black87,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Intent selection in a separate white card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('What are you looking for?'),
                    const SizedBox(height: 16),
                    ..._intentOptions.map((option) => _buildIntentOption(
                      option: option,
                      isSelected: controller.intent == option['value'],
                      onTap: () => controller.updateIntent(option['value']),
                      deepGreen: deepGreen,
                    )),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Continue button
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    key: _continueButtonKey,
                    onPressed: _isStepValid(controller) ? () {
                      HapticFeedback.mediumImpact();
                      widget.onNext();
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: deepGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Continue',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
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
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
  
  /// Builds an intent option card with icon, title and description
  Widget _buildIntentOption({
    required Map<String, dynamic> option,
    required bool isSelected,
    required VoidCallback onTap,
    required Color deepGreen,
  }) {
    return Semantics(
      button: true,
      label: '${option['title']} option',
      hint: option['description'],
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            onTap();
            HapticFeedback.selectionClick();
          },
          borderRadius: BorderRadius.circular(12),
          splashColor: deepGreen.withOpacity(0.1),
          highlightColor: deepGreen.withOpacity(0.05),
          child: Container(
            constraints: const BoxConstraints(minHeight: 90),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? deepGreen.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? deepGreen : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? deepGreen : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    option['icon'],
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option['title'],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? deepGreen : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        option['description'],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: deepGreen,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Validates if all required fields are filled
  bool _isStepValid(OnboardingController controller) {
    return (controller.tribe != null && controller.tribe!.isNotEmpty) &&
           controller.languages.isNotEmpty &&
           controller.intent != null;
  }
}
