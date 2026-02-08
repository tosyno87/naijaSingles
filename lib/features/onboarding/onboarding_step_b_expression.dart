import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/constants/app_colors.dart';

import 'bloc/onboarding_bloc.dart';
import 'bloc/onboarding_data.dart';
import 'shared_styles.dart';

/// Second step of onboarding focusing on self-expression.
///
/// This screen collects information about the user's music preferences,
/// fashion style, and weekend activities.
class OnboardingStepBExpression extends StatefulWidget {
  const OnboardingStepBExpression({
    required this.onNext,
    required this.onBack,
    super.key,
    this.backgroundColor = AppColors.backgroundColor,
  });
  final VoidCallback onNext;
  final VoidCallback onBack;
  final Color backgroundColor;

  @override
  State<OnboardingStepBExpression> createState() =>
      _OnboardingStepBExpressionState();
}

class _OnboardingStepBExpressionState extends State<OnboardingStepBExpression>
    with SingleTickerProviderStateMixin {
  // Keys for accessibility and testing
  final GlobalKey _musicKey = GlobalKey();
  final GlobalKey _fashionKey = GlobalKey();
  final GlobalKey _weekendKey = GlobalKey();
  final GlobalKey _continueButtonKey = GlobalKey();

  // Text controllers for text fields
  final TextEditingController _fashionController = TextEditingController();
  final TextEditingController _weekendController = TextEditingController();

  // Animation controller for chip selection
  late final AnimationController _animationController;

  // Music genres popular in Nigeria and Africa
  final List<String> _musicGenres = [
    'Afrobeats',
    'Highlife',
    'Juju',
    'Fuji',
    'Gospel',
    'Hip Hop',
    'R&B',
    'Amapiano',
    'Traditional',
    'Jazz',
    'Reggae',
    'Dancehall',
    'Alte',
    'Afro-fusion',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = context.read<OnboardingBloc>().state.data;
      if (data != null) {
        if (data.fashionStyle != null) {
          _fashionController.text = data.fashionStyle!;
        }
        if (data.weekendVibe != null) {
          _weekendController.text = data.weekendVibe!;
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fashionController.dispose();
    _weekendController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        final data = state.data ?? OnboardingData();

    // Deep green color for selected elements
    const Color deepGreen = Color(0xFF008037);

    // Calculate bottom padding based on keyboard visibility
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: 100.0 + keyboardPadding, // Extra padding for labelLarge
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress indicator
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: deepGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Step 2 of 3',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: deepGreen,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Header
                  Text(
                    'Your Style & Expression',
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade800,
                    ),
                    semanticsLabel: 'Your Style and Expression, Step 2 of 3',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tell us about your preferences and how you express yourself.',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      color: Colors.brown.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // New section title
                  Text(
                    'How do you express yourself?',
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade800,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Music genres card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.music_note,
                              color: deepGreen,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            _buildSectionTitle('What music moves you?'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select all that apply',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Semantics(
                          label: 'Music genre selection',
                          hint:
                              'Select one or more music genres that you enjoy',
                          child: Wrap(
                            key: _musicKey,
                            spacing: 8,
                            runSpacing: 12,
                            children: _musicGenres.map((genre) {
                              final isSelected =
                                  data.genres.contains(genre);
                              return FilterChip(
                                label: Text(
                                  genre,
                                  style: GoogleFonts.montserrat(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  final List<String> updatedGenres = [
                                    ...data.genres,
                                  ];
                                  if (selected) {
                                    updatedGenres.add(genre);
                                  } else {
                                    updatedGenres.remove(genre);
                                  }
                                  context.read<OnboardingBloc>().add(OnboardingGenresUpdated(updatedGenres));
                                  HapticFeedback.selectionClick();
                                },
                                backgroundColor: Colors.white,
                                selectedColor: deepGreen,
                                checkmarkColor: Colors.white,
                                showCheckmark: true,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected
                                        ? deepGreen
                                        : Colors.grey[400]!,
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

                  // Fashion style card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.style,
                              color: deepGreen,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            _buildSectionTitle('What\'s your fashion style?'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          key: _fashionKey,
                          controller: _fashionController,
                          textInputAction: TextInputAction.next,
                          style: GoogleFonts.montserrat(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Fashion Style',
                            hintText: 'e.g. Urban streetwear, Ankara, Casual',
                            hintStyle: GoogleFonts.montserrat(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            labelStyle: GoogleFonts.montserrat(
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
                              borderSide:
                                  const BorderSide(color: deepGreen, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          onChanged: (value) {
                            context.read<OnboardingBloc>().add(OnboardingFashionStyleUpdated(value.trim()));
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Weekend vibe card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.weekend,
                              color: deepGreen,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            _buildSectionTitle(
                              'What\'s your ideal weekend like?',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          key: _weekendKey,
                          controller: _weekendController,
                          textInputAction: TextInputAction.done,
                          style: GoogleFonts.montserrat(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Weekend Vibe',
                            hintText: 'e.g. Chill at home, beach day, concert',
                            hintStyle: GoogleFonts.montserrat(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            labelStyle: GoogleFonts.montserrat(
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
                              borderSide:
                                  const BorderSide(color: deepGreen, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          onChanged: (value) {
                            context.read<OnboardingBloc>().add(OnboardingWeekendVibeUpdated(value.trim()));
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),

            // Navigation bar at the bottom
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  bottom: 32 + keyboardPadding,
                  top: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back labelLarge at the bottom left
                    TextButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        widget.onBack();
                      },
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: Text(
                        'Back',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),

                    // Continue labelLarge
                    SizedBox(
                      width: 150,
                      height: 56,
                      child: ElevatedButton(
                        key: _continueButtonKey,
                        onPressed: _isStepValid(data)
                            ? () {
                                HapticFeedback.mediumImpact();
                                widget.onNext();
                              }
                            : null,
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
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  /// Builds a section title with consistent styling
  Widget _buildSectionTitle(String title) => Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      );

  /// Validates if all required fields are filled
  bool _isStepValid(OnboardingData data) =>
      data.genres.isNotEmpty &&
      data.fashionStyle != null &&
      data.fashionStyle!.trim().isNotEmpty &&
      data.weekendVibe != null &&
      data.weekendVibe!.trim().isNotEmpty;
}
