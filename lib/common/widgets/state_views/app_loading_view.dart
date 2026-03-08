import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';

/// Shared loading indicator for use across all screens.
///
/// Displays a branded loading spinner with an optional message.
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.message = 'Loading...'});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
        label: message,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: AppColors.primaryGreen,
                strokeWidth: 3,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
}
