import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'edit_profile_screen.dart';
import 'privacy_settings_screen.dart';
import 'settings_screen.dart';
import '../../../services/profile_verification_service.dart';
import '../../../services/content_moderation_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ProfileVerificationService _verificationService =
      ProfileVerificationService();
  final ContentModerationService _moderationService =
      ContentModerationService();

  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  VerificationStatus? _verificationStatus;

  // Afrocentric color scheme
  static const Color backgroundColor = Colors.white; // Clean white
  static const Color primaryColor = Color(0xFF008037); // Deep green
  static const Color cardColor = Color(0xFFFFFBF5); // Light cream for cards
  static final Color textPrimary = Colors.brown.shade800;
  static final Color textSecondary = Colors.brown.shade600;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        print('🔍 Loading user profile data for: ${user.uid}');
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          print('✅ User data loaded successfully');
          print('   Available fields: ${data?.keys.toList()}');
          print('   Name: ${data?['name']}');
          print('   Interests: ${data?['interests']}');
          print(
              '   Height: ${data?['heightDisplay'] ?? data?['height_ft_in']}');
          print('   Looking for: ${data?['lookingFor']}');
          print('   Bio length: ${(data?['bio'] ?? '').length} characters');
          print('   Photos field: ${data?['photos']}');
          print('   ImageUrl field: ${data?['imageUrl']}');
          print('   Profile photos: ${data?['profilePhotos']}');

          // Load verification status
          final verificationStatus =
              await _verificationService.getUserVerificationStatus(user.uid);

          setState(() {
            _userData = data;
            _verificationStatus = verificationStatus;
            _isLoading = false;
          });
        } else {
          print('❌ No user document found');
          setState(() => _isLoading = false);
        }
      } else {
        print('❌ No authenticated user');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'Profile',
          style: GoogleFonts.montserrat(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: textPrimary),
            onSelected: (value) {
              switch (value) {
                case 'privacy':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacySettingsScreen(),
                    ),
                  );
                  break;
                case 'settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'privacy',
                height: 56,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: textPrimary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.privacy_tip_outlined,
                          color: textPrimary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Privacy Settings',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              'Control who can see your profile',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                height: 56,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: textPrimary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.settings_outlined,
                          color: textPrimary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Settings',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              'App preferences and account',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildPhotoSection(),
                  const SizedBox(height: 24),
                  _buildBasicInfoCard(),
                  const SizedBox(height: 16),
                  _buildProfileActionButtons(),
                  const SizedBox(height: 16),
                  _buildVerificationSection(),
                  const SizedBox(height: 16),
                  _buildAboutSection(),
                  const SizedBox(height: 16),
                  _buildInterestsSection(),
                  const SizedBox(height: 16),
                  _buildLookingForSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildPhotoSection() {
    // Try multiple possible photo field names
    List<dynamic> photos = [];

    // Check different possible field names for photos
    if (_userData?['photos'] != null) {
      photos = List<dynamic>.from(_userData!['photos']);
    } else if (_userData?['imageUrl'] != null) {
      if (_userData!['imageUrl'] is List) {
        photos = List<dynamic>.from(_userData!['imageUrl']);
      } else {
        photos = [_userData!['imageUrl']];
      }
    } else if (_userData?['profilePhotos'] != null) {
      photos = List<dynamic>.from(_userData!['profilePhotos']);
    }

    // Filter out null/empty photos
    photos = photos
        .where((photo) => photo != null && photo.toString().isNotEmpty)
        .toList();

    print('📸 Found ${photos.length} photos: $photos');

    if (photos.isEmpty) {
      return _buildEmptyPhotoPlaceholder();
    }

    return _buildInstagramStylePhotoGrid(photos);
  }

  Widget _buildInstagramStylePhotoGrid(List<dynamic> photos) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo count header
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Photos (${photos.length})',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ),

          // Instagram-style grid
          Container(
            height: 300,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 1,
              ),
              itemCount:
                  photos.length > 6 ? 6 : photos.length, // Show max 6 photos
              itemBuilder: (context, index) {
                if (index == 0 && photos.length > 1) {
                  // First photo takes up 2x2 space (spans 2 columns and 2 rows)
                  return GestureDetector(
                    onTap: () => _showFullScreenPhoto(photos, index),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              photos[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.broken_image_outlined,
                                        size: 40,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Failed to load',
                                        style: GoogleFonts.montserrat(
                                          color: Colors.grey.shade600,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            // Photo number indicator
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                } else {
                  // Regular 1x1 photos
                  return GestureDetector(
                    onTap: () => _showFullScreenPhoto(photos, index),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              photos[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.broken_image_outlined,
                                        size: 24,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Failed',
                                        style: GoogleFonts.montserrat(
                                          color: Colors.grey.shade600,
                                          fontSize: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            // Photo number indicator
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
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
              },
            ),
          ),

          // Show more photos indicator
          if (photos.length > 6)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  '+${photos.length - 6} more photos',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Full screen photo viewer
  void _showFullScreenPhoto(List<dynamic> photos, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenPhotoViewer(
          photos: photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _buildEmptyPhotoPlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo_outlined,
            size: 48,
            color: primaryColor.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 8),
          Text(
            'Add Photos',
            style: GoogleFonts.montserrat(
              color: textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap to add your photos',
            style: GoogleFonts.montserrat(
              color: textSecondary.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Card(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _userData?['name'] ?? 'No name',
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ),
                // Verification Badge
                if (_verificationStatus != null)
                  _buildVerificationBadge(_verificationStatus!),
              ],
            ),
            const SizedBox(height: 8),
            if (_userData?['age'] != null)
              Text(
                '${_userData!['age']} years old',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: textSecondary,
                ),
              ),
            const SizedBox(height: 4),
            if (_userData?['heightDisplay'] != null ||
                _userData?['height_ft_in'] != null)
              Text(
                _userData?['heightDisplay'] ?? _userData?['height_ft_in'] ?? '',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationBadge(VerificationStatus status) {
    final badge = _verificationService.getVerificationBadge(status);
    final text = _verificationService.getVerificationStatusText(status);

    Color badgeColor;
    switch (status) {
      case VerificationStatus.verified:
        badgeColor = Colors.green;
        break;
      case VerificationStatus.pending:
        badgeColor = Colors.orange;
        break;
      case VerificationStatus.rejected:
        badgeColor = Colors.red;
        break;
      case VerificationStatus.unverified:
        badgeColor = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(badge, style: TextStyle(color: badgeColor, fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: badgeColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileActionButtons() {
    return Column(
      children: [
        // Edit Profile Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EditProfileScreen(),
                ),
              );

              // Reload data if profile was updated
              if (result == true) {
                _loadUserData();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_outlined, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Edit Profile',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Report Profile Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _showReportDialog,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: Icon(Icons.flag_outlined, size: 18),
            label: Text(
              'Report Profile',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Profile'),
        content: const Text('Why are you reporting this profile?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _reportProfile();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  Future<void> _reportProfile() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId != null) {
        await _moderationService.reportContent(
          contentId: currentUserId,
          contentType: 'profile',
          reporterId: currentUserId,
          reason: 'Inappropriate profile content',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile reported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error reporting profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildVerificationSection() {
    return Card(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified_user, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Profile Verification',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Current verification status
            if (_verificationStatus != null) ...[
              Row(
                children: [
                  _buildVerificationBadge(_verificationStatus!),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Current Status: ${_verificationService.getVerificationStatusText(_verificationStatus!)}',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Verification types
            Text(
              'Available Verifications:',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Verification buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: VerificationType.values.map((type) {
                return _buildVerificationButton(type);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationButton(VerificationType type) {
    return ElevatedButton.icon(
      onPressed: () => _requestVerification(type),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor.withOpacity(0.1),
        foregroundColor: primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      icon: Icon(_getVerificationIcon(type), size: 16),
      label: Text(
        type.toString().split('.').last.toUpperCase(),
        style: GoogleFonts.montserrat(fontSize: 12),
      ),
    );
  }

  IconData _getVerificationIcon(VerificationType type) {
    switch (type) {
      case VerificationType.email:
        return Icons.email;
      case VerificationType.phone:
        return Icons.phone;
      case VerificationType.photo:
        return Icons.photo_camera;
      case VerificationType.identity:
        return Icons.badge;
      case VerificationType.employment:
        return Icons.work;
    }
  }

  Future<void> _requestVerification(VerificationType type) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId != null) {
        final result = await _verificationService.requestVerification(
          userId: currentUserId,
          type: type,
          verificationData: _getVerificationData(type),
        );

        if (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${type.toString().split('.').last.toUpperCase()} verification requested'),
              backgroundColor: Colors.green,
            ),
          );
          _loadUserData(); // Refresh verification status
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to request verification'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error requesting verification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Map<String, dynamic> _getVerificationData(VerificationType type) {
    switch (type) {
      case VerificationType.email:
        return {'email': _auth.currentUser?.email ?? ''};
      case VerificationType.phone:
        return {'phone': _userData?['phone'] ?? ''};
      case VerificationType.photo:
        return {
          'photos': ['photo1.jpg', 'photo2.jpg'],
          'selfie': 'selfie.jpg'
        };
      case VerificationType.identity:
        return {
          'idType': 'passport',
          'idNumber': 'A1234567',
          'idPhoto': 'id.jpg'
        };
      case VerificationType.employment:
        return {
          'company': 'Tech Company',
          'position': 'Developer',
          'email': 'work@company.com'
        };
    }
  }

  Widget _buildAboutSection() {
    return Card(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _userData?['bio'] ?? 'No bio available',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestsSection() {
    final interests = _userData?['interests'] as List<dynamic>? ?? [];

    if (interests.isEmpty) return const SizedBox.shrink();

    return Card(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interests',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: interests.map((interest) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    interest.toString(),
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLookingForSection() {
    final lookingFor = _userData?['lookingFor'];

    if (lookingFor == null) return const SizedBox.shrink();

    return Card(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Looking For',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              lookingFor.toString(),
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Full-screen photo viewer widget
class _FullScreenPhotoViewer extends StatefulWidget {
  final List<dynamic> photos;
  final int initialIndex;

  const _FullScreenPhotoViewer({
    required this.photos,
    required this.initialIndex,
  });

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_currentIndex + 1} of ${widget.photos.length}',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Full screen photo viewer
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  child: Image.network(
                    widget.photos[index],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
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
                              'Failed to load image',
                              style: GoogleFonts.montserrat(
                                color: Colors.grey.shade400,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // Page indicators
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
                          : Colors.white.withOpacity(0.3),
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
}
