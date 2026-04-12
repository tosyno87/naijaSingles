import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../common/constants/app_colors.dart';

/// Typography for Account Settings and related drill-downs.
class SettingsTextStyles {
  SettingsTextStyles._();

  static TextStyle sectionLabel(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.montserrat(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
      color: dark ? Colors.grey.shade400 : AppColors.textSecondary,
    );
  }

  static TextStyle rowTitle(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.montserrat(
      fontSize: 17,
      fontWeight: fontWeight,
      color: color ?? (dark ? Colors.white : AppColors.textPrimary),
    );
  }

  static TextStyle rowSubtitle(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.montserrat(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.25,
      color: dark ? Colors.grey.shade400 : AppColors.textSecondary,
    );
  }

  static TextStyle consequence(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.montserrat(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.35,
      color: dark ? Colors.grey.shade500 : AppColors.textSecondary,
    );
  }
}
