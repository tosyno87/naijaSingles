import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:naijasingles/services/profile_image_cropper_service.dart';

/// Industry-standard image upload service following Hinge/Bumble/Tinder best practices
/// 
/// Features:
/// - Smart compression based on image size and quality
/// - Multiple aspect ratios for different photo types
/// - Automatic quality optimization
/// - Proper error handling and user feedback
/// - Memory-efficient processing
class IndustryStandardImageService {
  
  /// Maximum file sizes (in MB) for different photo types
  static const Map<CropType, double> _maxFileSizes = {
    CropType.square: 2.0,      // Profile photos - smaller for faster loading
    CropType.portrait: 3.0,     // Full body photos - medium size
    CropType.landscape: 4.0,    // Activity photos - larger for detail
    CropType.freeform: 5.0,     // Lifestyle photos - largest
  };

  /// Quality settings based on original image size
  static const Map<String, int> _qualitySettings = {
    'high': 90,     // For images < 1MB
    'medium': 75,   // For images 1-3MB
    'low': 60,      // For images 3-5MB
    'very_low': 45, // For images > 5MB
  };

  /// Pick, crop, and optimize image in one flow
  static Future<File?> pickCropAndOptimizeImage({
    required BuildContext context,
    required CropType cropType,
    String? title,
    bool showSourceDialog = true,
  }) async {
    try {
      File? selectedImage;
      
      if (showSourceDialog) {
        // Show source selection dialog
        selectedImage = await ProfileImageCropperService.showImagePickerWithCrop(
          context: context,
          cropType: cropType,
          title: title,
        );
      } else {
        // Direct camera pick
        selectedImage = await ProfileImageCropperService.pickAndCropImage(
          source: ImageSource.camera,
          cropType: cropType,
          title: title,
        );
      }

      if (selectedImage == null) return null;

      // Optimize the image
      return await _optimizeImage(selectedImage, cropType);
    } catch (e) {
      debugPrint('Error in pickCropAndOptimizeImage: $e');
      return null;
    }
  }

  /// Optimize image based on industry standards
  static Future<File> _optimizeImage(File imageFile, CropType cropType) async {
    try {
      // Get original image size
      final originalSize = await _getFileSizeInMB(imageFile);
      final maxSize = _maxFileSizes[cropType] ?? 2.0;
      
      // If image is already small enough, return as is
      if (originalSize <= maxSize) {
        return imageFile;
      }

      // Determine compression quality
      final quality = _getCompressionQuality(originalSize);
      
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomSuffix = Random().nextInt(1000);
      final outputPath = '${tempDir.path}/optimized_${timestamp}_$randomSuffix.jpg';

      // Compress image
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        outputPath,
        quality: quality,
        minWidth: _getMinWidth(cropType),
        minHeight: _getMinHeight(cropType),
        format: CompressFormat.jpeg,
        keepExif: false, // Remove EXIF data for privacy
      );

      if (compressedFile == null) {
        throw Exception('Failed to compress image');
      }

      final compressedSize = await _getFileSizeInMB(File(compressedFile.path));
      debugPrint('Image optimization: ${originalSize.toStringAsFixed(2)}MB -> ${compressedSize.toStringAsFixed(2)}MB (${quality}% quality)');

      return File(compressedFile.path);
    } catch (e) {
      debugPrint('Error optimizing image: $e');
      return imageFile; // Return original if optimization fails
    }
  }

  /// Get compression quality based on original image size
  static int _getCompressionQuality(double sizeInMB) {
    if (sizeInMB <= 1.0) return _qualitySettings['high']!;
    if (sizeInMB <= 3.0) return _qualitySettings['medium']!;
    if (sizeInMB <= 5.0) return _qualitySettings['low']!;
    return _qualitySettings['very_low']!;
  }

  /// Get minimum width based on crop type
  static int _getMinWidth(CropType cropType) {
    switch (cropType) {
      case CropType.square:
        return 400;  // Profile photos - smaller for faster loading
      case CropType.portrait:
        return 600;  // Full body photos - medium resolution
      case CropType.landscape:
        return 800;  // Activity photos - higher resolution
      case CropType.freeform:
        return 1000; // Lifestyle photos - highest resolution
    }
  }

  /// Get minimum height based on crop type
  static int _getMinHeight(CropType cropType) {
    switch (cropType) {
      case CropType.square:
        return 400;  // 1:1 aspect ratio
      case CropType.portrait:
        return 800;  // 3:4 aspect ratio
      case CropType.landscape:
        return 600;  // 4:3 aspect ratio
      case CropType.freeform:
        return 600;  // Flexible aspect ratio
    }
  }

  /// Get file size in MB
  static Future<double> _getFileSizeInMB(File file) async {
    final bytes = await file.length();
    return bytes / (1024 * 1024);
  }

  /// Batch optimize multiple images
  static Future<List<File>> optimizeMultipleImages({
    required List<File> imageFiles,
    required CropType cropType,
    Function(int, int)? onProgress,
  }) async {
    final List<File> optimizedImages = [];
    
    for (int i = 0; i < imageFiles.length; i++) {
      onProgress?.call(i + 1, imageFiles.length);
      
      try {
        final optimizedImage = await _optimizeImage(imageFiles[i], cropType);
        optimizedImages.add(optimizedImage);
      } catch (e) {
        debugPrint('Error optimizing image ${i + 1}: $e');
        optimizedImages.add(imageFiles[i]); // Add original if optimization fails
      }
    }
    
    return optimizedImages;
  }

  /// Validate image before upload
  static Future<bool> validateImage(File imageFile) async {
    try {
      // Check file size (max 10MB)
      final sizeInMB = await _getFileSizeInMB(imageFile);
      if (sizeInMB > 10.0) {
        debugPrint('Image too large: ${sizeInMB.toStringAsFixed(2)}MB');
        return false;
      }

      // Check if file exists and is readable
      if (!await imageFile.exists()) {
        debugPrint('Image file does not exist');
        return false;
      }

      // Try to read the image to validate it's a valid image
      final bytes = await imageFile.readAsBytes();
      if (bytes.isEmpty) {
        debugPrint('Image file is empty');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error validating image: $e');
      return false;
    }
  }

  /// Get image metadata for debugging
  static Future<Map<String, dynamic>> getImageMetadata(File imageFile) async {
    try {
      final sizeInMB = await _getFileSizeInMB(imageFile);
      final bytes = await imageFile.readAsBytes();
      
      return {
        'fileSize': sizeInMB,
        'fileSizeBytes': bytes.length,
        'fileName': imageFile.path.split('/').last,
        'filePath': imageFile.path,
        'isValid': await validateImage(imageFile),
      };
    } catch (e) {
      debugPrint('Error getting image metadata: $e');
      return {'error': e.toString()};
    }
  }
}

/// Image upload progress callback
typedef ImageUploadProgressCallback = void Function(int current, int total);

/// Image upload result
class ImageUploadResult {
  final bool success;
  final File? image;
  final String? error;
  final Map<String, dynamic>? metadata;

  ImageUploadResult({
    required this.success,
    this.image,
    this.error,
    this.metadata,
  });
}
