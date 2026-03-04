// ⚠️ DEPRECATED: Use the canonical version at
// lib/features/group_chat/screens/create_group_screen.dart
// This file uses the legacy GroupService. The canonical version uses
// UnifiedGroupService with image upload, validation, and tag input.
// TODO: Migrate callers (groups_screen.dart) to the canonical version,
// then delete this file.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../common/constants/app_colors.dart';
import '../../../../common/widgets/custom_3d_icons.dart';
import '../../../../models/group_model.dart';
import '../../data/services/group_service.dart';

@Deprecated('Use CreateGroupScreen from group_chat/screens/ instead')
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagController = TextEditingController();

  final GroupService _groupService = GroupService();

  String _selectedCategory = 'Cultural';
  bool _isPublic = true;
  int _maxMembers = 100;
  final List<String> _tags = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final groupId = await _groupService.createGroup(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        isPublic: _isPublic,
        maxMembers: _maxMembers,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        tags: _tags,
        culturalInfo: {
          'category': _selectedCategory,
          'focus': _selectedCategory.toLowerCase(),
        },
        settings: {
          'allowMemberInvites': true,
          'requireApproval': false,
          'allowPosts': true,
        },
      );

      if (groupId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Group "${_nameController.text.trim()}" created successfully!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to create group');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating group: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag) && _tags.length < 5) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          title: Text(
            'Create Group',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          backgroundColor: AppColors.backgroundColor,
          elevation: 0,
        ),
        body: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Group Image Section
                      _buildGroupImageSection(),

                      const SizedBox(height: 24),

                      // Group Name
                      _buildTextField(
                        controller: _nameController,
                        label: 'Group Name',
                        hint: 'Enter group name',
                        icon: Icons.groups,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Group name is required';
                          }
                          if (value.trim().length < 3) {
                            return 'Group name must be at least 3 characters';
                          }
                          if (value.trim().length > 50) {
                            return 'Group name must be less than 50 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Description
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        hint: 'Describe your group and its purpose',
                        icon: Icons.edit,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Description is required';
                          }
                          if (value.trim().length < 10) {
                            return 'Description must be at least 10 characters';
                          }
                          if (value.trim().length > 500) {
                            return 'Description must be less than 500 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Category Selection
                      _buildCategorySelection(),

                      const SizedBox(height: 20),

                      // Location
                      _buildTextField(
                        controller: _locationController,
                        label: 'Location (Optional)',
                        hint: 'City, Country',
                        icon: Icons.location_on,
                      ),

                      const SizedBox(height: 20),

                      // Tags
                      _buildTagsSection(),

                      const SizedBox(height: 24),

                      // Section Divider
                      _buildSectionDivider('Group Settings'),

                      const SizedBox(height: 16),

                      // Group Settings
                      _buildGroupSettings(),

                      const SizedBox(height: 100), // Space for bottom button
                    ],
                  ),
                ),
              ),
            ),
            // Bottom Create Button
            _buildCreateButton(),
          ],
        ),
      );

  Widget _buildGroupImageSection() => Center(
        child: Stack(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.border,
              child: Icon(
                Icons.groups,
                size: 40,
                color: AppColors.textSecondary,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                  boxShadow: AppColors.buttonShadow,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // TODO: Implement image picker
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Image picker coming soon!'),
                          backgroundColor: AppColors.info,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppColors.cardShadow,
            ),
            child: TextFormField(
              controller: controller,
              maxLines: maxLines,
              validator: validator,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.montserrat(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  icon,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primaryGreen, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ],
      );

  Widget _buildCategorySelection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppColors.cardShadow,
            ),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primaryGreen, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                prefixIcon: const Icon(
                  Icons.filter_list,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
              ),
              items: GroupCategories.categories
                  .map(
                    (category) => DropdownMenuItem<String>(
                      value: category,
                      child: Row(
                        children: [
                          Text(GroupCategories.categoryIcons[category] ?? '🌟'),
                          const SizedBox(width: 8),
                          Text(
                            category,
                            style: GoogleFonts.montserrat(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value!);
              },
              icon: const Icon(Icons.arrow_drop_down,
                  color: AppColors.primaryGreen),
              dropdownColor: Colors.white,
              style: GoogleFonts.montserrat(
                  color: AppColors.textPrimary, fontSize: 14),
            ),
          ),
        ],
      );

  Widget _buildTagsSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tags (${_tags.length}/5)',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // Tags Display
          if (_tags.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags
                  .map(
                    (tag) => Chip(
                      label: Text(
                        tag,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
                      side: BorderSide(
                        color: AppColors.primaryGreen.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      deleteIcon: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.primaryGreen,
                      ),
                      onDeleted: () => _removeTag(tag),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Add Tag Input
          if (_tags.length < 5)
            Row(
              children: [
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: TextField(
                      controller: _tagController,
                      decoration: InputDecoration(
                        hintText: 'Add tag...',
                        hintStyle: GoogleFonts.montserrat(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.tag,
                          color: AppColors.primaryGreen,
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.primaryGreen, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primaryGreen),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _addTag,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(
                          Icons.add,
                          color: AppColors.primaryGreen,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      );

  Widget _buildSectionDivider(String title) => Row(
        children: [
          const Expanded(
            child: Divider(
              color: AppColors.border,
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Expanded(
            child: Divider(
              color: AppColors.border,
              thickness: 1,
            ),
          ),
        ],
      );

  Widget _buildGroupSettings() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Public/Private Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.public,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Public Group',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Anyone can find and join this group',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isPublic,
                  onChanged: (value) {
                    setState(() => _isPublic = value);
                  },
                  activeThumbColor: AppColors.primaryGreen,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Max Members
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.groups,
                      color: AppColors.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Maximum Members',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _maxMembers.toDouble(),
                  min: 10,
                  max: 500,
                  divisions: 49,
                  activeColor: AppColors.primaryGreen,
                  onChanged: (value) {
                    setState(() => _maxMembers = value.round());
                  },
                ),
                Text(
                  '$_maxMembers members',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildCreateButton() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppColors.buttonShadow,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoading ? null : _createGroup,
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Custom3DIcons.add(size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Create Group',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

}
