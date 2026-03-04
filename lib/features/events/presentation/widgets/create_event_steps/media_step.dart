import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../common/constants/app_colors.dart';
import '../../../data/models/enhanced_event_model.dart';

class MediaStep extends StatefulWidget {
  const MediaStep({
    required this.eventData,
    super.key,
  });
  final EventCreationData eventData;

  @override
  State<MediaStep> createState() => _MediaStepState();
}

class _MediaStepState extends State<MediaStep> {
  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedImages = [];
  bool _isProcessingImage = false;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Add Photos'),
            const SizedBox(height: 8),
            Text(
              'Add photos to make your event more attractive (optional)',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: const Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 32),
            _buildImageUploadSection(),
            const SizedBox(height: 32),
            if (widget.eventData.imageUrls.isNotEmpty) _buildImagePreview(),
            const SizedBox(height: 40),
          ],
        ),
      );

  Widget _buildSectionTitle(String title) => Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF333333),
        ),
      );

  Widget _buildImageUploadSection() => Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryGreen.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_upload_outlined,
              size: 40,
              color: AppColors.primaryGreen,
            ),
            const SizedBox(height: 12),
            Text(
              'Upload Event Photos',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Drag and drop or click to browse',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: const Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isProcessingImage ? null : _selectImages,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isProcessingImage
                    ? AppColors.primaryGreen.withValues(alpha: 0.6)
                    : AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isProcessingImage
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Processing...',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Choose Photos',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              'Supports JPG, PNG (Max 10 photos) • ${widget.eventData.imageUrls.length}/10 used',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: const Color(0xFF999999),
              ),
            ),
          ],
        ),
      );

  Widget _buildImagePreview() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Photo Preview',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This is how your photo will appear in the event card',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: const Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 16),

          // Card preview showing how image will be cropped
          _buildCardPreview(),

          const SizedBox(height: 24),

          // Grid of selected images
          Text(
            'Selected Photos (${widget.eventData.imageUrls.length})',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio:
                  1.2, // Slightly rectangular to better show landscape images
            ),
            itemCount: widget.eventData.imageUrls.length,
            itemBuilder: (context, index) => _buildImageTile(index),
          ),
        ],
      );

  Widget _buildCardPreview() {
    if (widget.eventData.imageUrls.isEmpty) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview with exact same dimensions as event card
          Container(
            height: 200, // Same as MyEventCard
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Image.file(
                    File(widget.eventData.imageUrls.first),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover, // Same as event card
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) =>
                        const ColoredBox(
                      color: Color(0xFFF0F0F0),
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 48,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ),
                  ),
                ),

                // Preview overlay
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'PREVIEW',
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Crop indicator
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.crop,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Full preview',
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sample event details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.eventData.name.isNotEmpty
                      ? widget.eventData.name
                      : 'Your Event Name',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Color(0xFF666666),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.eventData.location?.name ?? 'Event Location',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: const Color(0xFF666666),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageTile(int index) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.primaryGreen.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: AppColors.backgroundColor,
                child: widget.eventData.imageUrls[index].startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: widget.eventData.imageUrls[index],
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                            child:
                                CircularProgressIndicator(strokeWidth: 2)),
                        errorWidget: (context, url, error) =>
                            const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Color(0xFF999999),
                          ),
                        ),
                      )
                    : Image.file(
                        File(widget.eventData.imageUrls[index]),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ),
              ),
            ),

            // Action buttons overlay
            Positioned(
              top: 4,
              right: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Crop button
                  GestureDetector(
                    onTap: _isProcessingImage ? null : () => _cropImage(index),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _isProcessingImage
                            ? AppColors.primaryGreen.withValues(alpha: 0.6)
                            : AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.crop,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Delete button
                  GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Primary image indicator
            if (index == 0)
              Positioned(
                bottom: 4,
                left: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'MAIN',
                    style: GoogleFonts.montserrat(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );

  Future<void> _cropImage(int index) async {
    if (index < 0 || index >= widget.eventData.imageUrls.length) {
      _showErrorSnackBar('Invalid image index.');
      return;
    }

    try {
      final imagePath = widget.eventData.imageUrls[index];
      if (imagePath.startsWith('http')) {
        _showErrorSnackBar(
          'Cannot crop uploaded images. Please select a new image.',
        );
        return;
      }

      // Show loading indicator
      _showLoadingSnackBar('Cropping image...');

      // Use image_cropper to crop the image
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Event Photo',
            toolbarColor: AppColors.primaryGreen,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Event Photo',
            minimumAspectRatio: 1,
          ),
        ],
      );

      // Hide loading indicator
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (croppedFile != null) {
        setState(() {
          if (index < _selectedImages.length) {
            _selectedImages[index] = File(croppedFile.path);
          }
          widget.eventData.imageUrls[index] = croppedFile.path;
        });
        _showSuccessSnackBar('Image cropped successfully!');
      } else {
        _showErrorSnackBar('Image cropping was cancelled.');
      }
    } catch (e) {
      // Hide loading indicator
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showErrorSnackBar('Failed to crop image: ${e.toString()}');
    }
  }

  void _removeImage(int index) {
    if (index < 0 || index >= widget.eventData.imageUrls.length) {
      _showErrorSnackBar('Invalid image index.');
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Remove Photo',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to remove this photo?',
          style: GoogleFonts.montserrat(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                if (index < _selectedImages.length) {
                  _selectedImages.removeAt(index);
                }
                if (index < widget.eventData.imageUrls.length) {
                  widget.eventData.imageUrls.removeAt(index);
                }
              });
              _showSuccessSnackBar('Photo removed successfully!');
            },
            child: Text(
              'Remove',
              style: GoogleFonts.montserrat(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectImages() async {
    if (_isProcessingImage) return;

    try {
      setState(() {
        _isProcessingImage = true;
      });

      // Check if already at maximum limit
      if (widget.eventData.imageUrls.length >= 10) {
        _showErrorSnackBar(
          'Maximum 10 photos allowed. Please remove some photos first.',
        );
        return;
      }

      // Show options for camera or gallery
      final source = await _showImageSourceDialog();
      if (source == null) return;

      // Show loading indicator
      _showLoadingSnackBar('Selecting image...');

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 2048, // High quality for event photos
        maxHeight: 2048,
        imageQuality: 95, // High quality
      );

      // Hide loading indicator
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (image != null) {
        // Double-check limit before adding
        if (widget.eventData.imageUrls.length >= 10) {
          _showErrorSnackBar('Maximum 10 photos allowed.');
          return;
        }

        // Show cropping dialog for new images
        await _showCropDialogForNewImage(image.path);
      }
    } catch (e) {
      // Hide loading indicator
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showErrorSnackBar('Failed to select images: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingImage = false;
        });
      }
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async =>
      showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Select Image Source',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: AppColors.primaryGreen),
                title: Text('Gallery', style: GoogleFonts.montserrat()),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primaryGreen),
                title: Text('Camera', style: GoogleFonts.montserrat()),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

  Future<void> _showCropDialogForNewImage(String imagePath) async {
    try {
      // Validate image file first
      if (!_isValidImageFile(imagePath)) {
        return;
      }

      // Show loading indicator
      _showLoadingSnackBar('Cropping image...');

      // Use image_cropper to crop the new image
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Event Photo',
            toolbarColor: AppColors.primaryGreen,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Event Photo',
            minimumAspectRatio: 1,
          ),
        ],
      );

      // Hide loading indicator
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (croppedFile != null) {
        // Validate the cropped file as well
        if (_isValidImageFile(croppedFile.path)) {
          setState(() {
            _selectedImages.add(File(croppedFile.path));
            widget.eventData.imageUrls.add(croppedFile.path);
          });
          _showSuccessSnackBar('Photo cropped and added successfully!');
        }
      } else {
        _showErrorSnackBar('Image cropping was cancelled.');
      }
    } catch (e) {
      // Hide loading indicator
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showErrorSnackBar('Failed to crop image: ${e.toString()}');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.montserrat(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.montserrat(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showLoadingSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              message,
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 30), // Long duration for loading
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Validate if the image file is valid and supported
  bool _isValidImageFile(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) {
      return false;
    }

    final extension = filePath.toLowerCase().split('.').last;
    final supportedExtensions = ['jpg', 'jpeg', 'png'];

    if (!supportedExtensions.contains(extension)) {
      return false;
    }

    // Check file size (max 10MB)
    final fileSize = file.lengthSync();
    const maxSize = 10 * 1024 * 1024; // 10MB

    if (fileSize > maxSize) {
      _showErrorSnackBar('Image file is too large. Maximum size is 10MB.');
      return false;
    }

    return true;
  }
}
