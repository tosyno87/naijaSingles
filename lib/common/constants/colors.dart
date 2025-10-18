import 'package:flutter/material.dart';

// Afropeep MVP Color Scheme - Consistent across the app
const Color primaryColor = Color(0xFF008037); // Deep green
const Color backgroundColor = Color(0xFFE8F5E8); // Soft mint green
const Color cardColor = Color(0xFFFFFFFF); // White for cards
const Color textPrimary = Color(0xFF5D4037); // Brown
const Color textSecondary = Color(0xFF8D6E63); // Light brown
const Color textLight = Color(0xFF9E9E9E); // Gray

// Legacy colors - deprecated, use above colors instead
@Deprecated('Use Colors.grey instead')
const Color secondaryColor = Colors.grey;
@Deprecated('Use primaryColor instead')
const Color darkPrimaryColor = Color(0x222E8B57);
@Deprecated('Use textPrimary or textSecondary instead')
const Color textColor = Colors.white;

// Accent colors for specific use cases
const Color successColor = Color(0xFF4CAF50); // Green for success states
const Color errorColor = Color(0xFFFF5A5F); // Red for errors/dislike
const Color warningColor = Color(0xFFFF9800); // Orange for warnings
const Color infoColor = Color(0xFF2196F3); // Blue for info

// Opacity variations of primary colors
const Color primaryColorLight = Color(0x1A008037); // 10% opacity
const Color primaryColorMedium = Color(0x4D008037); // 30% opacity
const Color backgroundColorDark = Color(0xFFD4F0D4); // Slightly darker mint

// AppColors class for backward compatibility
class AppColors {
  static const Color primaryColor = Color(0xFF008037);
  static const Color backgroundColor = Color(0xFFE8F5E8);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF5D4037);
  static const Color textSecondary = Color(0xFF8D6E63);
  static const Color textLight = Color(0xFF9E9E9E);
  static const Color accentColor = Color(0xFFFF5A5F);
  static const Color errorColor = Color(0xFFFF5A5F);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color infoColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF8D6E63); // Add this back

  @Deprecated('Use AppColors.textSecondary instead')
  static const Color secondryColor = textSecondary;
}
