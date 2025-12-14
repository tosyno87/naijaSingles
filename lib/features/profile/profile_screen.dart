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
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  int _currentPhotoIndex = 0;
  PageController _photoPageController = PageController();

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
  Widget build(BuildContext context) {
    return Scaffold(
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
              PopupMenuItem(
                value: 'events',
                child: Row(
                  children: [
                    Icon(Icons.event, color: primaryColor),
                    const SizedBox(width: 12),
                    Text('Events'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'privacy',
                child: Row(
                  children: [
                    Icon(Icons.privacy_tip_outlined, color: primaryColor),
                    const SizedBox(width: 12),
                    Text('Privacy Settings'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, color: primaryColor),
                    const SizedBox(width: 12),
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
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Simplified Photo Section
                    _buildSimplifiedPhotoSection(),
                    const SizedBox(height: 24),

                    // Simplified Basic Info
                    _buildSimplifiedBasicInfo(),
                    const SizedBox(height: 16),

                    // Simplified About Section
                    _buildSimplifiedAbout(),
                    const SizedBox(height: 16),

                    // Simplified Interests
                    _buildSimplifiedInterests(),
                    const SizedBox(height: 16),

                    // Simplified Location (includes nationality)
                    _buildSimplifiedLocation(),
                    const SizedBox(height: 32),

                    // Single Edit Button
                    _buildEditButton(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

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

    return Container(
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
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showFullScreenPhoto(photos, index),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
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
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 60,
                            color: Colors.grey.shade400,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
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
                    child: Icon(
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
                    child: Icon(
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
                Icon(
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
                children: interests.take(6).map((interest) {
                  return Container(
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
                  );
                }).toList(),
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
                Icon(
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

  Widget _buildLocationRow(IconData icon, String label, String value) {
    return Row(
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
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
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
  }

  Widget _buildEditButton() {
    return SizedBox(
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
    );
  }

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
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 3.0,
            child: Center(
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
                          'Photo unavailable',
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
    );
  }
}
