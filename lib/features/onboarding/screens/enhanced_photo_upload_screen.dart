import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../features/user/controllers/onboarding_controller.dart';
import '../widgets/photo_type_indicator.dart';
import '../widgets/primary_photo_slot.dart';
import '../widgets/reorderable_photo_grid.dart';
import '../widgets/profile_preview_screen.dart';

class EnhancedPhotoUploadScreen extends StatefulWidget {
  const EnhancedPhotoUploadScreen({super.key});

  @override
  State<EnhancedPhotoUploadScreen> createState() =>
      _EnhancedPhotoUploadScreenState();
}

class _EnhancedPhotoUploadScreenState extends State<EnhancedPhotoUploadScreen> {
  // Afropeep MVP theme colors
  static const Color afropeepGreen = Color(0xFF007A33);
  static const Color cardBackground = Color(0xFFF7E8DA);
  static const Color textDarkBrown = Color(0xFF3A1D0F);
  static const Color textLightBrown = Color(0xFF8B6C59);
  static const Color goldAccent = Color(0xFFFFD700);

  // Phase 2: Advanced features state
  bool _useReorderableGrid = false;

  // Photo type guidance for each slot
  final Map<int, PhotoTypeGuidance> photoGuidance = {
    0: PhotoTypeGuidance(
      type: PhotoType.closeUp,
      title: "Main Photo",
      description: "A clear, smiling face shot with good lighting",
      isPrimary: true,
    ),
    1: PhotoTypeGuidance(
      type: PhotoType.fullBody,
      title: "Full Body",
      description: "Show your full body in a natural setting",
      isPrimary: false,
    ),
    2: PhotoTypeGuidance(
      type: PhotoType.activity,
      title: "Activity",
      description: "You doing something you're passionate about",
      isPrimary: false,
    ),
    3: PhotoTypeGuidance(
      type: PhotoType.social,
      title: "Social",
      description: "With friends, but make sure your face is visible",
      isPrimary: false,
    ),
    4: PhotoTypeGuidance(
      type: PhotoType.lifestyle,
      title: "Lifestyle",
      description: "Your hobbies, travels, or interests",
      isPrimary: false,
    ),
  };

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickImage(ImageSource source, int index) async {
    final controller =
        Provider.of<OnboardingController>(context, listen: false);
    await controller.pickProfilePhoto(source, index);


    setState(() {});
  }

  // Phase 2: Photo reordering functionality
  void _reorderPhotos(int oldIndex, int newIndex) {
    final controller =
        Provider.of<OnboardingController>(context, listen: false);

    // Don't allow reordering the primary photo (index 0)
    if (oldIndex == 0 || newIndex == 0) return;

    final photos = List<File?>.from(controller.profilePhotos);
    final photo = photos.removeAt(oldIndex);
    photos.insert(newIndex, photo);

    // Update controller with reordered photos
    for (int i = 0; i < photos.length; i++) {
      controller.profilePhotos[i] = photos[i];
    }

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Photos reordered successfully",
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: afropeepGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Phase 2: Set primary photo functionality
  void _setPrimaryPhoto(int index) {
    final controller =
        Provider.of<OnboardingController>(context, listen: false);

    if (index == 0) return; // Already primary

    final photos = List<File?>.from(controller.profilePhotos);
    final newPrimaryPhoto = photos[index];
    final currentPrimaryPhoto = photos[0];

    // Swap photos
    photos[0] = newPrimaryPhoto;
    photos[index] = currentPrimaryPhoto;

    // Update controller
    for (int i = 0; i < photos.length; i++) {
      controller.profilePhotos[i] = photos[i];
    }

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Main photo updated successfully",
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: goldAccent,
        duration: Duration(seconds: 2),
      ),
    );
  }


  void _showImageSourceDialog(int index) {
    final guidance = photoGuidance[index]!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (guidance.isPrimary) ...[
                  Icon(Icons.star, color: goldAccent, size: 20),
                  SizedBox(width: 8),
                ],
                Text(
                  "Add ${guidance.title} Photo",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textDarkBrown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              guidance.description,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: textLightBrown,
              ),
            ),
            const SizedBox(height: 16),
            _buildImageSourceOption(
              icon: Icons.camera_alt,
              title: "Take a Photo",
              subtitle: "Use your camera with professional cropping",
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, index);
              },
            ),
            const Divider(height: 24),
            _buildImageSourceOption(
              icon: Icons.photo_library,
              title: "Choose from Gallery",
              subtitle: "Select a photo with professional cropping",
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
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
              color: afropeepGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: afropeepGreen,
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
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textDarkBrown,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: textLightBrown,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: afropeepGreen,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoItem(int index) {
    final controller = Provider.of<OnboardingController>(context);
    final photo = controller.profilePhotos[index];
    final bool isRequired = index < 3; // First 3 photos are required
    final guidance = photoGuidance[index]!;

    // Use primary photo slot for index 0
    if (index == 0) {
      return PrimaryPhotoSlot(
        photo: photo,
        guidance: guidance,
        onTap: () => _showImageSourceDialog(index),
        onRemove: photo != null
            ? () {
                controller.removeProfilePhoto(index);
                setState(() {});
              }
            : null,
      );
    }

    return GestureDetector(
      onTap: () => _showImageSourceDialog(index),
      child: Stack(
        children: [
          // Photo background
          if (photo != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                photo,
                width: double.infinity,
                height: 150,
                fit: BoxFit.contain,
              ),
            ),
          
          // Container for empty state and borders
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: photo == null ? cardBackground : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isRequired
                    ? (photo == null
                        ? Colors.red.withValues(alpha: 0.5)
                        : afropeepGreen)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: photo == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getPhotoTypeIcon(guidance.type),
                        size: 36,
                        color: isRequired
                            ? Colors.red.withValues(alpha: 0.7)
                            : Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        guidance.title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isRequired
                              ? Colors.red.withValues(alpha: 0.7)
                              : Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        isRequired ? "Required" : "Optional",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isRequired
                              ? Colors.red.withValues(alpha: 0.7)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  )
                : null,
          ),

          // Photo type indicator
          if (photo == null)
            Positioned(
              top: 8,
              left: 8,
              child: PhotoTypeIndicator(type: guidance.type),
            ),


          // Remove button if photo exists
          if (photo != null)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  controller.removeProfilePhoto(index);
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
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
    );
  }


  IconData _getPhotoTypeIcon(PhotoType type) {
    switch (type) {
      case PhotoType.closeUp:
        return Icons.face;
      case PhotoType.fullBody:
        return Icons.person;
      case PhotoType.activity:
        return Icons.sports_soccer;
      case PhotoType.social:
        return Icons.group;
      case PhotoType.lifestyle:
        return Icons.favorite;
    }
  }

  void _showPhotoTipsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Photo Tips for Dating Success",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textDarkBrown,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTipSection(
                "Essential Tips",
                [
                  "Your main photo should be a clear, smiling face shot",
                  "Include at least one full-body photo",
                  "Show your face clearly in most photos",
                  "Use good lighting - natural light works best",
                ],
                Icons.star,
                goldAccent,
              ),
              SizedBox(height: 16),
              _buildTipSection(
                "Nigerian Dating Context",
                [
                  "Include photos in traditional attire if you're proud of your heritage",
                  "Show yourself at cultural events or festivals",
                  "Include photos that represent your lifestyle in Nigeria",
                  "Consider photos at popular Nigerian locations",
                ],
                Icons.flag,
                Colors.green,
              ),
              SizedBox(height: 16),
              _buildTipSection(
                "What to Avoid",
                [
                  "Heavily filtered or edited photos",
                  "Group photos where you can't be identified",
                  "Blurry or dark photos",
                  "Photos with sunglasses in every shot",
                  "Mirror selfies with messy backgrounds",
                ],
                Icons.warning,
                Colors.red,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Got it!",
              style: GoogleFonts.poppins(
                color: afropeepGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Phase 2: Profile preview navigation
  void _showProfilePreview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePreviewScreen(),
      ),
    );
  }

  Widget _buildTipSection(
      String title, List<String> tips, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textDarkBrown,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        ...tips
            .map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("• ", style: TextStyle(color: color)),
                      Expanded(
                        child: Text(
                          tip,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: textLightBrown,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<OnboardingController>(context);
    final int uploadedCount =
        controller.profilePhotos.where((photo) => photo != null).length;
    final bool hasMinimumPhotos = uploadedCount >= 3;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Add Your Profile Photos",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textDarkBrown,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "Upload at least 3 photos to complete your profile. Your first photo will be your main profile photo.",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: textLightBrown,
            ),
          ),

          const SizedBox(height: 8),

          // Photo count indicator and actions
          Column(
            children: [
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: hasMinimumPhotos
                            ? afropeepGreen.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        "$uploadedCount/5 photos (min 3)",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: hasMinimumPhotos ? afropeepGreen : Colors.red,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 8),

                  // Action buttons
                  if (uploadedCount > 0)
                    TextButton(
                      onPressed: _showProfilePreview,
                      style: TextButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.preview, size: 14, color: afropeepGreen),
                          SizedBox(width: 4),
                          Text(
                            "Preview",
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: afropeepGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  TextButton(
                    onPressed: _showPhotoTipsDialog,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.help_outline,
                            size: 14, color: afropeepGreen),
                        SizedBox(width: 4),
                        Text(
                          "Tips",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: afropeepGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Phase 2: Toggle for reorderable grid
              if (uploadedCount > 1)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: _useReorderableGrid,
                          onChanged: (value) {
                            setState(() {
                              _useReorderableGrid = value;
                            });
                          },
                          activeColor: afropeepGreen,
                        ),
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "Enable photo reordering",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: textLightBrown,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Hinge-style bulk upload button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 24),
            child: ElevatedButton.icon(
              onPressed: () async {
                final controller = Provider.of<OnboardingController>(context, listen: false);
                await controller.pickMultiplePhotos(context);
                setState(() {});
              },
              icon: Icon(Icons.photo_library, color: Colors.white),
              label: Text(
                uploadedCount == 0 ? 'Select Multiple Photos' : 'Add More Photos',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: afropeepGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),

          // Phase 2: Conditional photo grid (reorderable or standard)
          if (_useReorderableGrid && uploadedCount > 1)
            ReorderablePhotoGrid(
              photos: controller.profilePhotos,
              photoGuidance: photoGuidance,
              onReorder: _reorderPhotos,
              onTap: _showImageSourceDialog,
              onRemove: (index) {
                controller.removeProfilePhoto(index);
                setState(() {});
              },
              onSetPrimary: _setPrimaryPhoto,
            )
          else ...[
            // Standard photo grid
            // Primary photo (index 0) - full width
            _buildPhotoItem(0),

            const SizedBox(height: 12),

            // Photo grid - second row (required photos)
            Row(
              children: [
                Expanded(child: _buildPhotoItem(1)),
                const SizedBox(width: 12),
                Expanded(child: _buildPhotoItem(2)),
              ],
            ),

            const SizedBox(height: 12),

            // Photo grid - third row (optional photos)
            Row(
              children: [
                Expanded(child: _buildPhotoItem(3)),
                const SizedBox(width: 12),
                Expanded(child: _buildPhotoItem(4)),
              ],
            ),
          ],

          const SizedBox(height: 32),

          // Enhanced photo tips card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade50,
                  Colors.green.shade50,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: afropeepGreen.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: afropeepGreen,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Quick Photo Guide",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textDarkBrown,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildQuickTipItem(
                  Icons.star,
                  "Main Photo: Clear face shot with a genuine smile",
                  goldAccent,
                ),
                _buildQuickTipItem(
                  Icons.person,
                  "Full Body: Show your style in a natural setting",
                  Colors.blue,
                ),
                _buildQuickTipItem(
                  Icons.favorite,
                  "Activity: Doing something you love or are passionate about",
                  Colors.red,
                ),
                _buildQuickTipItem(
                  Icons.group,
                  "Social: With friends, but ensure you're clearly visible",
                  Colors.purple,
                ),
                _buildQuickTipItem(
                  Icons.explore,
                  "Lifestyle: Your hobbies, travels, or cultural interests",
                  Colors.orange,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: afropeepGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.trending_up, color: afropeepGreen, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Profiles with diverse, high-quality photos get 3x more matches!",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: afropeepGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTipItem(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: textDarkBrown,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Data models for photo guidance
enum PhotoType {
  closeUp,
  fullBody,
  activity,
  social,
  lifestyle,
}

class PhotoTypeGuidance {
  final PhotoType type;
  final String title;
  final String description;
  final bool isPrimary;

  PhotoTypeGuidance({
    required this.type,
    required this.title,
    required this.description,
    required this.isPrimary,
  });
}
