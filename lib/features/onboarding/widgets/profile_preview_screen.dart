import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/constants/app_colors.dart';
import '../../../services/profile_sharing_service.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_data.dart';

class ProfilePreviewScreen extends StatefulWidget {
  const ProfilePreviewScreen({super.key});

  @override
  State<ProfilePreviewScreen> createState() => _ProfilePreviewScreenState();
}

class _ProfilePreviewScreenState extends State<ProfilePreviewScreen> {
  // Theme colors
  static const Color afropeepGreen = Color(0xFF008037); // MVP green
  static const Color cardBackground = Color(0xFFF7E8DA);
  static const Color textDarkBrown = Color(0xFF3A1D0F);
  static const Color textLightBrown = Color(0xFF8B6C59);
  static const Color goldAccent = Color(0xFFFFD700);

  final PageController _pageController = PageController();
  int _currentPhotoIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: afropeepGreen),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Profile Preview',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: afropeepGreen,
            ),
          ),
          centerTitle: true,
          actions: [
            TextButton.icon(
              onPressed: _showImprovementSuggestions,
              icon: const Icon(
                Icons.tips_and_updates,
                color: afropeepGreen,
                size: 18,
              ),
              label: Text(
                'Tips',
                style: GoogleFonts.montserrat(
                  color: afropeepGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        body: BlocBuilder<OnboardingBloc, OnboardingState>(
          builder: (context, state) {
            final data = state.data;
            if (data == null) return _buildNoPhotosState();

            final photos = data.profilePhotos
                .where((p) => p != null)
                .cast<File>()
                .toList();

            if (photos.isEmpty) {
              return _buildNoPhotosState();
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildPhotoCarousel(photos),
                  const SizedBox(height: 20),
                  _buildProfileCard(data),
                  const SizedBox(height: 20),
                  _buildMatchPotentialCard(data),
                  const SizedBox(height: 20),
                  _buildQuickImprovements(data),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: _buildBottomActions(),
      );

  Widget _buildPhotoCarousel(List<File> photos) => Container(
        height: 500,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Photo PageView
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPhotoIndex = index;
                });
              },
              itemCount: photos.length,
              itemBuilder: (context, index) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: FileImage(photos[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // Photo indicators
            if (photos.length > 1)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Row(
                  children: photos
                      .asMap()
                      .entries
                      .map(
                        (entry) => Expanded(
                          child: Container(
                            height: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: entry.key == _currentPhotoIndex
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),

            // Primary photo badge
            if (_currentPhotoIndex == 0)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: goldAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Main Photo',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Navigation arrows
            if (photos.length > 1) ...[
              if (_currentPhotoIndex > 0)
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              if (_currentPhotoIndex < photos.length - 1)
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      );

  Widget _buildProfileCard(OnboardingData data) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name and age
            Row(
              children: [
                Text(
                  '${data.fullName}, ${data.age}',
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: textDarkBrown,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: afropeepGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    data.tribe,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: afropeepGreen,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Bio
            if (data.bio.isNotEmpty)
              Text(
                data.bio,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: textLightBrown,
                  height: 1.4,
                ),
              ),

            const SizedBox(height: 16),

            // Interests
            if (data.interests.isNotEmpty) ...[
              Text(
                'Interests',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textDarkBrown,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: data.interests
                    .take(6)
                    .map(
                      (interest) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: cardBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: afropeepGreen.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          interest,
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: textDarkBrown,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              if (data.interests.length > 6)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '+${data.interests.length - 6} more interests',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: textLightBrown,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ],
        ),
      );

  Widget _buildMatchPotentialCard(OnboardingData data) {
    final photos = data.profilePhotos.where((p) => p != null).length;
    final hasGoodBio = data.bio.length >= 50;
    final hasInterests = data.interests.length >= 5;

    int score = 0;
    if (photos >= 3) score += 40;
    if (photos >= 5) score += 10;
    if (hasGoodBio) score += 30;
    if (hasInterests) score += 20;

    Color scoreColor;
    String scoreLabel;
    IconData scoreIcon;

    if (score >= 80) {
      scoreColor = Colors.green;
      scoreLabel = 'Excellent';
      scoreIcon = Icons.star;
    } else if (score >= 60) {
      scoreColor = Colors.orange;
      scoreLabel = 'Good';
      scoreIcon = Icons.thumb_up;
    } else {
      scoreColor = Colors.red;
      scoreLabel = 'Needs Work';
      scoreIcon = Icons.warning;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scoreColor.withValues(alpha: 0.1),
            scoreColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scoreColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(scoreIcon, color: scoreColor, size: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Match Potential',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textDarkBrown,
                    ),
                  ),
                  Text(
                    '$scoreLabel ($score/100)',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: scoreColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              CircularProgressIndicator(
                value: score / 100,
                backgroundColor: scoreColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                strokeWidth: 6,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildScoreItem('Photos', photos, 5, photos >= 3),
              _buildScoreItem('Bio', hasGoodBio ? 1 : 0, 1, hasGoodBio),
              _buildScoreItem(
                'Interests',
                hasInterests ? 1 : 0,
                1,
                hasInterests,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, int current, int total, bool isGood) =>
      Expanded(
        child: Column(
          children: [
            Icon(
              isGood ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isGood ? Colors.green : Colors.grey,
              size: 16,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 10,
                color: textLightBrown,
              ),
            ),
            Text(
              '$current/$total',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isGood ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
      );

  Widget _buildQuickImprovements(OnboardingData data) {
    final List<String> improvements = [];

    final photos = data.profilePhotos.where((p) => p != null).length;
    if (photos < 5) improvements.add('Add ${5 - photos} more photos');
    if (data.bio.length < 50) improvements.add('Write a longer bio');
    if (data.interests.length < 5) improvements.add('Add more interests');

    if (improvements.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.green.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.green, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Your profile looks great! You're ready to start matching.",
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Quick Improvements',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textDarkBrown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...improvements.map(
            (improvement) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.arrow_right, color: Colors.blue, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    improvement,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.blue.shade700,
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

  Widget _buildNoPhotosState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.photo_camera_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No Photos to Preview',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textDarkBrown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some photos to see how your profile will look',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: textLightBrown,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildBottomActions() => Container(
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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: afropeepGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Back to Editing',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: afropeepGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _shareProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: afropeepGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Share Preview',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  void _showImprovementSuggestions() {
    unawaited(
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile Improvement Tips',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: textDarkBrown,
                ),
              ),
              const SizedBox(height: 16),
              _buildTipItem(
                Icons.photo_camera,
                'Photo Variety',
                'Include different types of photos: close-up, full-body, activity, and social photos.',
                Colors.blue,
              ),
              _buildTipItem(
                Icons.edit,
                'Compelling Bio',
                'Write 50-200 characters that show your personality and give conversation starters.',
                Colors.green,
              ),
              _buildTipItem(
                Icons.favorite,
                'Diverse Interests',
                'Select 5-10 interests that represent different aspects of your personality.',
                Colors.purple,
              ),
              _buildTipItem(
                Icons.star,
                'Main Photo',
                'Your first photo should be a clear, smiling face shot with good lighting.',
                goldAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem(
    IconData icon,
    String title,
    String description,
    Color color,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textDarkBrown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: textLightBrown,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  void _shareProfile() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final data = context.read<OnboardingBloc>().state.data;
    final name =
        (data?.fullName.isNotEmpty ?? false) ? data!.fullName : 'My profile';
    unawaited(
      ProfileSharingService().shareProfile(
        userId: userId,
        displayName: name,
      ),
    );
  }
}
