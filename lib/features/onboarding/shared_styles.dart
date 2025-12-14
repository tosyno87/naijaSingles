import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../common/constants/app_colors.dart';

/// Shared styling constants for the onboarding flow
class OnboardingStyles {
  // Colors - using centralized AppColors
  // Use AppColors.backgroundColor instead of local backgroundColor
  static const Color primaryColor = Color(0xFF27AE60);
  static const Color accentColor = Color(0xFFE57C23);
  static const Color textDarkColor = Color(0xFF3C2A21);
  static const Color textLightColor = Color(0xFF8B7E74);

  // Spacing
  static const double standardPadding = 24.0;
  static const double standardSpacing = 16.0;
  static const double smallSpacing = 8.0;
  static const double largeSpacing = 32.0;

  // Text styles
  static TextStyle get headingStyle => GoogleFonts.montserrat(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textDarkColor,
      );

  static TextStyle get subheadingStyle => GoogleFonts.montserrat(
        fontSize: 16,
        color: textLightColor,
      );

  static TextStyle get sectionTitleStyle => GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      );

  static TextStyle get labelLargeTextStyle => GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      );

  // Decorations
  static BoxDecoration get inputDecoration => BoxDecoration(
        color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
      );

  static BoxDecoration get selectedItemDecoration => BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryColor,
          width: 2,
        ),
      );

  static BoxDecoration get unselectedItemDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      );

  // Input decoration
  static InputDecoration textFieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor),
        ),
      );

  // Button styles
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(
          horizontal: 32.0,
          vertical: 12.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      );

  // Chip styles
  static ChipThemeData get chipTheme => ChipThemeData(
        backgroundColor: Colors.white,
        disabledColor: Colors.grey.shade200,
        selectedColor: primaryColor.withValues(alpha: 0.2),
        secondarySelectedColor: primaryColor.withValues(alpha: 0.2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        labelStyle: TextStyle(color: Colors.black87),
        secondaryLabelStyle: TextStyle(color: primaryColor),
        brightness: Brightness.light,
      );
}
