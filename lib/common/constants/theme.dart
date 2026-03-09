import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized theme definitions using AppColors tokens.
/// lightTheme = white background / dark text (default).
/// darkTheme  = dark background / light text.
///
/// The structural logic lives in [buildLightTheme] / [buildDarkTheme] so
/// tests can pass a plain [TextTheme] and validate the production theme
/// structure without triggering [GoogleFonts] font downloads.
class MyThemes {
  // ─── Shared button & input styles ───────────────────────────────
  static final _elevatedButton = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: AppColors.textOnPrimary,
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );

  static final _outlinedButton = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryGreen,
      side: const BorderSide(color: AppColors.primaryGreen, width: 2),
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );

  // ─── Light text theme (base, before GoogleFonts wrapping) ───────
  static const _lightTextTheme = TextTheme(
    displayLarge: TextStyle(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.bold,
    ),
    displayMedium: TextStyle(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.bold,
    ),
    displaySmall: TextStyle(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: TextStyle(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.bold,
    ),
    headlineSmall: TextStyle(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(color: AppColors.textPrimary),
    bodyMedium: TextStyle(color: AppColors.textSecondary),
  );

  // ─── Dark text theme (base, before GoogleFonts wrapping) ────────
  static const _darkTextTheme = TextTheme(
    displayLarge: TextStyle(
      color: AppColors.darkTextPrimary,
      fontWeight: FontWeight.bold,
    ),
    displayMedium: TextStyle(
      color: AppColors.darkTextPrimary,
      fontWeight: FontWeight.bold,
    ),
    displaySmall: TextStyle(
      color: AppColors.darkTextPrimary,
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: TextStyle(
      color: AppColors.darkTextPrimary,
      fontWeight: FontWeight.bold,
    ),
    headlineSmall: TextStyle(
      color: AppColors.darkTextPrimary,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      color: AppColors.darkTextPrimary,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(color: AppColors.darkTextPrimary),
    bodyMedium: TextStyle(color: AppColors.darkTextSecondary),
  );

  // ─── Factory: builds the light ThemeData with an injectable TextTheme ──
  /// Builds the light theme. Production callers use [lightTheme].
  /// Tests can call this directly with a plain [textTheme] to bypass
  /// GoogleFonts font loading.
  @visibleForTesting
  static ThemeData buildLightTheme(TextTheme textTheme) => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.backgroundColor,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primaryGreen,
          secondary: AppColors.accentGreen,
          error: AppColors.error,
        ),
        textTheme: textTheme,
        elevatedButtonTheme: _elevatedButton,
        outlinedButtonTheme: _outlinedButton,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primaryGreen, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.7),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundColor,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
        dividerColor: AppColors.divider,
        cardColor: AppColors.cardColor,
      );

  // ─── Factory: builds the dark ThemeData with an injectable TextTheme ───
  /// Builds the dark theme. Production callers use [darkTheme].
  /// Tests can call this directly with a plain [textTheme] to bypass
  /// GoogleFonts font loading.
  @visibleForTesting
  static ThemeData buildDarkTheme(TextTheme textTheme) => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBackground,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryGreenLight,
          secondary: AppColors.accentGreen,
          surface: AppColors.darkSurface,
          error: AppColors.error,
        ),
        textTheme: textTheme,
        elevatedButtonTheme: _elevatedButton,
        outlinedButtonTheme: _outlinedButton,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkCard,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.primaryGreenLight,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          labelStyle: const TextStyle(color: AppColors.darkTextSecondary),
          hintStyle: TextStyle(
            color: AppColors.darkTextSecondary.withValues(alpha: 0.7),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkSurface,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.darkTextPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
        ),
        dividerColor: AppColors.darkDivider,
        cardColor: AppColors.darkCard,
      );

  // ─── Production theme instances (use GoogleFonts) ─────────────
  static final lightTheme = buildLightTheme(
    GoogleFonts.montserratTextTheme(_lightTextTheme),
  );

  static final darkTheme = buildDarkTheme(
    GoogleFonts.montserratTextTheme(_darkTextTheme),
  );
}
