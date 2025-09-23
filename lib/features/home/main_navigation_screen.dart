import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naijasingles/features/explore/explore_screen.dart';
import 'package:naijasingles/features/messages/messages_screen.dart';
import 'package:naijasingles/features/communities/ui/screens/communities_hub_screen.dart';
import 'package:naijasingles/features/profile/profile_screen.dart';
import 'package:naijasingles/debug/quick_analysis.dart';
import 'package:naijasingles/common/widgets/custom_3d_icons.dart';
import 'package:naijasingles/common/constants/app_colors.dart';

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
  
  // Getter to ensure valid index
  int get _validSelectedIndex => _selectedIndex.clamp(0, _pages.length - 1);
  late bool _backgroundTasksRunning;

  // Define the pages to be shown for each tab
  // Order matches the BottomNavigationBarItems below
  // NEW COMMUNITY-FIRST NAVIGATION
  final List<Widget> _pages = [
    const CommunitiesHubScreen(), // Tab 0: Communities Hub (All community features)
    const ExploreScreen(
        showBackButton: false), // Tab 1: Connect (Dating/Friendship)
    const MessagesScreen(), // Tab 2: Messages
        const ProfileScreen(), // Tab 3: Profile
  ];

  // Deep green color for accents
  // Using centralized app colors

  @override
  void initState() {
    super.initState();
    _backgroundTasksRunning = widget.backgroundTasksRunning;
    
    // Ensure selected index is within valid range
    _selectedIndex = _selectedIndex.clamp(0, _pages.length - 1);

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
      backgroundColor: AppColors.backgroundColor,
      // The body will switch between screens based on the selected index
      body: Stack(
        children: [
          // Main content
          Builder(
            builder: (context) {
              final page = _pages[_validSelectedIndex];
              print('🎯 Displaying page at index $_validSelectedIndex: ${page.runtimeType}');
              return page;
            },
          ),

          // Background task indicator
          if (_backgroundTasksRunning)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.9),
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

          // Temporary analysis button (remove after testing)
          if (kDebugMode)
            Positioned(
              top: MediaQuery.of(context).padding.top + 50,
              right: 16,
              child: FloatingActionButton(
                heroTag: "analysis_fab",
                mini: true,
                backgroundColor: Colors.blue.withOpacity(0.8),
                child: const Icon(Icons.analytics, color: Colors.white, size: 16),
                onPressed: () => _runUserAnalysis(context),
              ),
            ),
        ],
      ),

      // SINGLE bottom navigation bar for the entire app
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _validSelectedIndex,
        onTap: (index) {
          setState(() {
            // Ensure index is within valid range
            _selectedIndex = index.clamp(0, _pages.length - 1);
            print('🔄 Tab tapped: index=$index, _selectedIndex=$_selectedIndex, _validSelectedIndex=$_validSelectedIndex');
            print('📱 Pages length: ${_pages.length}');
          });
        },
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.montserrat(
          fontSize: 12,
        ),
            items: [
              BottomNavigationBarItem(
                icon: Custom3DIcons.communities(),
                label: 'Communities',
              ),
              BottomNavigationBarItem(
                icon: Custom3DIcons.connect(),
                label: 'Connect',
              ),
              BottomNavigationBarItem(
                icon: Custom3DIcons.messages(),
                label: 'Messages',
              ),
              BottomNavigationBarItem(
                icon: Custom3DIcons.profile(),
                label: 'Profile',
              ),
            ],
      ),
    );
  }

  // Temporary analysis method (remove after testing)
  void _runUserAnalysis(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '📊 User Analysis',
              style: GoogleFonts.montserrat(
                  fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await QuickAnalysis.runQuickAnalysis();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Analysis complete! Check console for results.')),
                  );
                }
              },
              icon: const Icon(Icons.analytics),
              label: const Text('Run User Analysis'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await QuickAnalysis.cleanupProfiles();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Cleanup complete! Check console for results.')),
                  );
                }
              },
              icon: const Icon(Icons.cleaning_services),
              label: const Text('Cleanup Incomplete Profiles'),
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
}
