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

            // Photo list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: maxPhotos,
                itemBuilder: (context, index) {
                  final photo = index < uploadedPhotos.length 
                      ? uploadedPhotos[index] 
                      : null;
                  final isFirstPhoto = index == 0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildPhotoCard(
                      photo: photo,
                      index: index,
                      isMainPhoto: isFirstPhoto,
                      onTap: () => _showAddPhotoOptions(index),
                      onRemove: photo != null 
                          ? () => _removePhoto(index)
                          : null,
                      onReorderUp: index > 0 && photo != null
                          ? () => _movePhoto(index, index - 1)
                          : null,
                      onReorderDown: index < uploadedCount - 1 && photo != null
                          ? () => _movePhoto(index, index + 1)
                          : null,
                    ),
                  );
                },
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
                      // Add photo button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddPhotoOptions(uploadedCount),
                          icon: const Icon(Icons.add_photo_alternate, size: 22),
                          label: Text(
                            uploadedCount == 0
                                ? 'Add Your First Photo'
                                : 'Add Another Photo',
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

  Widget _buildPhotoCard({
    required File? photo,
    required int index,
    required bool isMainPhoto,
    required VoidCallback onTap,
    VoidCallback? onRemove,
    VoidCallback? onReorderUp,
    VoidCallback? onReorderDown,
  }) => GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: isMainPhoto ? 1.0 : 0.75, // Square for main photo, 4:3 for others
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: photo == null ? Colors.grey.shade100 : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isMainPhoto && photo != null
                  ? primaryGreen
                  : Colors.grey.shade300,
              width: isMainPhoto && photo != null ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              // Photo or empty state - fills entire container
              if (photo != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    photo,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover, // Fill container completely
                  ),
                )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add Photo',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

            // Main photo badge
            if (isMainPhoto && photo != null)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Main Photo',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Reorder buttons (only show if photo exists)
            if (photo != null) ...[
              // Move up button
              if (onReorderUp != null)
                Positioned(
                  top: 12,
                  right: 48,
                  child: GestureDetector(
                    onTap: onReorderUp,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_upward,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),

              // Move down button
              if (onReorderDown != null)
                Positioned(
                  top: 48,
                  right: 48,
                  child: GestureDetector(
                    onTap: onReorderDown,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_downward,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),

              // Delete button
              if (onRemove != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
            ],
            ],
          ),
        ),
      ),
    );

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
