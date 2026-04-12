import 'package:flutter/material.dart';

import '../../../../common/constants/app_colors.dart';

/// App-wide settings switches: gray off, brand on.
Widget settingsSwitchTheme({
  required BuildContext context,
  required Widget child,
}) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return SwitchTheme(
    data: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return dark ? Colors.grey.shade600 : Colors.grey.shade400;
        }
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryGreen;
        }
        return dark ? Colors.grey.shade500 : Colors.grey.shade400;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return dark ? Colors.grey.shade800 : Colors.grey.shade300;
        }
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryGreen.withValues(alpha: 0.38);
        }
        return dark ? Colors.grey.shade700 : Colors.grey.shade300;
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    child: child,
  );
}
