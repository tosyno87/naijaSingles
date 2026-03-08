import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/constants/app_colors.dart';
import 'bloc/onboarding_bloc.dart';
import 'bloc/onboarding_data.dart';

/// Third step of onboarding focusing on personal values.
///
/// This screen collects information about what matters to the user
/// in a partner and their dealbreakers.
class OnboardingStepCValues extends StatefulWidget {
  const OnboardingStepCValues({
    required this.onBack,
    required this.finishOnboarding,
    super.key,
    this.backgroundColor = AppColors.backgroundColor,
  });
  final VoidCallback onBack;
  final VoidCallback finishOnboarding;
  final Color backgroundColor;

  @override
  State<OnboardingStepCValues> createState() => _OnboardingStepCValuesState();
}

class _OnboardingStepCValuesState extends State<OnboardingStepCValues>
    with SingleTickerProviderStateMixin {
  // Keys for accessibility and testing
  final GlobalKey _valuesKey = GlobalKey();
  final GlobalKey _dealbreakersKey = GlobalKey();
  final GlobalKey _finishButtonKey = GlobalKey();

  // State variables for animation and validation feedback
  bool _showValidationMessage = false;
  late AnimationController _animationController;

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
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<OnboardingBloc, OnboardingState>(
        builder: (context, state) {
          final data = state.data ?? OnboardingData();

          // Deep green color for selected elements
          const Color deepGreen = Color(0xFF008037);

          return Scaffold(
            backgroundColor: widget.backgroundColor,
            body: SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                            'Step 3 of 3',
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
                      'Your Values & Preferences',
                      style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown.shade800,
                      ),
                      semanticsLabel:
                          'Your Values and Preferences, Step 3 of 3',
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tell us what matters most to you in relationships.',
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        color: Colors.brown.shade600,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Partner values card
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
                          _buildSectionTitle('What matters most in a partner?'),
                          const SizedBox(height: 8),
                          Text(
                            'Select at least 3 values that are important to you',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Semantics(
                            label: 'Partner values selection',
                            hint:
                                'Select at least 3 values that matter to you in a partner',
                            child: Wrap(
                              key: _valuesKey,
                              spacing: 8,
                              runSpacing: 12,
                              children: _partnerValues.map((value) {
                                final isSelected =
                                    data.values.contains(value['id']);
                                return _buildValueCheckbox(
                                  label: value['label'],
                                  isSelected: isSelected,
                                  onChanged: (selected) {
                                    final List<String> updatedValues = [
                                      ...data.values,
                                    ];
                                    if (selected) {
                                      updatedValues.add(value['id']);
                                    } else {
                                      updatedValues.remove(value['id']);
                                    }
                                    context.read<OnboardingBloc>().add(
                                          OnboardingValuesUpdated(
                                              updatedValues,),
                                        );
                                    unawaited(HapticFeedback.selectionClick());
                                  },
                                  deepGreen: deepGreen,
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Dealbreakers card
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
                          _buildSectionTitle('Any dealbreakers? (Optional)'),
                          const SizedBox(height: 8),
                          Text(
                            'Select any absolute dealbreakers for you',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Semantics(
                            label: 'Dealbreakers selection',
                            hint:
                                'Select any absolute dealbreakers for you in a relationship',
                            child: Wrap(
                              key: _dealbreakersKey,
                              spacing: 8,
                              runSpacing: 12,
                              children: _dealbreakers.map((dealbreaker) {
                                final isSelected = data.dealbreakers
                                    .contains(dealbreaker['id']);
                                return _buildValueCheckbox(
                                  label: dealbreaker['label'],
                                  isSelected: isSelected,
                                  onChanged: (selected) {
                                    final List<String> updatedDealbreakers = [
                                      ...data.dealbreakers,
                                    ];
                                    if (selected) {
                                      updatedDealbreakers
                                          .add(dealbreaker['id']);
                                    } else {
                                      updatedDealbreakers
                                          .remove(dealbreaker['id']);
                                    }
                                    context.read<OnboardingBloc>().add(
                                          OnboardingDealbreakersUpdated(
                                            updatedDealbreakers,
                                          ),
                                        );
                                    unawaited(HapticFeedback.selectionClick());
                                  },
                                  deepGreen: deepGreen,
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Validation message
                    AnimatedOpacity(
                      opacity: _showValidationMessage ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: _showValidationMessage
                          ? Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Please select at least 3 values that matter to you',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 14,
                                        color: Colors.amber[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    // Navigation labelLarges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back labelLarge
                        TextButton.icon(
                          onPressed: () {
                            unawaited(HapticFeedback.lightImpact());
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

                        // Finish labelLarge
                        SizedBox(
                          width: 150,
                          height: 56,
                          child: ElevatedButton(
                            key: _finishButtonKey,
                            onPressed: _isStepValid(data)
                                ? () {
                                    unawaited(HapticFeedback.mediumImpact());
                                    unawaited(
                                      Navigator.pushReplacementNamed(
                                        context,
                                        '/dating',
                                      ),
                                    );
                                  }
                                : () {
                                    setState(() {
                                      _showValidationMessage = true;
                                      // Hide the message after 3 seconds
                                      Future.delayed(const Duration(seconds: 3),
                                          () {
                                        if (mounted) {
                                          setState(() {
                                            _showValidationMessage = false;
                                          });
                                        }
                                      });
                                    });
                                    unawaited(HapticFeedback.vibrate());
                                  },
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
                              'Finish',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
        },
      );

  /// Builds a section title with consistent styling
  Widget _buildSectionTitle(String title) => Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      );

  /// Builds a custom checkbox for values selection
  Widget _buildValueCheckbox({
    required String label,
    required bool isSelected,
    required ValueChanged<bool> onChanged,
    required Color deepGreen,
  }) =>
      LayoutBuilder(
        builder: (context, constraints) => AnimatedScale(
          scale: isSelected ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                onChanged(!isSelected);
                _animationController.reset();
                unawaited(_animationController.forward());
              },
              borderRadius: BorderRadius.circular(8),
              splashColor: deepGreen.withValues(alpha: 0.1),
              highlightColor: deepGreen.withValues(alpha: 0.05),
              child: Container(
                width: constraints.maxWidth / 2 - 8,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? deepGreen.withValues(alpha: 0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? deepGreen : Colors.grey[400]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected ? deepGreen : Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: isSelected
                            ? null
                            : Border.all(color: Colors.grey[400]!),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 18,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: isSelected ? deepGreen : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  /// Validates if all required fields are filled
  bool _isStepValid(OnboardingData data) => data.values.length >= 3;
}
