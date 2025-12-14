import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../common/routes/route_name.dart';

import 'edit_profile_screen.dart';
import 'privacy_settings_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  int _currentPhotoIndex = 0;
  final PageController _photoPageController = PageController();

  // Simplified color scheme
  static const Color backgroundColor = Colors.white;
  static const Color primaryColor = Color(0xFF008037);
  static const Color cardColor = Color(0xFFFFFBF5);
  static final Color textPrimary = Colors.brown.shade800;
  static final Color textSecondary = Colors.brown.shade600;

  StreamSubscription<DocumentSnapshot>? _userDataSubscription;

  @override
  void initState() {
    super.initState();
    _listenToUserData();
  }

  @override
  void dispose() {
    _photoPageController.dispose();
    _userDataSubscription?.cancel();
    super.dispose();
  }

  // Listen to Firestore changes for automatic updates (e.g., after photo upload)
  void _listenToUserData() {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        _userDataSubscription =
            _firestore.collection('users').doc(user.uid).snapshots().listen(
          (docSnapshot) {
            if (docSnapshot.exists) {
              setState(() {
                _userData = docSnapshot.data();
                _isLoading = false;
              });
            } else {
              setState(() => _isLoading = false);
            }
          },
          onError: (error) {
            log('❌ Error listening to user data: $error');
            setState(() => _isLoading = false);
          },
        );
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      log('❌ Error setting up user data listener: $e');
      setState(() => _isLoading = false);
    }
  }

  // Legacy method kept for compatibility (not used if _listenToUserData is active)
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
      log('❌ Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Profile',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: textPrimary),
            color: cardColor,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              switch (value) {
                case 'events':
                  Navigator.pushNamed(context, RouteName.eventsScreen);
                  break;
                case 'privacy':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrivacySettingsScreen(),
                    ),
                  );
                  break;
                case 'settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'events',
                child: Row(
                  children: [
                    Icon(Icons.event, color: primaryColor),
                    SizedBox(width: 12),
                    Text('Events'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'privacy',
                child: Row(
                  children: [
                    Icon(Icons.privacy_tip_outlined, color: primaryColor),
                    SizedBox(width: 12),
                    Text('Privacy Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, color: primaryColor),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SafeArea(
              child: SingleChildScrollView(
                // Remove padding for seamless Hinge-style layout
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hinge-style large photo section (full width, no padding)
                    _buildHingePhotoSection(),
                    
                    // Profile header (name, age, location) - integrated with photos
                    _buildHingeProfileHeader(),
                    
                    // About section - seamless
                    _buildHingeAboutSection(),
                    
                    // Details section - seamless
                    _buildHingeDetailsSection(),
                    
                    // Interests section - seamless
                    _buildHingeInterestsSection(),
                    
                    // Edit button with padding
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: _buildEditButton(),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );

  Widget _buildSimplifiedPhotoSection() {
    // Try multiple field names for compatibility
    final photos = _userData?['photos'] as List<dynamic>? ??
        _userData?['Pictures'] as List<dynamic>? ??
        _userData?['imageUrl'] as List<dynamic>? ??
        [];

    if (photos.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryColor.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              size: 48,
              color: primaryColor.withOpacity(0.6),
            ),
            const SizedBox(height: 8),
            Text(
              'Add Photos',
              style: GoogleFonts.montserrat(
                color: textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          // Main photo
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
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey.shade100, // Background for images that don't fill container
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      photos[index],
                      fit: BoxFit.contain, // Show full image without cropping
                      errorBuilder: (context, error, stackTrace) => ColoredBox(
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 60,
                            color: Colors.grey.shade400,
                          ),
                        ),
                    ),
                  ),
                ),
              ),
          ),

          // Photo counter
          if (photos.length > 1)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentPhotoIndex + 1}/${photos.length}',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // Navigation arrows
          if (photos.length > 1) ...[
            Positioned(
              left: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_currentPhotoIndex > 0) {
                      _photoPageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_currentPhotoIndex < photos.length - 1) {
                      _photoPageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSimplifiedBasicInfo() {
    final name = _userData?['name'] ?? 'Your Name';
    final age = _userData?['age'] ?? _calculateAge(_userData?['dateOfBirth']);
    final gender = _userData?['gender'] ?? 'Not specified';

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
              name,
              style: GoogleFonts.montserrat(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.cake_outlined,
                  label: age != null ? '$age years old' : 'Age not set',
                ),
                const SizedBox(width: 12),
                _buildInfoChip(
                  icon: Icons.person_outline,
                  label: gender,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimplifiedAbout() {
    final bio = _userData?['bio'] ?? '';

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
              'About Me',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              bio.isEmpty ? 'Tell others about yourself...' : bio,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: bio.isEmpty ? textSecondary : textPrimary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimplifiedInterests() {
    final interests = _userData?['interests'] as List<dynamic>? ?? [];

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
                const Icon(
                  Icons.favorite_outline,
                  color: primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Interests',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (interests.isEmpty)
              Text(
                'No interests added yet',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: interests.take(6).map((interest) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      interest.toString(),
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: primaryColor,
                      ),
                    ),
                  ),).toList(),
              ),
            if (interests.length > 6)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+${interests.length - 6} more',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimplifiedLocation() {
    // Handle both String and Map types for location and nationality
    String location = '';
    String nationality = '';

    if (_userData?['location'] != null) {
      if (_userData!['location'] is String) {
        location = _userData!['location'] as String;
      } else if (_userData!['location'] is Map) {
        location = _userData!['location']['name'] ??
            _userData!['location']['city'] ??
            '';
      }
    }

    if (_userData?['nationality'] != null) {
      if (_userData!['nationality'] is String) {
        nationality = _userData!['nationality'] as String;
      } else if (_userData!['nationality'] is Map) {
        nationality = _userData!['nationality']['name'] ??
            _userData!['nationality']['country'] ??
            '';
      }
    }

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
                const Icon(
                  Icons.location_on_outlined,
                  color: primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Location',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (location.isNotEmpty)
              _buildLocationRow(Icons.location_on, 'Location', location),
            if (nationality.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildLocationRow(Icons.public, 'Nationality', nationality),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String label, String value) => Row(
      children: [
        Icon(
          icon,
          color: textSecondary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '$label: $value',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: textPrimary,
            ),
          ),
        ),
      ],
    );

  Widget _buildInfoChip({required IconData icon, required String label}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: primaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

  Widget _buildEditButton() => SizedBox(
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
            const Icon(Icons.edit_outlined, size: 20),
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
    );

  int? _calculateAge(String? dobString) {
    if (dobString == null) return null;

    try {
      final dob = DateTime.parse(dobString);
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return null;
    }
  }

  // Hinge-style photo section - large, full-width
  Widget _buildHingePhotoSection() {
    final photos = _userData?['photos'] as List<dynamic>? ??
        _userData?['Pictures'] as List<dynamic>? ??
        _userData?['imageUrl'] as List<dynamic>? ??
        [];

    if (photos.isEmpty) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.6,
        color: cardColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo_outlined,
                size: 48,
                color: primaryColor.withOpacity(0.6),
              ),
              const SizedBox(height: 8),
              Text(
                'Add Photos',
                style: GoogleFonts.montserrat(
                  color: textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: PageView.builder(
        controller: _photoPageController,
        itemCount: photos.length,
        onPageChanged: (index) {
          setState(() {
            _currentPhotoIndex = index;
          });
        },
        itemBuilder: (context, index) => GestureDetector(
          onTap: () => _showFullScreenPhoto(photos, index),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                photos[index].toString(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => ColoredBox(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image_outlined, size: 60),
                ),
              ),
              // Photo indicator dots at bottom
              if (photos.length > 1)
                Positioned(
                  bottom: 20,
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

  // Hinge-style profile header
  Widget _buildHingeProfileHeader() {
    final name = _userData?['name'] ?? 'Your Name';
    final age = _userData?['age'] ?? _calculateAge(_userData?['dateOfBirth']);
    final nationality = _userData?['nationality']?.toString() ?? '';
    
    String location = '';
    if (_userData?['location'] != null) {
      if (_userData!['location'] is String) {
        location = _userData!['location'] as String;
      } else if (_userData!['location'] is Map) {
        location = _userData!['location']?['name']?.toString() ?? '';
      }
    }
    if (location.isEmpty && _userData?['living_in'] != null) {
      location = _userData!['living_in'].toString();
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
              color: textPrimary,
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flag, size: 16, color: primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          nationality,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (location.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, size: 16, color: primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          location,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
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

  // Hinge-style about section
  Widget _buildHingeAboutSection() {
    final bio = _userData?['bio']?.toString() ?? '';
    if (bio.isEmpty) return const SizedBox.shrink();

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
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            bio,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Hinge-style details section
  Widget _buildHingeDetailsSection() {
    final details = <Map<String, dynamic>>[];

    // Helper to safely get value from root or editInfo
    String? getValue(String key) {
      final rootValue = _userData?[key];
      if (rootValue != null && rootValue.toString().isNotEmpty) {
        return rootValue.toString();
      }
      final editInfoValue = _userData?['editInfo']?[key];
      if (editInfoValue != null && editInfoValue.toString().isNotEmpty) {
        return editInfoValue.toString();
      }
      return null;
    }

    // Education - graduation cap icon (like Hinge)
    final education = getValue('education');
    if (education != null) {
      details.add({'icon': Icons.school, 'label': '', 'value': education});
    }

    // Work/Job - briefcase icon (like Hinge)
    final workTitle = getValue('job_title') ?? 
                     getValue('profession') ?? 
                     getValue('occupation');
    if (workTitle != null) {
      details.add({'icon': Icons.business_center, 'label': '', 'value': workTitle});
    }

    // Religion - book icon (like Hinge)
    final religion = getValue('religion');
    if (religion != null) {
      details.add({'icon': Icons.menu_book, 'label': '', 'value': religion});
    }

    // Relationship Intent (Relationship goals) - search icon (like Hinge)
    final relationshipIntent = getValue('relationshipIntent') ??
                              _userData?['preferences']?['relationshipIntent']?.toString();
    if (relationshipIntent != null && relationshipIntent.isNotEmpty) {
      details.add({'icon': Icons.search, 'label': '', 'value': relationshipIntent});
    }

    // Tribe - group icon
    final tribe = getValue('tribe');
    if (tribe != null) {
      details.add({'icon': Icons.group, 'label': '', 'value': tribe});
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
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          // Hinge-style details: just icon and value, no label
          ...details.map((detail) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      detail['icon'] as IconData,
                      size: 20,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        detail['value'] as String,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: textPrimary,
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

  // Hinge-style interests section
  Widget _buildHingeInterestsSection() {
    final interests = _userData?['interests'] as List<dynamic>? ?? [];
    if (interests.isEmpty) return const SizedBox.shrink();

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
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: interests.map((interest) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    interest.toString(),
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: primaryColor,
                    ),
                  ),
                )).toList(),
          ),
          const SizedBox(height: 24),
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
}

// Simplified full-screen photo viewer
class _FullScreenPhotoViewer extends StatefulWidget {

  const _FullScreenPhotoViewer({
    required this.photos,
    required this.initialIndex,
  });
  final List<dynamic> photos;
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
      body: PageView.builder(
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
              child: Image.network(
                widget.photos[index],
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => ColoredBox(
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
    );
}
