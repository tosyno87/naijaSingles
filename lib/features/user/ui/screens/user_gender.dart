import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../../common/routes/route_name.dart';
import '../../../../common/widgets/custom_snackbar.dart';

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

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Start animation after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _animationController != null) {
        unawaited(_animationController!.forward());
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
    final userData =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    log(userData.toString());
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
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
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Progress indicator
              Container(
                height: 4,
                width:
                    screenSize.width * 0.45, // 45% of screen width (third step)
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 40),

              // Title section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'I am a...',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This helps us find the right matches for you',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Gender options with card-style layout
              Column(
                children: [
                  _buildGenderCard(
                    'Man',
                    selectedGender == 'men',
                    () => setState(() => selectedGender = 'men'),
                    Icons.male_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildGenderCard(
                    'Woman',
                    selectedGender == 'women',
                    () => setState(() => selectedGender = 'women'),
                    Icons.female_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildGenderCard(
                    'Non-binary',
                    selectedGender == 'other',
                    () => setState(() => selectedGender = 'other'),
                    Icons.transgender_rounded,
                  ),
                ],
              ),

              const Spacer(),

              // iOS-style toggle for "Show my gender on profile"
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Show my gender on my profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    CupertinoSwitch(
                      value: showOnProfile,
                      activeTrackColor: AppColors.primaryGreen,
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

              // Continue labelLarge
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedGender == null
                        ? null
                        : () {
                            if (selectedGender != null) {
                              final userGender = {
                                'userGender': selectedGender,
                                'showOnProfile': showOnProfile,
                              };
                              userData.addAll(userGender);
                              unawaited(Navigator.pushNamed(
                                context,
                                RouteName.nationalityScreen,
                                arguments: userData,
                              ));
                            } else {
                              CustomSnackbar.showSnackBarSimple(
                                'Please select your gender',
                                context,
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
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
      ),
    );
  }

  // Card-style gender option with shadow and rounded corners
  Widget _buildGenderCard(
    String title,
    bool isSelected,
    VoidCallback onTap,
    IconData icon,
  ) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? AppColors.primaryGreen : Colors.grey[200]!,
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
                  color:
                      isSelected ? const Color(0xFFB7E4C7) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color:
                      isSelected ? AppColors.primaryGreen : Colors.grey[600],
                  size: 28,
                ),
              ),
              const SizedBox(width: 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primaryGreen : Colors.black87,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
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
