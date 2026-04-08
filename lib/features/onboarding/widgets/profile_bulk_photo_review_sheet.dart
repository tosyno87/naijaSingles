import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../onboarding_theme.dart';

/// Bottom sheet shown after multi-select from Photo Library.
/// Displays thumbnails in a reorderable horizontal list so the user can
/// control which photo becomes "Main" (index 0) before cropping begins.
class ProfileBulkPhotoReviewSheet extends StatefulWidget {
  const ProfileBulkPhotoReviewSheet({required this.photos, super.key});

  final List<File> photos;

  @override
  State<ProfileBulkPhotoReviewSheet> createState() =>
      _ProfileBulkPhotoReviewSheetState();
}

class _ProfileBulkPhotoReviewSheetState
    extends State<ProfileBulkPhotoReviewSheet> {
  late final List<File> _ordered = List.of(widget.photos);

  @override
  Widget build(BuildContext context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              '${_ordered.length} selected',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: OnboardingTheme.titleColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Drag to reorder. First photo becomes your main.',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: OnboardingTheme.subtitleColor,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ReorderableListView(
                scrollDirection: Axis.horizontal,
                proxyDecorator: _proxyDecorator,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _ordered.removeAt(oldIndex);
                    _ordered.insert(newIndex, item);
                  });
                },
                children: [
                  for (int i = 0; i < _ordered.length; i++)
                    _buildThumbnail(i),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize:
                          const Size.fromHeight(OnboardingTheme.buttonHeight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          OnboardingTheme.buttonRadius,
                        ),
                      ),
                      side: const BorderSide(color: OnboardingTheme.fieldBorder),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        color: OnboardingTheme.subtitleColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.pop(context, List<File>.of(_ordered)),
                    style: FilledButton.styleFrom(
                      minimumSize:
                          const Size.fromHeight(OnboardingTheme.buttonHeight),
                      backgroundColor: OnboardingTheme.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          OnboardingTheme.buttonRadius,
                        ),
                      ),
                    ),
                    child: Text(
                      'Continue',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) =>
      AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Material(
        elevation: 4,
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
      child: child,
    );

  Widget _buildThumbnail(int index) => Container(
      key: ValueKey(_ordered[index].path),
      width: 88,
      height: 88,
      margin: EdgeInsets.only(right: index < _ordered.length - 1 ? 8 : 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: index == 0
            ? Border.all(color: OnboardingTheme.primaryGreen, width: 2.5)
            : Border.all(color: OnboardingTheme.fieldBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(_ordered[index], fit: BoxFit.cover),
          if (index == 0)
            Positioned(
              bottom: 4,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: OnboardingTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Main',
                    style: GoogleFonts.montserrat(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
}
