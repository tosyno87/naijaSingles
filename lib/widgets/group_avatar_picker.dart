import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../common/constants/app_colors.dart';
import '../services/image_upload_service.dart';

/// Widget for selecting and displaying group avatar
class GroupAvatarPicker extends StatefulWidget {
  const GroupAvatarPicker({
    required this.onImageSelected,
    super.key,
    this.selectedImage,
    this.size = 100,
    this.defaultImageUrl,
  });
  final File? selectedImage;
  final Function(File?) onImageSelected;
  final double size;
  final String? defaultImageUrl;

  @override
  State<GroupAvatarPicker> createState() => _GroupAvatarPickerState();
}

class _GroupAvatarPickerState extends State<GroupAvatarPicker> {
  final ImageUploadService _imageService = ImageUploadService();

  @override
  Widget build(BuildContext context) => Column(
        children: [
          // Avatar display
          GestureDetector(
            onTap: _showImagePickerDialog,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryGreen,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: widget.selectedImage != null
                    ? Image.file(
                        widget.selectedImage!,
                        fit: BoxFit.cover,
                        width: widget.size,
                        height: widget.size,
                      )
                    : widget.defaultImageUrl != null
                        ? Image.network(
                            widget.defaultImageUrl!,
                            fit: BoxFit.cover,
                            width: widget.size,
                            height: widget.size,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildDefaultAvatar(),
                          )
                        : _buildDefaultAvatar(),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Change photo button
          TextButton.icon(
            onPressed: _showImagePickerDialog,
            icon: Icon(
              widget.selectedImage != null ? Icons.edit : Icons.add_a_photo,
              color: AppColors.primaryGreen,
              size: 20,
            ),
            label: Text(
              widget.selectedImage != null ? 'Change Photo' : 'Add Photo',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
              ),
            ),
          ),

          // Remove photo button (if image is selected)
          if (widget.selectedImage != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _removeImage,
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 18,
              ),
              label: Text(
                'Remove Photo',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
            ),
          ],

          // Image requirements text
          const SizedBox(height: 8),
          Text(
            'Recommended: Square image, at least 200x200 pixels',
            style: GoogleFonts.montserrat(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );

  Widget _buildDefaultAvatar() => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.group,
          size: widget.size * 0.4,
          color: AppColors.primaryGreen,
        ),
      );

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select Group Photo',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),

            // Options
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.photo_library,
                  color: AppColors.primaryGreen,
                  size: 24,
                ),
              ),
              title: Text(
                'Choose from Gallery',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Select an existing photo',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.gallery);
              },
            ),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: AppColors.primaryGreen,
                  size: 24,
                ),
              ),
              title: Text(
                'Take Photo',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Capture a new photo',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.camera);
              },
            ),

            // Cancel button
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.grey[600],
                  size: 24,
                ),
              ),
              title: Text(
                'Cancel',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              onTap: () => Navigator.pop(context),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final File? image = await _imageService.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        if (_imageService.validateImage(image)) {
          widget.onImageSelected(image);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Invalid image. Please select a valid image file (max 10MB).',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage() {
    widget.onImageSelected(null);
  }
}
