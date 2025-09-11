import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../common/widgets/custom_3d_icons.dart';

class CulturalProfileScreen extends StatefulWidget {
  const CulturalProfileScreen({Key? key}) : super(key: key);

  @override
  State<CulturalProfileScreen> createState() => _CulturalProfileScreenState();
}

class _CulturalProfileScreenState extends State<CulturalProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  // Modern Afrocentric color scheme
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color primaryColor = Color(0xFF008037);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color gradientStart = Color(0xFF008037);
  static const Color gradientEnd = Color(0xFF059669);

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [gradientStart, gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'Cultural Profile',
          style: GoogleFonts.poppins(
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
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Custom3DIcons.edit(size: 20),
              onPressed: () {
                // Navigate to edit cultural profile
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
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
  }

  Widget _buildCulturalIdentityHeader() {
    final name = _userData?['name']?.toString() ?? 'Cultural Community Member';
    final photos = _userData?['photos'] as List<dynamic>? ?? [];
    final mainPhoto = photos.isNotEmpty ? photos[0] : null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradientStart, gradientEnd],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
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
                  color: Colors.black.withOpacity(0.2),
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
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.white.withOpacity(0.2),
                          child: Custom3DIcons.profile(size: 60),
                        );
                      },
                    )
                  : Container(
                      color: Colors.white.withOpacity(0.2),
                      child: Custom3DIcons.profile(size: 60),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Name and Cultural Badge
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Cultural Heritage
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Custom3DIcons.culturalHeritage(size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _userData?['culturalHeritage']?.toString() ?? 'Cultural Community Member',
                    style: GoogleFonts.poppins(
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
          const SizedBox(height: 12),

          // Verification Status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Custom3DIcons.verified(size: 20),
              const SizedBox(width: 8),
              Text(
                'Community Verified',
                style: GoogleFonts.poppins(
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
    final heritage = _userData?['culturalHeritage']?.toString() ?? 'Mixed Heritage';
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
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Custom3DIcons.celebration(size: 24),
              const SizedBox(width: 12),
              Text(
                'Cultural Identity',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Heritage
          _buildInfoRow(
            'Heritage',
            heritage,
            Custom3DIcons.traditions(size: 20),
          ),
          const SizedBox(height: 12),

          // Languages
          _buildInfoRow(
            'Languages',
            languages.join(', '),
            Custom3DIcons.language(size: 20),
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
    final eventsOrganized = _userData?['eventsOrganized'] as List<dynamic>? ?? [];
    final communityRole = _userData?['communityRole']?.toString() ?? 'Member';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Custom3DIcons.groups(size: 24),
              const SizedBox(width: 12),
              Text(
                'Community Involvement',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Community Role
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              communityRole,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primaryColor,
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
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Custom3DIcons.business(size: 24),
              const SizedBox(width: 12),
              Text(
                'Professional Profile',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              if (isMentor) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Mentor',
                    style: GoogleFonts.poppins(
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
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.take(5).map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    skill.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: primaryColor,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCulturalInterests() {
    final interests = _userData?['interests'] as List<dynamic>? ?? [];
    final culturalInterests = _userData?['culturalInterests'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Icon(
                Icons.favorite,
                color: primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Cultural Interests',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (culturalInterests.isNotEmpty) ...[
            Text(
              'Cultural Activities',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: culturalInterests.map((interest) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    interest.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: primaryColor,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          if (interests.isNotEmpty) ...[
            Text(
              'General Interests',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: interests.take(8).map((interest) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: textSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: textSecondary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    interest.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectionPreferences() {
    final lookingFor = _userData?['lookingFor']?.toString() ?? 'Friendship';
    final ageRange = _userData?['ageRange']?.toString() ?? '18-35';
    final maxDistance = _userData?['maxDistance']?.toString() ?? '50km';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Icon(
                Icons.handshake,
                color: primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Connection Preferences',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
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
            ageRange,
            Custom3DIcons.age(size: 20),
          ),
          const SizedBox(height: 12),

          _buildInfoRow(
            'Max Distance',
            maxDistance,
            Custom3DIcons.location(size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildCulturalContributions() {
    final storiesShared = _userData?['storiesShared'] as List<dynamic>? ?? [];
    final eventsCreated = _userData?['eventsCreated'] as List<dynamic>? ?? [];
    final mentorshipProvided = _userData?['mentorshipProvided'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Custom3DIcons.star(size: 24),
              const SizedBox(width: 12),
              Text(
                'Cultural Contributions',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
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

  Widget _buildInfoRow(String label, String value, Widget icon) {
    return Row(
      children: [
        icon,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Widget icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          icon,
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
