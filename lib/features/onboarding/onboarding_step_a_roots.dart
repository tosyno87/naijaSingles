import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../user/controllers/onboarding_controller.dart';
import '../../../common/constants/colors.dart';
import '../../../common/widgets/custom_button.dart';

/// First step of onboarding focusing on cultural roots.
///
/// This screen collects information about the user's tribe,
/// languages spoken, and their intent for using the app.
class OnboardingStepARoots extends StatefulWidget {
  final VoidCallback onNext;
  final Color backgroundColor;

  const OnboardingStepARoots({
    Key? key,
    required this.onNext,
    this.backgroundColor = const Color(0xFFFDF6EC),
  }) : super(key: key);

  @override
  State<OnboardingStepARoots> createState() => _OnboardingStepARootsState();
}

class _OnboardingStepARootsState extends State<OnboardingStepARoots> {
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
  
  // Intent options
  final List<Map<String, dynamic>> _intentOptions = [
    {
      'value': 'Dating',
      'title': 'Dating',
      'description': 'Find a romantic partner',
      'icon': Icons.favorite
    },
    {
      'value': 'Friendship',
      'title': 'Friendship',
      'description': 'Make new friends',
      'icon': Icons.people
    },
    {
      'value': 'Community',
      'title': 'Community',
      'description': 'Connect with your cultural community',
      'icon': Icons.diversity_3
    }
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize the text controller with existing value if available
    final controller = Provider.of<OnboardingController>(context, listen: false);
    if (controller.tribe != null) {
      _tribeController.text = controller.tribe!;
    }
  }

  @override
  void dispose() {
    _tribeController.dispose();
    super.dispose();
  }

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
                'Your Cultural Roots',
                style: GoogleFonts.montserrat(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tell us about your cultural background to help us connect you with like-minded people.',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: Colors.brown.shade600,
                ),
              ),
              const SizedBox(height: 32),
              
              // Tribe input
              _buildSectionTitle('What is your tribe or ethnic group?'),
              const SizedBox(height: 8),
              TextField(
                controller: _tribeController,
                decoration: InputDecoration(
                  hintText: 'Enter your tribe',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                onChanged: (value) {
                  controller.updateTribe(value);
                },
              ),
              const SizedBox(height: 12),
              
              // Suggested tribes
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestedTribes.map((tribe) {
                  return ActionChip(
                    label: Text(tribe),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade300),
                    onPressed: () {
                      _tribeController.text = tribe;
                      controller.updateTribe(tribe);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              
              // Languages selection
              _buildSectionTitle('Which languages do you speak?'),
              const SizedBox(height: 8),
              Text(
                'Select all that apply',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableLanguages.map((language) {
                  final isSelected = controller.languages.contains(language);
                  return FilterChip(
                    label: Text(language),
                    selected: isSelected,
                    onSelected: (selected) {
                      List<String> updatedLanguages = [...controller.languages];
                      if (selected) {
                        updatedLanguages.add(language);
                      } else {
                        updatedLanguages.remove(language);
                      }
                      controller.updateLanguages(updatedLanguages);
                    },
                    backgroundColor: Colors.white,
                    selectedColor: primaryColor.withOpacity(0.2),
                    checkmarkColor: primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? primaryColor : Colors.black87,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? primaryColor : Colors.grey.shade300,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              
              // Intent selection
              _buildSectionTitle('What are you looking for?'),
              const SizedBox(height: 16),
              ..._intentOptions.map((option) => _buildIntentOption(
                option: option,
                isSelected: controller.intent == option['value'],
                onTap: () => controller.updateIntent(option['value']),
              )),
              const SizedBox(height: 40),
              
              // Continue button
              Center(
                child: CustomButton(
                  text: 'Continue',
                  onTap: _isStepValid(controller) ? widget.onNext : null,
                  color: primaryColor,
                  active: _isStepValid(controller),
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
      style: const TextStyle(
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Colors.grey.shade100,
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? primaryColor : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: primaryColor,
                size: 24,
              ),
          ],
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
