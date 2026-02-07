import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/onboarding_bloc.dart';

class PreferencesOnboardingScreen extends StatefulWidget {
  const PreferencesOnboardingScreen({super.key});

  @override
  State<PreferencesOnboardingScreen> createState() =>
      _PreferencesOnboardingScreenState();
}

class _PreferencesOnboardingScreenState
    extends State<PreferencesOnboardingScreen> {
  String _selectedInterestedIn = 'everyone';
  RangeValues _ageRange = const RangeValues(18, 50);
  double _maxDistance = 50.0; // Default 50 miles (industry standard)

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
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 32 : 24),
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

          SizedBox(height: isTablet ? 40 : 32),

          // Interested In Section
          Text(
            'I\'m interested in',
            style: GoogleFonts.montserrat(
              fontSize: isTablet ? 22 : 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          _buildInterestedInOptions(),

          SizedBox(height: isTablet ? 40 : 32),

          // Distance Section (Industry Standard - Tinder, Bumble, Hinge)
          Text(
            'Maximum Distance',
            style: GoogleFonts.montserrat(
              fontSize: isTablet ? 22 : 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          _buildDistanceSlider(),

          SizedBox(height: isTablet ? 40 : 32),

          // Age Range Section
          Text(
            'Age Range',
            style: GoogleFonts.montserrat(
              fontSize: isTablet ? 22 : 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          _buildAgeRangeSlider(),

          SizedBox(height: isTablet ? 40 : 32),
        ],
      ),
    );
  }

  Widget _buildInterestedInOptions() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Column(
      children: [
        _buildInterestedInOption('Men', 'men', Icons.male),
        SizedBox(height: isTablet ? 16 : 12),
        _buildInterestedInOption('Women', 'women', Icons.female),
        SizedBox(height: isTablet ? 16 : 12),
        _buildInterestedInOption('Everyone', 'everyone', Icons.people),
      ],
    );
  }

  Widget _buildInterestedInOption(String label, String value, IconData icon) {
    final isSelected = _selectedInterestedIn == value;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedInterestedIn = value);
        context.read<OnboardingBloc>().add(
              OnboardingInterestedInUpdated(value),
            );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 16,
          vertical: isTablet ? 20 : 16,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF008037).withValues(alpha: 0.1)
              : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF008037) : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  isSelected ? const Color(0xFF008037) : Colors.grey.shade600,
              size: isTablet ? 24 : 20,
            ),
            SizedBox(width: isTablet ? 16 : 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? const Color(0xFF008037) : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: const Color(0xFF008037),
                size: isTablet ? 24 : 20,
              ),
          ],
        ),
      ),
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
        SizedBox(height: isTablet ? 16 : 12),
        RangeSlider(
          values: _ageRange,
          min: 18,
          max: 80,
          divisions: 62,
          activeColor: const Color(0xFF008037),
          inactiveColor: Colors.grey.shade300,
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
  }

  Widget _buildDistanceSlider() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Column(
      children: [
        Text(
          _maxDistance.round() == 100
              ? '${_maxDistance.round()} miles (Anywhere)'
              : 'Within ${_maxDistance.round()} miles',
          style: GoogleFonts.montserrat(
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF008037),
          ),
        ),
        SizedBox(height: isTablet ? 16 : 12),
        Slider(
          value: _maxDistance,
          min: 1,
          max: 100,
          divisions: 99,
          activeColor: const Color(0xFF008037),
          inactiveColor: Colors.grey.shade300,
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
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1 mile',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                '100 miles',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
