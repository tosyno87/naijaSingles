import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Button variant for styling
enum AuthButtonVariant { primary, secondary }

/// Afropeep-branded primary button widget
/// Reusable button for authentication and action screens
class AfropeepPrimaryButton extends StatelessWidget {
  const AfropeepPrimaryButton({
    required this.text,
    super.key,
    this.icon,
    this.backgroundColor,
    this.gradient,
    this.textColor,
    this.onPressed,
    this.isLoading = false,
    this.variant = AuthButtonVariant.primary,
    this.width,
    this.height,
    this.borderRadius,
    this.disabledBackgroundColor,
  });
  final IconData? icon;
  final String text;
  final Color? backgroundColor;

  /// Optional gradient; when set, overrides [backgroundColor] for enabled state.
  final LinearGradient? gradient;
  final Color? textColor;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AuthButtonVariant variant;
  final double? width;
  final double? height;

  /// Custom border radius (e.g. 28 for pill). Default: 16 primary, 28 secondary.
  final double? borderRadius;
  final Color? disabledBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final bool isPrimary = variant == AuthButtonVariant.primary;
    final bgColor = backgroundColor ??
        (isPrimary ? AppColors.primaryGreen : Colors.grey.shade400);
    final txtColor = textColor ?? Colors.white;
    final btnHeight = height ?? 56;
    final radius = borderRadius ?? (isPrimary ? 16.0 : 28.0);

    final isEnabled = onPressed != null && !isLoading;
    final effectiveBgColor =
        isEnabled ? bgColor : (disabledBackgroundColor ?? Colors.grey.shade400);

    final Widget child = isLoading
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
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: txtColor,
                ),
              );

    if (gradient != null && isEnabled) {
      return SizedBox(
        width: width ?? double.infinity,
        height: btnHeight,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(radius),
            child: Container(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(radius),
                boxShadow: isPrimary
                    ? [
                        BoxShadow(
                          color: AppColors.primaryGreen.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: child,
            ),
          ),
        ),
      );
    }

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
            borderRadius: BorderRadius.circular(radius),
          ),
          elevation: isEnabled && isPrimary ? 3 : 1,
          shadowColor: isEnabled && isPrimary
              ? AppColors.primaryGreen.withValues(alpha: 0.3)
              : Colors.transparent,
          disabledBackgroundColor:
              disabledBackgroundColor ?? Colors.grey.shade400,
        ),
        child: child,
      ),
    );
  }
}
