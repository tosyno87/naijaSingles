import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Button variant for styling
enum AuthButtonVariant { primary, secondary }

/// Modern dating app style primary button widget
/// Reusable button for authentication and action screens
class AfropeepPrimaryButton extends StatelessWidget {

  const AfropeepPrimaryButton({
    required this.text, super.key,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.onPressed,
    this.isLoading = false,
    this.variant = AuthButtonVariant.primary,
    this.width,
    this.height,
  });
  final IconData? icon;
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AuthButtonVariant variant;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final bool isPrimary = variant == AuthButtonVariant.primary;
    final bgColor = backgroundColor ??
        (isPrimary ? AppColors.primaryGreen : Colors.grey.shade400);
    final txtColor = textColor ?? Colors.white;
    final btnHeight = height ?? 56;

    final isEnabled = onPressed != null && !isLoading;
    final effectiveBgColor = isEnabled ? bgColor : Colors.grey.shade400;

    return SizedBox(
      width: width ?? double.infinity,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBgColor,
          foregroundColor: txtColor,
          minimumSize: Size.fromHeight(btnHeight),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isPrimary ? 16 : 28), // Pill shape for secondary
          ),
          elevation: isEnabled && isPrimary ? 3 : 1,
          shadowColor: isEnabled && isPrimary
              ? AppColors.primaryGreen.withValues(alpha: 0.3)
              : Colors.transparent,
          disabledBackgroundColor: Colors.grey.shade400,
        ),
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: txtColor,
                  strokeWidth: 2,
                ),
              )
            : icon != null
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          size: 22,
                          color: txtColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            text,
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: txtColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                : Text(
                    text,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: txtColor,
                    ),
                  ),
      ),
    );
  }
}

