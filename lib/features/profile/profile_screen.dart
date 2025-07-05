import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'edit_profile_screen.dart';
import 'privacy_settings_screen.dart';

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

  // Afrocentric color scheme
  static const Color backgroundColor = Color(0xFFFDF1E7); // Warm cream
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
          print('   Height: ${data?['heightDisplay'] ?? data?['height_ft_in']}');
          print('   Looking for: ${data?['lookingFor']}');
          print('   Bio length: ${(data?['bio'] ?? '').length} characters');
          
          setState(() {
            _userData = data;
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
        iconTheme: IconThemeData(color: textPrimary), // This sets the back arrow color
        title: Text(
          'My Profile',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Profile Photos Section
                    _buildPhotoSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Basic Info Card
                    _buildBasicInfoCard(),
                    
                    const SizedBox(height: 16),
                    
                    // About Me Card
                    _buildAboutMeCard(),
                    
                    const SizedBox(height: 16),
                    
                    // Interests Card
                    _buildInterestsCard(),
                    
                    const SizedBox(height: 16),
                    
                    // Details Card
                    _buildDetailsCard(),
                    
                    const SizedBox(height: 32),
                    
                    // Profile Action Buttons
                    _buildProfileActionButtons(),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPhotoSection() {
    final photos = _userData?['photos'] as List<dynamic>? ?? [];
    
    return Container(
      height: 200,
      child: photos.isEmpty
          ? _buildEmptyPhotoPlaceholder()
          : PageView.builder(
              itemCount: photos.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
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
                            Icons.person,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: CircularProgressIndicator(color: primaryColor),
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

  Widget _buildEmptyPhotoPlaceholder() {
    return Container(
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
            style: GoogleFonts.poppins(
              color: textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    final name = _userData?['name'] ?? 'Your Name';
    // Use pre-calculated age from database, fallback to calculation if not available
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ),
              ],
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

  Widget _buildAboutMeCard() {
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
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              bio.isEmpty ? 'Tell others about yourself...' : bio,
              style: GoogleFonts.poppins(
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

  Widget _buildInterestsCard() {
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
                  style: GoogleFonts.poppins(
                    fontSize: 20,
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
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: interests.map((interest) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
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
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    final tribe = _userData?['tribe'] ?? 'Not specified';
    final preferences = _userData?['preferences'] as Map<String, dynamic>? ?? {};
    final interestedIn = preferences['interestedIn'] ?? _userData?['interestedIn'] ?? 'Not specified';
    final ageRange = preferences['ageRange'] as List<dynamic>? ?? [];
    final lookingFor = preferences['lookingFor'] ?? _userData?['lookingFor'] ?? 'Not specified';
    final relationshipIntent = preferences['relationshipIntent'] ?? _userData?['relationshipIntent'] ?? 'Not specified';
    final heightDisplay = _userData?['heightDisplay'] ?? _userData?['height_ft_in'] ?? 'Not specified';
    
    // Additional fields from onboarding
    final education = _userData?['education'] ?? '';
    final occupation = _userData?['occupation'] ?? '';
    final languages = _userData?['languages'] as List<dynamic>? ?? [];
    final nationality = _userData?['nationality'] ?? '';
    
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
                  Icons.info_outline,
                  color: primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Details',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Basic details
            _buildDetailRow('Tribe/Ethnicity', tribe),
            const SizedBox(height: 12),
            _buildDetailRow('Height', heightDisplay),
            
            // Additional profile info (if available)
            if (education.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailRow('Education', education),
            ],
            if (occupation.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailRow('Occupation', occupation),
            ],
            if (nationality.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailRow('Nationality', nationality),
            ],
            if (languages.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailRow('Languages', languages.join(', ')),
            ],
            
            const SizedBox(height: 16),
            
            // Divider
            Container(
              height: 1,
              color: textSecondary.withValues(alpha: 0.2),
            ),
            
            const SizedBox(height: 16),
            
            // Dating preferences
            Text(
              'Dating Preferences',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Looking for', lookingFor),
            const SizedBox(height: 12),
            _buildDetailRow('Interested in', interestedIn),
            const SizedBox(height: 12),
            _buildDetailRow('Relationship goals', relationshipIntent),
            if (ageRange.length == 2) ...[
              const SizedBox(height: 12),
              _buildDetailRow('Age preference', '${ageRange[0]} - ${ageRange[1]} years'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
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
        color: primaryColor.withValues(alpha: 0.1),
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
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileActionButtons() {
    return Row(
      children: [
        // Edit Profile Button
        Expanded(
          child: SizedBox(
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
              child: Text(
                'Edit Profile',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Privacy Settings Button
        Expanded(
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrivacySettingsScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: cardColor,
                foregroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: primaryColor, width: 2),
                ),
                elevation: 1,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.privacy_tip_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Privacy',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  int? _calculateAge(String? dobString) {
    if (dobString == null) return null;
    
    try {
      final dob = DateTime.parse(dobString);
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return null;
    }
  }
}
