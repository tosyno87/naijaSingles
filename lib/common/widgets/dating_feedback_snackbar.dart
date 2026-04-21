import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Floating snack bars for Connect / profile flows: sits above home indicator,
/// main tab bar, and on-profile action rows so feedback does not cover primary actions.
class DatingFeedbackSnackBar {
  DatingFeedbackSnackBar._();

  /// Extra space above the bottom safe area. Use a larger value when the screen
  /// has a thick bottom bar (e.g. profile detail actions) instead of only the main tab bar.
  static const double marginAboveMainTabBar = 72;

  /// Clears the Connect / profile three-button action row (Pass / Super Like / Like).
  /// Tuned to keep feedback above actions without covering Pass/Super Like/Like.
  static const double marginAboveProfileActions = 160;

  static void show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 3),
    double bottomMarginAddition = marginAboveMainTabBar,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }

    final mq = MediaQuery.of(context);
    final bottom = mq.viewPadding.bottom + bottomMarginAddition;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: backgroundColor,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(16, 0, 16, bottom),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }
}
