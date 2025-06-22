import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../user/controllers/onboarding_controller.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<OnboardingController>(context);
    
    // Background color for the app - warm cream color
    const Color backgroundColor = Color(0xFFFDF6EC);
    
    // Deep green color for accents
    const Color deepGreen = Color(0xFF008037);
    
    // Warm brown for headers
    final Color warmBrown = Colors.brown.shade800;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'My Profile',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: warmBrown,
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.edit, color: deepGreen),
            label: Text(
              'Edit',
              style: GoogleFonts.poppins(
                color: deepGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/edit_profile');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: deepGreen),
            onPressed: () {
              // Settings functionality to be implemented
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header with Avatar, Name, Age, Location
              _buildProfileHeader(context, controller, deepGreen, warmBrown),
              
              const SizedBox(height: 24),
              
              // About Me Section
              _buildAboutMeSection(context, controller, deepGreen, warmBrown),
              
              const SizedBox(height: 24),
              
              // Tribe & Intent Section
              _buildTribeAndIntentSection(controller, deepGreen, warmBrown),
              
              const SizedBox(height: 24),
              
              // Languages Section
              if (controller.languages.isNotEmpty)
                _buildLanguagesSection(controller, deepGreen, warmBrown),
              
              const SizedBox(height: 24),
              
              // Interests Section
              if (controller.genres.isNotEmpty)
                _buildInterestsSection(controller, deepGreen, warmBrown),
              
              const SizedBox(height: 24),
              
              // Education & Occupation Section
              _buildEducationAndOccupationSection(controller, deepGreen, warmBrown),
              
              const SizedBox(height: 24),
              
              // Values Section
              if (controller.values.isNotEmpty)
                _buildValuesSection(controller, deepGreen, warmBrown),
              
              const SizedBox(height: 32),
              
              // Edit Profile Button
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: deepGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
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
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
  
  // Profile Header with Avatar, Name, Age, Location
  Widget _buildProfileHeader(BuildContext context, OnboardingController controller, Color deepGreen, Color warmBrown) {
    return Column(
      children: [
        // Profile Image with Edit Button
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            // Avatar
            CircleAvatar(
              radius: 60,
              backgroundColor: deepGreen,
              child: CircleAvatar(
                radius: 57,
                backgroundColor: Colors.white,
                backgroundImage: controller.photos.isNotEmpty
                    ? NetworkImage(controller.photos.first)
                    : const AssetImage('assets/images/placeholder_profile.jpg') as ImageProvider,
                onBackgroundImageError: (_, __) {},
              ),
            ),
            
            // Edit Photo Button
            Container(
              decoration: BoxDecoration(
                color: deepGreen,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Name
        Text(
          controller.userName ?? 'Your Name',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: warmBrown,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Age and Location
        if (controller.dateOfBirth != null || controller.locationName != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (controller.dateOfBirth != null) ...[
                Icon(Icons.cake, size: 16, color: deepGreen),
                const SizedBox(width: 4),
                Text(
                  _calculateAge(controller.dateOfBirth!).toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ],
              if (controller.dateOfBirth != null && controller.locationName != null)
                Text(
                  ' • ',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              if (controller.locationName != null) ...[
                Icon(Icons.location_on, size: 16, color: deepGreen),
                const SizedBox(width: 4),
                Text(
                  controller.locationName!,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }
  
  // About Me Section
  Widget _buildAboutMeSection(BuildContext context, OnboardingController controller, Color deepGreen, Color warmBrown) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: deepGreen.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'About Me',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: warmBrown,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: deepGreen, size: 20),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              controller.bio ?? "Tell others about yourself...",
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: controller.bio != null ? Colors.black87 : Colors.grey[400],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Tribe & Intent Section
  Widget _buildTribeAndIntentSection(OnboardingController controller, Color deepGreen, Color warmBrown) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: deepGreen.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cultural Roots & Intent',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: warmBrown,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (controller.tribe != null)
                  _buildChip(Icons.people, controller.tribe!, deepGreen),
                if (controller.intent != null)
                  _buildChip(
                    controller.intent == 'dating' 
                        ? Icons.favorite 
                        : controller.intent == 'friendship' 
                            ? Icons.people 
                            : Icons.business_center,
                    controller.intent!.substring(0, 1).toUpperCase() + controller.intent!.substring(1),
                    deepGreen,
                  ),
                if (controller.nationality != null)
                  _buildChip(Icons.flag, controller.nationality!, deepGreen),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Languages Section
  Widget _buildLanguagesSection(OnboardingController controller, Color deepGreen, Color warmBrown) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: deepGreen.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Languages',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: warmBrown,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.languages.map((language) {
                return _buildChip(Icons.language, language, deepGreen);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  // Interests Section
  Widget _buildInterestsSection(OnboardingController controller, Color deepGreen, Color warmBrown) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: deepGreen.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interests',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: warmBrown,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.genres.map((interest) {
                return Chip(
                  label: Text(
                    interest,
                    style: GoogleFonts.poppins(
                      color: deepGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  backgroundColor: deepGreen.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: deepGreen,
                      width: 0.5,
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
  
  // Education & Occupation Section
  Widget _buildEducationAndOccupationSection(OnboardingController controller, Color deepGreen, Color warmBrown) {
    if (controller.education == null && controller.occupation == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: deepGreen.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Education & Work',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: warmBrown,
              ),
            ),
            const SizedBox(height: 16),
            if (controller.education != null)
              _buildInfoRow(Icons.school, 'Education', controller.education!, deepGreen),
            if (controller.education != null && controller.occupation != null)
              const SizedBox(height: 12),
            if (controller.occupation != null)
              _buildInfoRow(Icons.work, 'Occupation', controller.occupation!, deepGreen),
          ],
        ),
      ),
    );
  }
  
  // Values Section
  Widget _buildValuesSection(OnboardingController controller, Color deepGreen, Color warmBrown) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: deepGreen.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Values',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: warmBrown,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.values.map((value) {
                return _buildChip(Icons.check_circle, value, deepGreen);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to build consistent chips
  Widget _buildChip(IconData icon, String label, Color deepGreen) {
    return Chip(
      avatar: Icon(icon, color: deepGreen, size: 18),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.black87,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: Colors.white,
      side: BorderSide(color: deepGreen, width: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
  }
  
  // Helper method to build info row
  Widget _buildInfoRow(IconData icon, String label, String value, Color deepGreen) {
    return Row(
      children: [
        Icon(icon, color: deepGreen, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Calculate age from date of birth
  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }
}
