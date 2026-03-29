import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/theme.dart';

/// Shows a dialog wrapped in [MyThemes.lightTheme] so delete-account flows stay
/// visually consistent when the app is in dark mode (dialogs default to dark surface).
Future<T?> showAccountDeletionThemedDialog<T>(
  BuildContext context,
  Widget Function(BuildContext dialogContext) dialogBuilder, {
  bool barrierDismissible = true,
}) =>
    showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => Theme(
        data: MyThemes.lightTheme,
        child: dialogBuilder(ctx),
      ),
    );

/// Default surface for delete warnings (matches settings / cards).
Color get deleteAccountDialogBackgroundColor => AppColors.cardColor;
