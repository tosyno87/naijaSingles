import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

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
            toolbarColor: const Color(0xFF008037), // MVP green
            toolbarWidgetColor: Colors.white,
            initAspectRatio: _getAspectRatio(cropType),
            lockAspectRatio: true,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: const Color(0xFF008037),
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

  /// Request camera permission before using camera
  /// Note: On iOS, permissions are handled automatically by the system
  /// when accessing the camera. We only need to request on Android.
  static Future<bool> _requestCameraPermission() async {
    try {
      // iOS handles camera permissions automatically - no need to request
      if (Platform.isIOS) {
        developer.log('📷 iOS detected - camera permission handled by system');
        return true; // iOS will show permission dialog automatically
      }
      
      developer.log('📷 Checking camera permission (Android)...');
      final status = await Permission.camera.status;
      
      if (status.isGranted) {
        developer.log('✅ Camera permission already granted');
        return true;
      }
      
      if (status.isDenied) {
        developer.log('🔒 Camera permission denied, requesting...');
        final result = await Permission.camera.request();
        if (result.isGranted) {
          developer.log('✅ Camera permission granted');
          return true;
        } else {
          developer.log('❌ Camera permission denied by user');
          return false;
        }
      }
      
      if (status.isPermanentlyDenied) {
        developer.log('❌ Camera permission permanently denied');
        return false;
      }
      
      return false;
    } catch (e) {
      developer.log('❌ Error requesting camera permission: $e');
      // On iOS, if permission_handler fails, still allow camera access
      // as iOS handles it natively
      if (Platform.isIOS) {
        return true;
      }
      return false;
    }
  }

  /// Request storage permission (for gallery access)
  /// Note: On iOS, permissions are handled automatically by the system
  static Future<bool> _requestStoragePermission() async {
    try {
      developer.log('📁 Checking storage permission...');
      
      // For Android 13+ (API 33+), use READ_MEDIA_IMAGES
      if (Platform.isAndroid) {
        // Check if we're on Android 13+ (API 33+)
        final photosStatus = await Permission.photos.status;
        
        if (photosStatus.isGranted) {
          developer.log('✅ Photos permission already granted');
          return true;
        }
        
        if (photosStatus.isDenied) {
          developer.log('🔒 Photos permission denied, requesting...');
          final result = await Permission.photos.request();
          return result.isGranted;
        }
        
        if (photosStatus.isPermanentlyDenied) {
          developer.log('❌ Photos permission permanently denied');
          return false;
        }
      } else {
        // For iOS, permissions are handled automatically by the system
        // when accessing photo library. We can return true here.
        developer.log('📁 iOS detected - photo library permission handled by system');
        return true; // iOS will show permission dialog automatically
      }
      
      return false;
    } catch (e) {
      developer.log('❌ Error requesting storage permission: $e');
      // On iOS, if permission_handler fails, still allow photo access
      // as iOS handles it natively
      if (Platform.isIOS) {
        return true;
      }
      return false;
    }
  }

  /// Pick and crop image in one flow with proper permission handling
  static Future<File?> pickAndCropImage({
    required ImageSource source,
    required CropType cropType,
    String? title,
    BuildContext? context,
  }) async {
    try {
      developer.log('📸 Starting image pick with source: $source');
      
      // Request appropriate permission based on source
      bool hasPermission = false;
      if (source == ImageSource.camera) {
        hasPermission = await _requestCameraPermission();
        if (!hasPermission && context != null && context.mounted) {
          _showPermissionDeniedDialog(
            context,
            'Camera permission is required to take photos. Please enable it in Settings.',
            Permission.camera,
          );
          return null;
        }
      } else {
        hasPermission = await _requestStoragePermission();
        if (!hasPermission && context != null && context.mounted) {
          _showPermissionDeniedDialog(
            context,
            'Photo library access is required to select photos. Please enable it in Settings.',
            Permission.photos,
          );
          return null;
        }
      }
      
      if (!hasPermission) {
        developer.log('❌ Permission not granted, cannot proceed');
        return null;
      }
      
      // First pick the image
      final ImagePicker picker = ImagePicker();
      developer.log('📷 Picking image with picker...');
      
      XFile? image;
      try {
        // On iOS, don't use preferredCameraDevice (it's Android-only and causes crashes)
        if (Platform.isAndroid) {
          image = await picker.pickImage(
            source: source,
            maxWidth: 1920, // Industry standard for mobile
            maxHeight: 1920,
            imageQuality: 90, // Reduced from 95 for better performance
            preferredCameraDevice: CameraDevice.rear,
          );
        } else {
          // iOS - no preferredCameraDevice parameter
          image = await picker.pickImage(
            source: source,
            maxWidth: 1920,
            maxHeight: 1920,
            imageQuality: 90,
          );
        }
      } on PlatformException catch (e) {
        developer.log('❌ PlatformException picking image: ${e.code} - ${e.message}');
        developer.log('❌ Details: ${e.details}');
        
        String errorMessage = 'Failed to access ${source == ImageSource.camera ? 'camera' : 'photo library'}.';
        
        // Handle iOS-specific errors
        if (Platform.isIOS) {
          if (e.code == 'camera_access_denied' || e.code == 'photo_library_access_denied') {
            errorMessage = 'Camera access was denied. Please enable it in Settings > Privacy & Security > Camera.';
          } else if (e.code == 'camera_unavailable') {
            errorMessage = 'Camera is not available. It may be in use by another app.';
          } else if (e.message?.contains('permission') == true) {
            errorMessage = 'Permission denied. Please enable camera access in Settings.';
          }
        }
        
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              action: Platform.isIOS
                  ? SnackBarAction(
                      label: 'Settings',
                      textColor: Colors.white,
                      onPressed: () => openAppSettings(),
                    )
                  : null,
            ),
          );
        }
        return null;
      } catch (error) {
        developer.log('❌ Error picking image: $error');
        developer.log('❌ Error type: ${error.runtimeType}');
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to access ${source == ImageSource.camera ? 'camera' : 'photo library'}. Please try again.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }

      if (image == null) {
        developer.log('⚠️ No image selected by user');
        return null;
      }
      
      developer.log('✅ Image picked successfully: ${image.path}');

      // Then crop it
      developer.log('✂️ Starting image crop...');
      final croppedFile = await cropImage(
        imagePath: image.path,
        cropType: cropType,
        title: title,
      );
      
      if (croppedFile != null) {
        developer.log('✅ Image cropped successfully: ${croppedFile.path}');
      } else {
        developer.log('⚠️ Image cropping cancelled or failed');
      }
      
      return croppedFile;
    } catch (e, stackTrace) {
      developer.log('❌ Error picking and cropping image: $e');
      developer.log('❌ Stack trace: $stackTrace');
      
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      
      return null;
    }
  }

  /// Show dialog when permission is denied
  static void _showPermissionDeniedDialog(
    BuildContext context,
    String message,
    Permission permission,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
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
              color: const Color(0xFF008037).withValues(alpha: 0.1),
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
            color: Color(0xFF008037),
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
