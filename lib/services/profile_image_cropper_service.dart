import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// Industry-standard image cropping service for profile photos
/// Implements Hinge/Bumble-style cropping with proper aspect ratios
class ProfileImageCropperService {
  /// Crop image with industry-standard settings for profile photos
  static Future<File?> cropImage({
    required String imagePath,
    required CropType cropType,
    String? title,
  }) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: title ?? 'Crop Photo',
            toolbarColor: const Color(0xFF007A33), // Afropeep green
            toolbarWidgetColor: Colors.white,
            initAspectRatio: _getAspectRatio(cropType),
            lockAspectRatio: true,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: const Color(0xFF007A33),
            statusBarColor: Colors.black,
            hideBottomControls: false,
            showCropGrid: true,
            cropGridColor: Colors.white.withValues(alpha: 0.5),
            cropFrameColor: Colors.white,
            cropFrameStrokeWidth: 2,
            cropGridStrokeWidth: 1,
          ),
          IOSUiSettings(
            title: title ?? 'Crop Photo',
            doneButtonTitle: 'Done',
            cancelButtonTitle: 'Cancel',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
            rotateButtonsHidden: false,
            rotateClockwiseButtonHidden: false,
            hidesNavigationBar: false,
          ),
        ],
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 85, // Reduced from 90 for better file size
        maxWidth: 1080, // Industry standard for mobile
        maxHeight: 1080,
      );

      return croppedFile != null ? File(croppedFile.path) : null;
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return null;
    }
  }

  /// Get aspect ratio based on crop type
  static CropAspectRatioPreset _getAspectRatio(CropType cropType) {
    switch (cropType) {
      case CropType.square:
        return CropAspectRatioPreset.square;
      case CropType.portrait:
        return CropAspectRatioPreset.ratio4x3;
      case CropType.landscape:
        return CropAspectRatioPreset.ratio16x9;
      case CropType.freeform:
        return CropAspectRatioPreset.original;
    }
  }

  /// Pick and crop image in one flow
  static Future<File?> pickAndCropImage({
    required ImageSource source,
    required CropType cropType,
    String? title,
  }) async {
    try {
      // First pick the image
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920, // Industry standard for mobile
        maxHeight: 1920,
        imageQuality: 90, // Reduced from 95 for better performance
      );

      if (image == null) return null;

      // Then crop it
      return await cropImage(
        imagePath: image.path,
        cropType: cropType,
        title: title,
      );
    } catch (e) {
      debugPrint('Error picking and cropping image: $e');
      return null;
    }
  }

  /// Show image source selection dialog with cropping
  static Future<File?> showImagePickerWithCrop({
    required BuildContext context,
    required CropType cropType,
    String? title,
  }) async {
    // Show source selection dialog
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title ?? 'Select Photo Source',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3A1D0F),
              ),
            ),
            const SizedBox(height: 24),
            _buildSourceOption(
              icon: Icons.camera_alt,
              title: 'Take Photo',
              subtitle: 'Use your camera',
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const Divider(height: 24),
            _buildSourceOption(
              icon: Icons.photo_library,
              title: 'Choose from Gallery',
              subtitle: 'Select from your photos',
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return null;

    // Pick and crop the image
    return await pickAndCropImage(
      source: source,
      cropType: cropType,
      title: title,
    );
  }

  static Widget _buildSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF007A33).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF007A33),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF3A1D0F),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8B6C59),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: Color(0xFF007A33),
            size: 16,
          ),
        ],
      ),
    );
  }
}

/// Crop type enum for different photo types
enum CropType {
  square, // 1:1 - Main profile photo
  portrait, // 3:4 - Full body photos
  landscape, // 4:3 - Activity photos
  freeform, // No fixed ratio - Lifestyle photos
}
