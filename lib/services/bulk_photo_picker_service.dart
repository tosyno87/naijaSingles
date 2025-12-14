import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:naijasingles/services/profile_image_cropper_service.dart';

/// Hinge-style bulk photo picker service
/// Allows users to select multiple photos at once, then crop them individually
class BulkPhotoPickerService {
  /// Pick multiple photos at once (Hinge style)
  static Future<List<File>> pickMultiplePhotos({
    required BuildContext context,
    int maxPhotos = 5,
  }) async {
    try {
      // Show source selection dialog
      final ImageSource? source = await _showBulkPhotoSourceDialog(context);
      if (source == null) return [];

      // Pick multiple images
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 95,
      );

      if (images.isEmpty) return [];

      // Limit to maxPhotos
      final limitedImages = images.take(maxPhotos).toList();

      // Convert to File objects
      final List<File> files =
          limitedImages.map((image) => File(image.path)).toList();

      return files;
    } catch (e) {
      debugPrint('Error picking multiple photos: $e');
      return [];
    }
  }

  /// Show bulk photo source selection dialog
  static Future<ImageSource?> _showBulkPhotoSourceDialog(
      BuildContext context) async {
    return showModalBottomSheet<ImageSource>(
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
              'Select Photos',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3A1D0F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose up to 5 photos from your gallery',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Color(0xFF8B6C59),
              ),
            ),
            const SizedBox(height: 24),
            _buildBulkSourceOption(
              icon: Icons.photo_library,
              title: 'Choose from Gallery',
              subtitle: 'Select multiple photos at once',
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
            _buildBulkSourceOption(
              icon: Icons.camera_alt,
              title: 'Take Photos',
              subtitle: 'Take photos one by one',
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildBulkSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF008037).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF008037).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF008037).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF008037),
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
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3A1D0F),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Color(0xFF8B6C59),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: const Color(0xFF008037),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// Crop individual photos after bulk selection
  static Future<List<File>> cropSelectedPhotos({
    required List<File> selectedPhotos,
    required BuildContext context,
  }) async {
    final List<File> croppedPhotos = [];

    for (int i = 0; i < selectedPhotos.length; i++) {
      final photo = selectedPhotos[i];

      // Determine crop type based on photo index
      CropType cropType;
      String title;

      switch (i) {
        case 0:
          cropType = CropType.square; // Main photo - square crop
          title = 'Crop Main Photo';
          break;
        case 1:
          cropType = CropType.portrait; // Full body - portrait crop
          title = 'Crop Full Body Photo';
          break;
        case 2:
          cropType = CropType.landscape; // Activity - landscape crop
          title = 'Crop Activity Photo';
          break;
        case 3:
          cropType = CropType.portrait; // Social - portrait crop
          title = 'Crop Social Photo';
          break;
        case 4:
          cropType = CropType.freeform; // Lifestyle - freeform crop
          title = 'Crop Lifestyle Photo';
          break;
        default:
          cropType = CropType.square;
          title = 'Crop Photo';
      }

      // Show cropping dialog
      final croppedPhoto = await ProfileImageCropperService.cropImage(
        imagePath: photo.path,
        cropType: cropType,
        title: title,
      );

      if (croppedPhoto != null) {
        croppedPhotos.add(croppedPhoto);
      } else {
        // User cancelled cropping, stop the process
        break;
      }
    }

    return croppedPhotos;
  }
}
