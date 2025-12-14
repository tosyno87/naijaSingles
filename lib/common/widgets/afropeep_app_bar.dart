import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Reusable AppBar for authentication screens
/// Provides consistent transparent background with green back button and title
class AfropeepAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? titleColor;
  final Color? backButtonColor;
  final bool centerTitle;

  const AfropeepAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.backgroundColor,
    this.titleColor,
    this.backButtonColor,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackColor = backButtonColor ?? AppColors.primaryGreen;
    final effectiveTitleColor = titleColor ?? AppColors.primaryGreen;
    final effectiveBgColor = backgroundColor ?? Colors.transparent;

    return AppBar(
      backgroundColor: effectiveBgColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        color: effectiveBackColor,
        onPressed: onBack ?? () => Navigator.of(context).pop(),
      ),
      title: Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: effectiveTitleColor,
        ),
      ),
      centerTitle: centerTitle,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

