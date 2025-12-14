import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../user/controllers/onboarding_controller.dart';

class PreferencesOnboardingScreen extends StatefulWidget {
  const PreferencesOnboardingScreen({Key? key}) : super(key: key);

  @override
  State<PreferencesOnboardingScreen> createState() =>
      _PreferencesOnboardingScreenState();
}

class _PreferencesOnboardingScreenState
    extends State<PreferencesOnboardingScreen> {
  String _selectedInterestedIn = 'everyone';
  RangeValues _ageRange = const RangeValues(18, 50);

  @override
  void initState() {
    super.initState();
    final controller =
        Provider.of<OnboardingController>(context, listen: false);
    _selectedInterestedIn = controller.interestedIn;
    _ageRange = RangeValues(
      controller.ageRange[0].toDouble(),
      controller.ageRange[1].toDouble(),
    );

    // Debug logging
    print('🔍 PreferencesOnboardingScreen initState:');
    print('   Initial interestedIn: "${controller.interestedIn}"');
    print('   Initial ageRange: ${controller.ageRange}');
    print('   Local selectedInterestedIn: "$_selectedInterestedIn"');
    print('   Local ageRange: $_ageRange');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Padding(
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

          SizedBox(height: isTablet ? 48 : 40),

          // Interested In Section
          Text(
            'I\'m interested in',
            style: GoogleFonts.montserrat(
              fontSize: isTablet ? 22 : 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          _buildInterestedInOptions(),

          SizedBox(height: isTablet ? 48 : 40),

          // Age Range Section
          Text(
            'Age Range',
            style: GoogleFonts.montserrat(
              fontSize: isTablet ? 22 : 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          _buildAgeRangeSlider(),

          const Spacer(),
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
        setState(() {
          _selectedInterestedIn = value;
        });
        // Save to controller immediately
        final controller =
            Provider.of<OnboardingController>(context, listen: false);
        controller.setInterestedIn(value);

        // Debug logging
        print(
            '🔍 PreferencesOnboardingScreen: Selected interestedIn: "$value"');
        print(
            '   Controller interestedIn after setting: "${controller.interestedIn}"');
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
            // Save to controller immediately
            final controller =
                Provider.of<OnboardingController>(context, listen: false);
            controller.setAgeRange([values.start.round(), values.end.round()]);

            // Debug logging
            print(
                '🔍 PreferencesOnboardingScreen: Age range changed to: ${values.start.round()}-${values.end.round()}');
            print(
                '   Controller ageRange after setting: ${controller.ageRange}');
          },
        ),
      ],
    );
  }
}
