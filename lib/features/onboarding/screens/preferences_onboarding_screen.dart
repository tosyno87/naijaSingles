import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/onboarding_bloc.dart';
import '../onboarding_theme.dart';

class PreferencesOnboardingScreen extends StatefulWidget {
  const PreferencesOnboardingScreen({super.key});

  @override
  State<PreferencesOnboardingScreen> createState() =>
      _PreferencesOnboardingScreenState();
}

class _PreferencesOnboardingScreenState
    extends State<PreferencesOnboardingScreen> {
  String _selectedInterestedIn = '';

  @override
  void initState() {
    super.initState();
    final data = context.read<OnboardingBloc>().state.data;

    if (data != null) {
      _selectedInterestedIn = data.interestedIn;
    }
  }

  @override
  Widget build(BuildContext context) => OnboardingTheme.constrainedContent(
        child: SingleChildScrollView(
          padding: OnboardingTheme.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Who do you want to see?',
                style: OnboardingTheme.titleStyle,
              ),
              const SizedBox(height: OnboardingTheme.titleToSubtitle),
              Text(
                'You can change this anytime in settings',
                style: OnboardingTheme.subtitleStyle,
              ),
              const SizedBox(height: OnboardingTheme.subtitleToField),
              _buildInterestedInOptions(),
              const SizedBox(height: OnboardingTheme.fieldToBottom),
            ],
          ),
        ),
      );

  Widget _buildInterestedInOptions() => Column(
        children: [
          _buildInterestedInOption('Men', 'men', Icons.male),
          const SizedBox(height: 12),
          _buildInterestedInOption('Women', 'women', Icons.female),
          const SizedBox(height: 12),
          _buildInterestedInOption('Everyone', 'everyone', Icons.people),
        ],
      );

  Widget _buildInterestedInOption(String label, String value, IconData icon) {
    final isSelected = _selectedInterestedIn == value;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedInterestedIn = value);
        context.read<OnboardingBloc>().add(
              OnboardingInterestedInUpdated(value),
            );
      },
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          minHeight: OnboardingTheme.fieldHeight,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: OnboardingTheme.fieldContentPadding,
          vertical: OnboardingTheme.fieldContentPadding,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? OnboardingTheme.primaryGreen.withValues(alpha: 0.08)
              : OnboardingTheme.fieldFill,
          border: Border.all(
            color: isSelected
                ? OnboardingTheme.primaryGreen
                : const Color(0xFF8BB89E),
            width: isSelected
                ? OnboardingTheme.fieldFocusBorderWidth
                : OnboardingTheme.fieldBorderWidth,
          ),
          borderRadius: BorderRadius.circular(OnboardingTheme.fieldRadius),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? OnboardingTheme.primaryGreen
                  : const Color(0xFF4A4A4A),
              size: OnboardingTheme.fieldIconSize,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: OnboardingTheme.fieldTextStyle.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? OnboardingTheme.primaryGreen
                      : const Color(0xFF3A3A3A),
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: OnboardingTheme.primaryGreen,
                size: OnboardingTheme.fieldIconSize,
              ),
          ],
        ),
      ),
    );
  }
}
