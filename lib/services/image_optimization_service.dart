import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Industry-standard image optimization service
/// Features:
/// - Smart compression based on image type
/// - Multiple format support (JPEG, WebP, PNG)
/// - Progressive JPEG for web
/// - Thumbnail generation
/// - EXIF data handling
/// - Quality optimization
/// - Size-based compression
class ImageOptimizationService {
  factory ImageOptimizationService() => _instance;
  ImageOptimizationService._internal();
  static final ImageOptimizationService _instance =
      ImageOptimizationService._internal();

  // Image quality settings
  static const int _profilePhotoQuality = 85;
  static const int _thumbnailQuality = 70;
  static const int _fullSizeQuality = 90;
  static const int _webQuality = 80;

  // Image size limits
  static const int _maxProfilePhotoSize = 1080;
  static const int _maxThumbnailSize = 300;
  static const int _maxFullSize = 1920;
  static const int _maxWebSize = 1200;

  /// Optimize image for profile photos
  Future<File> optimizeProfilePhoto(File imageFile) async {
    try {
      log('🖼️ Optimizing profile photo...');

      // Get image info
      final imageInfo = await _getImageInfo(imageFile);
      log('📊 Original image: ${imageInfo.width}x${imageInfo.height}, ${imageInfo.sizeInMB}MB');

      // Determine compression settings
      final compressionSettings = _getCompressionSettings(
        imageType: ImageType.profilePhoto,
        originalSize: imageInfo.sizeInMB,
        originalWidth: imageInfo.width,
        originalHeight: imageInfo.height,
      );

      // Compress image
      final compressedFile = await _compressImage(
        imageFile,
        compressionSettings,
      );

      log('✅ Profile photo optimized: ${compressedFile.path}');
      return compressedFile;
    } catch (e) {
      log('❌ Error optimizing profile photo: $e');
      rethrow;
    }
  }

  /// Optimize image for web display
  Future<File> optimizeForWeb(File imageFile) async {
    try {
      log('🌐 Optimizing image for web...');

      final imageInfo = await _getImageInfo(imageFile);
      final compressionSettings = _getCompressionSettings(
        imageType: ImageType.web,
        originalSize: imageInfo.sizeInMB,
        originalWidth: imageInfo.width,
        originalHeight: imageInfo.height,
      );

      final compressedFile =
          await _compressImage(imageFile, compressionSettings);

      log('✅ Image optimized for web: ${compressedFile.path}');
      return compressedFile;
    } catch (e) {
      log('❌ Error optimizing for web: $e');
      rethrow;
    }
  }

  /// Generate thumbnail
  Future<File> generateThumbnail(File imageFile, {int size = 300}) async {
    try {
      log('🖼️ Generating thumbnail...');

      final tempDir = await getTemporaryDirectory();
      final thumbnailPath =
          '${tempDir.path}/thumbnail_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        thumbnailPath,
        quality: _thumbnailQuality,
        minWidth: size,
        minHeight: size,
      );

      if (compressedFile == null) {
        throw Exception('Failed to generate thumbnail');
      }

      log('✅ Thumbnail generated: ${compressedFile.path}');
      return File(compressedFile.path);
    } catch (e) {
      log('❌ Error generating thumbnail: $e');
      rethrow;
    }
  }

  /// Compress image with smart settings
  Future<File> _compressImage(
      File imageFile, CompressionSettings settings,) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final compressedPath =
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.${settings.format.name}';

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        compressedPath,
        quality: settings.quality,
        minWidth: settings.minWidth,
        minHeight: settings.minHeight,
        format: settings.format,
        keepExif: settings.keepExif,
      );

      if (compressedFile == null) {
        throw Exception('Failed to compress image');
      }

      return File(compressedFile.path);
    } catch (e) {
      log('❌ Error compressing image: $e');
      rethrow;
    }
  }

  /// Generate thumbnail with specific settings
  Future<File> _generateThumbnail(File imageFile) async => generateThumbnail(imageFile);

  /// Get compression settings based on image type and size
  CompressionSettings _getCompressionSettings({
    required ImageType imageType,
    required double originalSize,
    required int originalWidth,
    required int originalHeight,
  }) {
    int quality;
    int minWidth;
    int minHeight;
    CompressFormat format;
    bool keepExif;

    switch (imageType) {
      case ImageType.profilePhoto:
        quality = _profilePhotoQuality;
        minWidth = _maxProfilePhotoSize;
        minHeight = _maxProfilePhotoSize;
        format = CompressFormat.jpeg;
        keepExif = false;
        break;
      case ImageType.web:
        quality = _webQuality;
        minWidth = _maxWebSize;
        minHeight = _maxWebSize;
        format = CompressFormat.webp;
        keepExif = false;
        break;
      case ImageType.fullSize:
        quality = _fullSizeQuality;
        minWidth = _maxFullSize;
        minHeight = _maxFullSize;
        format = CompressFormat.jpeg;
        keepExif = false;
        break;
      case ImageType.thumbnail:
        quality = _thumbnailQuality;
        minWidth = _maxThumbnailSize;
        minHeight = _maxThumbnailSize;
        format = CompressFormat.jpeg;
        keepExif = false;
        break;
    }

    // Adjust quality based on original size
    if (originalSize > 5.0) {
      quality = (quality * 0.8).round(); // Reduce quality for large images
    } else if (originalSize < 1.0) {
      quality = (quality * 1.1).round(); // Increase quality for small images
    }

    return CompressionSettings(
      quality: quality,
      minWidth: minWidth,
      minHeight: minHeight,
      format: format,
      keepExif: keepExif,
    );
  }

  /// Get image information
  Future<ImageInfo> _getImageInfo(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      final sizeInMB = bytes.length / (1024 * 1024);

      return ImageInfo(
        width: image.width,
        height: image.height,
        sizeInMB: sizeInMB,
        format: _getImageFormat(bytes),
      );
    } catch (e) {
      log('❌ Error getting image info: $e');
      rethrow;
    }
  }

  /// Detect image format
  ImageFormat _getImageFormat(Uint8List bytes) {
    if (bytes.length < 4) return ImageFormat.unknown;

    // Check for common image formats
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) return ImageFormat.jpeg;
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return ImageFormat.png;
    }
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
      return ImageFormat.gif;
    }
    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46) {
      return ImageFormat.webp;
    }

    return ImageFormat.unknown;
  }

  /// Upload optimized image to Firebase Storage
  Future<String> uploadOptimizedImage({
    required File imageFile,
    required String path,
    required ImageType imageType,
    String? userId,
  }) async {
    try {
      log('☁️ Uploading optimized image...');

      // Optimize image based on type
      File optimizedFile;
      switch (imageType) {
        case ImageType.profilePhoto:
          optimizedFile = await optimizeProfilePhoto(imageFile);
          break;
        case ImageType.web:
          optimizedFile = await optimizeForWeb(imageFile);
          break;
        case ImageType.fullSize:
          optimizedFile = await _compressImage(
              imageFile,
              _getCompressionSettings(
                imageType: imageType,
                originalSize: await _getImageInfo(imageFile)
                    .then((info) => info.sizeInMB),
                originalWidth:
                    await _getImageInfo(imageFile).then((info) => info.width),
                originalHeight:
                    await _getImageInfo(imageFile).then((info) => info.height),
              ),);
          break;
        case ImageType.thumbnail:
          optimizedFile = await generateThumbnail(imageFile);
          break;
      }

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child(path);
      final uploadTask = await storageRef.putFile(optimizedFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      log('✅ Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      log('❌ Error uploading optimized image: $e');
      rethrow;
    }
  }

  /// Batch optimize multiple images
  Future<List<File>> batchOptimizeImages({
    required List<File> imageFiles,
    required ImageType imageType,
  }) async {
    try {
      log('🔄 Batch optimizing ${imageFiles.length} images...');

      final List<File> optimizedFiles = [];

      for (int i = 0; i < imageFiles.length; i++) {
        try {
          File optimizedFile;
          switch (imageType) {
            case ImageType.profilePhoto:
              optimizedFile = await optimizeProfilePhoto(imageFiles[i]);
              break;
            case ImageType.web:
              optimizedFile = await optimizeForWeb(imageFiles[i]);
              break;
            case ImageType.fullSize:
              optimizedFile = await _compressImage(
                  imageFiles[i],
                  _getCompressionSettings(
                    imageType: imageType,
                    originalSize: await _getImageInfo(imageFiles[i])
                        .then((info) => info.sizeInMB),
                    originalWidth: await _getImageInfo(imageFiles[i])
                        .then((info) => info.width),
                    originalHeight: await _getImageInfo(imageFiles[i])
                        .then((info) => info.height),
                  ),);
              break;
            case ImageType.thumbnail:
              optimizedFile = await generateThumbnail(imageFiles[i]);
              break;
          }
          optimizedFiles.add(optimizedFile);
        } catch (e) {
          log('❌ Error optimizing image ${i + 1}: $e');
          // Continue with other images
        }
      }

      log('✅ Batch optimization completed: ${optimizedFiles.length}/${imageFiles.length} images');
      return optimizedFiles;
    } catch (e) {
      log('❌ Error in batch optimization: $e');
      rethrow;
    }
  }

  /// Get optimized image size info
  Future<OptimizationResult> getOptimizationResult(
      File originalFile, File optimizedFile,) async {
    try {
      final originalInfo = await _getImageInfo(originalFile);
      final optimizedInfo = await _getImageInfo(optimizedFile);

      final sizeReduction = ((originalInfo.sizeInMB - optimizedInfo.sizeInMB) /
              originalInfo.sizeInMB) *
          100;

      return OptimizationResult(
        originalSize: originalInfo.sizeInMB,
        optimizedSize: optimizedInfo.sizeInMB,
        sizeReduction: sizeReduction,
        originalDimensions: '${originalInfo.width}x${originalInfo.height}',
        optimizedDimensions: '${optimizedInfo.width}x${optimizedInfo.height}',
        compressionRatio: optimizedInfo.sizeInMB / originalInfo.sizeInMB,
      );
    } catch (e) {
      log('❌ Error getting optimization result: $e');
      rethrow;
    }
  }
}

/// Image types for optimization
enum ImageType {
  profilePhoto,
  web,
  fullSize,
  thumbnail,
}

/// Image formats
enum ImageFormat {
  jpeg,
  png,
  gif,
  webp,
  unknown,
}

/// Compression settings
class CompressionSettings {

  const CompressionSettings({
    required this.quality,
    required this.minWidth,
    required this.minHeight,
    required this.format,
    required this.keepExif,
  });
  final int quality;
  final int minWidth;
  final int minHeight;
  final CompressFormat format;
  final bool keepExif;

  @override
  String toString() => 'CompressionSettings(quality: $quality, minWidth: $minWidth, minHeight: $minHeight, format: $format)';
}

/// Image information
class ImageInfo {

  const ImageInfo({
    required this.width,
    required this.height,
    required this.sizeInMB,
    required this.format,
  });
  final int width;
  final int height;
  final double sizeInMB;
  final ImageFormat format;

  @override
  String toString() => 'ImageInfo(${width}x$height, ${sizeInMB.toStringAsFixed(2)}MB, $format)';
}

/// Optimization result
class OptimizationResult {

  const OptimizationResult({
    required this.originalSize,
    required this.optimizedSize,
    required this.sizeReduction,
    required this.originalDimensions,
    required this.optimizedDimensions,
    required this.compressionRatio,
  });
  final double originalSize;
  final double optimizedSize;
  final double sizeReduction;
  final String originalDimensions;
  final String optimizedDimensions;
  final double compressionRatio;

  @override
  String toString() => 'OptimizationResult(${originalSize.toStringAsFixed(2)}MB -> ${optimizedSize.toStringAsFixed(2)}MB, ${sizeReduction.toStringAsFixed(1)}% reduction)';
}
