import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/routes/route_name.dart';
import '../../controllers/onboarding_controller.dart';

/// A multi-step onboarding flow with cultural focus for NaijaSingles app.
///
/// This widget provides a 3-screen onboarding experience using PageView
/// with a shared OnboardingController to maintain state across screens.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Warm Afrocentric background color
  static const Color afrocentricBackground = Color(0xFFFDF6EC);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Navigate to the next page or finish onboarding if on the last page
  void onNext() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // On the last page, complete onboarding
      final controller =
          Provider.of<OnboardingController>(context, listen: false);

      // Save data and navigate to the next screen in the app flow
      Navigator.pushReplacementNamed(
        context,
        RouteName.userNameScreen,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<OnboardingController>(context);

    return Scaffold(
      backgroundColor: afrocentricBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: List.generate(
                  3,
                  (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: _currentPage >= index
                            ? primaryColor
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
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
                  // Screen 1: Cultural Identity
                  _buildCulturalIdentityScreen(controller),

                  // Screen 2: Relationship Intent
                  _buildRelationshipIntentScreen(controller),

                  // Screen 3: Lifestyle & Values
                  _buildLifestyleValuesScreen(controller),
                ],
              ),
            ),

            // Navigation labelLarges
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back labelLarge (hidden on first page)
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text(
                        'Back',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 16,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 80),

                  // Next/Finish labelLarge
                  ElevatedButton(
                    onPressed: _isCurrentPageValid(controller) ? onNext : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      _currentPage < 2 ? 'Next' : 'Finish',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Check if the current page has valid data to proceed
  bool _isCurrentPageValid(OnboardingController controller) {
    switch (_currentPage) {
      case 0:
        // Cultural identity validation
        return controller.tribe != null ||
            controller.languages.isNotEmpty ||
            controller.nationality != null;
      case 1:
        // Relationship intent validation
        return controller.intent != null;
      case 2:
        // Lifestyle and values validation
        return controller.genres.isNotEmpty ||
            controller.fashionStyle != null ||
            controller.weekendVibe != null ||
            controller.values.isNotEmpty;
      default:
        return false;
    }
  }

  /// Build the cultural identity screen (Page 1)
  Widget _buildCulturalIdentityScreen(OnboardingController controller) =>
      SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Your Cultural Identity',
              style: GoogleFonts.montserrat(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tell us about your cultural background to help us connect you with like-minded people.',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.brown.shade600,
              ),
            ),
            const SizedBox(height: 40),

            // Tribe selection
            _buildInputLabel('Tribe or Ethnic Group'),
            _buildDropdownField<String>(
              value: controller.tribe,
              items: const [
                'Yoruba',
                'Igbo',
                'Hausa',
                'Fulani',
                'Ijaw',
                'Kanuri',
                'Ibibio',
                'Tiv',
                'Other',
              ],
              onChanged: (value) {
                if (value != null) controller.updateTribe(value);
              },
              hint: 'Select your tribe',
            ),
            const SizedBox(height: 24),

            // Languages selection
            _buildInputLabel('Languages Spoken'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'English',
                'Yoruba',
                'Igbo',
                'Hausa',
                'Pidgin',
                'French',
                'Arabic',
                'Other',
              ]
                  .map(
                    (language) => _buildSelectionChip(
                      label: language,
                      isSelected: controller.languages.contains(language),
                      onSelected: (selected) {
                        final List<String> updatedLanguages = [
                          ...controller.languages,
                        ];
                        if (selected) {
                          updatedLanguages.add(language);
                        } else {
                          updatedLanguages.remove(language);
                        }
                        controller.updateLanguages(updatedLanguages);
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),

            // Nationality selection
            _buildInputLabel('Nationality'),
            _buildDropdownField<String>(
              value: controller.nationality,
              items: const [
                'Nigerian',
                'Nigerian Diaspora',
                'Other African',
                'Other',
              ],
              onChanged: (value) {
                if (value != null) {
                  final bool isDiaspora = value == 'Nigerian Diaspora';
                  controller.updateNationality(value, isDiaspora);
                }
              },
              hint: 'Select your nationality',
            ),
            const SizedBox(height: 40),
          ],
        ),
      );

  /// Build the relationship intent screen (Page 2)
  Widget _buildRelationshipIntentScreen(OnboardingController controller) =>
      SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'What Are You Looking For?',
              style: GoogleFonts.montserrat(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Let us know what kind of connections you want to make.',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.brown.shade600,
              ),
            ),
            const SizedBox(height: 40),

            // Intent selection cards
            _buildIntentCard(
              controller: controller,
              title: 'Dating',
              description: 'I want to find a romantic partner',
              icon: Icons.favorite,
              intentValue: 'Dating',
            ),
            const SizedBox(height: 16),

            _buildIntentCard(
              controller: controller,
              title: 'Friendship',
              description: 'I want to make new friends',
              icon: Icons.people,
              intentValue: 'Friendship',
            ),
            const SizedBox(height: 16),

            _buildIntentCard(
              controller: controller,
              title: 'Community',
              description: 'I want to connect with my cultural community',
              icon: Icons.diversity_3,
              intentValue: 'Community',
            ),
            const SizedBox(height: 40),
          ],
        ),
      );

  /// Build the lifestyle and values screen (Page 3)
  Widget _buildLifestyleValuesScreen(OnboardingController controller) =>
      SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Your Lifestyle & Values',
              style: GoogleFonts.montserrat(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tell us about your preferences and what matters to you.',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.brown.shade600,
              ),
            ),
            const SizedBox(height: 40),

            // Music genres
            _buildInputLabel('Favorite Music Genres'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Afrobeats',
                'Highlife',
                'Gospel',
                'Hip Hop',
                'R&B',
                'Amapiano',
                'Fuji',
                'Juju',
                'Traditional',
              ]
                  .map(
                    (genre) => _buildSelectionChip(
                      label: genre,
                      isSelected: controller.genres.contains(genre),
                      onSelected: (selected) {
                        final List<String> updatedGenres = [
                          ...controller.genres
                        ];
                        if (selected) {
                          updatedGenres.add(genre);
                        } else {
                          updatedGenres.remove(genre);
                        }
                        controller.updateGenres(updatedGenres);
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),

            // Fashion style
            _buildInputLabel('Your Fashion Style'),
            _buildDropdownField<String>(
              value: controller.fashionStyle,
              items: const [
                'Traditional',
                'Modern African',
                'Western',
                'Afro-fusion',
                'Minimalist',
                'Vintage',
                'Other',
              ],
              onChanged: (value) {
                if (value != null) controller.updateFashionStyle(value);
              },
              hint: 'Select your style',
            ),
            const SizedBox(height: 24),

            // Weekend vibe
            _buildInputLabel('Your Ideal Weekend'),
            _buildDropdownField<String>(
              value: controller.weekendVibe,
              items: const [
                'Outdoor adventures',
                'Cultural events',
                'Quiet time at home',
                'Nightlife & clubbing',
                'Family gatherings',
                'Religious activities',
                'Sports & fitness',
              ],
              onChanged: (value) {
                if (value != null) controller.updateWeekendVibe(value);
              },
              hint: 'Select your weekend vibe',
            ),
            const SizedBox(height: 24),

            // Values
            _buildInputLabel('Important Values to You'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Family',
                'Tradition',
                'Religion',
                'Education',
                'Career',
                'Community',
                'Independence',
                'Creativity',
              ]
                  .map(
                    (value) => _buildSelectionChip(
                      label: value,
                      isSelected: controller.values.contains(value),
                      onSelected: (selected) {
                        final List<String> updatedValues = [
                          ...controller.values
                        ];
                        if (selected) {
                          updatedValues.add(value);
                        } else {
                          updatedValues.remove(value);
                        }
                        controller.updateValues(updatedValues);
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      );

  /// Build a label for input fields
  Widget _buildInputLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      );

  /// Build a dropdown field
  Widget _buildDropdownField<T>({
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String hint,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint),
          isExpanded: true,
          underline: const SizedBox(),
          items: items
              .map(
                (T item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(item.toString()),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      );

  /// Build a selection chip for multi-select options
  Widget _buildSelectionChip({
    required String label,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
  }) =>
      FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: onSelected,
        backgroundColor: Colors.white,
        selectedColor: primaryColor.withValues(alpha: 0.2),
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

  /// Build an intent selection card
  Widget _buildIntentCard({
    required OnboardingController controller,
    required String title,
    required String description,
    required IconData icon,
    required String intentValue,
  }) {
    final isSelected = controller.intent == intentValue;

    return GestureDetector(
      onTap: () => controller.updateIntent(intentValue),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected ? primaryColor.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: isSelected ? 2.0 : 1.0,
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
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? primaryColor : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
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
}
