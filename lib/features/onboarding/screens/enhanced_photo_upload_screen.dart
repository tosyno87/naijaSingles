import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../bloc/onboarding_bloc.dart';
import '../onboarding_theme.dart';

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
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<OnboardingBloc, OnboardingState>(
        builder: (context, state) {
          final uploadedPhotos =
              state.data?.profilePhotos ?? List<File?>.filled(9, null);
          return _buildContent(context, uploadedPhotos);
        },
      );

  Widget _buildContent(BuildContext context, List<File?> uploadedPhotos) {
    final photoCount =
        uploadedPhotos.where((p) => p != null).length;

    return OnboardingTheme.constrainedContent(
      child: SingleChildScrollView(
        padding: OnboardingTheme.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add your best photos', style: OnboardingTheme.titleStyle),
            const SizedBox(height: OnboardingTheme.titleToSubtitle),
            Text(
              'Upload at least 1 photo. Profiles with 3+ photos get more matches.',
              style: OnboardingTheme.subtitleStyle,
            ),
            const SizedBox(height: 8),
            Text(
              '$photoCount / 9 photos added',
              style: OnboardingTheme.helperStyle.copyWith(
                color: OnboardingTheme.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: OnboardingTheme.subtitleToField),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: List.generate(9, (index) {
                final photo = index < uploadedPhotos.length
                    ? uploadedPhotos[index]
                    : null;
                return SizedBox(
                  width: (MediaQuery.of(context).size.width -
                          OnboardingTheme.horizontalPadding * 2 -
                          24) /
                      3,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _buildPhotoGridItem(
                      context: context,
                      photo: photo,
                      index: index,
                      isMainPhoto: index == 0,
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: OnboardingTheme.fieldToBottom),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGridItem({
    required BuildContext context,
    required File? photo,
    required int index,
    required bool isMainPhoto,
  }) =>
      GestureDetector(
        onTap: () => _showAddPhotoOptions(context, index),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: photo == null
                  ? OnboardingTheme.fieldFill
                  : OnboardingTheme.background,
              borderRadius: BorderRadius.circular(OnboardingTheme.fieldRadius),
              border: isMainPhoto && photo != null
                  ? Border.all(color: OnboardingTheme.primaryGreen, width: 3)
                  : Border.all(color: OnboardingTheme.fieldBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                if (photo != null)
                  Image.file(
                    photo,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  )
                else
                  Center(
                    child: Icon(
                      Icons.add_photo_alternate,
                      size: 48,
                      color: OnboardingTheme.fieldBorder,
                    ),
                  ),

                if (isMainPhoto && photo != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: OnboardingTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.white, size: 12),
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

                if (photo != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _removePhoto(index),
                      child: Container(
                        width: OnboardingTheme.minTapTarget,
                        height: OnboardingTheme.minTapTarget,
                        alignment: Alignment.topRight,
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
                  ),
              ],
            ),
          ),
        ),
      );

  Future<void> _showAddPhotoOptions(BuildContext context, int index) async {
    final bloc = context.read<OnboardingBloc>();
    final photos =
        bloc.state.data?.profilePhotos ?? List<File?>.filled(9, null);
    final firstEmpty = photos.indexWhere((photo) => photo == null);

    if (index < photos.length && photos[index] != null) {
      _showPhotoOptionsBottomSheet(context, index);
      return;
    }

    if (firstEmpty != -1 && index != firstEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add photos from left to right.'),
        ),
      );
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: OnboardingTheme.background,
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
              leading: const Icon(
                Icons.camera_alt,
                color: OnboardingTheme.primaryGreen,
              ),
              title: Text(
                'Take Photo',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: OnboardingTheme.primaryGreen,
              ),
              title: Text(
                'Choose from Gallery',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                if (!context.mounted) return;
                Navigator.pop(context, ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source != null && context.mounted) {
      bloc.add(OnboardingProfilePhotoPicked(source, index, context));
    }
  }

  void _showPhotoOptionsBottomSheet(BuildContext parentContext, int index) {
    unawaited(
      showModalBottomSheet(
        context: parentContext,
        backgroundColor: OnboardingTheme.background,
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
                  leading: const Icon(
                    Icons.star,
                    color: OnboardingTheme.primaryGreen,
                  ),
                  title: Text(
                    'Set as Main Photo',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _setAsMainPhoto(index);
                  },
                ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: OnboardingTheme.primaryGreen,
                ),
                title: Text(
                  'Replace Photo',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final bloc = parentContext.read<OnboardingBloc>();
                  final source = await showModalBottomSheet<ImageSource>(
                    context: parentContext,
                    backgroundColor: OnboardingTheme.background,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            margin:
                                const EdgeInsets.only(top: 12, bottom: 8),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.camera_alt,
                              color: OnboardingTheme.primaryGreen,
                            ),
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
                            leading: const Icon(
                              Icons.photo_library,
                              color: OnboardingTheme.primaryGreen,
                            ),
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
                  if (source != null && parentContext.mounted) {
                    bloc.add(
                      OnboardingProfilePhotoPicked(
                        source,
                        index,
                        parentContext,
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
