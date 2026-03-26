import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized design tokens for all onboarding step screens.
/// Based on Onboarding Spec v1.
class OnboardingTheme {
  OnboardingTheme._();

  // ---------------------------------------------------------------------------
  // Colors
  // ---------------------------------------------------------------------------
  static const Color background = Color(0xFFF9F9F7);
  static const Color fieldFill = Color(0xFFE5EFE8);
  static const Color fieldBorder = Color(0xFFAED5BD);
  static const Color focusBorder = Color(0xFF008037);
  static const Color titleColor = Color(0xFF1F1F1F);
  static const Color subtitleColor = Color(0xFF6B6B6B);
  static const Color sectionLabelColor = Color(0xFF2B1E17);
  static const Color fieldTextColor = Color(0xFF2B1E17);
  static const Color primaryGreen = Color(0xFF008037);
  static const Color gradientEnd = Color(0xFF0AA36C);
  static const Color progressTrack = Color(0xFFE2E2E2);
  static const Color helperError = Color(0xFF6B6B6B);

  // ---------------------------------------------------------------------------
  // Spacing rhythm
  // ---------------------------------------------------------------------------
  static const double titleToSubtitle = 8;
  static const double subtitleToField = 28;
  static const double labelToField = 10;
  static const double fieldToSection = 24;
  static const double fieldToBottom = 32;
  static const double horizontalPadding = 24;
  static const double topPadding = 16;
  static const double maxContentWidth = 560;

  // ---------------------------------------------------------------------------
  // Field component
  // ---------------------------------------------------------------------------
  static const double fieldHeight = 64;
  static const double fieldRadius = 16;
  static const double fieldBorderWidth = 1;
  static const double fieldFocusBorderWidth = 2;
  static const double fieldContentPadding = 16;
  static const double fieldIconSize = 22;

  // ---------------------------------------------------------------------------
  // Button
  // ---------------------------------------------------------------------------
  static const double buttonHeight = 56;
  static const double buttonRadius = 28;

  // ---------------------------------------------------------------------------
  // Progress bar
  // ---------------------------------------------------------------------------
  static const double progressHeight = 6;
  static const double progressRadius = 3;

  // ---------------------------------------------------------------------------
  // Animation
  // ---------------------------------------------------------------------------
  static const Duration stepTransition = Duration(milliseconds: 250);
  static const Curve stepCurve = Curves.easeOutCubic;
  static const Duration fieldFocusAnimation = Duration(milliseconds: 150);

  // ---------------------------------------------------------------------------
  // Accessibility
  // ---------------------------------------------------------------------------
  static const double minTapTarget = 44;

  // ---------------------------------------------------------------------------
  // Type scale (Montserrat)
  // ---------------------------------------------------------------------------
  static TextStyle get titleStyle => GoogleFonts.montserrat(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: titleColor,
        height: 32 / 28,
      );

  static TextStyle get subtitleStyle => GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: subtitleColor,
        height: 24 / 16,
      );

  static TextStyle get sectionLabelStyle => GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: sectionLabelColor,
        height: 22 / 16,
      );

  static TextStyle get fieldTextStyle => GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: fieldTextColor,
        height: 24 / 18,
      );

  static TextStyle get helperStyle => GoogleFonts.montserrat(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: helperError,
        height: 18 / 13,
      );

  static TextStyle get buttonTextStyle => GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  // ---------------------------------------------------------------------------
  // Reusable InputDecoration factory
  // ---------------------------------------------------------------------------
  static InputDecoration fieldDecoration({
    String? hint,
    Widget? prefix,
    Widget? suffix,
  }) =>
      InputDecoration(
        filled: true,
        fillColor: fieldFill,
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: subtitleColor,
        ),
        prefixIcon: prefix,
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: const BorderSide(color: fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: const BorderSide(color: fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: const BorderSide(
            color: focusBorder,
            width: fieldFocusBorderWidth,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: fieldFocusBorderWidth,
          ),
        ),
        errorStyle: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.redAccent,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: fieldContentPadding,
          vertical: fieldContentPadding,
        ),
        constraints: const BoxConstraints(minHeight: fieldHeight),
      );

  // ---------------------------------------------------------------------------
  // Dropdown container decoration
  // ---------------------------------------------------------------------------
  static BoxDecoration dropdownDecoration({bool hasFocus = false}) =>
      BoxDecoration(
        color: fieldFill,
        borderRadius: BorderRadius.circular(fieldRadius),
        border: Border.all(
          color: hasFocus ? focusBorder : fieldBorder,
          width: hasFocus ? fieldFocusBorderWidth : fieldBorderWidth,
        ),
      );

  // ---------------------------------------------------------------------------
  // Standard page padding
  // ---------------------------------------------------------------------------
  static EdgeInsets get pagePadding => const EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
        top: topPadding,
      );

  // ---------------------------------------------------------------------------
  // Gradient for primary CTA button
  // ---------------------------------------------------------------------------
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [primaryGreen, gradientEnd],
  );

  // ---------------------------------------------------------------------------
  // Constrained content wrapper for tablet
  // ---------------------------------------------------------------------------
  static Widget constrainedContent({required Widget child}) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: child,
        ),
      );
}
