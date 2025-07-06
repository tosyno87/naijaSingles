import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF3C1361); // Deep purple
  static const Color accentColor = Color(0xFFFFD700); // Vibrant yellow
  static const Color secondaryColor = Color(0xFF00B140); // Vibrant green
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFE0E0E0);
  static const Color errorColor = Color(0xFFFF5252);
}

class MyThemes {
  static final darkTheme = ThemeData(
    scaffoldBackgroundColor: AppColors.primaryColor,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accentColor,
      secondary: AppColors.secondaryColor,
      error: AppColors.errorColor,
    ),
    textTheme: GoogleFonts.montserratTextTheme(
      const TextTheme(
        displayLarge: TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textSecondary),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentColor,
        foregroundColor: AppColors.primaryColor,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accentColor,
        side: const BorderSide(color: AppColors.accentColor, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accentColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.errorColor, width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle:
          TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  static final lightTheme = darkTheme; // Using the same theme for consistency
}
