import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:naijasingles/common/constants/app_colors.dart';
import 'package:naijasingles/services/unified_group_service.dart';
import 'package:naijasingles/services/validation_service.dart';
import 'package:naijasingles/widgets/group_avatar_picker.dart';
import 'package:naijasingles/widgets/tag_input_widget.dart';
import 'package:naijasingles/widgets/success_dialog.dart';
// import 'package:naijasingles/common/widgets/loading_dialog.dart'; // TODO: Create loading dialog widget
import 'dart:io';

/// Screen for editing group settings (creator/admin only)
class GroupSettingsScreen extends StatefulWidget {
  final UnifiedGroup group;

  const GroupSettingsScreen({
    super.key,
    required this.group,
  });

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  final UnifiedGroupService _groupService = UnifiedGroupService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  // State variables
  String _selectedType = '';
  List<String> _tags = [];
  File? _selectedImage;
  bool _isLoading = false;
  bool _canEdit = false;

  // Tag suggestions
  final List<String> _tagSuggestions = [
    'music', 'nigerian', 'afrobeats', 'lagos', 'abuja', 'networking',
    'business', 'tech', 'art', 'sports', 'fitness', 'food', 'travel',
    'culture', 'language', 'education', 'career', 'entrepreneurship',
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
    _descriptionController.text = widget.group.description ?? '';
    _locationController.text = widget.group.location ?? '';
    _selectedType = widget.group.type.toString().split('.').last; // Convert enum to string
    _tags = List<String>.from(widget.group.tags ?? []);
  }

  void _checkPermissions() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isCreator = currentUserId == widget.group.creatorId;
    final isAdmin = widget.group.adminIds.contains(currentUserId ?? '');
    
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

    // LoadingDialog.show(context: context, message: 'Saving group settings...'); // TODO: Implement loading dialog

    try {
      // TODO: Handle image upload if _selectedImage is not null
      // For now, we'll just update the group without image changes
      
      await _groupService.updateGroupSettings(
        groupId: widget.group.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        // location: _locationController.text.trim(), // TODO: Add location parameter to service
        // type: _selectedType, // TODO: Add type parameter to service
        tags: _tags,
        // imageUrl: null, // TODO: Add image upload logic
      );

      // LoadingDialog.hide(context); // TODO: Implement loading dialog

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
      // LoadingDialog.hide(context); // TODO: Implement loading dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
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

  Widget _buildAvatarSection() {
    return Column(
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
            onImageSelected: (image) {
              setState(() {
                _selectedImage = image;
              });
            },
            size: 120,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupInfoSection() {
    return Column(
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
  }

  Widget _buildGroupTypeSection() {
    return Column(
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
          value: _selectedType.isNotEmpty ? _selectedType : null,
          decoration: InputDecoration(
            labelText: 'Select group type',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.category),
          ),
          items: const [
            DropdownMenuItem(value: 'music', child: Text('Music')),
            DropdownMenuItem(value: 'sports', child: Text('Sports')),
            DropdownMenuItem(value: 'travel', child: Text('Travel')),
            DropdownMenuItem(value: 'food', child: Text('Food')),
            DropdownMenuItem(value: 'art', child: Text('Art')),
            DropdownMenuItem(value: 'career', child: Text('Career')),
            DropdownMenuItem(value: 'fitness', child: Text('Fitness')),
            DropdownMenuItem(value: 'gaming', child: Text('Gaming')),
            DropdownMenuItem(value: 'reading', child: Text('Reading')),
            DropdownMenuItem(value: 'movies', child: Text('Movies')),
            DropdownMenuItem(value: 'events', child: Text('Events')),
            DropdownMenuItem(value: 'networking', child: Text('Networking')),
            DropdownMenuItem(value: 'support', child: Text('Support')),
            DropdownMenuItem(value: 'study', child: Text('Study')),
          ],
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
  }

  Widget _buildTagsSection() {
    return Column(
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
          maxTags: 5,
          hintText: 'e.g., music, nigerian, afrobeats',
          suggestions: _tagSuggestions,
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
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
  }

  Widget _buildSaveButton() {
    return SizedBox(
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
}
