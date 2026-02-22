import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/onboarding_bloc.dart';
import '../widgets/reusable_input_widgets.dart';

class AdditionalPreferencesScreen extends StatefulWidget {
  const AdditionalPreferencesScreen({super.key});

  @override
  State<AdditionalPreferencesScreen> createState() =>
      _AdditionalPreferencesScreenState();
}

class _AdditionalPreferencesScreenState
    extends State<AdditionalPreferencesScreen> {
  double _height = 170;
  String _heightUnit = 'cm';
  String _lookingFor = 'Dating';
  String _relationshipIntent = 'Not sure yet';

  final List<Map<String, dynamic>> _lookingForOptions = [
    {'label': 'Dating', 'value': 'Dating', 'icon': Icons.favorite_outline},
    {
      'label': 'Friendship',
      'value': 'Friendship',
      'icon': Icons.people_outline,
    },
    {
      'label': 'Networking',
      'value': 'Networking',
      'icon': Icons.business_center_outlined,
    },
  ];

  final List<Map<String, dynamic>> _relationshipIntentOptions = [
    {
      'label': 'Short-term fun',
      'value': 'Short-term',
      'icon': Icons.flash_on_outlined,
    },
    {
      'label': 'Long-term relationship',
      'value': 'Long-term',
      'icon': Icons.favorite_border,
    },
    {
      'label': 'Casual dating',
      'value': 'Casual',
      'icon': Icons.coffee_outlined,
    },
    {
      'label': 'Not sure yet',
      'value': 'Not sure yet',
      'icon': Icons.help_outline,
    },
  ];

  @override
  void initState() {
    super.initState();
    final data = context.read<OnboardingBloc>().state.data;
    if (data != null) {
      _height = data.height.toDouble();
      _heightUnit = data.heightUnit;
      _lookingFor = data.lookingFor;
      _relationshipIntent = data.relationshipIntent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black87,
            size: isTablet ? 28 : 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 32 : 24,
              vertical: 16,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Tell us more about you',
                    style: GoogleFonts.montserrat(
                      fontSize: isTablet ? 32 : 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: isTablet ? 12 : 8),
                  Text(
                    'Help us create better matches for you',
                    style: GoogleFonts.montserrat(
                      fontSize: isTablet ? 18 : 16,
                      color: Colors.black54,
                    ),
                  ),

                  SizedBox(height: isTablet ? 48 : 40),

                  // Height Section
                  const SectionHeader(
                    title: 'Height',
                    subtitle: 'Your height helps with better matching',
                  ),
                  SizedBox(height: isTablet ? 20 : 16),
                  HeightInput(
                    initialHeight: _height,
                    initialUnit: _heightUnit,
                    onChanged: (height, unit) {
                      setState(() {
                        _height = height;
                        _heightUnit = unit;
                      });
                    },
                  ),

                  SizedBox(height: isTablet ? 48 : 40),

                  // Looking For Section
                  const SectionHeader(
                    title: 'I\'m looking for',
                    subtitle: 'What brings you to Afropeep?',
                  ),
                  SizedBox(height: isTablet ? 20 : 16),
                  ..._buildLookingForOptions(),

                  SizedBox(height: isTablet ? 48 : 40),

                  // Relationship Intent Section
                  const SectionHeader(
                    title: 'Relationship goals',
                    subtitle: 'What are you hoping to find?',
                  ),
                  SizedBox(height: isTablet ? 20 : 16),
                  ..._buildRelationshipIntentOptions(),

                  SizedBox(height: isTablet ? 48 : 40),

                  // Continue Button
                  ContinueButton(
                    onPressed: _saveAndContinue,
                  ),

                  SizedBox(height: isTablet ? 32 : 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLookingForOptions() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return _lookingForOptions
        .map(
          (option) => Padding(
            padding: EdgeInsets.only(bottom: isTablet ? 16 : 12),
            child: SelectionOption(
              label: option['label'],
              value: option['value'],
              selectedValue: _lookingFor,
              onSelected: (value) {
                setState(() {
                  _lookingFor = value;
                });
              },
              icon: option['icon'],
            ),
          ),
        )
        .toList();
  }

  List<Widget> _buildRelationshipIntentOptions() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return _relationshipIntentOptions
        .map(
          (option) => Padding(
            padding: EdgeInsets.only(bottom: isTablet ? 16 : 12),
            child: SelectionOption(
              label: option['label'],
              value: option['value'],
              selectedValue: _relationshipIntent,
              onSelected: (value) {
                setState(() {
                  _relationshipIntent = value;
                });
              },
              icon: option['icon'],
            ),
          ),
        )
        .toList();
  }

  void _saveAndContinue() {
    context.read<OnboardingBloc>()
      ..add(OnboardingHeightUpdated(_height, _heightUnit))
      ..add(OnboardingLookingForUpdated(_lookingFor))
      ..add(OnboardingRelationshipIntentUpdated(_relationshipIntent));

    // Navigate to next screen or complete onboarding
    // You can customize this based on your onboarding flow
    Navigator.pop(context);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Preferences saved successfully!',
          style: GoogleFonts.montserrat(),
        ),
        backgroundColor: const Color(0xFF008037),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
