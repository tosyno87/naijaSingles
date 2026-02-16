// ignore_for_file: unused_import
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../../common/routes/route_name.dart';
import '../../../../common/widgets/custom_button.dart';
import '../../../../common/widgets/custom_snackbar.dart';

class ShowGender extends StatefulWidget {
  const ShowGender({super.key});

  @override
  _ShowGenderState createState() => _ShowGenderState();
}

class _ShowGenderState extends State<ShowGender> {
  String? selectedPreference;

  void _selectOption(String option) {
    setState(() {
      // If already selected, deselect it
      if (selectedPreference == option) {
        selectedPreference = null;
      } else {
        selectedPreference = option;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // for adding userdetails in this user map from navigation
    final userData =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Progress indicator
                    Container(
                      height: 4,
                      width: screenSize.width *
                          0.90, // 90% of screen width (sixth step)
                      decoration: BoxDecoration(
                        color: const Color(0xFF27AE60),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Title section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Show me',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Select who you want to see and match with',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Preference options with card-style layout
                    Column(
                      children: [
                        _buildPreferenceCard(
                          'Men',
                          'men',
                          Icons.male_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildPreferenceCard(
                          'Women',
                          'women',
                          Icons.female_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildPreferenceCard(
                          'Everyone',
                          'everyone',
                          Icons.people_alt_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Continue labelLarge fixed at the bottom
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedPreference == null
                      ? null
                      : () {
                          userData.addAll({'showGender': selectedPreference});
                          log(userData.toString());
                          Navigator.pushNamed(
                            context,
                            RouteName.universityScreen,
                            arguments: userData,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[500],
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'CONTINUE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Card-style preference option with shadow and rounded corners
  Widget _buildPreferenceCard(String title, String value, IconData icon) {
    final bool isSelected = selectedPreference == value;

    return GestureDetector(
      onTap: () {
        _selectOption(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF27AE60) : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.grey[50],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFB7E4C7) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFF27AE60) : Colors.grey[600],
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF27AE60) : Colors.black87,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFF27AE60),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
