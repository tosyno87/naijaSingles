import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../bloc/onboarding_bloc.dart';
import '../onboarding_theme.dart';
import '../widgets/profile_bulk_photo_review_sheet.dart';

enum _PhotoAddChoice { camera, photoLibrary }

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
    final emptySlots = uploadedPhotos.where((p) => p == null).length;

    return OnboardingTheme.constrainedContent(
      child: SingleChildScrollView(
        padding: OnboardingTheme.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add your photos', style: OnboardingTheme.titleStyle),
            const SizedBox(height: OnboardingTheme.titleToSubtitle),
            Text(
              'Add at least 3 to get started',
              style: OnboardingTheme.subtitleStyle,
            ),
            const SizedBox(height: OnboardingTheme.subtitleToField),
            if (emptySlots > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: OnboardingTheme.buttonHeight,
                  child: FilledButton.icon(
                    onPressed: () => _showAddPhotoOptions(
                      context,
                      uploadedPhotos.indexWhere((p) => p == null).clamp(0, 8),
                    ),
                    icon: const Icon(Icons.add_a_photo, size: 20),
                    label: Text(
                      'Add photos',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: OnboardingTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          OnboardingTheme.buttonRadius,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
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
            const SizedBox(height: 16),
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add,
                          size: 28,
                          color: OnboardingTheme.primaryGreen,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${index + 1}',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: OnboardingTheme.fieldBorder,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isMainPhoto && photo != null)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: OnboardingTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'Main',
                            style: GoogleFonts.montserrat(
                              fontSize: 10.5,
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
                    top: 10,
                    right: 10,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _removePhoto(index),
                      child: Container(
                        width: OnboardingTheme.minTapTarget,
                        height: OnboardingTheme.minTapTarget,
                        alignment: Alignment.center,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.72),
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
                  ),
              ],
            ),
          ),
        ),
      );

  Future<void> _showAddPhotoOptions(
      BuildContext parentContext, int index) async {
    final bloc = parentContext.read<OnboardingBloc>();
    final photos =
        bloc.state.data?.profilePhotos ?? List<File?>.filled(9, null);
    final firstEmpty = photos.indexWhere((photo) => photo == null);

    if (index < photos.length && photos[index] != null) {
      _showPhotoOptionsBottomSheet(parentContext, index);
      return;
    }

    if (firstEmpty != -1 && index != firstEmpty) {
      ScaffoldMessenger.of(parentContext).showSnackBar(
        const SnackBar(
          content: Text('Please add photos from left to right.'),
        ),
      );
      return;
    }

    final emptySlots = photos.where((p) => p == null).length;

    final choice = await showModalBottomSheet<_PhotoAddChoice>(
      context: parentContext,
      backgroundColor: OnboardingTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
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
                'Camera',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
              ),
              onTap: () => Navigator.pop(sheetContext, _PhotoAddChoice.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: OnboardingTheme.primaryGreen,
              ),
              title: Text(
                'Photo Library',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
              ),
              onTap: () =>
                  Navigator.pop(sheetContext, _PhotoAddChoice.photoLibrary),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!parentContext.mounted || choice == null) return;

    if (choice == _PhotoAddChoice.camera) {
      bloc.add(
        OnboardingProfilePhotoPicked(ImageSource.camera, index, parentContext),
      );
      return;
    }

    // Photo Library: multi-select, review, then crop+merge via bloc
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 95,
    );
    if (images.isEmpty || !parentContext.mounted) return;

    final files = images.take(emptySlots).map((x) => File(x.path)).toList();

    final ordered = await showModalBottomSheet<List<File>>(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: OnboardingTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ProfileBulkPhotoReviewSheet(photos: files),
    );

    if (ordered == null || ordered.isEmpty || !parentContext.mounted) return;

    bloc.add(OnboardingBulkPhotosCropAndMerge(ordered, parentContext));
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
                              'Camera',
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
                              'Photo Library',
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
