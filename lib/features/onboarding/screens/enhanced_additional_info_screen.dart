import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/onboarding_bloc.dart';
import '../onboarding_theme.dart';
import '../widgets/afropeep_height_dropdown.dart';

class EnhancedAdditionalInfoScreen extends StatefulWidget {
  const EnhancedAdditionalInfoScreen({super.key});

  @override
  State<EnhancedAdditionalInfoScreen> createState() =>
      _EnhancedAdditionalInfoScreenState();
}

class _EnhancedAdditionalInfoScreenState
    extends State<EnhancedAdditionalInfoScreen> {
  String _heightFtIn = HeightData.defaultHeightFtIn;
  int _heightCm = HeightData.defaultHeightCm;
  String _platformPurpose = 'Dating & Romance';
  String _relationshipIntent = '';

  final List<Map<String, dynamic>> _platformPurposeOptions = [
    {
      'label': 'Dating & Romance',
      'value': 'Dating & Romance',
      'icon': Icons.favorite,
      'color': Colors.red.shade400,
    },
    {
      'label': 'Friendship & Social',
      'value': 'Friendship & Social',
      'icon': Icons.people,
      'color': Colors.blue.shade400,
    },
    {
      'label': 'Professional Networking',
      'value': 'Professional Networking',
      'icon': Icons.business_center,
      'color': Colors.green.shade400,
    },
    {
      'label': 'All of the Above',
      'value': 'All of the Above',
      'icon': Icons.explore,
      'color': Colors.purple.shade400,
    },
  ];

  final List<Map<String, dynamic>> _relationshipIntentOptions = [
    {
      'label': 'Looking for marriage',
      'value': 'Marriage',
      'icon': Icons.church,
      'color': Colors.purple.shade400,
    },
    {
      'label': 'Serious relationship',
      'value': 'Serious',
      'icon': Icons.favorite,
      'color': Colors.red.shade400,
    },
    {
      'label': 'Long-term relationship',
      'value': 'Long-term',
      'icon': Icons.favorite_border,
      'color': Colors.pink.shade400,
    },
    {
      'label': 'Dating to see where it goes',
      'value': 'Open',
      'icon': Icons.explore,
      'color': Colors.green.shade400,
    },
    {
      'label': 'Casual dating',
      'value': 'Casual',
      'icon': Icons.coffee_outlined,
      'color': Colors.orange.shade400,
    },
    {
      'label': 'Not sure yet',
      'value': 'Not sure yet',
      'icon': Icons.help_outline,
      'color': Colors.grey.shade500,
    },
  ];

  @override
  void initState() {
    super.initState();
    final data = context.read<OnboardingBloc>().state.data;

    if (data != null && data.height > 0) {
      _heightCm = data.height.round();
      final String? ftIn = HeightData.getFtInFromCm(_heightCm);
      if (ftIn != null) {
        _heightFtIn = ftIn;
      }
    }

    if (data == null) return;

    String displayValue;
    switch (data.lookingFor) {
      case 'Dating':
        displayValue = 'Dating & Romance';
      case 'Friendship':
        displayValue = 'Friendship & Social';
      case 'Networking':
        displayValue = 'Professional Networking';
      case 'Mixed':
        displayValue = 'All of the Above';
      default:
        displayValue = 'Dating & Romance';
    }
    _platformPurpose = displayValue;
    _relationshipIntent = data.relationshipIntent;
  }

  @override
  Widget build(BuildContext context) => OnboardingTheme.constrainedContent(
        child: SingleChildScrollView(
          padding: OnboardingTheme.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tell us more about you', style: OnboardingTheme.titleStyle),
              const SizedBox(height: OnboardingTheme.titleToSubtitle),
              Text(
                'Help us create better matches for you',
                style: OnboardingTheme.subtitleStyle,
              ),

              const SizedBox(height: 16),

              // Optional step indicator
              Container(
                padding: const EdgeInsets.all(OnboardingTheme.fieldContentPadding),
                decoration: BoxDecoration(
                  color: OnboardingTheme.primaryGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(OnboardingTheme.fieldRadius),
                  border: Border.all(
                    color: OnboardingTheme.primaryGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: OnboardingTheme.primaryGreen,
                      size: OnboardingTheme.fieldIconSize,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This step is optional. You can complete it later in your profile settings.',
                        style: OnboardingTheme.helperStyle.copyWith(
                          color: OnboardingTheme.sectionLabelColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: OnboardingTheme.subtitleToField),

              // 1. Height
              Text('Height', style: OnboardingTheme.sectionLabelStyle),
              const SizedBox(height: 4),
              Text(
                'Height preferences matter in dating',
                style: OnboardingTheme.helperStyle,
              ),
              const SizedBox(height: OnboardingTheme.labelToField),
              AfropeepHeightDropdown(
                initialHeightFtIn: _heightFtIn,
                initialHeightCm: _heightCm,
                onChanged: (heightFtIn, heightCm) {
                  setState(() {
                    _heightFtIn = heightFtIn;
                    _heightCm = heightCm;
                  });
                  context.read<OnboardingBloc>().add(
                        OnboardingHeightFromDropdownUpdated(
                          heightFtIn,
                          heightCm,
                        ),
                      );
                },
              ),

              const SizedBox(height: OnboardingTheme.fieldToSection),

              // 2. Looking For
              Text(
                'What brings you to Afropeep?',
                style: OnboardingTheme.sectionLabelStyle,
              ),
              const SizedBox(height: 4),
              Text(
                'Help us understand how to serve you better',
                style: OnboardingTheme.helperStyle,
              ),
              const SizedBox(height: OnboardingTheme.labelToField),
              _buildDropdown(
                value: _platformPurpose,
                options: _platformPurposeOptions,
                hint: 'Select your purpose',
                onChanged: (value) {
                  setState(() {
                    _platformPurpose = value;
                  });
                  String controllerValue;
                  switch (value) {
                    case 'Dating & Romance':
                      controllerValue = 'Dating';
                    case 'Friendship & Social':
                      controllerValue = 'Friendship';
                    case 'Professional Networking':
                      controllerValue = 'Networking';
                    case 'All of the Above':
                      controllerValue = 'Mixed';
                    default:
                      controllerValue = 'Dating';
                  }
                  context.read<OnboardingBloc>().add(
                        OnboardingLookingForUpdated(controllerValue),
                      );
                },
              ),

              const SizedBox(height: OnboardingTheme.fieldToSection),

              // 3. Relationship Goals
              Text(
                'Relationship goals',
                style: OnboardingTheme.sectionLabelStyle,
              ),
              const SizedBox(height: 4),
              Text(
                'What are you hoping to find?',
                style: OnboardingTheme.helperStyle,
              ),
              const SizedBox(height: OnboardingTheme.labelToField),
              _buildDropdown(
                value: _relationshipIntent,
                options: _relationshipIntentOptions,
                hint: 'Select your relationship goals',
                onChanged: (value) {
                  setState(() {
                    _relationshipIntent = value;
                  });
                  context.read<OnboardingBloc>().add(
                        OnboardingRelationshipIntentUpdated(value),
                      );
                },
              ),

              const SizedBox(height: OnboardingTheme.fieldToBottom),
            ],
          ),
        ),
      );

  Widget _buildDropdown({
    required String value,
    required List<Map<String, dynamic>> options,
    required Function(String) onChanged,
    required String hint,
  }) {
    final validValue =
        value.isNotEmpty && options.any((option) => option['value'] == value)
            ? value
            : null;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: OnboardingTheme.fieldHeight,
      ),
      decoration: OnboardingTheme.dropdownDecoration(
        hasFocus: validValue != null,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validValue,
          isExpanded: true,
          hint: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: OnboardingTheme.fieldContentPadding,
            ),
            child: Text(
              hint,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: OnboardingTheme.subtitleColor,
              ),
            ),
          ),
          icon: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(
              Icons.keyboard_arrow_down,
              color: OnboardingTheme.primaryGreen,
              size: OnboardingTheme.fieldIconSize,
            ),
          ),
          dropdownColor: OnboardingTheme.background,
          borderRadius: BorderRadius.circular(OnboardingTheme.fieldRadius),
          menuMaxHeight: MediaQuery.of(context).size.height * 0.4,
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option['value'],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: OnboardingTheme.fieldContentPadding,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        if (option['icon'] != null) ...[
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: (option['color'] as Color?)
                                      ?.withValues(alpha: 0.15) ??
                                  Colors.grey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              option['icon'],
                              color: option['color'] ?? Colors.grey,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            option['label'],
                            style: OnboardingTheme.fieldTextStyle.copyWith(
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
      ),
    );
  }
}
