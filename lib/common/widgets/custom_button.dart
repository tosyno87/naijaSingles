import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final Color color;
  final bool active;
  final double? width;

  const CustomButton({
    super.key,
    required this.text,
    required this.onTap,
    required this.color,
    required this.active,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: active ? onTap : null,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          // Use the suggested medium sea green color
          color: active ? const Color(0xFF27AE60) : Colors.grey[300],
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(30),
          // Add subtle shadow for depth
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        height: 56, // Fixed height for better visibility
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Center(
          child: Text(
            text.tr().toString(),
            style: TextStyle(
              fontSize: 16,
              // Keep text white for contrast against green background
              color: active ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
