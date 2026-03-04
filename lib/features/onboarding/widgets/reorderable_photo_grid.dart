import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/enhanced_photo_upload_screen.dart';
import '../data/services/photo_quality_analyzer.dart';
import 'photo_type_indicator.dart';

class ReorderablePhotoGrid extends StatefulWidget {
  const ReorderablePhotoGrid({
    required this.photos,
    required this.photoGuidance,
    required this.onReorder,
    required this.onTap,
    required this.onRemove,
    required this.onSetPrimary,
    super.key,
  });
  final List<File?> photos;
  final Map<int, PhotoTypeGuidance> photoGuidance;
  final Function(int, int) onReorder;
  final Function(int) onTap;
  final Function(int) onRemove;
  final Function(int) onSetPrimary;

  @override
  State<ReorderablePhotoGrid> createState() => _ReorderablePhotoGridState();
}

class _ReorderablePhotoGridState extends State<ReorderablePhotoGrid> {
  // Theme colors
  static const Color afropeepGreen = Color(0xFF008037); // MVP green
  static const Color cardBackground = Color(0xFFF7E8DA);
  static const Color textDarkBrown = Color(0xFF3A1D0F);
  static const Color textLightBrown = Color(0xFF8B6C59);
  static const Color goldAccent = Color(0xFFFFD700);
  static const Color warningOrange = Color(0xFFFF8C00);

  int? _draggedIndex;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reordering instructions
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: afropeepGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: afropeepGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.drag_indicator,
                  color: afropeepGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Long press and drag photos to reorder them. Your first photo will be your main profile photo.',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: afropeepGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Primary photo (always first)
          _buildPhotoCard(0, isPrimary: true),

          const SizedBox(height: 12),

          // Reorderable grid for other photos
          ReorderableWrap(
            spacing: 12,
            runSpacing: 12,
            onReorder: (oldIndex, newIndex) {
              // Adjust indices since we're not including the primary photo
              final adjustedOldIndex = oldIndex + 1;
              final adjustedNewIndex = newIndex + 1;
              widget.onReorder(adjustedOldIndex, adjustedNewIndex);
            },
            children: List.generate(4, (index) {
              final photoIndex = index + 1; // Skip primary photo
              return _buildPhotoCard(
                photoIndex,
                key: ValueKey('photo_$photoIndex'),
                isPrimary: false,
              );
            }),
          ),
        ],
      );

  Widget _buildPhotoCard(int index, {required bool isPrimary, Key? key}) {
    final photo = widget.photos[index];
    final guidance = widget.photoGuidance[index]!;
    final bool isRequired = index < 3;

    return GestureDetector(
      key: key,
      onTap: () => widget.onTap(index),
      onLongPress: !isPrimary
          ? () {
              setState(() {
                _draggedIndex = index;
              });
              _showReorderingFeedback();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isPrimary ? double.infinity : null,
        height: isPrimary ? 200 : 150,
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(isPrimary ? 16 : 12),
          border: Border.all(
            color: isPrimary
                ? goldAccent
                : isRequired
                    ? (photo == null
                        ? Colors.red.withValues(alpha: 0.5)
                        : afropeepGreen)
                    : Colors.transparent,
            width: isPrimary ? 3 : 2,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: goldAccent.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : _draggedIndex == index
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
        ),
        child: Stack(
          children: [
            // Photo background
            if (photo != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(isPrimary ? 13 : 10),
                child: Image.file(
                  photo,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),

            // Primary photo badge
            if (isPrimary)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: const BoxDecoration(
                    color: goldAccent,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(13),
                      topRight: Radius.circular(13),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'MAIN PHOTO',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),

            // Content when no photo
            if (photo == null)
              Positioned.fill(
                top: isPrimary ? 40 : 0,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isPrimary ? 12 : 8),
                        decoration: BoxDecoration(
                          color: (isPrimary
                                  ? goldAccent
                                  : _getPhotoTypeColor(guidance.type))
                              .withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getPhotoTypeIcon(guidance.type),
                          size: isPrimary ? 36 : 28,
                          color: isPrimary
                              ? goldAccent
                              : _getPhotoTypeColor(guidance.type),
                        ),
                      ),
                      SizedBox(height: isPrimary ? 8 : 6),
                      Text(
                        guidance.title,
                        style: GoogleFonts.montserrat(
                          fontSize: isPrimary ? 14 : 12,
                          fontWeight: FontWeight.w600,
                          color: textDarkBrown,
                        ),
                      ),
                      if (isPrimary) ...[
                        const SizedBox(height: 4),
                        Flexible(
                          child: Text(
                            guidance.description,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              color: textLightBrown,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      SizedBox(height: isPrimary ? 6 : 4),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isPrimary ? 10 : 8,
                          vertical: isPrimary ? 3 : 2,
                        ),
                        decoration: BoxDecoration(
                          color: isRequired
                              ? Colors.red.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isRequired ? 'REQUIRED' : 'OPTIONAL',
                          style: GoogleFonts.montserrat(
                            fontSize: isPrimary ? 9 : 8,
                            fontWeight: FontWeight.w600,
                            color:
                                isRequired ? Colors.red : Colors.grey.shade600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Photo type indicator for empty slots
            if (photo == null && !isPrimary)
              Positioned(
                top: 8,
                left: 8,
                child: PhotoTypeIndicator(type: guidance.type),
              ),

            // Quality indicator for uploaded photos
            if (photo != null)
              Positioned(
                top: isPrimary ? 48 : 8,
                left: 8,
                child: _buildQualityIndicator(photo),
              ),

            // Drag handle for non-primary photos
            if (!isPrimary && photo != null)
              Positioned(
                top: 8,
                right: 40,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.drag_indicator,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),

            // Remove button
            if (photo != null)
              Positioned(
                top: isPrimary ? 48 : 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => widget.onRemove(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),

            // Set as primary button for non-primary photos with photos
            if (!isPrimary && photo != null)
              Positioned(
                bottom: 8,
                left: 8,
                child: GestureDetector(
                  onTap: () => _showSetPrimaryDialog(index),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: goldAccent.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_border,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'Set Main',
                          style: GoogleFonts.montserrat(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityIndicator(File photo) {
    final quality = PhotoQualityAnalyzer.analyzePhoto(photo);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getQualityColor(quality.qualityScore),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getQualityIcon(quality.qualityScore),
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 2),
          Text(
            _getQualityLabel(quality.qualityScore),
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _getQualityColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return warningOrange;
    return Colors.red;
  }

  IconData _getQualityIcon(int score) {
    if (score >= 80) return Icons.check_circle;
    if (score >= 60) return Icons.warning;
    return Icons.error;
  }

  String _getQualityLabel(int score) {
    if (score >= 80) return 'Great';
    if (score >= 60) return 'Good';
    return 'Poor';
  }

  Color _getPhotoTypeColor(PhotoType type) {
    switch (type) {
      case PhotoType.closeUp:
        return goldAccent;
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

  IconData _getPhotoTypeIcon(PhotoType type) {
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

  void _showReorderingFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.drag_indicator, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Drag to reorder photos',
              style: GoogleFonts.montserrat(fontSize: 14),
            ),
          ],
        ),
        backgroundColor: afropeepGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSetPrimaryDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Set as Main Photo?',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textDarkBrown,
          ),
        ),
        content: Text(
          'This photo will become your main profile photo and appear first to potential matches.',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: textLightBrown,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onSetPrimary(index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: goldAccent,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Set as Main',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom reorderable wrap widget
class ReorderableWrap extends StatefulWidget {
  const ReorderableWrap({
    required this.children,
    required this.onReorder,
    super.key,
    this.spacing = 0,
    this.runSpacing = 0,
  });
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final Function(int, int) onReorder;

  @override
  State<ReorderableWrap> createState() => _ReorderableWrapState();
}

class _ReorderableWrapState extends State<ReorderableWrap> {
  @override
  Widget build(BuildContext context) => ReorderableListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        onReorder: widget.onReorder,
        children: widget.children.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;

          return Container(
            key: ValueKey('reorderable_$index'),
            margin: EdgeInsets.only(
              right: (index % 2 == 0) ? widget.spacing : 0,
              bottom: widget.runSpacing,
            ),
            width:
                (MediaQuery.of(context).size.width - 48 - widget.spacing) / 2,
            child: child,
          );
        }).toList(),
      );
}
