// ignore_for_file: unused_import
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:naijasingles/common/routes/route_name.dart';
import 'package:naijasingles/common/widgets/custom_button.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/providers/theme_provider.dart';
import '../../../../common/widgets/custom_snackbar.dart';

class ShowGender extends StatefulWidget {
  const ShowGender({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ShowGenderState createState() => _ShowGenderState();
}

class _ShowGenderState extends State<ShowGender> with SingleTickerProviderStateMixin {
  String? selectedPreference;
  
  // Use nullable types instead of late initialization
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Initialize animation
    _fadeAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    );
    
    // Start animation after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _animationController != null) {
        _animationController!.forward();
      }
    });
  }
  
  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

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
    var userData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    
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
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    
                    // Centered title section
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            "Show me",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Select who you want to see and match with",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // Preference options with card-style layout and animations
                    _fadeAnimation != null
                      ? FadeTransition(
                          opacity: _fadeAnimation!,
                          child: Column(
                            children: [
                              _buildPreferenceCard(
                                "Men",
                                "men",
                                Icons.male_rounded,
                              ),
                              const SizedBox(height: 20),
                              _buildPreferenceCard(
                                "Women",
                                "women",
                                Icons.female_rounded,
                              ),
                              const SizedBox(height: 20),
                              _buildPreferenceCard(
                                "Everyone",
                                "everyone",
                                Icons.people_alt_rounded,
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            _buildPreferenceCard(
                              "Men",
                              "men",
                              Icons.male_rounded,
                            ),
                            const SizedBox(height: 20),
                            _buildPreferenceCard(
                              "Women",
                              "women",
                              Icons.female_rounded,
                            ),
                            const SizedBox(height: 20),
                            _buildPreferenceCard(
                              "Everyone",
                              "everyone",
                              Icons.people_alt_rounded,
                            ),
                          ],
                        ),
                  ],
                ),
              ),
            ),
            
            // Continue button fixed at the bottom
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedPreference == null ? null : () {
                    userData.addAll({'showGender': selectedPreference});
                    log(userData.toString());
                    Navigator.pushNamed(
                      context, 
                      RouteName.universityScreen,
                      arguments: userData
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
                    "CONTINUE",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
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
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.95, end: isSelected ? 1.0 : 0.98),
        duration: const Duration(milliseconds: 200),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? const Color(0xFF27AE60) : Colors.transparent,
                  width: isSelected ? 2 : 0,
                ),
                borderRadius: BorderRadius.circular(16),
                color: isSelected ? const Color(0xFFEAF8F1) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isSelected ? 0.05 : 0.08),
                    blurRadius: isSelected ? 5 : 8,
                    spreadRadius: isSelected ? 0 : 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFDFF5E7) : Colors.grey[100],
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
        },
      ),
    );
  }
}
