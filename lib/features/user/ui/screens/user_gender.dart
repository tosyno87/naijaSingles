// ignore_for_file: unused_import

import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:naijasingles/common/routes/route_name.dart';
import 'package:naijasingles/common/widgets/custom_button.dart';
import 'package:naijasingles/common/widgets/custom_snackbar.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/providers/theme_provider.dart';

class Gender extends StatefulWidget {
  const Gender({super.key});

  @override
  GenderState createState() => GenderState();
}

class GenderState extends State<Gender> with SingleTickerProviderStateMixin {
  String? selectedGender;
  bool showOnProfile = true;
  
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

  @override
  Widget build(BuildContext context) {
    var userData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    log(userData.toString());
    
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Centered title section with softer font
              Center(
                child: Column(
                  children: [
                    const Text(
                      "I am a",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600, // Softer than bold
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "This helps us personalize your experience",
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
              
              const SizedBox(height: 50),
              
              // Gender options with card-style layout and animations
              _fadeAnimation != null
                ? FadeTransition(
                    opacity: _fadeAnimation!,
                    child: Column(
                      children: [
                        _buildGenderCard(
                          "Man",
                          selectedGender == "men",
                          () {
                            _animateCardTap(() {
                              setState(() => selectedGender = "men");
                            });
                          },
                          Icons.male_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildGenderCard(
                          "Woman",
                          selectedGender == "women",
                          () {
                            _animateCardTap(() {
                              setState(() => selectedGender = "women");
                            });
                          },
                          Icons.female_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildGenderCard(
                          "Non-binary",
                          selectedGender == "other",
                          () {
                            _animateCardTap(() {
                              setState(() => selectedGender = "other");
                            });
                          },
                          Icons.transgender_rounded,
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      _buildGenderCard(
                        "Man",
                        selectedGender == "men",
                        () => setState(() => selectedGender = "men"),
                        Icons.male_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildGenderCard(
                        "Woman",
                        selectedGender == "women",
                        () => setState(() => selectedGender = "women"),
                        Icons.female_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildGenderCard(
                        "Non-binary",
                        selectedGender == "other",
                        () => setState(() => selectedGender = "other"),
                        Icons.transgender_rounded,
                      ),
                    ],
                  ),
              
              const Spacer(),
              
              // iOS-style toggle for "Show my gender on profile"
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Show my gender on my profile",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    CupertinoSwitch(
                      value: showOnProfile,
                      activeColor: const Color(0xFF27AE60),
                      onChanged: (value) {
                        setState(() {
                          showOnProfile = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Continue button with contrasting green
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedGender == null ? null : () {
                      if (selectedGender != null) {
                        final userGender = {
                          'userGender': selectedGender,
                          'showOnProfile': showOnProfile
                        };
                        userData.addAll(userGender);
                        Navigator.pushNamed(
                          context, 
                          RouteName.sexualorientationScreen,
                          arguments: userData
                        );
                      } else {
                        CustomSnackbar.showSnackBarSimple(
                          "Please select your gender",
                          context
                        );
                      }
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
      ),
    );
  }
  
  // Card-style gender option with shadow and rounded corners
  Widget _buildGenderCard(String title, bool isSelected, VoidCallback onTap, IconData icon) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF27AE60) : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
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
  
  // Animation for card tap
  void _animateCardTap(VoidCallback callback) {
    callback();
    // You could add additional tap animations here if desired
  }
}
