// ⚠️ DEPRECATED: This file is deprecated. Use app_colors.dart instead.
//
// All colors have been moved to lib/common/constants/app_colors.dart
// This file is kept for backward compatibility during migration.
//
// TODO: Migrate all imports from 'constants/colors.dart' to 'constants/app_colors.dart'
// Then delete this file.

@Deprecated(
    'Use app_colors.dart instead. This file will be removed in a future version.')
library;

import 'package:flutter/material.dart';

// Re-export from app_colors.dart for backward compatibility
export 'app_colors.dart' show AppColors;

// Deprecated top-level constants - use AppColors from app_colors.dart instead
@Deprecated('Use AppColors.primaryGreen from app_colors.dart')
const Color primaryColor = Color(0xFF008037);

@Deprecated(
    'Use AppColors.backgroundColor (white) from app_colors.dart. Old cream color is deprecated.')
const Color backgroundColor = Colors.white; // Updated to white (was cream)

@Deprecated('Use AppColors.cardColor from app_colors.dart')
const Color cardColor = Color(0xFFFFFFFF);

@Deprecated('Use AppColors.textPrimary from app_colors.dart')
const Color textPrimary = Color(0xFF5D4037);

@Deprecated('Use AppColors.textSecondary from app_colors.dart')
const Color textSecondary = Color(0xFF8D6E63);

@Deprecated('Use AppColors.textTertiary from app_colors.dart')
const Color textLight = Color(0xFF9E9E9E);

@Deprecated('Use AppColors.error from app_colors.dart')
const Color errorColor = Color(0xFFFF5A5F);

@Deprecated('Use AppColors.success from app_colors.dart')
const Color successColor = Color(0xFF4CAF50);

@Deprecated('Use AppColors.warning from app_colors.dart')
const Color warningColor = Color(0xFFFF9800);

@Deprecated('Use AppColors.info from app_colors.dart')
const Color infoColor = Color(0xFF2196F3);
