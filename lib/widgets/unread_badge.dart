import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget for displaying unread message count badge
class UnreadBadge extends StatelessWidget {
  final int count;
  final double? size;
  final Color? backgroundColor;
  final Color? textColor;

  const UnreadBadge({
    super.key,
    required this.count,
    this.size,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final badgeSize = size ?? 20.0;
    final bgColor = backgroundColor ?? Colors.red;
    final txtColor = textColor ?? Colors.white;

    return Container(
      constraints: BoxConstraints(minWidth: badgeSize),
      height: badgeSize,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(badgeSize / 2),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : count.toString(),
          style: GoogleFonts.montserrat(
            fontSize: badgeSize * 0.6,
            fontWeight: FontWeight.bold,
            color: txtColor,
          ),
        ),
      ),
    );
  }
}

/// Widget for displaying unread indicator dot
class UnreadDot extends StatelessWidget {
  final bool hasUnread;
  final double? size;
  final Color? color;

  const UnreadDot({
    super.key,
    required this.hasUnread,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasUnread) return const SizedBox.shrink();

    final dotSize = size ?? 8.0;
    final dotColor = color ?? Colors.red;

    return Container(
      width: dotSize,
      height: dotSize,
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: dotColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

/// Widget for displaying unread indicator with optional badge
class UnreadIndicator extends StatelessWidget {
  final int? count;
  final bool showDot;
  final double? badgeSize;
  final double? dotSize;
  final Color? badgeColor;
  final Color? dotColor;
  final Color? textColor;

  const UnreadIndicator({
    super.key,
    this.count,
    this.showDot = true,
    this.badgeSize,
    this.dotSize,
    this.badgeColor,
    this.dotColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (count != null && count! > 0) {
      return UnreadBadge(
        count: count!,
        size: badgeSize,
        backgroundColor: badgeColor,
        textColor: textColor,
      );
    } else if (showDot) {
      return UnreadDot(
        hasUnread: true,
        size: dotSize,
        color: dotColor,
      );
    }
    return const SizedBox.shrink();
  }
}
