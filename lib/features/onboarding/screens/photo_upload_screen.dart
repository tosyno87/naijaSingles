import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../bloc/onboarding_bloc.dart';

class PhotoUploadScreen extends StatefulWidget {
  const PhotoUploadScreen({super.key});

  @override
  State<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  // Afropeep MVP theme colors
  static const Color afropeepGreen = Color(0xFF008037); // MVP green
  static const Color cardBackground = Color(0xFFF7E8DA);
  static const Color textDarkBrown = Color(0xFF3A1D0F);
  static const Color textLightBrown = Color(0xFF8B6C59);

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickImage(ImageSource source, int index) async {
    context.read<OnboardingBloc>().add(
          OnboardingProfilePhotoPicked(source, index, context),
        );
    if (mounted) {
      setState(() {});
    }
  }

  void _showImageSourceDialog(int index) {
    unawaited(
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Photo',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: textDarkBrown,
                ),
              ),
              const SizedBox(height: 16),
              _buildImageSourceOption(
                icon: Icons.camera_alt,
                title: 'Take a Photo',
                subtitle: 'Use your camera to take a new photo',
                onTap: () {
                  Navigator.pop(context);
                  unawaited(_pickImage(ImageSource.camera, index));
                },
              ),
              const Divider(height: 24),
              _buildImageSourceOption(
                icon: Icons.photo_library,
                title: 'Choose from Gallery',
                subtitle: 'Select a photo from your device',
                onTap: () {
                  Navigator.pop(context);
                  unawaited(_pickImage(ImageSource.gallery, index));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: afropeepGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: afropeepGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textDarkBrown,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: textLightBrown,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: afropeepGreen,
              size: 16,
            ),
          ],
        ),
      );

  Widget _buildPhotoItem(int index) {
    final data = context.read<OnboardingBloc>().state.data;
    final photo = data?.profilePhotos.elementAtOrNull(index);
    final bool isRequired = index < 3; // First 3 photos are required

    return GestureDetector(
      onTap: () => _showImageSourceDialog(index),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isRequired
                    ? (photo == null
                        ? Colors.red.withValues(alpha: 0.5)
                        : afropeepGreen)
                    : Colors.transparent,
                width: 2,
              ),
              image: photo != null
                  ? DecorationImage(
                      image: FileImage(photo),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: photo == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: 36,
                        color: isRequired
                            ? Colors.red.withValues(alpha: 0.7)
                            : Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isRequired ? 'Required' : 'Add Photo',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isRequired
                              ? Colors.red.withValues(alpha: 0.7)
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  )
                : null,
          ),

          // Remove labelLarge if photo exists
          if (photo != null)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  context.read<OnboardingBloc>().add(
                        OnboardingProfilePhotoRemoved(index),
                      );
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
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
    );
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<OnboardingBloc, OnboardingState>(
        builder: (context, state) {
          final data = state.data;
          final int uploadedCount =
              data?.profilePhotos.where((photo) => photo != null).length ?? 0;
          final bool hasMinimumPhotos = uploadedCount >= 3;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Your Profile Photos',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textDarkBrown,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Upload at least 3 photos to complete your profile',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: textLightBrown,
                  ),
                ),

                const SizedBox(height: 8),

                // Photo count indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: hasMinimumPhotos
                        ? afropeepGreen.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$uploadedCount/5 photos uploaded (minimum 3)',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: hasMinimumPhotos ? afropeepGreen : Colors.red,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Photo grid - first row (required photos)
                Row(
                  children: [
                    Expanded(child: _buildPhotoItem(0)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildPhotoItem(1)),
                  ],
                ),

                const SizedBox(height: 12),

                // Photo grid - second row (1 required, 2 optional)
                Row(
                  children: [
                    Expanded(child: _buildPhotoItem(2)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildPhotoItem(3)),
                  ],
                ),

                const SizedBox(height: 12),

                // Photo grid - third row (optional)
                _buildPhotoItem(4),

                const SizedBox(height: 32),

                // Photo tips
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.blue.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tips for great profile photos:',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTipItem(
                        'Use clear, well-lit photos that show your face',
                      ),
                      _buildTipItem(
                        'Include at least one full-body photo',
                      ),
                      _buildTipItem(
                        'Show your interests and personality',
                      ),
                      _buildTipItem(
                        'Avoid heavily filtered or edited photos',
                      ),
                      _buildTipItem(
                        'Smile! Profiles with smiling photos get more matches',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );

  Widget _buildTipItem(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.check_circle,
              size: 16,
              color: Colors.blue.shade800,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.blue.shade900,
                ),
              ),
            ),
          ],
        ),
      );
}
