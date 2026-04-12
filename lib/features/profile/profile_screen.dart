import 'dart:async';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../common/constants/app_colors.dart';
import '../../common/routes/route_name.dart';
import '../../common/utils/country_flag.dart';
import '../../common/widgets/state_views/state_views.dart';

import 'edit_profile_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.auth, this.firestore});

  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final FirebaseAuth _auth = widget.auth ?? FirebaseAuth.instance;
  late final FirebaseFirestore _firestore =
      widget.firestore ?? FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  int _currentPhotoIndex = 0;
  final PageController _photoPageController = PageController();

  // Simplified color scheme
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
    unawaited(_userDataSubscription?.cancel());
    super.dispose();
  }

  // Listen to Firestore changes for automatic updates (e.g., after photo upload)
  void _listenToUserData() {
    try {
      unawaited(_userDataSubscription?.cancel());
      final user = _auth.currentUser;
      if (user != null) {
        _userDataSubscription =
            _firestore.collection('users').doc(user.uid).snapshots().listen(
          (docSnapshot) {
            if (!mounted) {
              return;
            }
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
            if (!mounted) {
              return;
            }
            setState(() => _isLoading = false);
          },
        );
      } else {
        setState(() => _isLoading = false);
      }
    } on Object catch (e) {
      log('❌ Error setting up user data listener: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundColor,
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
                    unawaited(
                      Navigator.pushNamed(
                        context,
                        RouteName.eventsScreen,
                      ),
                    );
                    break;
                  case 'settings':
                    unawaited(
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
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
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings_outlined, color: primaryColor),
                      SizedBox(width: 12),
                      Text('Account Settings'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: _isLoading
            ? const AppLoadingView(message: 'Loading profile...')
            : _userData == null
                ? AppEmptyView(
                    title: 'Profile unavailable',
                    subtitle:
                        'We could not load your profile details right now.',
                    icon: Icons.person_off_outlined,
                    actionLabel: 'Retry',
                    onAction: _listenToUserData,
                  )
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

  Widget _buildEditButton() => SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const EditProfileScreen(),
              ),
            );
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
    if (dobString == null) {
      return null;
    }

    try {
      final dob = DateTime.parse(dobString);
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age;
    } on Object {
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
                color: primaryColor.withValues(alpha: 0.6),
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
              CachedNetworkImage(
                imageUrl: photos[index].toString(),
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (context, url, error) => ColoredBox(
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
                              : Colors.white.withValues(alpha: 0.5),
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

  String _safeStringFromField(
    Object? value, {
    List<String> mapKeys = const ['name', 'country'],
  }) {
    if (value == null) {
      return '';
    }
    if (value is String) {
      return value;
    }
    if (value is Map) {
      for (final key in mapKeys) {
        final v = value[key];
        if (v != null && v.toString().isNotEmpty) {
          return v.toString();
        }
      }
    }
    return '';
  }

  // Hinge-style profile header
  Widget _buildHingeProfileHeader() {
    final name = _userData?['name'] ?? 'Your Name';
    final age = _userData?['age'] ?? _calculateAge(_userData?['dateOfBirth']);
    final nationality = _safeStringFromField(_userData?['nationality']);

    String location = _safeStringFromField(
      _userData?['location'],
      mapKeys: ['name', 'city'],
    );
    if (location.isEmpty) {
      location = _safeStringFromField(_userData?['living_in']);
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${CountryFlag.flagOrFallback(nationality)} $nationality',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ),
                if (location.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: primaryColor,
                        ),
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
    if (bio.isEmpty) {
      return const SizedBox.shrink();
    }

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
      details.add(
        {'icon': Icons.business_center, 'label': '', 'value': workTitle},
      );
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
      details.add(
        {'icon': Icons.search, 'label': '', 'value': relationshipIntent},
      );
    }

    // Tribe - group icon
    final tribe = getValue('tribe');
    if (tribe != null) {
      details.add({'icon': Icons.group, 'label': '', 'value': tribe});
    }

    if (details.isEmpty) {
      return const SizedBox.shrink();
    }

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
          ...details.map(
            (detail) => Padding(
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
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Hinge-style interests section
  Widget _buildHingeInterestsSection() {
    final interests = _userData?['interests'] as List<dynamic>? ?? [];
    if (interests.isEmpty) {
      return const SizedBox.shrink();
    }

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
            children: interests
                .map(
                  (interest) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.3),
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
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Full screen photo viewer
  void _showFullScreenPhoto(List<dynamic> photos, int initialIndex) {
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
              child: CachedNetworkImage(
                imageUrl: widget.photos[index].toString(),
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
      );
}
