import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../common/constants/app_colors.dart';
import '../../common/routes/route_name.dart';
import '../../common/widgets/custom_3d_icons.dart';
import '../../services/region_detection_service.dart';

class CulturalProfileScreen extends StatefulWidget {
  const CulturalProfileScreen({super.key});

  @override
  State<CulturalProfileScreen> createState() => _CulturalProfileScreenState();
}

class _CulturalProfileScreenState extends State<CulturalProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  // Using centralized app colors

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _userData = doc.data();
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
          title: Text(
            'Profile',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Custom3DIcons.edit(size: 20),
                onPressed: () {
                  Navigator.pushNamed(context, RouteName.settingsScreen);
                },
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              )
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Cultural Identity Header
                      _buildCulturalIdentityHeader(),
                      const SizedBox(height: 24),

                      // Cultural Heritage Badge
                      _buildCulturalHeritageBadge(),
                      const SizedBox(height: 20),

                      // Community Involvement
                      _buildCommunityInvolvement(),
                      const SizedBox(height: 20),

                      // Professional Networking
                      _buildProfessionalNetworking(),
                      const SizedBox(height: 20),

                      // Cultural Interests & Skills
                      _buildCulturalInterests(),
                      const SizedBox(height: 20),

                      // Connection Preferences
                      _buildConnectionPreferences(),
                      const SizedBox(height: 20),

                      // Cultural Contributions
                      _buildCulturalContributions(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      );

  Widget _buildCulturalIdentityHeader() {
    final name = _userData?['name']?.toString() ?? 'Cultural Community Member';
    final photos = _userData?['photos'] as List<dynamic>? ?? [];
    final mainPhoto = photos.isNotEmpty ? photos[0] : null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Photo
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child: mainPhoto != null
                  ? Image.network(
                      mainPhoto,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => ColoredBox(
                        color: Colors.white.withValues(alpha: 0.2),
                        child: Custom3DIcons.profile(size: 60),
                      ),
                    )
                  : ColoredBox(
                      color: Colors.white.withValues(alpha: 0.2),
                      child: Custom3DIcons.profile(size: 60),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Name and Cultural Badge
          Text(
            name,
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Nationality & Tribe
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Custom3DIcons.culture(size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _getNationalityText(),
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Tribe Badge
          if (_getTribeText().isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Custom3DIcons.traditions(size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _getTribeText(),
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Verification Status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Custom3DIcons.verified(size: 20),
              const SizedBox(width: 8),
              Text(
                'Community Verified',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCulturalHeritageBadge() {
    final nationality = _getNationalityText();
    final tribe = _getTribeText();
    final languages = _userData?['languages'] as List<dynamic>? ?? ['English'];
    final locationData = _userData?['location'];
    final location = locationData is String
        ? locationData
        : locationData is Map
            ? '${locationData['city'] ?? ''}, ${locationData['country'] ?? 'Diaspora'}'
            : 'Diaspora';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Custom3DIcons.culture(),
              const SizedBox(width: 12),
              Text(
                'Nationality & Tribe',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Nationality
          _buildInfoRow(
            'Nationality',
            nationality,
            Custom3DIcons.culture(size: 20),
          ),
          const SizedBox(height: 12),

          // Tribe
          if (tribe.isNotEmpty)
            _buildInfoRow(
              'Tribe',
              tribe,
              Custom3DIcons.traditions(size: 20),
            ),
          if (tribe.isNotEmpty) const SizedBox(height: 12),

          // Languages
          _buildInfoRow(
            'Languages',
            languages.join(', '),
            Custom3DIcons.translate(size: 20),
          ),
          const SizedBox(height: 12),

          // Location
          _buildInfoRow(
            'Location',
            location,
            Custom3DIcons.location(size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityInvolvement() {
    final groupsJoined = _userData?['groupsJoined'] as List<dynamic>? ?? [];
    final eventsOrganized =
        _userData?['eventsOrganized'] as List<dynamic>? ?? [];
    final communityRole = _userData?['communityRole']?.toString() ?? 'Member';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Custom3DIcons.groups(),
              const SizedBox(width: 12),
              Text(
                'Community Involvement',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Community Role
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              communityRole,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Groups',
                  groupsJoined.length.toString(),
                  Custom3DIcons.groups(size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Events',
                  eventsOrganized.length.toString(),
                  Custom3DIcons.events(size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalNetworking() {
    final industry = _userData?['industry']?.toString() ?? 'Not specified';
    final position = _userData?['position']?.toString() ?? 'Professional';
    final skills = _userData?['skills'] as List<dynamic>? ?? [];
    final isMentor = _userData?['isMentor'] ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Custom3DIcons.business(),
              const SizedBox(width: 12),
              Text(
                'Professional Profile',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (isMentor) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Mentor',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Industry',
            industry,
            Custom3DIcons.work(size: 20),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Position',
            position,
            Custom3DIcons.skills(size: 20),
          ),
          const SizedBox(height: 12),
          if (skills.isNotEmpty) ...[
            Text(
              'Skills',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills
                  .take(5)
                  .map(
                    (skill) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primaryGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        skill.toString(),
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCulturalInterests() {
    final interests = _userData?['interests'] as List<dynamic>? ?? [];
    final culturalInterests =
        _userData?['culturalInterests'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.favorite,
                color: AppColors.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Cultural Interests',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (culturalInterests.isNotEmpty) ...[
            Text(
              'Cultural Activities',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: culturalInterests
                  .map(
                    (interest) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primaryGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        interest.toString(),
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          if (interests.isNotEmpty) ...[
            Text(
              'General Interests',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: interests
                  .take(8)
                  .map(
                    (interest) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.textSecondary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        interest.toString(),
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectionPreferences() {
    final lookingFor = _userData?['lookingFor']?.toString() ?? 'Friendship';
    final ageRangeText = _getAgeRangeText();
    final maxDistanceText = _getMaxDistanceText();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.handshake,
                color: AppColors.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Connection Preferences',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Looking For',
            lookingFor,
            Custom3DIcons.search(size: 20),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Age Range',
            ageRangeText,
            Custom3DIcons.age(size: 20),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Max Distance',
            maxDistanceText,
            Custom3DIcons.location(size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildCulturalContributions() {
    final storiesShared = _userData?['storiesShared'] as List<dynamic>? ?? [];
    final eventsCreated = _userData?['eventsCreated'] as List<dynamic>? ?? [];
    final mentorshipProvided =
        _userData?['mentorshipProvided'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Custom3DIcons.star(),
              const SizedBox(width: 12),
              Text(
                'Cultural Contributions',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Stories',
                  storiesShared.length.toString(),
                  Custom3DIcons.book(size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Events',
                  eventsCreated.length.toString(),
                  Custom3DIcons.events(size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Mentorship',
                  mentorshipProvided.length.toString(),
                  Custom3DIcons.school(size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Widget icon) => Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildStatCard(String label, String value, Widget icon) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryGreen.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            icon,
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );

  String _getNationalityText() {
    // Extract nationality from user data - using available fields
    if (_userData?['living_in']?.isNotEmpty == true) {
      // If living_in contains country info, use it
      final location = _userData!['living_in'].toString().toLowerCase();
      if (location.contains('nigeria') ||
          location.contains('lagos') ||
          location.contains('abuja')) {
        return '🇳🇬 Nigerian';
      } else if (location.contains('ghana') || location.contains('accra')) {
        return '🇬🇭 Ghanaian';
      } else if (location.contains('kenya') || location.contains('nairobi')) {
        return '🇰🇪 Kenyan';
      } else if (location.contains('south africa') ||
          location.contains('johannesburg') ||
          location.contains('cape town')) {
        return '🇿🇦 South African';
      } else if (location.contains('uk') ||
          location.contains('london') ||
          location.contains('manchester')) {
        return '🇬🇧 British-Nigerian';
      } else if (location.contains('usa') ||
          location.contains('america') ||
          location.contains('new york') ||
          location.contains('atlanta')) {
        return '🇺🇸 American-Nigerian';
      } else if (location.contains('canada') ||
          location.contains('toronto') ||
          location.contains('vancouver')) {
        return '🇨🇦 Canadian-Nigerian';
      }
    }
    return '🇳🇬 Nigerian'; // Default to Nigerian for demo
  }

  String _getTribeText() {
    // Extract tribe from user data - using available fields
    if (_userData?['profession']?.isNotEmpty == true) {
      final profession = _userData!['profession'].toString().toLowerCase();
      // Check if profession field contains tribe info
      if (profession.contains('yoruba') ||
          profession.contains('igbo') ||
          profession.contains('hausa')) {
        return profession;
      }
    }

    // Simulate tribe based on name patterns (for demo purposes)
    final name = _userData?['name']?.toString().toLowerCase() ?? '';
    if (name.contains('ade') ||
        name.contains('tunde') ||
        name.contains('kemi') ||
        name.contains('yemi')) {
      return '🏛️ Yoruba';
    } else if (name.contains('chi') ||
        name.contains('nkechi') ||
        name.contains('chukwu') ||
        name.contains('nnamdi')) {
      return '🏛️ Igbo';
    } else if (name.contains('ahmed') ||
        name.contains('fatima') ||
        name.contains('hassan') ||
        name.contains('aisha')) {
      return '🏛️ Hausa';
    }

    return '🏛️ Yoruba'; // Default tribe for demo
  }

  /// Get formatted age range text from user preferences
  String _getAgeRangeText() {
    try {
      // Check preferences.ageRange first (new format)
      if (_userData?['preferences'] != null &&
          _userData!['preferences'] is Map) {
        final preferences = _userData!['preferences'] as Map;
        if (preferences['ageRange'] != null &&
            preferences['ageRange'] is List) {
          final ageRange = preferences['ageRange'] as List;
          if (ageRange.length >= 2) {
            return '${ageRange[0]} - ${ageRange[1]} years';
          }
        }
      }

      // Check age_range field (alternative format)
      if (_userData?['age_range'] != null && _userData!['age_range'] is Map) {
        final ageRange = _userData!['age_range'] as Map;
        final min = ageRange['min']?.toString() ?? '18';
        final max = ageRange['max']?.toString() ?? '50';
        return '$min - $max years';
      }

      // Check ageRange field (direct format)
      if (_userData?['ageRange'] != null && _userData!['ageRange'] is Map) {
        final ageRange = _userData!['ageRange'] as Map;
        final min = ageRange['min']?.toString() ?? '18';
        final max = ageRange['max']?.toString() ?? '50';
        return '$min - $max years';
      }

      // Default fallback
      return '18 - 50 years';
    } catch (e) {
      return '18 - 50 years'; // Safe fallback
    }
  }

  /// Get formatted max distance text with proper unit conversion
  String _getMaxDistanceText() {
    try {
      // Get user's location data for region detection
      final locationData = _userData?['location'] as Map<String, dynamic>?;

      // Get max distance from various possible fields
      double? distanceKm;

      // Check preferences.maxDistance first
      if (_userData?['preferences'] != null &&
          _userData!['preferences'] is Map) {
        final preferences = _userData!['preferences'] as Map;
        if (preferences['maxDistance'] != null) {
          distanceKm = (preferences['maxDistance'] as num).toDouble();
        }
      }

      // Check maxDistance field directly
      if (distanceKm == null && _userData?['maxDistance'] != null) {
        distanceKm = (_userData!['maxDistance'] as num).toDouble();
      }

      // Check max_distance field
      if (distanceKm == null && _userData?['max_distance'] != null) {
        distanceKm = (_userData!['max_distance'] as num).toDouble();
      }

      // Default to 50km if no distance found
      distanceKm ??= 50.0;

      // Format distance with proper unit based on region
      return RegionDetectionService.formatDistance(distanceKm, locationData);
    } catch (e) {
      return '50 km'; // Safe fallback
    }
  }
}
