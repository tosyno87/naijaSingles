import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/onboarding_bloc.dart';
import '../widgets/reusable_input_widgets.dart';

class OnboardingPreferencesScreen extends StatefulWidget {
  const OnboardingPreferencesScreen({super.key, this.onNext});
  final VoidCallback? onNext;

  @override
  State<OnboardingPreferencesScreen> createState() =>
      _OnboardingPreferencesScreenState();
}

class _OnboardingPreferencesScreenState
    extends State<OnboardingPreferencesScreen> {
  String _selectedInterestedIn = 'everyone';
  RangeValues _ageRange = const RangeValues(18, 50);

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 32 : 24,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Dating Preferences',
            style: GoogleFonts.montserrat(
              fontSize: isTablet ? 32 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            'Help us find your perfect match',
            style: GoogleFonts.montserrat(
              fontSize: isTablet ? 18 : 16,
              color: Colors.black54,
            ),
          ),

          SizedBox(height: isTablet ? 48 : 40),

          // Interested In Section
          const SectionHeader(
            title: 'I\'m interested in',
            subtitle: 'Who would you like to meet?',
          ),
          SizedBox(height: isTablet ? 20 : 16),
          _buildInterestedInOptions(),

          SizedBox(height: isTablet ? 48 : 40),

          // Age Range Section
          const SectionHeader(
            title: 'Age Range',
            subtitle: 'What age range are you looking for?',
          ),
          SizedBox(height: isTablet ? 20 : 16),
          _buildAgeRangeSlider(),

          const Spacer(),

          // Continue Button
          ContinueButton(
            onPressed: _saveAndContinue,
          ),
        ],
      ),
    );
  }

  Widget _buildInterestedInOptions() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Column(
      children: [
        SelectionOption(
          label: 'Men',
          value: 'men',
          selectedValue: _selectedInterestedIn,
          onSelected: (value) {
            setState(() {
              _selectedInterestedIn = value;
            });
          },
          icon: Icons.male,
        ),
        SizedBox(height: isTablet ? 16 : 12),
        SelectionOption(
          label: 'Women',
          value: 'women',
          selectedValue: _selectedInterestedIn,
          onSelected: (value) {
            setState(() {
              _selectedInterestedIn = value;
            });
          },
          icon: Icons.female,
        ),
        SizedBox(height: isTablet ? 16 : 12),
        SelectionOption(
          label: 'Everyone',
          value: 'everyone',
          selectedValue: _selectedInterestedIn,
          onSelected: (value) {
            setState(() {
              _selectedInterestedIn = value;
            });
          },
          icon: Icons.people,
        ),
      ],
    );
  }

  Widget _buildAgeRangeSlider() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Column(
      children: [
        Text(
          '${_ageRange.start.round()} - ${_ageRange.end.round()} years',
          style: GoogleFonts.montserrat(
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF008037),
          ),
        ),
        SizedBox(height: isTablet ? 20 : 16),
        RangeSlider(
          values: _ageRange,
          min: 18,
          max: 80,
          divisions: 62,
          activeColor: const Color(0xFF008037),
          inactiveColor: Colors.grey.shade300,
          onChanged: (RangeValues values) {
            setState(() {
              _ageRange = values;
            });
          },
        ),
      ],
    );
  }

  void _saveAndContinue() {
    context.read<OnboardingBloc>()
      ..add(OnboardingInterestedInUpdated(_selectedInterestedIn))
      ..add(OnboardingAgeRangeUpdated(
        [_ageRange.start.round(), _ageRange.end.round()],
      ),);

    if (widget.onNext != null) {
      widget.onNext!();
    }
  }
}
