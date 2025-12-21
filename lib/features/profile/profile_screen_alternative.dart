// Alternative approach: Floating Edit Button + App Bar Menu
// This is even cleaner - similar to Instagram profile style

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreenAlternative extends StatelessWidget {
  const ProfileScreenAlternative({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        // Floating action button for edit (like Instagram)
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'profile_screen_fab',
          onPressed: () {
            // Navigate to edit profile
          },
          backgroundColor: const Color(0xFF008037),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.edit_outlined),
          label: Text(
            'Edit',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // App bar with menu
        appBar: AppBar(
          backgroundColor: const Color(0xFFFDF1E7),
          elevation: 0,
          title: const Text('Profile'),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'privacy',
                  child: ListTile(
                    leading: Icon(Icons.privacy_tip_outlined),
                    title: Text('Privacy Settings'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: ListTile(
                    leading: Icon(Icons.settings_outlined),
                    title: Text('Settings & Account'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),

        body: const SingleChildScrollView(
          child: Column(
            children: [
              // Profile content here
              SizedBox(
                height: 200,
                child: Center(
                  child: Text('Profile Content'),
                ),
              ),

              // No buttons needed - everything in FAB and menu
              SizedBox(height: 80), // Space for FAB
            ],
          ),
        ),
      );
}
