import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';

import '../../common/routes/route_name.dart';
import '../settings/safety_center_screen.dart';
import '../settings/help_center_screen.dart';
import '../settings/feedback_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // MVP color scheme (matching profile_screen.dart)
  static const Color backgroundColor = Color(0xFFFDF1E7); // Warm cream
  static const Color primaryColor =
      Color(0xFF008037); // Deep green (afropeepGreen)
  static const Color cardColor = Color(0xFFFFFBF5); // Light cream for cards
  static final Color textPrimary = Colors.brown.shade800;
  static final Color textSecondary = Colors.brown.shade600;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Section
            _buildSectionHeader('Account'),
            const SizedBox(height: 16),

            _buildSettingsCard([
              _buildSettingsItem(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                subtitle: 'Update your photos and info',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to edit profile (handled by parent)
                },
              ),
              _buildDivider(),
              _buildSettingsItem(
                icon: Icons.email_outlined,
                title: 'Email',
                subtitle: user?.email ?? 'Not available',
                onTap: () => _showEmailDialog(),
              ),
              _buildDivider(),
              _buildSettingsItem(
                icon: Icons.lock_outline,
                title: 'Change Password',
                subtitle: 'Update your password',
                onTap: () => _showChangePasswordDialog(),
              ),
            ]),

            const SizedBox(height: 32),

            // Privacy & Safety Section
            _buildSectionHeader('Privacy & Safety'),
            const SizedBox(height: 16),

            _buildSettingsCard([
              _buildSettingsItem(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Settings',
                subtitle: 'Control who can see your profile',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to privacy settings (handled by parent)
                },
              ),
              _buildDivider(),
              _buildSettingsItem(
                icon: Icons.block_outlined,
                title: 'Blocked Users',
                subtitle: 'Manage blocked accounts',
                onTap: () => Navigator.pushNamed(context, RouteName.blockedUsers),
              ),
              _buildDivider(),
              _buildSettingsItem(
                icon: Icons.report_outlined,
                title: 'Safety Center',
                subtitle: 'Report issues and get help',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SafetyCenterScreen(),
                    ),
                  );
                },
              ),
            ]),

            const SizedBox(height: 32),

            // App Settings Section
            _buildSectionHeader('App Settings'),
            const SizedBox(height: 16),

            _buildSettingsCard([
              _buildSettingsItem(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Manage your notification preferences',
                onTap: () => Navigator.pushNamed(context, RouteName.notificationSettings),
              ),
              _buildDivider(),
              _buildSettingsItem(
                icon: Icons.location_on_outlined,
                title: 'Location',
                subtitle: 'Update your location settings',
                onTap: () => _showComingSoon('Location Settings'),
              ),
              _buildDivider(),
              _buildSettingsItem(
                icon: Icons.language_outlined,
                title: 'Language',
                subtitle: 'English (US)',
                onTap: () => _showComingSoon('Language Settings'),
              ),
            ]),

            const SizedBox(height: 32),

            // Support Section
            _buildSectionHeader('Support'),
            const SizedBox(height: 16),

            _buildSettingsCard([
              _buildSettingsItem(
                icon: Icons.help_outline,
                title: 'Help Center',
                subtitle: 'Get help and support',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HelpCenterScreen(),
                    ),
                  );
                },
              ),
              _buildDivider(),
              _buildSettingsItem(
                icon: Icons.feedback_outlined,
                title: 'Send Feedback',
                subtitle: 'Share your thoughts with us',
                onTap: () => _showFeedbackDialog(),
              ),
              _buildDivider(),
              _buildSettingsItem(
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'App version and info',
                onTap: () => _showAboutDialog(),
              ),
            ]),

            const SizedBox(height: 40),

            // Sign Out Button - Robust solution with proper width constraints
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _showSignOutDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cardColor,
                    foregroundColor: Colors.red.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.red.shade300, width: 2),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Sign Out',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Delete Account Button - Robust solution with proper width constraints
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _showDeleteAccountDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cardColor, // Same as Sign Out button
                    foregroundColor: Colors.red.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                          color: Colors.red.shade300,
                          width: 2), // Same border as Sign Out
                    ),
                    elevation: 2, // Same elevation as Sign Out
                  ),
                  child: Text(
                    'Delete Account',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700, // Same text color as Sign Out
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (iconColor ?? primaryColor).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.grey.shade200,
      indent: 72,
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor, // MVP background
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.logout_outlined,
                color: Colors.red.shade700,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Sign Out',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out of your account?',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          // Cancel button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: textSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ),
          ),
          // Sign Out confirmation button - Fixed layout
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ElevatedButton(
              onPressed: () => _performSignOut(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12), // Proper padding
                minimumSize:
                    const Size(100, 44), // Minimum size to prevent cramping
              ),
              child: Text(
                'Sign Out',
                style: GoogleFonts.poppins(
                  fontSize: 14, // Slightly smaller to fit better
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor, // MVP background - same as sign-out dialog
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Account',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.red.shade700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning text with high contrast against cardColor
            Text(
              'This action cannot be undone. Deleting your account will:',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color:
                    textPrimary, // Use textPrimary for high contrast against cardColor
              ),
            ),
            const SizedBox(height: 16),
            // Bullet points with high contrast and better formatting
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50, // Light red background for emphasis
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200, width: 1),
              ),
              child: Text(
                '• Remove all your photos and profile information\n'
                '• Delete all your matches and conversations\n'
                '• Cancel any active subscriptions\n'
                '• Make your profile invisible to other users',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.red.shade800, // High contrast red for warnings
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Cancel button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: textSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ),
          ),
          // Delete button - Fixed layout
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ElevatedButton(
              onPressed: () => _showDeleteConfirmation(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                minimumSize: const Size(80, 44),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    Navigator.pop(context); // Close first dialog

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Final Confirmation',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.red.shade700,
          ),
        ),
        content: Text(
          'Type "DELETE" to confirm account deletion:',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: textSecondary,
          ),
        ),
        actions: [
          // Cancel button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: textSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ),
          ),
          // Confirm Delete button - Fixed layout
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showComingSoon('Account Deletion');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                minimumSize: const Size(120, 44), // Wider for "Confirm Delete"
              ),
              child: Text(
                'Confirm Delete',
                style: GoogleFonts.poppins(
                  fontSize: 13, // Smaller to fit the longer text
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performSignOut() async {
    try {
      // Close dialog
      Navigator.pop(context);

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor, // MVP background
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: primaryColor, // MVP green
                  strokeWidth: 3,
                ),
                const SizedBox(height: 20),
                Text(
                  'Signing out...',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Sign out from Firebase
      await _auth.signOut();

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Navigate to login screen
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      log('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to sign out. Please try again.',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showEmailDialog() {
    _showComingSoon('Email Settings');
  }

  void _showChangePasswordDialog() {
    _showComingSoon('Change Password');
  }

  void _showFeedbackDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FeedbackScreen(),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'About NaijaSingles',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 1.0.0',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'NaijaSingles is a dating app designed to connect Nigerian singles worldwide. Find meaningful connections, chat with matches, and discover love.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '© 2024 NaijaSingles. All rights reserved.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature coming soon!',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
