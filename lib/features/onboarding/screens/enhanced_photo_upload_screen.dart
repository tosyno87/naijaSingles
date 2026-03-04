import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../common/constants/app_colors.dart';
import '../bloc/onboarding_bloc.dart';

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
  static const Color textPrimary = Color(0xFF3E1F0D);
  static const Color dividerColor = Color(0xFFE5E5E5);

  @override
  Widget build(BuildContext context) => BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        final uploadedPhotos =
            state.data?.profilePhotos ?? List<File?>.filled(9, null);
        return _buildContent(context, uploadedPhotos);
      },
    );

  Widget _buildContent(BuildContext context, List<File?> uploadedPhotos) => Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
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
            // Photo grid - Tinder-style: Scrollable grid showing up to 9 photos
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: List.generate(9, (index) {
                    final photo = index < uploadedPhotos.length
                        ? uploadedPhotos[index]
                        : null;
                    return SizedBox(
                      width: (MediaQuery.of(context).size.width - 72) /
                          3, // 3 columns
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: _buildPhotoGridItem(
                          photo: photo,
                          index: index,
                          isMainPhoto: index == 0,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // Bottom section - Minimal like Tinder (no button needed, photos are tappable)
          ],
        ),
      ),
    );

  // Tinder-style photo grid item - Minimal, clean, edge-to-edge
  Widget _buildPhotoGridItem({
    required File? photo,
    required int index,
    required bool isMainPhoto,
  }) => GestureDetector(
      onTap: () => _showAddPhotoOptions(index),
      child: AspectRatio(
        aspectRatio: 1, // Square - Industry standard (Tinder, Bumble, Hinge)
        child: Container(
          decoration: BoxDecoration(
            color: photo == null ? Colors.grey.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            // Subtle border only for main photo
            border: isMainPhoto && photo != null
                ? Border.all(color: primaryGreen, width: 3)
                : Border.all(color: Colors.grey.shade200),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Photo - Tinder style: edge-to-edge fill
              if (photo != null)
                Image.file(
                  photo,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
              else
                // Empty state
                Center(
                  child: Icon(
                    Icons.add_photo_alternate,
                    size: 48,
                    color: Colors.grey.shade300,
                  ),
                ),

              // Main photo badge (only if photo exists)
              if (isMainPhoto && photo != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            ],
          ),
        ),
      ),
    );

  Future<void> _showAddPhotoOptions(int index) async {
    final bloc = context.read<OnboardingBloc>();
    final photos =
        bloc.state.data?.profilePhotos ?? List<File?>.filled(9, null);
    final firstEmpty = photos.indexWhere((photo) => photo == null);

    // If clicking on existing photo, show options
    if (index < photos.length && photos[index] != null) {
      _showPhotoOptionsBottomSheet(index);
      return;
    }

    // Prevent scattered uploads: users must fill from left to right.
    if (firstEmpty != -1 && index != firstEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add photos from left to right.'),
        ),
      );
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
      bloc.add(OnboardingProfilePhotoPicked(source, index, context));
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
                final bloc = context.read<OnboardingBloc>();
                final currentContext = context;
                final source = await showModalBottomSheet<ImageSource>(
                  context: context,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
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
                          leading:
                              const Icon(Icons.camera_alt, color: primaryGreen),
                          title: Text(
                            'Take Photo',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () =>
                              Navigator.pop(context, ImageSource.camera),
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library,
                              color: primaryGreen,),
                          title: Text(
                            'Choose from Gallery',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () =>
                              Navigator.pop(context, ImageSource.gallery),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
                if (source != null && currentContext.mounted) {
                  bloc.add(
                    OnboardingProfilePhotoPicked(
                      source,
                      index,
                      currentContext,
                    ),
                  );
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
    context.read<OnboardingBloc>().add(
          OnboardingProfilePhotoRemoved(index),
        );
  }

  void _movePhoto(int fromIndex, int toIndex) {
    context.read<OnboardingBloc>().add(
          OnboardingProfilePhotosReordered(fromIndex, toIndex),
        );
  }

  void _setAsMainPhoto(int index) {
    if (index == 0) return;
    _movePhoto(index, 0);
  }
}
