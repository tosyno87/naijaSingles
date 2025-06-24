import 'package:flutter/material.dart';

// Afropeep MVP Color Scheme - Consistent across the app
const Color primaryColor = Color(0xFF008037); // Deep green
const Color backgroundColor = Color(0xFFFFF6E5); // Light cream
const Color cardColor = Color(0xFFFFFFFF); // White for cards
const Color textPrimary = Color(0xFF5D4037); // Brown
const Color textSecondary = Color(0xFF8D6E63); // Light brown
const Color textLight = Color(0xFF9E9E9E); // Gray

// Legacy colors - deprecated, use above colors instead
@deprecated
const Color secondryColor = Colors.grey;
@deprecated
const Color darkPrimaryColor = Color(0x222E8B57);
@deprecated
const Color textColor = Colors.white;

// Accent colors for specific use cases
const Color successColor = Color(0xFF4CAF50); // Green for success states
const Color errorColor = Color(0xFFFF5A5F); // Red for errors/dislike
const Color warningColor = Color(0xFFFF9800); // Orange for warnings
const Color infoColor = Color(0xFF2196F3); // Blue for info

// Opacity variations of primary colors
const Color primaryColorLight = Color(0x1A008037); // 10% opacity
const Color primaryColorMedium = Color(0x4D008037); // 30% opacity
const Color backgroundColorDark = Color(0xFFFDF1E7); // Slightly darker cream
