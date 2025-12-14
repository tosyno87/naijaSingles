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
    final photos = (widget.user.imageUrl ?? []) as List<String>;
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
          // Photo carousel section - horizontal swipeable
          if (photos.isNotEmpty) _buildPhotoSection(photos),

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
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            image: DecorationImage(
              image: NetworkImage(photos[index]),
              fit: BoxFit.cover,
              onError: (exception, stackTrace) {
                // Handle error
              },
            ),
          ),
          child: Stack(
            children: [
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
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "${widget.user.name ?? 'Unknown'}, ${widget.user.age ?? 'N/A'}",
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (widget.user.nationality != null || widget.user.living_in != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (widget.user.nationality != null)
                  _buildInfoChip(widget.user.nationality!, Icons.flag),
                if (widget.user.living_in != null)
                  _buildInfoChip(widget.user.living_in!, Icons.location_on),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryGreen),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
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

    if (widget.user.education != null && widget.user.education!.isNotEmpty) {
      details.add({'icon': Icons.school, 'label': 'Education', 'value': widget.user.education!});
    }
    if (widget.user.job_title != null && widget.user.job_title!.isNotEmpty) {
      details.add({'icon': Icons.work, 'label': 'Work', 'value': widget.user.job_title!});
    }
    if (widget.user.religion != null && widget.user.religion!.isNotEmpty) {
      details.add({'icon': Icons.favorite, 'label': 'Religion', 'value': widget.user.religion!});
    }
    if (widget.user.tribe != null && widget.user.tribe!.isNotEmpty) {
      details.add({'icon': Icons.group, 'label': 'Tribe', 'value': widget.user.tribe!});
    }

    if (details.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...details.map((detail) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      detail['icon'] as IconData,
                      size: 20,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail['label'] as String,
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            detail['value'] as String,
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
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
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Pass button
          Expanded(
            child: OutlinedButton(
              onPressed: widget.onPass,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: AppColors.primaryGreen,
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Pass',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Connect button
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: widget.onConnect,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Connect',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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

