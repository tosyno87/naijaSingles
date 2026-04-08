import 'dart:io';
import 'package:flutter/material.dart';
import 'profile_image_cropper_service.dart';

/// Service for cropping a batch of pre-selected photos individually.
class BulkPhotoPickerService {
  /// Crop individual photos after bulk selection.
  /// The crop type rotates by index (main = square, body = portrait, etc.)
  /// so reorder order from the review sheet matters.
  static Future<List<File>> cropSelectedPhotos({
    required List<File> selectedPhotos,
    required BuildContext context,
  }) async {
    final List<File> croppedPhotos = [];

    for (int i = 0; i < selectedPhotos.length; i++) {
      final photo = selectedPhotos[i];

      CropType cropType;
      String title;

      switch (i) {
        case 0:
          cropType = CropType.square;
          title = 'Crop Main Photo';
          break;
        case 1:
          cropType = CropType.portrait;
          title = 'Crop Full Body Photo';
          break;
        case 2:
          cropType = CropType.landscape;
          title = 'Crop Activity Photo';
          break;
        case 3:
          cropType = CropType.portrait;
          title = 'Crop Social Photo';
          break;
        case 4:
          cropType = CropType.freeform;
          title = 'Crop Lifestyle Photo';
          break;
        default:
          cropType = CropType.square;
          title = 'Crop Photo';
      }

      final croppedPhoto = await ProfileImageCropperService.cropImage(
        imagePath: photo.path,
        cropType: cropType,
        title: title,
      );

      if (croppedPhoto != null) {
        croppedPhotos.add(croppedPhoto);
      } else {
        break;
      }
    }

    return croppedPhotos;
  }
}
