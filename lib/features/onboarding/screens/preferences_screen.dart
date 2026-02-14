import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/onboarding_bloc.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  String _selectedInterestedIn = 'everyone';
  RangeValues _ageRange = const RangeValues(18, 50);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dating Preferences',
                style: GoogleFonts.montserrat(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Help us find your perfect match',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 40),

              // Interested In Section
              Text(
                'I\'m interested in',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildInterestedInOptions(),

              const SizedBox(height: 40),

              // Age Range Section
              Text(
                'Age Range',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildAgeRangeSlider(),

              const Spacer(),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _savePreferences,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008037),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildInterestedInOptions() => Column(
        children: [
          _buildInterestedInOption('Men', 'men'),
          const SizedBox(height: 12),
          _buildInterestedInOption('Women', 'women'),
          const SizedBox(height: 12),
          _buildInterestedInOption('Everyone', 'everyone'),
        ],
      );

  Widget _buildInterestedInOption(String label, String value) {
    final isSelected = _selectedInterestedIn == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedInterestedIn = value;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF008037).withValues(alpha: 0.1)
              : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF008037) : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? const Color(0xFF008037) : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildAgeRangeSlider() => Column(
        children: [
          Text(
            '${_ageRange.start.round()} - ${_ageRange.end.round()} years',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF008037),
            ),
          ),
          const SizedBox(height: 16),
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

  void _savePreferences() {
    context.read<OnboardingBloc>()
      ..add(OnboardingInterestedInUpdated(_selectedInterestedIn))
      ..add(
        OnboardingAgeRangeUpdated(
          [_ageRange.start.round(), _ageRange.end.round()],
        ),
      );
    Navigator.pop(context);
  }
}
