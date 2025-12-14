import 'package:flutter/material.dart';

/// Modern Afrocentric Green Color Theme
/// Inspired by the beautiful Cultural Profile design
class AppColors {
  // Prevent instantiation
  AppColors._();

  // 🎨 PRIMARY GREEN THEME
  static const Color primaryGreen = Color(0xFF008037);
  static const Color primaryGreenDark = Color(0xFF006B2E);
  static const Color primaryGreenLight = Color(0xFF059669);
  static const Color accentGreen = Color(0xFF10B981);

  // 🌟 GRADIENT COLORS
  static const Color gradientStart = Color(0xFF008037);
  static const Color gradientEnd = Color(0xFF059669);
  static const Color gradientLight = Color(0xFF10B981);
  static const Color gradientDark = Color(0xFF006B2E);

  // 🎯 BACKGROUND COLORS - Afrocentric Theme
  static const Color backgroundColor = Colors.white; // White background
  static const Color surfaceColor = Colors.white; // White surface
  static const Color cardColor = Colors.white; // White cards
  static const Color overlayColor = Color(0xFFF8FAFC);

  // 📝 TEXT COLORS - Afrocentric Theme
  static const Color textPrimary =
      Color(0xFF2D2D2D); // Dark text for white background
  static const Color textSecondary = Color(0xFF666666); // Medium grey
  static const Color textTertiary = Color(0xFF94A3B8);
  
  // ⚠️ DEPRECATED: Use textSecondary instead. Kept for backward compatibility.
  @Deprecated('Use AppColors.textSecondary instead')
  static const Color secondaryColor = Color(0xFF8D6E63); // Light brown (old secondary color)
  static const Color textOnPrimary = Colors.white; // White text on green
  static const Color textOnSurface = Color(0xFF2D2D2D); // Dark text on white

  // 🎨 ACCENT COLORS
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // 💕 SOCIAL COLORS
  static const Color like = Color(0xFFE91E63);
  static const Color heart = Color(0xFFE91E63);
  static const Color star = Color(0xFFFFD700);
  static const Color premium = Color(0xFF9C27B0);

  // 🏢 PROFESSIONAL COLORS
  static const Color business = Color(0xFF37474F);
  static const Color networking = Color(0xFF607D8B);
  static const Color skills = Color(0xFF795548);

  // 🎓 LEARNING COLORS
  static const Color education = Color(0xFF3F51B5);
  static const Color knowledge = Color(0xFFFFC107);
  static const Color wisdom = Color(0xFF9C27B0);

  // 🌍 CULTURAL COLORS
  static const Color heritage = Color(0xFF8D6E63);
  static const Color traditions = Color(0xFFFF9800);
  static const Color community = Color(0xFF009688);
  static const Color culture = Color(0xFF6B46C1);

  // 🎵 ENTERTAINMENT COLORS
  static const Color music = Color(0xFF9C27B0);
  static const Color art = Color(0xFFFF9800);
  static const Color celebration = Color(0xFFFF5722);
  static const Color festival = Color(0xFFFFC107);

  // 🏃‍♂️ LIFESTYLE COLORS
  static const Color fitness = Color(0xFF4CAF50);
  static const Color health = Color(0xFF4CAF50);
  static const Color sports = Color(0xFF2196F3);
  static const Color wellness = Color(0xFF00BCD4);

  // 🍽️ FOOD COLORS
  static const Color food = Color(0xFFFF9800);
  static const Color cooking = Color(0xFF8D6E63);
  static const Color dining = Color(0xFF795548);

  // 🌍 TRAVEL COLORS
  static const Color travel = Color(0xFF00BCD4);
  static const Color adventure = Color(0xFF4CAF50);
  static const Color exploration = Color(0xFF2196F3);

  // 🎯 STATUS COLORS
  static const Color online = Color(0xFF10B981);
  static const Color offline = Color(0xFF94A3B8);
  static const Color verified = Color(0xFF10B981);
  static const Color newUser = Color(0xFF3B82F6);

  // 🔧 UTILITY COLORS
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color shadow = Color(0x1A000000);
  static const Color disabled = Color(0xFF94A3B8);
  
  // 🎨 AUTH SCREEN COLORS
  static const Color iconBackgroundColor = Color(0xFFDFF5E2); // Light green for icon background

  // 📱 NAVIGATION COLORS - Afrocentric Theme
  static const Color navSelected = Color(0xFF008037); // Green for active
  static const Color navUnselected = Color(0xFF666666); // Grey for inactive
  static const Color navBackground = Colors.white; // White nav bar

  // 🎨 GRADIENT DEFINITIONS
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightGradient = LinearGradient(
    colors: [gradientLight, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [gradientStart, gradientDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 🌟 SHADOW DEFINITIONS
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: shadow,
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: primaryGreen.withOpacity(0.3),
          blurRadius: 15,
          offset: const Offset(0, 6),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get iconShadow => [
        BoxShadow(
          color: shadow,
          blurRadius: 10,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
      ];

  // 🎯 THEME DATA - Afrocentric Theme
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          brightness: Brightness.light,
          primary: primaryGreen,
          secondary: accentGreen,
          surface: surfaceColor,
          background: backgroundColor,
          error: error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: textPrimary,
        ),
        cardTheme: CardThemeData(
          color: cardColor,
          elevation: 0,
          shadowColor: shadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: textOnPrimary,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
          ),
          headlineSmall: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(
            color: textPrimary,
          ),
          bodyMedium: TextStyle(
            color: textPrimary,
          ),
          bodySmall: TextStyle(
            color: textSecondary,
          ),
        ),
      );
}
