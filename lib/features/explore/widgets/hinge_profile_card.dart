import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/constants/app_colors.dart';
import '../../../common/utils/country_flag.dart';
import '../../../common/utils/remote_image_url.dart';
import '../../../models/user_model.dart';

/// Vertical profile card: photos, identity, bio, and details in one scrollable column.
class HingeProfileCard extends StatefulWidget {
  const HingeProfileCard({
    required this.user,
    this.onConnect,
    this.onPass,
    this.onSuperLike,
    super.key,
  });

  final UserModel user;
  final VoidCallback? onConnect;
  final VoidCallback? onPass;
  final VoidCallback? onSuperLike;

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
    final bio =
        widget.user.bio ?? widget.user.editInfo?['userBio']?.toString() ?? '';
    final interests = _extractInterests();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo carousel section - horizontal swipeable, or placeholder if no photos
          if (photos.isNotEmpty)
            _buildPhotoSection(photos)
          else
            _buildPhotoPlaceholder(),

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

  List<String> _extractPhotos(Object? imageUrl) {
    if (imageUrl == null) return [];
    if (imageUrl is! List) return [];
    if (imageUrl.isEmpty) return [];

    final photos = imageUrl
        .map((e) => e?.toString() ?? '')
        .where(
          (url) =>
              url.isNotEmpty &&
              url.trim().isNotEmpty &&
              !isPlaceholderOrUnreliableImageUrl(url),
        )
        .toList()
        .cast<String>();

    return photos;
  }

  Widget _buildSinglePhotoPlaceholder(double height) => SizedBox(
        height: height,
        width: double.infinity,
        child: DecoratedBox(
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
                Icon(Icons.person, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'Photo unavailable',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildPhotoPlaceholder() {
    final screenHeight = MediaQuery.of(context).size.height;
    return SizedBox(
      height: screenHeight * 0.5,
      child: DecoratedBox(
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
          final usePlaceholder = isPlaceholderOrUnreliableImageUrl(photoUrl);

          return ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            child: Stack(
              children: [
                if (usePlaceholder)
                  _buildSinglePhotoPlaceholder(screenHeight * 0.5)
                else
                  CachedNetworkImage(
                    imageUrl: photoUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF008037),
                          ),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) {
                      if (kDebugMode) {
                        debugPrint(
                          '❌ Error loading photo $index ($photoUrl): $error',
                        );
                      }
                      return _buildSinglePhotoPlaceholder(screenHeight * 0.5);
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
                                : Colors.white.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader() {
    final rawName = widget.user.name ?? '';
    final name =
        rawName.trim().isEmpty ? 'Unknown' : rawName.trim();
    final age = widget.user.age;
    final nationality = widget.user.nationality?.trim() ?? '';
    var location = widget.user.living_in?.trim() ?? '';
    if (location.isEmpty) {
      location =
          widget.user.editInfo?['locationName']?.toString().trim() ?? '';
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name + (age != null ? ', $age' : ''),
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (nationality.isNotEmpty || location.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (nationality.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${CountryFlag.flagOrFallback(nationality)} $nationality',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                if (location.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          location,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBioSection(String bio) => Padding(
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

  Widget _buildPromptsSection() => const SizedBox.shrink();

  Widget _buildDetailsSection() {
    final details = <Map<String, dynamic>>[];

    if (widget.user.age != null) {
      details.add({
        'icon': Icons.cake,
        'label': '',
        'value': widget.user.age.toString(),
      });
    }

    final gender =
        widget.user.userGender ?? widget.user.editInfo?['userGender'];
    if (gender != null && gender.toString().trim().isNotEmpty) {
      details.add({
        'icon': Icons.person,
        'label': '',
        'value': gender.toString(),
      });
    }

    final height = widget.user.editInfo?['heightDisplay'] ??
        widget.user.editInfo?['height_ft_in'];
    if (height != null &&
        height.toString().trim().isNotEmpty &&
        height.toString() != '0') {
      details.add({
        'icon': Icons.straighten,
        'label': '',
        'value': height.toString(),
      });
    }

    // Work / profession
    final workTitle = widget.user.job_title ??
        widget.user.profession ??
        widget.user.occupation;
    if (workTitle != null && workTitle.toString().isNotEmpty) {
      details.add({
        'icon': Icons.business_center,
        'label': '',
        'value': workTitle.toString(),
      });
    }

    // Education
    if (widget.user.education != null && widget.user.education!.isNotEmpty) {
      details.add(
        {'icon': Icons.school, 'label': '', 'value': widget.user.education},
      );
    }

    // Religion
    if (widget.user.religion != null && widget.user.religion!.isNotEmpty) {
      details.add({
        'icon': Icons.menu_book,
        'label': '',
        'value': widget.user.religion,
      });
    }

    // Relationship intent / goals
    final relationshipIntent = widget.user.editInfo?['relationshipIntent'] ??
        widget.user.editInfo?['preferences']?['relationshipIntent'];
    if (relationshipIntent != null &&
        relationshipIntent.toString().isNotEmpty) {
      details.add({
        'icon': Icons.search,
        'label': '',
        'value': relationshipIntent.toString(),
      });
    }

    // Tribe - group icon
    if (widget.user.tribe != null && widget.user.tribe!.isNotEmpty) {
      details
          .add({'icon': Icons.group, 'label': '', 'value': widget.user.tribe});
    }

    if (details.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          ...details.map(
            (detail) => Padding(
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
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInterestsSection(List<String> interests) => Padding(
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
              children: interests
                  .map(
                    (interest) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primaryGreen.withValues(alpha: 0.3),
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
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );

  Widget _buildActionButtons() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pass button
            _buildCircleAction(
              onTap: widget.onPass,
              fillColor: Colors.white,
              border: const BorderSide(
                color: AppColors.textSecondary,
                width: 1.5,
              ),
              icon: Icons.close,
              iconColor: AppColors.textSecondary,
              size: 56,
            ),
            const SizedBox(width: 20),
            // Super Like button
            _buildCircleAction(
              onTap: widget.onSuperLike,
              fillColor: const Color(0xFF2196F3),
              icon: Icons.star_rounded,
              iconColor: Colors.white,
              size: 48,
            ),
            const SizedBox(width: 20),
            // Connect / Like button
            _buildCircleAction(
              onTap: widget.onConnect,
              fillColor: AppColors.primaryGreen,
              icon: Icons.favorite,
              iconColor: Colors.white,
              size: 56,
            ),
          ],
        ),
      );

  Widget _buildCircleAction({
    required VoidCallback? onTap,
    required Color fillColor,
    required IconData icon,
    required Color iconColor,
    required double size,
    BorderSide border = BorderSide.none,
  }) =>
      Material(
        color: fillColor,
        shape: CircleBorder(side: border),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, color: iconColor, size: size * 0.43),
          ),
        ),
      );

  List<String> _extractInterests() {
    final interests = <String>[];

    // Try to get interests from editInfo
    if (widget.user.editInfo != null) {
      final editInfo = widget.user.editInfo!;
      if (editInfo['interests'] is List) {
        final interestsList = editInfo['interests'] as List<dynamic>;
        interests
            .addAll(interestsList.map<String>((e) => e.toString()).take(10));
      }
    }

    return interests;
  }
}
