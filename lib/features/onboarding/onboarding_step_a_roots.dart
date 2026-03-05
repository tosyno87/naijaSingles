import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/constants/app_colors.dart';
import '../../../common/utils/app_logger.dart';
import 'bloc/onboarding_bloc.dart';
import 'bloc/onboarding_data.dart';

/// First step of onboarding focusing on cultural roots.
///
/// This screen collects information about the user's tribe,
/// languages spoken, and their intent for using the app.
class OnboardingStepARoots extends StatefulWidget {
  const OnboardingStepARoots({
    required this.onNext,
    super.key,
    this.backgroundColor = AppColors.backgroundColor,
  });
  final VoidCallback onNext;
  final Color backgroundColor;

  @override
  State<OnboardingStepARoots> createState() => _OnboardingStepARootsState();
}

class _OnboardingStepARootsState extends State<OnboardingStepARoots> {
  // Keys for accessibility and testing
  final GlobalKey<FormFieldState> _tribeFieldKey = GlobalKey<FormFieldState>();
  final GlobalKey _languagesKey = GlobalKey();
  final GlobalKey _continueButtonKey = GlobalKey();

  final TextEditingController _tribeController = TextEditingController();

  // State for dropdown and custom tribe entry
  String? _selectedTribe;
  bool _isCustomTribe = false;

  // State for language selection
  String? _selectedLanguage;
  bool _isCustomLanguage = false;
  final TextEditingController _customLanguageController =
      TextEditingController();

  // List of African tribes for dropdown
  final List<String> _africanTribes = [
    'Yoruba',
    'Igbo',
    'Hausa',
    'Amhara',
    'Tigray',
    'Oromo',
    'Fulani',
    'Zulu',
    'Xhosa',
    'Shona',
    'Twi',
    'Ewe',
    'Wolof',
    'Somali',
    'Berber',
    'Tutsi',
    'Akan',
    'Baganda',
    'Other',
  ];

  // List of languages for dropdown
  final List<String> _availableLanguages = [
    'English',
    'Yoruba',
    'Igbo',
    'Hausa',
    'Pidgin',
    'French',
    'Arabic',
    'Swahili',
    'Amharic',
    'Zulu',
    'Xhosa',
    'Twi',
    'Wolof',
    'Somali',
    'Portuguese',
    'Spanish',
    'Other',
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
  void initState() {
    super.initState();

    // Add listener to text controller to rebuild UI when text changes
    _tribeController.addListener(() {
      AppLogger.debug("Tribe text changed: '${_tribeController.text}'");
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = context.read<OnboardingBloc>().state.data;
      if (data != null && data.tribe.isNotEmpty) {
        AppLogger.debug("Setting initial tribe: '${data.tribe}'");
        _tribeController.text = data.tribe;

        if (_africanTribes.contains(data.tribe)) {
          setState(() {
            _selectedTribe = data.tribe;
            _isCustomTribe = false;
          });
        } else {
          // If not in the list, set to "Other" and enable custom entry
          setState(() {
            _selectedTribe = 'Other';
            _isCustomTribe = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _tribeController.dispose();
    _customLanguageController.dispose();
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
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: deepGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Step 1 of 3',
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

                    // Header section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Cultural Roots',
                          style: GoogleFonts.montserrat(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown.shade800,
                          ),
                          semanticsLabel: 'Your Cultural Roots, Step 1 of 3',
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tell us about your cultural background to help us connect you with like-minded people.',
                          style: GoogleFonts.montserrat(
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
                          // Tribe input
                          _buildSectionTitle(
                              'What is your tribe or ethnic group?'),
                          const SizedBox(height: 12),

                          // Dropdown for tribe selection
                          DropdownButtonFormField<String>(
                            key: _tribeFieldKey,
                            initialValue: _selectedTribe,
                            onChanged: (value) {
                              if (value == 'Other') {
                                setState(() {
                                  _selectedTribe = value;
                                  _isCustomTribe = true;
                                  // Clear the text field for custom entry
                                  _tribeController.text = '';
                                });
                              } else {
                                setState(() {
                                  _selectedTribe = value;
                                  _isCustomTribe = false;
                                  _tribeController.text = value ?? '';
                                  context
                                      .read<OnboardingBloc>()
                                      .add(OnboardingTribeUpdated(value ?? ''));
                                });
                              }
                            },
                            items: _africanTribes
                                .map(
                                  (tribe) => DropdownMenuItem(
                                    value: tribe,
                                    child: Text(
                                      tribe,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            decoration: InputDecoration(
                              labelText: 'Tribe or Ethnic Group',
                              labelStyle: GoogleFonts.montserrat(
                                color: deepGreen,
                                fontSize: 16,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[400]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[400]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: deepGreen, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            dropdownColor: Colors.white,
                            icon: const Icon(Icons.arrow_drop_down,
                                color: deepGreen),
                            isExpanded: true,
                          ),

                          // Manual entry field if "Other" is selected
                          if (_isCustomTribe) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _tribeController,
                              decoration: InputDecoration(
                                labelText: 'Enter your tribe',
                                labelStyle: GoogleFonts.montserrat(
                                  color: deepGreen,
                                  fontSize: 16,
                                ),
                                hintText: 'Type your tribe or ethnic group',
                                hintStyle: GoogleFonts.montserrat(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[400]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[400]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: deepGreen, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              onChanged: (value) {
                                context
                                    .read<OnboardingBloc>()
                                    .add(OnboardingTribeUpdated(value.trim()));
                              },
                            ),
                          ],
                          const SizedBox(height: 32),

                          // Languages selection
                          _buildSectionTitle('Which languages do you speak?'),
                          const SizedBox(height: 8),
                          Text(
                            'Select all languages that you speak',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Display selected languages as chips
                          if (data.languages.isNotEmpty) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: data.languages
                                  .map(
                                    (language) => Chip(
                                      label: Text(
                                        language,
                                        style: GoogleFonts.montserrat(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      backgroundColor: deepGreen,
                                      deleteIconColor: Colors.white,
                                      onDeleted: () {
                                        setState(() {
                                          final List<String> updatedLanguages =
                                              [
                                            ...data.languages,
                                          ];
                                          updatedLanguages.remove(language);
                                          context.read<OnboardingBloc>().add(
                                                OnboardingLanguagesUpdated(
                                                    updatedLanguages),
                                              );
                                        });
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Dropdown for language selection
                          DropdownButtonFormField<String>(
                            key: _languagesKey,
                            initialValue: _selectedLanguage,
                            hint: Text(
                              'Select a language',
                              style: GoogleFonts.montserrat(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            onChanged: (value) {
                              if (value == 'Other') {
                                setState(() {
                                  _selectedLanguage = value;
                                  _isCustomLanguage = true;
                                });
                              } else if (value != null) {
                                setState(() {
                                  _selectedLanguage = value;
                                  _isCustomLanguage = false;

                                  // Add to languages list if not already there
                                  if (!data.languages.contains(value)) {
                                    final List<String> updatedLanguages = [
                                      ...data.languages,
                                    ];
                                    updatedLanguages.add(value);
                                    context.read<OnboardingBloc>().add(
                                        OnboardingLanguagesUpdated(
                                            updatedLanguages));

                                    // Reset dropdown after selection
                                    _selectedLanguage = null;
                                  }
                                });
                              }
                            },
                            items: _availableLanguages
                                .map(
                                  (language) => DropdownMenuItem(
                                    value: language,
                                    child: Text(
                                      language,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            decoration: InputDecoration(
                              labelText: 'Add Language',
                              labelStyle: GoogleFonts.montserrat(
                                color: deepGreen,
                                fontSize: 16,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[400]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[400]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: deepGreen, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            dropdownColor: Colors.white,
                            icon: const Icon(Icons.arrow_drop_down,
                                color: deepGreen),
                            isExpanded: true,
                          ),

                          // Manual entry field if "Other" is selected
                          if (_isCustomLanguage) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _customLanguageController,
                                    decoration: InputDecoration(
                                      labelText: 'Enter language',
                                      labelStyle: GoogleFonts.montserrat(
                                        color: deepGreen,
                                        fontSize: 16,
                                      ),
                                      hintText: 'Type a language you speak',
                                      hintStyle: GoogleFonts.montserrat(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Colors.grey[400]!),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Colors.grey[400]!),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: deepGreen,
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                    ),
                                    style: GoogleFonts.montserrat(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () {
                                    final customLanguage =
                                        _customLanguageController.text.trim();
                                    if (customLanguage.isNotEmpty) {
                                      setState(() {
                                        // Add custom language to the list
                                        if (!data.languages
                                            .contains(customLanguage)) {
                                          final List<String> updatedLanguages =
                                              [
                                            ...data.languages,
                                          ];
                                          updatedLanguages.add(customLanguage);
                                          context.read<OnboardingBloc>().add(
                                                OnboardingLanguagesUpdated(
                                                    updatedLanguages),
                                              );
                                        }

                                        // Reset custom language state
                                        _customLanguageController.clear();
                                        _isCustomLanguage = false;
                                        _selectedLanguage = null;
                                      });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: deepGreen,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                  ),
                                  child: Text(
                                    'Add',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
                          _buildSectionTitle('What are you looking for?'),
                          const SizedBox(height: 16),
                          ..._intentOptions.map(
                            (option) => _buildIntentOption(
                              option: option,
                              isSelected: data.intent == option['value'],
                              onTap: () => context.read<OnboardingBloc>().add(
                                  OnboardingIntentUpdated(option['value'])),
                              deepGreen: deepGreen,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Continue labelLarge
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          key: _continueButtonKey,
                          onPressed: _isStepValid(data)
                              ? () {
                                  unawaited(HapticFeedback.mediumImpact());
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

  /// Builds an intent option card with icon, title and description
  Widget _buildIntentOption({
    required Map<String, dynamic> option,
    required bool isSelected,
    required VoidCallback onTap,
    required Color deepGreen,
  }) =>
      Semantics(
        button: true,
        label: '${option['title']} option',
        hint: option['description'],
        selected: isSelected,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              onTap();
              unawaited(HapticFeedback.selectionClick());
            },
            borderRadius: BorderRadius.circular(12),
            splashColor: deepGreen.withValues(alpha: 0.1),
            highlightColor: deepGreen.withValues(alpha: 0.05),
            child: Container(
              constraints: const BoxConstraints(minHeight: 90),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? deepGreen.withValues(alpha: 0.1)
                    : Colors.white,
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
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? deepGreen : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          option['description'],
                          style: GoogleFonts.montserrat(
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

  /// Validates if all required fields are filled
  bool _isStepValid(OnboardingData data) {
    bool isTribeValid = _selectedTribe != null;
    if (_selectedTribe == 'Other') {
      isTribeValid = _tribeController.text.trim().isNotEmpty;
    }
    return isTribeValid && data.languages.isNotEmpty && data.intent != null;
  }
}
