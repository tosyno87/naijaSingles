import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Reusable circular icon container for authentication screens
/// Provides consistent styling with light green background and shadow
class AuthIconContainer extends StatelessWidget {
  const AuthIconContainer({
    required this.icon,
    super.key,
    this.size = 100,
    this.iconColor,
    this.backgroundColor,
  });
  final IconData icon;
  final double size;
  final Color? iconColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final iconBgColor = backgroundColor ?? AppColors.iconBackgroundColor;
    final iconCol = iconColor ?? AppColors.primaryGreen;
    const primaryColor = AppColors.primaryGreen;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: iconBgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: iconCol,
        size: size * 0.5, // Icon is 50% of container size
      ),
    );
  }
}
