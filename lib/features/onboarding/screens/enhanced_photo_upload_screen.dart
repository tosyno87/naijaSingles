import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../features/user/controllers/onboarding_controller.dart';

/// Enum representing different types of photos for user profiles
enum PhotoType {
  closeUp,
  fullBody,
  activity,
  social,
  lifestyle,
}

/// Guidance information for each photo type
class PhotoTypeGuidance {

  const PhotoTypeGuidance({
    required this.type,
    required this.title,
    required this.description,
    this.isPrimary = false,
  });
  final PhotoType type;
  final String title;
  final String description;
  final bool isPrimary;
}

class EnhancedPhotoUploadScreen extends StatefulWidget {
  const EnhancedPhotoUploadScreen({super.key});

  @override
  State<EnhancedPhotoUploadScreen> createState() =>
      _EnhancedPhotoUploadScreenState();
}

class _EnhancedPhotoUploadScreenState extends State<EnhancedPhotoUploadScreen> {
  // MVP Color Scheme
  static const Color primaryGreen = Color(0xFF008037);
  static const Color backgroundColor = Colors.white;
  static const Color textPrimary = Color(0xFF3E1F0D);
  static const Color dividerColor = Color(0xFFE5E5E5);

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<OnboardingController>(context);
    final uploadedPhotos = controller.profilePhotos;
    final uploadedCount = uploadedPhotos.where((photo) => photo != null).length;
    final hasMinimumPhotos = uploadedCount >= 3;
    const maxPhotos = 6; // Allow up to 6 photos like popular apps

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: primaryGreen),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Add Photos',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: dividerColor,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator and count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: uploadedCount / 6,
                      backgroundColor: dividerColor,
                      valueColor: const AlwaysStoppedAnimation<Color>(primaryGreen),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Photo count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$uploadedCount of 6 photos',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                      if (!hasMinimumPhotos)
                        Text(
                          'Add ${3 - uploadedCount} more',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: dividerColor),

            // Photo grid - Tinder-style 3 photos side by side
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Add at least 3 photos',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Profiles with 3+ photos get 5x more matches',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // 3-photo grid (Tinder style)
                    Row(
                      children: [
                        Expanded(
                          child: _buildPhotoGridItem(
                            photo: uploadedPhotos[0],
                            index: 0,
                            isMainPhoto: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPhotoGridItem(
                            photo: uploadedPhotos[1],
                            index: 1,
                            isMainPhoto: false,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPhotoGridItem(
                            photo: uploadedPhotos[2],
                            index: 2,
                            isMainPhoto: false,
                          ),
                        ),
                      ],
                    ),
                    
                    // Additional photos (optional, shown below grid if added)
                    if (uploadedCount > 3) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Additional Photos (Optional)',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: List.generate(
                          maxPhotos - 3,
                          (index) {
                            final actualIndex = index + 3;
                            final photo = actualIndex < uploadedPhotos.length 
                                ? uploadedPhotos[actualIndex] 
                                : null;
                            return SizedBox(
                              width: (MediaQuery.of(context).size.width - 64 - 36) / 3,
                              child: _buildPhotoGridItem(
                                photo: photo,
                                index: actualIndex,
                                isMainPhoto: false,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom section
            DecoratedBox(
              decoration: BoxDecoration(
                color: backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Only show "Add Photo" button if less than 3 photos
                      if (uploadedCount < 3)
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Find first empty slot
                              int emptySlot = uploadedPhotos.indexWhere((p) => p == null);
                              if (emptySlot == -1) emptySlot = uploadedCount;
                              _showAddPhotoOptions(emptySlot);
                            },
                            icon: const Icon(Icons.add_photo_alternate, size: 22),
                            label: Text(
                              'Add Photo ${uploadedCount + 1}',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      // Removed Continue button - navigation handled by OnboardingMain wrapper
                      if (!hasMinimumPhotos && uploadedCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'Add at least 3 photos to continue',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
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

  // Tinder-style photo grid item - Square (1:1) aspect ratio
  Widget _buildPhotoGridItem({
    required File? photo,
    required int index,
    required bool isMainPhoto,
  }) {
    return GestureDetector(
      onTap: () => _showAddPhotoOptions(index),
      child: AspectRatio(
        aspectRatio: 1.0, // Square - Industry standard (Tinder, Bumble, Hinge)
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: photo == null ? Colors.grey.shade100 : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isMainPhoto && photo != null
                  ? primaryGreen
                  : Colors.grey.shade300,
              width: isMainPhoto && photo != null ? 2.5 : 1.5,
            ),
            boxShadow: photo != null
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              // Photo - use BoxFit.contain to show full image without cropping
              if (photo != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: Colors.black, // Black background for better contrast
                    child: Image.file(
                      photo,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain, // Show full photo without cropping
                    ),
                  ),
                )
              else
                // Empty state
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 40,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add Photo',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (isMainPhoto)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Main',
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: primaryGreen,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              // Main photo badge (only if photo exists)
              if (isMainPhoto && photo != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Main',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Delete/Replace button (only if photo exists)
              if (photo != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _removePhoto(index),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddPhotoOptions(int index) async {
    final controller = Provider.of<OnboardingController>(context, listen: false);
    
    // If clicking on existing photo, show options
    if (index < controller.profilePhotos.length && 
        controller.profilePhotos[index] != null) {
      _showPhotoOptionsBottomSheet(index);
      return;
    }

    // Otherwise, show source selection
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: primaryGreen),
              title: Text(
                'Take Photo',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: primaryGreen),
              title: Text(
                'Choose from Gallery',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source != null) {
      await controller.pickProfilePhoto(source, index, context);
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _showPhotoOptionsBottomSheet(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (index > 0)
              ListTile(
                leading: const Icon(Icons.star, color: primaryGreen),
                title: Text(
                  'Set as Main Photo',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _setAsMainPhoto(index);
                },
              ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: primaryGreen),
              title: Text(
                'Replace Photo',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                final controller = Provider.of<OnboardingController>(context, listen: false);
                final currentContext = context; // Capture context before async
                final source = await showModalBottomSheet<ImageSource>(
                  context: context,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.camera_alt, color: primaryGreen),
                          title: Text(
                            'Take Photo',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () => Navigator.pop(context, ImageSource.camera),
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library, color: primaryGreen),
                          title: Text(
                            'Choose from Gallery',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () => Navigator.pop(context, ImageSource.gallery),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
                if (source != null && currentContext.mounted) {
                  await controller.pickProfilePhoto(source, index, currentContext);
                  if (mounted) {
                    setState(() {});
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(
                'Delete Photo',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _removePhoto(index);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _removePhoto(int index) {
    final controller = Provider.of<OnboardingController>(context, listen: false);
    controller.removeProfilePhoto(index);
    setState(() {});
  }

  void _movePhoto(int fromIndex, int toIndex) {
    final controller = Provider.of<OnboardingController>(context, listen: false);
    final photos = List<File?>.from(controller.profilePhotos);
    final photo = photos.removeAt(fromIndex);
    photos.insert(toIndex, photo);

    // Update controller
    for (int i = 0; i < photos.length; i++) {
      controller.profilePhotos[i] = photos[i];
    }
    setState(() {});
  }

  void _setAsMainPhoto(int index) {
    if (index == 0) return;
    _movePhoto(index, 0);
  }
}
