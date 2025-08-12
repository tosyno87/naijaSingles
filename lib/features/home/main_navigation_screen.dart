import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naijasingles/features/explore/explore_screen.dart';
import 'package:naijasingles/features/messages/messages_screen.dart';
import 'package:naijasingles/features/events/presentation/screens/events_screen.dart';
import 'package:naijasingles/features/profile/profile_screen.dart';
import 'package:naijasingles/debug/simple_debug.dart';

class MainNavigationScreen extends StatefulWidget {
  final bool backgroundTasksRunning;

  const MainNavigationScreen({
    Key? key,
    this.backgroundTasksRunning = false,
  }) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  late bool _backgroundTasksRunning;

  // Define the pages to be shown for each tab
  // Order matches the BottomNavigationBarItems below
  final List<Widget> _pages = [
    const ExploreScreen(
        showBackButton: false), // Tab 0: Explore - no back labelLarge
    const MessagesScreen(), // Tab 1: Messages
    const EventsScreen(), // Tab 2: Events
    const ProfileScreen(), // Tab 3: Profile
  ];

  // Deep green color for accents
  static const Color deepGreen = Color(0xFF008037);

  @override
  void initState() {
    super.initState();
    _backgroundTasksRunning = widget.backgroundTasksRunning;

    // Auto-hide the background task indicator after 10 seconds
    if (_backgroundTasksRunning) {
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted) {
          setState(() {
            _backgroundTasksRunning = false;
          });
        }
      });
    }
  }

  void setBackgroundTasksComplete() {
    if (mounted) {
      setState(() {
        _backgroundTasksRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body will switch between screens based on the selected index
      body: Stack(
        children: [
          // Main content
          _pages[_selectedIndex],

          // Background task indicator
          if (_backgroundTasksRunning)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: deepGreen.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Finishing setup...",
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Debug button (only in debug mode)
          if (kDebugMode)
            Positioned(
              top: MediaQuery.of(context).padding.top + 50,
              right: 16,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.red.withOpacity(0.8),
                child:
                    const Icon(Icons.bug_report, color: Colors.white, size: 16),
                onPressed: () => _showDebugMenu(context),
              ),
            ),
        ],
      ),

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
        selectedLabelStyle: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.montserrat(
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
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _showDebugMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '🐛 Debug Menu',
              style: GoogleFonts.montserrat(
                  fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildDebugButton(
              'Test Database Connection',
              Icons.storage,
              () => SimpleDebug.testDatabaseConnection(),
            ),
            _buildDebugButton(
              'Clear My Swipe History',
              Icons.refresh,
              () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await SimpleDebug.clearSwipeHistory(user.uid);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Swipe history cleared! Check console for details.')),
                    );
                  }
                }
              },
            ),
            _buildDebugButton(
              'Show My Excluded Users',
              Icons.visibility_off,
              () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await SimpleDebug.showExcludedUsers(user.uid);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Check console for excluded users list.')),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugButton(
      String title, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(12),
        ),
      ),
    );
  }
}
