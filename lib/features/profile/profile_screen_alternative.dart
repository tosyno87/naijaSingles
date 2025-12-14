// Alternative approach: Floating Edit Button + App Bar Menu
// This is even cleaner - similar to Instagram profile style

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreenAlternative extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Floating action button for edit (like Instagram)
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "profile_screen_fab",
        onPressed: () {
          // Navigate to edit profile
        },
        backgroundColor: Color(0xFF008037),
        foregroundColor: Colors.white,
        icon: Icon(Icons.edit_outlined),
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
        backgroundColor: Color(0xFFFDF1E7),
        elevation: 0,
        title: Text('Profile'),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'privacy',
                child: ListTile(
                  leading: Icon(Icons.privacy_tip_outlined),
                  title: Text('Privacy Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
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

      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile content here
            Container(
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
}
