import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/user_model.dart';
import '../../../common/constants/app_colors.dart';

/// Hinge-style profile card that displays all information in a vertical scrollable format
/// Users can scroll down to see photos, bio, prompts, and details without tapping
class HingeProfileCard extends StatefulWidget {
  const HingeProfileCard({
    required this.user,
    this.onConnect,
    this.onPass,
    super.key,
  });

  final UserModel user;
  final VoidCallback? onConnect;
  final VoidCallback? onPass;

  @override
  State<HingeProfileCard> createState() => _HingeProfileCardState();
}

class _HingeProfileCardState extends State<HingeProfileCard> {
  final PageController _photoPageController = PageController();
  int _currentPhotoIndex = 0;

  @override
  void dispose() {
    _photoPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Safely convert imageUrl to List<String>
    final imageUrl = widget.user.imageUrl;
    final photos = _extractPhotos(imageUrl);
    final bio = widget.user.bio ?? widget.user.editInfo?['userBio']?.toString() ?? '';
    final interests = _extractInterests();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo carousel section - horizontal swipeable, or placeholder if no photos
          if (photos.isNotEmpty) _buildPhotoSection(photos) else _buildPhotoPlaceholder(),

          // Profile header (name, age, location)
          _buildProfileHeader(),

          // Bio section
          if (bio.isNotEmpty) _buildBioSection(bio),

          // Prompts section (can be expanded later)
          _buildPromptsSection(),

          // Details section
          _buildDetailsSection(),

          // Interests section
          if (interests.isNotEmpty) _buildInterestsSection(interests),

          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  List<String> _extractPhotos(dynamic imageUrl) {
    // Debug: Log what we're receiving
    debugPrint('🔍 HingeProfileCard._extractPhotos - imageUrl type: ${imageUrl.runtimeType}');
    debugPrint('🔍 HingeProfileCard._extractPhotos - imageUrl value: $imageUrl');
    
    if (imageUrl == null) {
      debugPrint('❌ imageUrl is null');
      return [];
    }
    if (imageUrl is! List) {
      debugPrint('❌ imageUrl is not a List, it is: ${imageUrl.runtimeType}');
      return [];
    }
    if (imageUrl.isEmpty) {
      debugPrint('❌ imageUrl list is empty');
      return [];
    }
    
    final photos = imageUrl
        .map((e) => e?.toString() ?? '')
        .where((url) => url.isNotEmpty && url.trim().isNotEmpty)
        .toList()
        .cast<String>();
    
    debugPrint('✅ Extracted ${photos.length} photos: $photos');
    return photos;
  }

  Widget _buildPhotoPlaceholder() {
    final screenHeight = MediaQuery.of(context).size.height;
    return SizedBox(
      height: screenHeight * 0.5,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No photos available',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection(List<String> photos) {
    final screenHeight = MediaQuery.of(context).size.height;
    return SizedBox(
      height: screenHeight * 0.5, // 50% of screen height for photos
      child: PageView.builder(
        controller: _photoPageController,
        onPageChanged: (index) {
          setState(() {
            _currentPhotoIndex = index;
          });
        },
        itemCount: photos.length,
        itemBuilder: (context, index) {
          final photoUrl = photos[index];
          debugPrint('🖼️ Loading photo $index: $photoUrl');
          
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            child: Stack(
              children: [
                Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF008037),
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('❌ Error loading photo $index ($photoUrl): $error');
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Failed to load',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Photo indicator dots
                if (photos.length > 1)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        photos.length,
                        (dotIndex) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: dotIndex == _currentPhotoIndex
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
      ),
    );
  }

  Widget _buildProfileHeader() {
    // Get basic info
    final age = widget.user.age;
    final gender = widget.user.userGender ?? widget.user.editInfo?['userGender'];
    final height = widget.user.editInfo?['heightDisplay'] ?? 
                   widget.user.editInfo?['height_ft_in'];
    final location = widget.user.living_in ?? 
                     widget.user.editInfo?['locationName'];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name only (age will be in details row)
          Text(
            widget.user.name ?? 'Unknown',
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Hinge-style horizontal basic info row
          if (age != null || gender != null || height != null || location != null)
            Row(
              children: [
                if (age != null)
                  _buildBasicInfoItem(Icons.cake, age.toString()),
                if (gender != null) ...[
                  if (age != null) const SizedBox(width: 16),
                  _buildBasicInfoItem(Icons.person, gender.toString()),
                ],
                if (height != null && height.toString().isNotEmpty && height.toString() != '0') ...[
                  if (age != null || gender != null) const SizedBox(width: 16),
                  _buildBasicInfoItem(Icons.straighten, height.toString()),
                ],
                if (location != null) ...[
                  if (age != null || gender != null || height != null) const SizedBox(width: 16),
                  _buildBasicInfoItem(Icons.location_on, location.toString()),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }


  Widget _buildBioSection(String bio) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            bio,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPromptsSection() {
    // Placeholder for prompts - can be expanded later
    // Hinge uses 3 prompts, we can add this feature later
    return const SizedBox.shrink();
  }

  Widget _buildDetailsSection() {
    final details = <Map<String, dynamic>>[];

    // Work/Profession - briefcase icon (like Hinge)
    final workTitle = widget.user.job_title ?? 
                     widget.user.profession ?? 
                     widget.user.occupation;
    if (workTitle != null && workTitle.toString().isNotEmpty) {
      details.add({'icon': Icons.business_center, 'label': '', 'value': workTitle.toString()});
    }

    // Education - graduation cap icon (like Hinge)
    if (widget.user.education != null && widget.user.education!.isNotEmpty) {
      details.add({'icon': Icons.school, 'label': '', 'value': widget.user.education!});
    }

    // Religion - book icon (like Hinge)
    if (widget.user.religion != null && widget.user.religion!.isNotEmpty) {
      details.add({'icon': Icons.menu_book, 'label': '', 'value': widget.user.religion!});
    }

    // Relationship Intent (Relationship goals) - search icon (like Hinge)
    final relationshipIntent = widget.user.editInfo?['relationshipIntent'] ??
                              widget.user.editInfo?['preferences']?['relationshipIntent'];
    if (relationshipIntent != null && relationshipIntent.toString().isNotEmpty) {
      details.add({'icon': Icons.search, 'label': '', 'value': relationshipIntent.toString()});
    }

    // Tribe - group icon
    if (widget.user.tribe != null && widget.user.tribe!.isNotEmpty) {
      details.add({'icon': Icons.group, 'label': '', 'value': widget.user.tribe!});
    }

    if (details.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Hinge-style details: just icon and value, no label
          ...details.map((detail) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      detail['icon'] as IconData,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        detail['value'] as String,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInterestsSection(List<String> interests) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interests',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: interests.map((interest) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    interest,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                )).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pass button - circular, minimalistic
          Material(
            color: Colors.white,
            shape: const CircleBorder(
              side: BorderSide(color: AppColors.textSecondary, width: 1.5),
            ),
            child: InkWell(
              onTap: widget.onPass,
              customBorder: const CircleBorder(),
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Connect button - circular, minimalistic
          Material(
            color: AppColors.primaryGreen,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: widget.onConnect,
              customBorder: const CircleBorder(),
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _extractInterests() {
    final interests = <String>[];
    
    // Try to get interests from editInfo
    if (widget.user.editInfo != null) {
      final editInfo = widget.user.editInfo!;
      if (editInfo['interests'] is List) {
        final interestsList = editInfo['interests'] as List<dynamic>;
        interests.addAll(interestsList.map<String>((e) => e.toString()).take(10));
      }
    }

    return interests;
  }
}

