import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../common/bloc/user/user_bloc.dart';
import '../../common/constants/app_colors.dart';
import '../../common/constants/constants.dart';
import '../../common/routes/route_name.dart';
import '../../common/utils/account_deletion_scope.dart';
import '../../common/utils/app_logger.dart';
import '../../common/utils/profile_completion_guard.dart';
import '../../common/widgets/custom_3d_icons.dart';
import '../../debug/quick_analysis.dart';
import '../../models/user_model.dart';
import '../account_status/presentation/widgets/account_status_banner.dart';
import '../communities/ui/screens/discover_page_v2.dart';
import '../explore/explore_screen.dart';
import '../messages/messages_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({
    super.key,
    this.backgroundTasksRunning = false,
  });
  final bool backgroundTasksRunning;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // Getter to ensure valid index
  int get _validSelectedIndex => _selectedIndex.clamp(0, _pages.length - 1);
  late bool _backgroundTasksRunning;
  bool _hasCheckedRegistration = false;

  // Define the pages to be shown for each tab
  // Order matches the BottomNavigationBarItems below
  // CONNECT-FIRST NAVIGATION (Connect is the home page)
  final List<Widget> _pages = [
    const ExploreScreen(), // Tab 0: Connect (Dating/Friendship) - HOME PAGE
    const DiscoverPageV2(), // Tab 1: Discover (Events & Communities)
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

    // Check user registration status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkUserRegistration());
    });

    // Auto-hide the background task indicator after 10 seconds
    if (_backgroundTasksRunning) {
      unawaited(Future.delayed(const Duration(seconds: 10), () {
        if (!context.mounted) return;
        setState(() {
          _backgroundTasksRunning = false;
        });
      }));
    }
  }

  Future<void> _checkUserRegistration() async {
    if (_hasCheckedRegistration || !mounted) return;

    // FIRST: Check if user is actually authenticated
    // If not authenticated, redirect to welcome screen (don't go to onboarding)
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      developer
          .log('⚠️ User not authenticated - redirecting to welcome screen');
      _hasCheckedRegistration = true;
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          RouteName.welcomeScreen,
          (route) => false,
        );
      }
      return;
    }

    developer.log('✅ User is authenticated: ${currentUser.uid}');

    final userBloc = context.read<UserBloc>();

    // Set a maximum timeout to prevent infinite loading
    const maxWaitTime = Duration(seconds: 3);
    final startTime = DateTime.now();

    // Force reload user data from Firestore (in case we just completed onboarding)
    try {
      userBloc.add(const UserListenStarted());
    } on Object catch (e) {
      developer.log('⚠️ Error reloading user data: $e');
    }

    // Wait for user data with timeout
    while (DateTime.now().difference(startTime) < maxWaitTime) {
      if (!mounted) return;

      // Check if user data is loaded (use BLoC)
      final currentUserFromBloc = userBloc.currentUser;
      if (currentUserFromBloc != null &&
          ProfileCompletionGuard.isUserComplete(currentUserFromBloc)) {
        developer.log('✅ User data loaded, showing main navigation');
        if (mounted) {
          setState(() {
            _hasCheckedRegistration = true;
          });
        }
        return;
      }

      // Wait a bit before checking again
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // Timeout reached - check Firestore directly as fallback
    if (!mounted) return;

    developer.log('⚠️ Timeout reached, checking Firestore directly...');

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await firebaseFireStoreInstance
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 2));

        if (doc.exists) {
          final data = doc.data();
          if (data != null && ProfileCompletionGuard.isDocumentComplete(data)) {
            developer
                .log('✅ User data found in Firestore, updating UserBloc...');
            final userModel = UserModel.fromDocument(doc);
            userBloc.add(UserDataUpdated(userModel));

            if (mounted) {
              setState(() {
                _hasCheckedRegistration = true;
              });
            }
            return;
          }
        }
      }
    } catch (e) {
      developer.log('⚠️ Error checking Firestore: $e');
    }

    // User is authenticated but no profile data found - redirect to onboarding
    // (or to welcome if account deletion is in progress - doc removed before signOut)
    _hasCheckedRegistration = true;
    if (AccountDeletionScope.inProgress) {
      developer.log(
          '⚠️ Account deletion in progress - redirecting to welcome (not onboarding)',);
      AccountDeletionScope.inProgress = false;
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          RouteName.welcomeScreen,
          (route) => false,
        );
      }
    } else {
      developer.log(
          '⚠️ Authenticated user has incomplete profile - redirecting to onboarding',);
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          RouteName.onboarding,
          (route) => false,
        );
      }
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
    final userBloc = context.watch<UserBloc>();
    final currentUser = userBloc.currentUser;

    // Show loading screen while checking registration - prevent any content flash
    if (!_hasCheckedRegistration ||
        currentUser == null ||
        !ProfileCompletionGuard.isUserComplete(currentUser)) {
      // If we haven't checked yet or user doesn't exist, show loading
      // This prevents the wrong screen from appearing
      if (!_hasCheckedRegistration) {
        // Still checking - show loading
        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(height: 24),
                Text(
                  'Loading...',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      // Check completed - verify user is authenticated
      // If not authenticated, redirect to welcome screen (not onboarding)
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        developer.log(
            '⚠️ User not authenticated in build - redirecting to welcome screen',);
        unawaited(Future.microtask(() {
          if (context.mounted) {
            unawaited(Navigator.of(context).pushNamedAndRemoveUntil(
              RouteName.welcomeScreen,
              (route) => false,
            ));
          }
        }));
        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(height: 24),
                Text(
                  'Redirecting...',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Authenticated but no user data - redirect to onboarding or welcome (if deletion in progress)
      if (AccountDeletionScope.inProgress) {
        developer.log(
            '⚠️ Account deletion in progress - redirecting to welcome (not onboarding)',);
        AccountDeletionScope.inProgress = false;
        unawaited(Future.microtask(() {
          if (context.mounted) {
            unawaited(Navigator.of(context).pushNamedAndRemoveUntil(
              RouteName.welcomeScreen,
              (route) => false,
            ));
          }
        }));
      } else {
        developer.log(
            '⚠️ Authenticated user has incomplete profile - redirecting to onboarding',);
        unawaited(Future.microtask(() {
          if (context.mounted) {
            unawaited(Navigator.of(context).pushNamedAndRemoveUntil(
              RouteName.onboarding,
              (route) => false,
            ));
          }
        }));
      }
      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: AppColors.primaryGreen,
              ),
              const SizedBox(height: 24),
              Text(
                'Setting up your profile...',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      // Column: banner takes layout space above content so pages shift down.
      body: Column(
        children: [
          // Account status banner (paused / incognito).
          // Returns SizedBox.shrink() when status is active, so zero height.
          const AccountStatusBanner(),

          // Main content fills remaining space.
          Expanded(
            child: Stack(
              children: [
                IndexedStack(
                  index: _validSelectedIndex,
                  children: _pages,
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
                      'Finishing setup...',
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
                heroTag: 'analysis_fab',
                mini: true,
                backgroundColor: Colors.blue.withValues(alpha: 0.8),
                child:
                    const Icon(Icons.analytics, color: Colors.white, size: 16),
                onPressed: () => _runUserAnalysis(context),
              ),
            ),
              ],
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
            AppLogger.debug(
              '🔄 Tab tapped: index=$index, _selectedIndex=$_selectedIndex, _validSelectedIndex=$_validSelectedIndex',
            );
            AppLogger.debug('📱 Pages length: ${_pages.length}');
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
            icon: Custom3DIcons.connect(),
            label: 'Connect',
          ),
          BottomNavigationBarItem(
            icon: Custom3DIcons.discover(),
            label: 'Discover',
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
    unawaited(showModalBottomSheet(
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
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
                      content: Text(
                        'Analysis complete! Check console for results.',
                      ),
                    ),
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
                      content: Text(
                        'Cleanup complete! Check console for results.',
                      ),
                    ),
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
    ));
  }
}
