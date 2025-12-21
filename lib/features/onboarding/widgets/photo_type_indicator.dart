import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/enhanced_photo_upload_screen.dart';

class PhotoTypeIndicator extends StatelessWidget {
  const PhotoTypeIndicator({
    required this.type,
    super.key,
  });
  final PhotoType type;

  // Theme colors
  static const Color afropeepGreen = Color(0xFF008037); // MVP green
  static const Color textDarkBrown = Color(0xFF3A1D0F);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: _getTypeColor().withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getTypeIcon(),
              size: 12,
              color: Colors.white,
            ),
            const SizedBox(width: 3),
            Text(
              _getTypeLabel(),
              style: GoogleFonts.montserrat(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );

  Color _getTypeColor() {
    switch (type) {
      case PhotoType.closeUp:
        return const Color(0xFFFFD700); // Gold
      case PhotoType.fullBody:
        return Colors.blue;
      case PhotoType.activity:
        return Colors.red;
      case PhotoType.social:
        return Colors.purple;
      case PhotoType.lifestyle:
        return Colors.orange;
    }
  }

  IconData _getTypeIcon() {
    switch (type) {
      case PhotoType.closeUp:
        return Icons.face;
      case PhotoType.fullBody:
        return Icons.person;
      case PhotoType.activity:
        return Icons.sports_soccer;
      case PhotoType.social:
        return Icons.group;
      case PhotoType.lifestyle:
        return Icons.favorite;
    }
  }

  String _getTypeLabel() {
    switch (type) {
      case PhotoType.closeUp:
        return 'Face';
      case PhotoType.fullBody:
        return 'Body';
      case PhotoType.activity:
        return 'Activity';
      case PhotoType.social:
        return 'Social';
      case PhotoType.lifestyle:
        return 'Life';
    }
  }
}
