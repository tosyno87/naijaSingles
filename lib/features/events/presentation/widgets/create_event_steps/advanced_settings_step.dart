import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../common/constants/app_colors.dart';
import '../../../data/models/enhanced_event_model.dart';

class AdvancedSettingsStep extends StatefulWidget {
  const AdvancedSettingsStep({
    required this.eventData,
    super.key,
  });
  final EventCreationData eventData;

  @override
  State<AdvancedSettingsStep> createState() => _AdvancedSettingsStepState();
}

class _AdvancedSettingsStepState extends State<AdvancedSettingsStep> {
  final ImagePicker _picker = ImagePicker();
  late TextEditingController _priceController;
  late TextEditingController _capacityController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.eventData.ticketPrice?.toString() ?? '',
    );
    _capacityController = TextEditingController(
      text: widget.eventData.maxAttendees.toString(),
    );

    _priceController.addListener(() {
      final price = double.tryParse(_priceController.text);
      widget.eventData.ticketPrice = price;
    });

    _capacityController.addListener(() {
      final capacity = int.tryParse(_capacityController.text);
      if (capacity != null && capacity > 0) {
        widget.eventData.maxAttendees = capacity;
      }
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Advanced Settings'),
            const SizedBox(height: 8),
            Text(
              'Customize photos, pricing, and capacity (all optional)',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: const Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 32),

            // Photos Section
            _buildPhotosSection(),
            const SizedBox(height: 32),

            // Ticketing Section
            _buildTicketingSection(),
            const SizedBox(height: 32),

            // Capacity Section
            _buildCapacitySection(),
            const SizedBox(height: 40),
          ],
        ),
      );

  Widget _buildSectionTitle(String title) => Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF333333),
        ),
      );

  Widget _buildPhotosSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Photos',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add photos to make your event more attractive (optional)',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: const Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 16),

          // Image Upload Buttons
          Row(
            children: [
              Expanded(
                child: _buildImageUploadButton(
                  icon: Icons.camera_alt,
                  label: 'Take Photo'.tr(),
                  onTap: () => _pickImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildImageUploadButton(
                  icon: Icons.photo_library,
                  label: 'Choose from Gallery'.tr(),
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ),
            ],
          ),

          // Image Preview Grid
          if (widget.eventData.imageUrls.isNotEmpty) _buildImagePreview(),
        ],
      );

  Widget _buildImageUploadButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: AppColors.primaryGreen,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  Widget _buildImagePreview() => Container(
        margin: const EdgeInsets.only(top: 16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: widget.eventData.imageUrls.length,
          itemBuilder: (context, index) =>
              _buildImageItem(widget.eventData.imageUrls[index], index),
        ),
      );

  Widget _buildImageItem(String imagePath, int index) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // Image
              Positioned.fill(
                child: imagePath.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: imagePath,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                            child:
                                CircularProgressIndicator(strokeWidth: 2),),
                        errorWidget: (context, url, error) => const Icon(
                            Icons.event,
                            size: 40,
                            color: Colors.grey,),
                      )
                    : Image.file(File(imagePath), fit: BoxFit.cover),
              ),
              // Remove button
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _removeImage(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
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
        ),
      );

  Widget _buildTicketingSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Pricing',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),

          // Free/Paid Toggle
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    'Free Event',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  subtitle: Text(
                    'Make this event free for everyone',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: const Color(0xFF666666),
                    ),
                  ),
                  value: widget.eventData.isFree,
                  onChanged: (value) {
                    setState(() {
                      widget.eventData.isFree = value;
                      if (value) {
                        widget.eventData.ticketPrice = null;
                        _priceController.clear();
                      }
                    });
                  },
                  activeThumbColor: AppColors.primaryGreen,
                ),
              ],
            ),
          ),

          // Price Input (only for paid events)
          if (!widget.eventData.isFree) ...[
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: TextFormField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText:
                      'Ticket Price (${widget.eventData.currencySymbol})',
                  hintText: 'Enter ticket price',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  labelStyle: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: const Color(0xFF666666),
                  ),
                  hintStyle: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: const Color(0xFF999999),
                  ),
                ),
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: const Color(0xFF333333),
                ),
              ),
            ),
          ],
        ],
      );

  Widget _buildCapacitySection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Capacity',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Maximum number of attendees',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: const Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: TextFormField(
              controller: _capacityController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: 'Maximum Attendees',
                hintText: 'Enter capacity (default: 100)',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                labelStyle: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: const Color(0xFF666666),
                ),
                hintStyle: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: const Color(0xFF999999),
                ),
              ),
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: const Color(0xFF333333),
              ),
            ),
          ),
        ],
      );

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Crop the image
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Event Photo',
              toolbarColor: AppColors.primaryGreen,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.ratio16x9,
              lockAspectRatio: true,
              backgroundColor: Colors.black,
              activeControlsWidgetColor: AppColors.primaryGreen,
              statusBarColor: Colors.black,
              hideBottomControls: false,
              showCropGrid: true,
              cropGridColor: Colors.white.withValues(alpha: 0.5),
              cropFrameColor: Colors.white,
              cropFrameStrokeWidth: 2,
              cropGridStrokeWidth: 1,
            ),
            IOSUiSettings(
              title: 'Crop Event Photo',
              doneButtonTitle: 'Done',
              cancelButtonTitle: 'Cancel',
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
              aspectRatioPickerButtonHidden: true,
              hidesNavigationBar: false,
            ),
          ],
          maxWidth: 1200,
          maxHeight: 1200,
        );

        if (croppedFile != null) {
          setState(() {
            widget.eventData.imageUrls.add(croppedFile.path);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      if (index < widget.eventData.imageUrls.length) {
        widget.eventData.imageUrls.removeAt(index);
      }
    });
  }
}
