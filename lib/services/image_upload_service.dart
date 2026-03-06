import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Service for handling image uploads to Firebase Storage
class ImageUploadService {
  factory ImageUploadService() => _instance;
  ImageUploadService._internal();
  static final ImageUploadService _instance = ImageUploadService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery or camera
  Future<File?> pickImage({
    ImageSource source = ImageSource.gallery,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } on Object catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Upload image to Firebase Storage
  Future<String> uploadImage({
    required File imageFile,
    required String path,
    String? fileName,
  }) async {
    try {
      if (!imageFile.existsSync()) {
        throw Exception('Selected image file does not exist.');
      }

      final extension = _extensionFromPath(imageFile.path);
      final contentType = _contentTypeForExtension(extension);

      // Generate unique filename if not provided
      final String finalFileName =
          fileName ??
          '${DateTime.now().millisecondsSinceEpoch}'
              '${extension.isNotEmpty ? extension : '.jpg'}';

      final storagePath = '$path/$finalFileName';
      final bucket = _storage.app.options.storageBucket ?? 'NO_BUCKET';
      final fileSize = imageFile.lengthSync();

      dev.log(
        '📤 Upload: $storagePath | bucket=$bucket | '
        'size=${fileSize}B | type=$contentType',
      );

      try {
        final token = await FirebaseAppCheck.instance.getToken(true);
        dev.log('🛡️ App Check token: ${token != null ? 'OK (${token.length} chars)' : 'NULL'}');
      } on Object catch (e) {
        dev.log('⚠️ App Check token fetch failed: $e — '
            'if enforcement is on for Storage, uploads will fail');
      }

      final Reference ref = _storage.ref().child(storagePath);

      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: contentType),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      dev.log('✅ Upload succeeded: $storagePath');
      return downloadUrl;
    } on FirebaseException catch (e) {
      final bucket = _storage.app.options.storageBucket ?? 'NO_BUCKET';
      dev.log(
        '❌ Upload FirebaseException: code=${e.code}, '
        'message=${e.message}, plugin=${e.plugin}, bucket=$bucket',
      );
      throw Exception(
        'Storage error [${e.code}]: ${e.message ?? 'no details'} '
        '(plugin: ${e.plugin}, bucket: $bucket)',
      );
    } on Object catch (e) {
      dev.log('❌ Upload error: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload image with compression.
  ///
  /// Currently delegates directly to [uploadImage]. When a compression
  /// package (e.g. flutter_image_compress) is added, compress here first.
  Future<String> uploadCompressedImage({
    required File imageFile,
    required String path,
    String? fileName,
    int quality = 85,
    int maxWidth = 800,
    int maxHeight = 800,
  }) =>
      uploadImage(
        imageFile: imageFile,
        path: path,
        fileName: fileName,
      );

  /// Delete image from Firebase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } on Object catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  /// Get image size in bytes
  Future<int> getImageSize(File imageFile) async {
    try {
      final Uint8List bytes = await imageFile.readAsBytes();
      return bytes.length;
    } on Object catch (e) {
      throw Exception('Failed to get image size: $e');
    }
  }

  /// Validate image file
  bool validateImage(File imageFile) {
    try {
      final String extension = _extensionFromPath(imageFile.path);
      const List<String> allowedExtensions = [
        '.jpg',
        '.jpeg',
        '.png',
        '.gif',
        '.webp',
        '.heic',
        '.heif',
      ];

      if (!allowedExtensions.contains(extension)) {
        return false;
      }

      // Check file size (max 10MB)
      final int sizeInBytes = imageFile.lengthSync();
      const int maxSizeInBytes = 10 * 1024 * 1024; // 10MB

      if (sizeInBytes > maxSizeInBytes) {
        return false;
      }

      return true;
    } on Object {
      return false;
    }
  }

  String _contentTypeForExtension(String extension) {
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.heic':
        return 'image/heic';
      case '.heif':
        return 'image/heif';
      default:
        return 'image/jpeg';
    }
  }

  String _extensionFromPath(String filePath) {
    final index = filePath.lastIndexOf('.');
    if (index < 0 || index == filePath.length - 1) {
      return '';
    }
    return filePath.substring(index).toLowerCase();
  }

  /// Show image picker dialog
  Future<File?> showImagePickerDialog() async {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return null;
    return showDialog<File>(
        context: ctx,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Select Image'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  final File? image = await pickImage();
                  if (!context.mounted) return;
                  if (image != null && validateImage(image)) {
                    Navigator.pop(context, image);
                  } else if (image != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Invalid image. Please select a valid image file.',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  final File? image =
                      await pickImage(source: ImageSource.camera);
                  if (!context.mounted) return;
                  if (image != null && validateImage(image)) {
                    Navigator.pop(context, image);
                  } else if (image != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Invalid image. Please select a valid image file.',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      );
  }
}

// Global navigator key for accessing context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
