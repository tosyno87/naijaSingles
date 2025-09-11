import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../explore/explore_screen.dart';
import '../messages/messages_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // Define all main screens here (removed Dating tab)
  // Order matches the BottomNavigationBarItems below
  final List<Widget> _screens = [
    const ExploreScreen(), // Tab 0: Explore
    const MessagesScreen(), // Tab 1: Messages
    const ProfileScreen(), // Tab 2: Profile
  ];

  // Deep green color for accents
  static const Color deepGreen = Color(0xFF008037);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body will switch between screens based on the current index
      body: _screens[_currentIndex],

      // SINGLE bottom navigation bar for the entire app
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: deepGreen,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
