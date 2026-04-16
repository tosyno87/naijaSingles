import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';

/// Shared empty state view for use across all screens.
///
/// Displays an icon, title, subtitle and an optional action button.
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    required this.title,
    super.key,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.iconSize,
    this.compactSpacing = false,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.footerLinkLabel,
    this.onFooterLink,
    /// When set with [footerLinkLabel], shows above the link to anchor it to context.
    this.footerLinkHint,
    this.contentPadding,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  /// When null, uses default size or a slightly smaller size when [compactSpacing] is true.
  final double? iconSize;
  /// Tighter gaps between icon, title, subtitle, and primary button (~8–12 px less).
  final bool compactSpacing;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  /// Small text link shown below the primary button (e.g. “Adjust preferences”).
  final String? footerLinkLabel;
  final VoidCallback? onFooterLink;
  /// One line of secondary copy tying [footerLinkLabel] to the section (utility row).
  final String? footerLinkHint;
  final EdgeInsetsGeometry? contentPadding;

  static double _defaultIconSize({required bool compact}) {
    const double standard = AppSpacing.iconXxl + 16;
    return compact ? standard * 0.85 : standard;
  }

  @override
  Widget build(BuildContext context) {
    final double resolvedIconSize =
        iconSize ?? _defaultIconSize(compact: compactSpacing);
    final double gapAfterIcon = compactSpacing ? AppSpacing.xs : AppSpacing.sm;
    final double gapTitleToSubtitle =
        compactSpacing ? AppSpacing.xs : AppSpacing.sm;
    final double gapBeforePrimary =
        compactSpacing ? AppSpacing.sm : AppSpacing.md;

    return Center(
      child: SingleChildScrollView(
        padding:
            contentPadding ?? const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: resolvedIconSize,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            SizedBox(height: gapAfterIcon),
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: gapTitleToSubtitle),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              SizedBox(height: gapBeforePrimary),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm + 4,
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (footerLinkLabel != null && onFooterLink != null) ...[
              SizedBox(
                height: footerLinkHint != null ? AppSpacing.sm : AppSpacing.xs,
              ),
              if (footerLinkHint != null) ...[
                Text(
                  footerLinkHint!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    height: 1.3,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Semantics(
                  button: true,
                  label: footerLinkLabel,
                  child: GestureDetector(
                    onTap: onFooterLink,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        footerLinkLabel!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                TextButton(
                  onPressed: onFooterLink,
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    footerLinkLabel!,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ],
            if (onSecondaryAction != null &&
                secondaryActionLabel != null) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: onSecondaryAction,
                child: Text(
                  secondaryActionLabel!,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
