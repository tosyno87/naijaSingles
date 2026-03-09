import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../common/constants/app_colors.dart';
import '../../../common/widgets/state_views/state_views.dart';
import '../../../models/user_model.dart';
import '../widgets/mode_specific_profile_sections.dart';

/// Pre-match profile screen - for viewing other users before matching
/// This is different from MatchProfileScreen which is for after matching
class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({
    required this.user,
    super.key,
    this.selectedMode,
  });
  final UserModel user;
  final String? selectedMode;

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  int _currentPhotoIndex = 0;
  final PageController _photoPageController = PageController();

  // MVP theme colors
  static const Color afropeepGreen = Color(0xFF008037); // MVP green
  static const Color cardBackground = Color(0xFFF7E8DA);
  static const Color textDarkBrown = Color(0xFF3A1D0F);
  static const Color textLightBrown = Color(0xFF8B6C59);

  @override
  void dispose() {
    _photoPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos =
        widget.user.imageUrl?.cast<String>() ?? <String>[]; // Fix type casting

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      extendBodyBehindAppBar: true, // Allow content behind app bar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            widget.user.name?.split(' ').first ?? 'Profile',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          // Photo section
          SliverToBoxAdapter(
            child: SizedBox(
              height: 500,
              child: _buildPhotoSection(photos),
            ),
          ),

          // Profile content
          SliverToBoxAdapter(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic info
                    _buildBasicInfo(),

                    const SizedBox(height: 24),

                    // Bio section
                    if (_getBio().isNotEmpty) ...[
                      _buildBioSection(),
                      const SizedBox(height: 24),
                    ],

                    // Interests section
                    if (_getInterests().isNotEmpty) ...[
                      _buildInterestsSection(),
                      const SizedBox(height: 24),
                    ],

                    // Mode-specific sections
                    if (widget.selectedMode != null) ...[
                      ModeSpecificProfileSections(
                        user: widget.user,
                        selectedMode: widget.selectedMode!,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Additional info
                    _buildAdditionalInfo(),

                    const SizedBox(
                      height: 24,
                    ), // Extra space at bottom for comfortable scrolling
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(List<String> photos) {
    if (photos.isEmpty) {
      return const ColoredBox(
        color: Color(0xFFF5F5F5),
        child: AppEmptyView(
          title: 'No Photos Available',
          subtitle: 'This profile does not have photos yet.',
          icon: Icons.person_outline,
        ),
      );
    }

    return Stack(
      children: [
        // Photo PageView
        PageView.builder(
          controller: _photoPageController,
          itemCount: photos.length,
          onPageChanged: (index) {
            setState(() {
              _currentPhotoIndex = index;
            });
          },
          itemBuilder: (context, index) => GestureDetector(
            onTap: () => _showFullScreenPhoto(photos, index),
            child: CachedNetworkImage(
              imageUrl: photos[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => ColoredBox(
                color: Colors.grey.shade100,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: afropeepGreen,
                    strokeWidth: 2,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => ColoredBox(
                color: Colors.grey.shade200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image_outlined,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Photo unavailable',
                      style: GoogleFonts.montserrat(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Enhanced photo indicators with better contrast
        if (photos.length > 1)
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                photos.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: index == _currentPhotoIndex ? 28 : 8,
                  height: 4,
                  decoration: BoxDecoration(
                    color: index == _currentPhotoIndex
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Enhanced photo counter with better visibility
        if (photos.length > 1)
          Positioned(
            top: 80,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8), // Increased opacity
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${_currentPhotoIndex + 1} of ${photos.length}',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600, // Increased weight
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                      color: Colors.black.withValues(alpha: 0.8),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBasicInfo() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name and age
          Text(
            "${widget.user.name ?? 'Unknown'}, ${widget.user.age ?? 'N/A'}",
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textDarkBrown,
            ),
          ),

          const SizedBox(height: 12),

          // Cultural information tags
          if (widget.user.nationality != null || widget.user.tribe != null) ...[
            Row(
              children: [
                if (widget.user.nationality != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: afropeepGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: afropeepGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '🇳🇬 ${widget.user.nationality}',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: afropeepGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (widget.user.tribe != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: afropeepGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: afropeepGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '🏛️ ${widget.user.tribe}',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: afropeepGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Location and distance
          Row(
            children: [
              if (widget.user.address != null) ...[
                const Icon(
                  Icons.location_on,
                  size: 18,
                  color: afropeepGreen,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.user.address!,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: textLightBrown,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              if (widget.user.distanceBW != null) ...[
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: afropeepGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: afropeepGreen.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${widget.user.distanceBW} miles away',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: afropeepGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Additional details
          if (widget.user.profession != null ||
              widget.user.education != null) ...[
            const SizedBox(height: 12),
            if (widget.user.profession != null) ...[
              Row(
                children: [
                  const Icon(
                    Icons.work,
                    size: 18,
                    color: textLightBrown,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.user.profession!,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: textLightBrown,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            if (widget.user.education != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.school,
                    size: 18,
                    color: textLightBrown,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.user.education!,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: textLightBrown,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      );

  Widget _buildBioSection() {
    final bio = _getBio();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "About ${widget.user.name?.split(' ').first ?? 'them'}",
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textDarkBrown,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            bio,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: textDarkBrown,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsSection() {
    final interests = _getInterests();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interests',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textDarkBrown,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: interests
              .map(
                (interest) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: afropeepGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: afropeepGreen.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    interest,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: afropeepGreen,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'More Details',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textDarkBrown,
            ),
          ),

          const SizedBox(height: 16),

          // Info cards
          if (widget.user.editInfo?['userGender'] != null)
            _buildInfoCard(
              icon: Icons.person_outline,
              label: 'Gender',
              value: widget.user.editInfo!['userGender'].toString(),
            ),

          if (widget.user.editInfo?['userHeight'] != null)
            _buildInfoCard(
              icon: Icons.height,
              label: 'Height',
              value: widget.user.editInfo!['userHeight'].toString(),
            ),

          if (widget.user.editInfo?['userEducation'] != null)
            _buildInfoCard(
              icon: Icons.school_outlined,
              label: 'Education',
              value: widget.user.editInfo!['userEducation'].toString(),
            ),

          if (widget.user.editInfo?['userOccupation'] != null)
            _buildInfoCard(
              icon: Icons.work_outline,
              label: 'Occupation',
              value: widget.user.editInfo!['userOccupation'].toString(),
            ),
        ],
      );

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: afropeepGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: afropeepGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: textLightBrown,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: textDarkBrown,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  void _showFullScreenPhoto(List<String> photos, int initialIndex) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => _FullScreenPhotoViewer(
            photos: photos,
            initialIndex: initialIndex,
          ),
        ),
      ),
    );
  }

  String _getBio() {
    // Try multiple sources for bio data
    if (widget.user.bio != null && widget.user.bio!.isNotEmpty) {
      return widget.user.bio!;
    }
    if (widget.user.editInfo?['userBio'] != null &&
        widget.user.editInfo!['userBio'].toString().isNotEmpty) {
      return widget.user.editInfo!['userBio'].toString();
    }
    return '';
  }

  List<String> _getInterests() {
    final List<String> interests = [];

    // Try to get interests from different possible fields
    if (widget.user.editInfo?['interests'] is List) {
      interests.addAll(List<String>.from(widget.user.editInfo!['interests']));
    }

    // Add cultural information as interests
    if (widget.user.nationality != null &&
        widget.user.nationality!.isNotEmpty) {
      interests.add('🇳🇬 ${widget.user.nationality}');
    }
    if (widget.user.tribe != null && widget.user.tribe!.isNotEmpty) {
      interests.add('🏛️ ${widget.user.tribe}');
    }
    if (widget.user.languages != null && widget.user.languages!.isNotEmpty) {
      interests.addAll(widget.user.languages!.map((lang) => '🗣️ $lang'));
    }
    if (widget.user.religion != null && widget.user.religion!.isNotEmpty) {
      interests.add('🙏 ${widget.user.religion}');
    }
    if (widget.user.occupation != null && widget.user.occupation!.isNotEmpty) {
      interests.add('💼 ${widget.user.occupation}');
    }

    // Add default interests if none found
    if (interests.isEmpty) {
      interests.addAll(['Dating', 'Music', 'Travel']);
    }

    return interests;
  }
}

// Full-screen photo viewer (reused from profile screen)
class _FullScreenPhotoViewer extends StatefulWidget {
  const _FullScreenPhotoViewer({
    required this.photos,
    required this.initialIndex,
  });
  final List<String> photos;
  final int initialIndex;

  @override
  State<_FullScreenPhotoViewer> createState() => _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<_FullScreenPhotoViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            '${_currentIndex + 1} of ${widget.photos.length}',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.photos.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) => InteractiveViewer(
                minScale: 0.5,
                maxScale: 3,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.photos[index],
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) => ColoredBox(
                      color: Colors.grey.shade800,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Photo unavailable',
                            style: GoogleFonts.montserrat(
                              color: Colors.grey.shade400,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.photos.length > 1)
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.photos.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: index == _currentIndex ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: index == _currentIndex
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}
