// import 'package:naijasingles/common/widgets/loading_dialog.dart'; // TODO: Create loading dialog widget
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/constants/app_colors.dart';
import '../../../common/utils/app_logger.dart';
import '../data/services/unified_group_service.dart'
    show UnifiedGroupService, UnifiedGroup, GroupType;
import '../../../services/image_upload_service.dart';
import '../../../services/validation_service.dart';
import '../../../widgets/group_avatar_picker.dart';
import '../../../widgets/success_dialog.dart';
import '../../../widgets/tag_input_widget.dart';

/// Screen for editing group settings (creator/admin only)
class GroupSettingsScreen extends StatefulWidget {
  const GroupSettingsScreen({
    required this.group,
    super.key,
  });
  final UnifiedGroup group;

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  final UnifiedGroupService _groupService = UnifiedGroupService();
  final ImageUploadService _imageService = ImageUploadService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // State variables
  String _selectedType = '';
  List<String> _tags = [];
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isLoading = false;
  bool _canEdit = false;

  // Tag suggestions
  final List<String> _tagSuggestions = [
    'music',
    'nigerian',
    'afrobeats',
    'lagos',
    'abuja',
    'networking',
    'business',
    'tech',
    'art',
    'sports',
    'fitness',
    'food',
    'travel',
    'culture',
    'language',
    'education',
    'career',
    'entrepreneurship',
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
    _checkPermissions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _initializeData() {
    _nameController.text = widget.group.name;
    _descriptionController.text = widget.group.description;
    _locationController.text = widget.group.location ?? '';
    _selectedType = widget.group.type.name; // Convert enum to string
    _tags = List<String>.from(widget.group.tags);
    _uploadedImageUrl = widget.group.imageUrl;
  }

  void _checkPermissions() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      setState(() {
        _canEdit = false;
      });
      return;
    }
    final isCreator = currentUserId == widget.group.creatorId;
    final isAdmin = widget.group.adminIds.contains(currentUserId);

    setState(() {
      _canEdit = isCreator || isAdmin;
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_canEdit) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl = _uploadedImageUrl;

      // Upload image if a new one is selected
      if (_selectedImage != null) {
        try {
          AppLogger.info('Uploading group image...');
          imageUrl = await _imageService.uploadImage(
            imageFile: _selectedImage!,
            path: 'group_avatars',
            fileName:
                '${widget.group.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          AppLogger.info('Image uploaded successfully: $imageUrl');
        } catch (e) {
          AppLogger.error('Failed to upload image', error: e);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload image: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Parse GroupType from string
      GroupType? groupType;
      try {
        groupType = GroupType.values.firstWhere(
          (type) => type.name == _selectedType,
        );
      } catch (e) {
        AppLogger.error('Invalid group type: $_selectedType', error: e);
        // Keep existing type if invalid
      }

      await _groupService.updateGroupSettings(
        groupId: widget.group.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        type: groupType,
        tags: _tags,
        imageUrl: imageUrl,
      );

      if (mounted) {
        await SuccessDialog.show(
          context: context,
          title: 'Settings Updated!',
          message: 'Your group settings have been saved successfully.',
          actionText: 'Done',
          onAction: () {
            Navigator.pop(context); // Close dialog
            Navigator.pop(context); // Go back to group details
          },
          onClose: () {
            Navigator.pop(context); // Close dialog
            Navigator.pop(context); // Go back to group details
          },
        );
      }
    } catch (e) {
      AppLogger.error('Failed to save group settings', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_canEdit) {
      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          title: Text(
            'Group Settings',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppColors.backgroundColor,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Access Denied',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Only group creators and admins can edit group settings.',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Group Settings',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveSettings,
            child: Text(
              'Save',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _isLoading ? Colors.grey : AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group Avatar Section
              _buildAvatarSection(),
              const SizedBox(height: 24),

              // Group Information Section
              _buildGroupInfoSection(),
              const SizedBox(height: 24),

              // Group Type Section
              _buildGroupTypeSection(),
              const SizedBox(height: 24),

              // Tags Section
              _buildTagsSection(),
              const SizedBox(height: 24),

              // Location Section
              _buildLocationSection(),
              const SizedBox(height: 32),

              // Save Button
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Group Photo',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: GroupAvatarPicker(
              selectedImage: _selectedImage,
              defaultImageUrl: _uploadedImageUrl,
              onImageSelected: (image) {
                setState(() {
                  _selectedImage = image;
                  // Clear uploaded URL when new image is selected
                  if (image == null) {
                    _uploadedImageUrl = null;
                  }
                });
              },
              size: 120,
            ),
          ),
        ],
      );

  Widget _buildGroupInfoSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Group Information',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Group Name',
              hintText: 'Enter group name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.group),
            ),
            validator: ValidationService.validateGroupName,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Describe your group',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.description),
            ),
            maxLines: 3,
            validator: ValidationService.validateGroupDescription,
          ),
        ],
      );

  Widget _buildGroupTypeSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Group Type',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedType.isNotEmpty ? _selectedType : null,
            decoration: InputDecoration(
              labelText: 'Select group type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.category),
            ),
            items: GroupType.values.map((type) {
              final displayName = _getGroupTypeDisplayName(type.name);
              return DropdownMenuItem<String>(
                value: type.name,
                child: Text(displayName),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedType = value ?? '';
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a group type';
              }
              return null;
            },
          ),
        ],
      );

  Widget _buildTagsSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tags',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add tags to help others discover your group',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          TagInputWidget(
            tags: _tags,
            onTagsChanged: (tags) {
              setState(() {
                _tags = tags;
              });
            },
            hintText: 'e.g., music, nigerian, afrobeats',
            suggestions: _tagSuggestions,
          ),
        ],
      );

  Widget _buildLocationSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: 'Location',
              hintText: 'Enter group location',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.location_on),
            ),
          ),
        ],
      );

  String _getGroupTypeDisplayName(String typeName) {
    // Convert enum name to display name (e.g., 'music' -> 'Music')
    if (typeName.isEmpty) return '';
    return typeName[0].toUpperCase() + typeName.substring(1);
  }

  Widget _buildSaveButton() => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveSettings,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Save Settings',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      );
}
