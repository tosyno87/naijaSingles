import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/constants/app_colors.dart';
import '../../../common/utils/app_logger.dart';
import '../../../services/image_upload_service.dart';
import '../../../services/unified_group_service.dart';
import '../../../services/validation_service.dart';
import '../../../widgets/group_avatar_picker.dart';
import '../../../widgets/success_dialog.dart';
import '../../../widgets/tag_input_widget.dart';
import '../../groups/widgets/contact_picker_widget.dart';
import 'group_chat_screen.dart';

/// Screen for creating new group chats
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final UnifiedGroupService _groupService = UnifiedGroupService();
  final ImageUploadService _imageService = ImageUploadService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  GroupType _selectedType = GroupType.music;
  String? _selectedLocation;
  final List<String> _selectedMembers = [];
  List<String> _tags = [];
  File? _selectedImage;
  bool _isCreating = false;

  // Popular tag suggestions
  final List<String> _tagSuggestions = [
    'music',
    'nigerian',
    'afrobeats',
    'lagos',
    'abuja',
    'community',
    'friends',
    'networking',
    'events',
    'culture',
    'food',
    'travel',
    'sports',
    'fitness',
    'gaming',
    'art',
    'fashion',
    'tech',
    'business',
    'career',
    'study',
    'support',
    'local',
    'international',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: Text(
          'Create Group',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createGroup,
            child: Text(
              'Create',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
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
              _buildAvatarSection(),
              const SizedBox(height: 24),
              _buildGroupTypeSection(),
              const SizedBox(height: 24),
              _buildGroupInfoSection(),
              const SizedBox(height: 24),
              _buildTagsSection(),
              const SizedBox(height: 24),
              _buildMembersSection(),
              const SizedBox(height: 24),
              _buildLocationSection(),
              const SizedBox(height: 32),
              _buildCreateButton(),
            ],
          ),
        ),
      ),
    );

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
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: GroupType.values.map((type) {
            final isSelected = _selectedType == type;
            return GestureDetector(
              onTap: () => setState(() => _selectedType = type),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryGreen : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primaryGreen : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getGroupTypeIcon(type),
                      size: 16,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getGroupTypeLabel(type),
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
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
              borderRadius: BorderRadius.circular(12),
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
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.description),
          ),
          maxLines: 3,
          validator: ValidationService.validateGroupDescription,
        ),
      ],
    );

  Widget _buildMembersSection() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Members',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _selectMembers,
              icon: const Icon(Icons.add),
              label: const Text('Add Members'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_selectedMembers.isEmpty)
          GestureDetector(
            onTap: _selectMembers,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryGreen.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.contacts_outlined,
                    size: 48,
                    color: AppColors.primaryGreen.withOpacity(0.7),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add Members from Contacts',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Invite friends from your phone contacts or by email',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Select Contacts',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedMembers.map((memberId) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.primaryGreen.withOpacity(0.3),),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primaryGreen,
                      child: Text(
                        memberId.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      memberId, // In real app, you'd get the user's name
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _removeMember(memberId),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),).toList(),
          ),
      ],
    );

  Widget _buildLocationSection() {
    if (_selectedType != GroupType.local) return const SizedBox.shrink();

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
        const SizedBox(height: 12),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Location',
            hintText: 'Enter location (optional)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.location_on),
          ),
          onChanged: (value) =>
              _selectedLocation = value.trim().isEmpty ? null : value.trim(),
        ),
      ],
    );
  }

  Widget _buildCreateButton() => SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isCreating ? null : _createGroup,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isCreating
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                'Create Group',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );

  String _getGroupTypeLabel(GroupType type) {
    switch (type) {
      // Interest & Hobby Groups
      case GroupType.music:
        return 'Music';
      case GroupType.sports:
        return 'Sports';
      case GroupType.travel:
        return 'Travel';
      case GroupType.food:
        return 'Food';
      case GroupType.art:
        return 'Art';

      // Lifestyle & Career Groups
      case GroupType.career:
        return 'Career';
      case GroupType.fitness:
        return 'Fitness';
      case GroupType.gaming:
        return 'Gaming';
      case GroupType.reading:
        return 'Reading';
      case GroupType.movies:
        return 'Movies';

      // Social & Community Groups
      case GroupType.events:
        return 'Events';
      case GroupType.networking:
        return 'Networking';
      case GroupType.support:
        return 'Support';
      case GroupType.study:
        return 'Study';
      case GroupType.local:
        return 'Local';

      // Special Interest Groups
      case GroupType.tech:
        return 'Technology';
      case GroupType.fashion:
        return 'Fashion';
      case GroupType.pets:
        return 'Pets';
      case GroupType.parenting:
        return 'Parenting';
      case GroupType.seniors:
        return 'Seniors';
    }
  }

  IconData _getGroupTypeIcon(GroupType type) {
    switch (type) {
      // Interest & Hobby Groups
      case GroupType.music:
        return Icons.music_note;
      case GroupType.sports:
        return Icons.sports_soccer;
      case GroupType.travel:
        return Icons.travel_explore;
      case GroupType.food:
        return Icons.restaurant;
      case GroupType.art:
        return Icons.palette;

      // Lifestyle & Career Groups
      case GroupType.career:
        return Icons.work;
      case GroupType.fitness:
        return Icons.fitness_center;
      case GroupType.gaming:
        return Icons.sports_esports;
      case GroupType.reading:
        return Icons.menu_book;
      case GroupType.movies:
        return Icons.movie;

      // Social & Community Groups
      case GroupType.events:
        return Icons.event;
      case GroupType.networking:
        return Icons.people;
      case GroupType.support:
        return Icons.support_agent;
      case GroupType.study:
        return Icons.school;
      case GroupType.local:
        return Icons.location_on;

      // Special Interest Groups
      case GroupType.tech:
        return Icons.computer;
      case GroupType.fashion:
        return Icons.checkroom;
      case GroupType.pets:
        return Icons.pets;
      case GroupType.parenting:
        return Icons.child_care;
      case GroupType.seniors:
        return Icons.elderly;
    }
  }

  void _selectMembers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactPickerWidget(
          groupName: _nameController.text.isNotEmpty
              ? _nameController.text
              : 'New Group',
          groupId: '', // Will be set after group creation
          onInvitationsSent: (invitations) {
            // Handle sent invitations
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${invitations.length} invitations sent!'),
                backgroundColor: AppColors.primaryGreen,
              ),
            );
          },
        ),
      ),
    );
  }

  void _removeMember(String memberId) {
    setState(() {
      _selectedMembers.remove(memberId);
    });
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    // Show loading dialog
    LoadingDialog.show(
      context: context,
    );

    setState(() {
      _isCreating = true;
    });

    try {
      String? imageUrl;

      // Upload image if selected
      if (_selectedImage != null) {
        try {
          imageUrl = await _imageService.uploadCompressedImage(
            imageFile: _selectedImage!,
            path: 'group_avatars',
          );
        } catch (e) {
          // Continue without image if upload fails
          AppLogger.error('Image upload failed', error: e);
        }
      }

      // Create group
      final group = await _groupService.createGroup(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        location: _selectedLocation,
        initialMembers: _selectedMembers,
        imageUrl: imageUrl,
        tags: _tags,
      );

      // Hide loading dialog
      LoadingDialog.hide(context);

      // Show success dialog
      if (mounted) {
        await SuccessDialog.show(
          context: context,
          title: 'Group Created!',
          message:
              'Your group "${_nameController.text.trim()}" has been created successfully!',
          actionText: 'Open Group',
          onAction: () {
            Navigator.pop(context); // Close dialog
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => GroupChatScreen(groupId: group.id),
              ),
            );
          },
          onClose: () {
            Navigator.pop(context); // Close dialog
            Navigator.pop(context); // Go back to previous screen
          },
        );
      }
    } catch (e) {
      // Hide loading dialog
      LoadingDialog.hide(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create group: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
}
