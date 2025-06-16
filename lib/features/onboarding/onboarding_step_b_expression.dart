import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../user/controllers/onboarding_controller.dart';
import '../../common/constants/colors.dart';
import '../../common/widgets/custom_button.dart';

/// Second step of onboarding focusing on self-expression.
///
/// This screen collects information about the user's music preferences,
/// fashion style, and weekend activities.
class OnboardingStepBExpression extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final Color backgroundColor;

  const OnboardingStepBExpression({
    Key? key,
    required this.onNext,
    required this.onBack,
    this.backgroundColor = const Color(0xFFFDF6EC),
  }) : super(key: key);

  @override
  State<OnboardingStepBExpression> createState() => _OnboardingStepBExpressionState();
}

class _OnboardingStepBExpressionState extends State<OnboardingStepBExpression> {
  // Music genres popular in Nigeria and Africa
  final List<String> _musicGenres = [
    'Afrobeats', 'Highlife', 'Juju', 'Fuji', 'Gospel',
    'Hip Hop', 'R&B', 'Amapiano', 'Traditional', 'Jazz',
    'Reggae', 'Dancehall', 'Alte', 'Afro-fusion'
  ];
  
  // Fashion styles
  final List<String> _fashionStyles = [
    'Traditional', 'Modern African', 'Western', 'Afro-fusion',
    'Minimalist', 'Vintage', 'Streetwear', 'Formal', 'Casual'
  ];
  
  // Weekend activities
  final List<String> _weekendVibes = [
    'Outdoor adventures', 'Cultural events', 'Quiet time at home',
    'Nightlife & clubbing', 'Family gatherings', 'Religious activities',
    'Sports & fitness', 'Beach outings', 'Shopping', 'Movies & entertainment'
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
                'Your Style & Expression',
                style: GoogleFonts.montserrat(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tell us about your preferences and how you express yourself.',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: Colors.brown.shade600,
                ),
              ),
              const SizedBox(height: 32),
              
              // Music genres
              _buildSectionTitle('What music moves you?'),
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
                children: _musicGenres.map((genre) {
                  final isSelected = controller.genres.contains(genre);
                  return FilterChip(
                    label: Text(genre),
                    selected: isSelected,
                    onSelected: (selected) {
                      List<String> updatedGenres = [...controller.genres];
                      if (selected) {
                        updatedGenres.add(genre);
                      } else {
                        updatedGenres.remove(genre);
                      }
                      controller.updateGenres(updatedGenres);
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
              
              // Fashion style
              _buildSectionTitle('What\'s your fashion style?'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.fashionStyle,
                    hint: const Text('Select your style'),
                    isExpanded: true,
                    items: _fashionStyles.map((style) {
                      return DropdownMenuItem<String>(
                        value: style,
                        child: Text(style),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        controller.updateFashionStyle(value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Weekend vibe
              _buildSectionTitle('What\'s your ideal weekend like?'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.weekendVibe,
                    hint: const Text('Select your weekend vibe'),
                    isExpanded: true,
                    items: _weekendVibes.map((vibe) {
                      return DropdownMenuItem<String>(
                        value: vibe,
                        child: Text(vibe),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        controller.updateWeekendVibe(value);
                      }
                    },
                  ),
                ),
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
                      text: 'Continue',
                      onTap: _isStepValid(controller) ? widget.onNext : () {},
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
  
  /// Validates if all required fields are filled
  bool _isStepValid(OnboardingController controller) {
    return controller.genres.isNotEmpty &&
           controller.fashionStyle != null &&
           controller.weekendVibe != null;
  }
}
