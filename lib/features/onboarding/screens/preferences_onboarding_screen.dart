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
  RangeValues _ageRange = const RangeValues(18, 50);
  double _maxDistance = 50;

  @override
  void initState() {
    super.initState();
    final data = context.read<OnboardingBloc>().state.data;

    if (data != null) {
      _selectedInterestedIn = data.interestedIn;
      _ageRange = RangeValues(
        data.ageRange[0].toDouble(),
        data.ageRange[1].toDouble(),
      );
      _maxDistance = data.maxDistance.toDouble();
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
                'Help us find your perfect match.',
                style: OnboardingTheme.subtitleStyle,
              ),
              const SizedBox(height: 20),
              Text(
                "I'm interested in",
                style: OnboardingTheme.sectionLabelStyle,
              ),
              const SizedBox(height: OnboardingTheme.labelToField),
              _buildInterestedInOptions(),
              const SizedBox(height: OnboardingTheme.fieldToSection),
              Text(
                'Maximum Distance',
                style: OnboardingTheme.sectionLabelStyle,
              ),
              const SizedBox(height: OnboardingTheme.labelToField),
              _buildDistanceSlider(),
              const SizedBox(height: OnboardingTheme.fieldToSection),
              Text('Age Range', style: OnboardingTheme.sectionLabelStyle),
              const SizedBox(height: OnboardingTheme.labelToField),
              _buildAgeRangeSlider(),
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
                : OnboardingTheme.fieldBorder,
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
                  : OnboardingTheme.subtitleColor,
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
                      : OnboardingTheme.fieldTextColor,
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

  Widget _buildAgeRangeSlider() => Column(
        children: [
          Text(
            '${_ageRange.start.round()} - ${_ageRange.end.round()} years',
            style: OnboardingTheme.fieldTextStyle.copyWith(
              color: OnboardingTheme.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          RangeSlider(
            values: _ageRange,
            min: 18,
            max: 80,
            divisions: 62,
            activeColor: OnboardingTheme.primaryGreen,
            inactiveColor: OnboardingTheme.progressTrack,
            onChanged: (RangeValues values) {
              setState(() => _ageRange = values);
              context.read<OnboardingBloc>().add(
                    OnboardingAgeRangeUpdated([
                      values.start.round(),
                      values.end.round(),
                    ]),
                  );
            },
          ),
        ],
      );

  Widget _buildDistanceSlider() => Column(
        children: [
          Text(
            _maxDistance.round() == 100
                ? '${_maxDistance.round()} miles (Anywhere)'
                : 'Within ${_maxDistance.round()} miles',
            style: OnboardingTheme.fieldTextStyle.copyWith(
              color: OnboardingTheme.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Slider(
            value: _maxDistance,
            min: 1,
            max: 100,
            divisions: 99,
            activeColor: OnboardingTheme.primaryGreen,
            inactiveColor: OnboardingTheme.progressTrack,
            label: _maxDistance.round() == 100
                ? 'Anywhere'
                : '${_maxDistance.round()} miles',
            onChanged: (double value) {
              setState(() => _maxDistance = value);
              context.read<OnboardingBloc>().add(
                    OnboardingMaxDistanceUpdated(value.round()),
                  );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: OnboardingTheme.fieldContentPadding,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1 mile', style: OnboardingTheme.helperStyle),
                Text('100 miles', style: OnboardingTheme.helperStyle),
              ],
            ),
          ),
        ],
      );
}
