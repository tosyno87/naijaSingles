import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import 'animated_loading_indicator.dart';

class LoadingTransitionScreen extends StatelessWidget {
  const LoadingTransitionScreen({
    super.key,
    this.message = 'Setting up your profile...',
  });
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Custom animated loading indicator
              const AnimatedLoadingIndicator(
                size: 120,
              ),
              const SizedBox(height: 32),
              Text(
                message,
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3E1F0D),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'This will only take a moment',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}
