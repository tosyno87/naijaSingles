import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naijasingles/features/home/dating_homepage.dart';
import 'package:naijasingles/features/explore/explore_screen.dart';
import 'package:naijasingles/features/messages/messages_screen.dart';
import 'package:naijasingles/features/profile/profile_screen.dart';
import 'package:naijasingles/common/providers/user_provider.dart';
import 'package:provider/provider.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  
  // Define the pages to be shown for each tab
  final List<Widget> _pages = [
    const DatingHomePage(),
    const ExploreScreen(),
    const MessagesScreen(),
    const ProfileScreen(),
  ];
  
  // Deep green color for accents
  static const Color deepGreen = Color(0xFF008037);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body will switch between screens based on the selected index
      body: _pages[_selectedIndex],
      
      // SINGLE bottom navigation bar for the entire app
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.white,
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
            icon: Icon(Icons.favorite),
            label: 'Dating',
          ),
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
