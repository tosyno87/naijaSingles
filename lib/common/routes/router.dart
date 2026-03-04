import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/auth_method/auth_method_selection_screen.dart';
import '../../features/auth/auth_method/sign_in_method_selection_screen.dart';
import '../../features/auth/email_password/ui/screens/email_login_screen.dart';
import '../../features/auth/email_password/ui/screens/email_password_reset_screen.dart';
import '../../features/auth/email_password/ui/screens/email_signup_screen.dart';
import '../../features/auth/phone/ui/screens/otp_page.dart';
import '../../features/auth/phone/ui/screens/phone_number.dart';
import '../../features/auth/phone/ui/screens/update_phonenumber.dart';
import '../../features/auth/welcome/welcome_screen.dart';
import '../../features/chat/ui/screens/chat_page.dart';
import '../../features/dating/screens/user_detail_screen.dart';
import '../../features/events/data/models/enhanced_event_model.dart';
import '../../features/events/data/models/event_model.dart';
import '../../features/events/data/services/user_event_service.dart';
import '../../features/events/presentation/bloc/event_creation_bloc.dart';
import '../../features/events/presentation/screens/create_event_screen.dart';
import '../../features/events/presentation/screens/event_details_screen.dart';
import '../../features/events/presentation/screens/event_template_selection_screen.dart';
import '../../features/events/presentation/screens/events_screen.dart';
import '../../features/events/presentation/screens/my_events_screen.dart';
import '../../features/explore/explore_screen.dart';
import '../../features/group_chat/screens/group_list_screen.dart';
import '../../features/groups/ui/screens/groups_screen.dart';
import '../../features/home/main_navigation_screen.dart';
import '../../features/home/ui/screens/splash.dart';
import '../../features/home/ui/screens/user_filter/settings.dart';
import '../../features/home/ui/tab/tabbar.dart';
import '../../features/match/ui/screen/match_page.dart';
import '../../features/onboarding/onboarding_main.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/settings_screen.dart';
import '../../features/settings/account_deletion_screen.dart';
import '../../features/settings/blocked_users_screen.dart';
import '../../features/settings/feedback_screen.dart';
import '../../features/settings/help_center_screen.dart';
import '../../features/settings/language_settings_screen.dart';
import '../../features/settings/location_settings_screen.dart';
import '../../features/settings/notification_settings_screen.dart';
import '../../features/settings/safety_center_screen.dart';
import '../../features/user/ui/screens/show_gender.dart';
import '../../features/user/ui/screens/update_user_location.dart';
import '../../features/user/ui/screens/user_dob.dart';
import '../../features/user/ui/screens/user_gender.dart';
import '../../features/user/ui/screens/user_location.dart';
import '../../features/user/ui/screens/user_name.dart';
import '../../features/user/ui/screens/user_nationality.dart';
import '../../features/user/ui/screens/user_profile.dart';
import '../../features/user/ui/screens/user_profile_pic_set.dart';
import '../../features/user/ui/screens/user_search_location.dart';
import '../../features/user/ui/screens/user_sexual_details.dart';
import '../../features/user/ui/screens/user_university.dart';
import '../../models/user_model.dart';
import '../utils/large_image.dart';
import 'route_name.dart';

/// Transparent widget that handles Firebase auth callback deep links
/// Immediately pops itself so no UI is visible to the user
class _FirebaseCallbackHandler extends StatefulWidget {
  const _FirebaseCallbackHandler();

  @override
  State<_FirebaseCallbackHandler> createState() =>
      _FirebaseCallbackHandlerState();
}

class _FirebaseCallbackHandlerState extends State<_FirebaseCallbackHandler> {
  @override
  void initState() {
    super.initState();
    // Pop immediately in the next frame - user should never see this widget
    // Firebase will process the callback and trigger auth state changes
    // The PhoneAuthBloc listener will handle navigation to OTP screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Return completely transparent/empty widget
    // This ensures no visual flash occurs
    return const SizedBox.shrink();
  }
}

abstract class AppRouter {
  // register here for routes
  static Map<String, WidgetBuilder> allRoutes = {
    // Root route - redirect to welcome (splash removed to eliminate flash)
    '/': (context) => const WelcomeScreen(),
    RouteName.splashScreen: (context) => const Splash(),
    RouteName.welcomeScreen: (context) {
      debugPrint('🎯 WelcomeScreen route builder called');
      try {
        const widget = WelcomeScreen();
        debugPrint('✅ WelcomeScreen widget created successfully');
        return widget;
      } catch (e, stackTrace) {
        debugPrint('❌ Error creating WelcomeScreen: $e');
        debugPrint('Stack trace: $stackTrace');
        rethrow;
      }
    },
    RouteName.loginScreen: (context) =>
        const EmailLoginScreen(), // Redirect to EmailLoginScreen
    RouteName.tabScreen: (context) => const Tabbar(),
    // Auth method selection routes
    RouteName.authMethodSelection: (context) =>
        const AuthMethodSelectionScreen(),
    RouteName.signInMethodSelection: (context) =>
        const SignInMethodSelectionScreen(),
    // Email authentication routes
    RouteName.emailSignup: (context) => const EmailSignupScreen(),
    RouteName.emailLogin: (context) => const EmailLoginScreen(),
    RouteName.emailPasswordReset: (context) => const EmailPasswordResetScreen(),
    RouteName.profileScreen: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args == null || args is! Map) {
        return const Scaffold(body: Center(child: Text('Invalid route')));
      }
      return ProfilePage(
        isPurchased: args['isPurchased'] ?? false,
        items: args['items'] ?? {},
        purchases: args['purchases'] ?? [],
      );
    },
    RouteName.phoneNumberScreen: (context) {
      // Get isSignIn from route arguments, default to false (sign-up)
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      final isSignIn = args?['isSignIn'] ?? false;
      return PhoneNumber(
        updatePhoneNumber: false,
        isSignIn: isSignIn,
      );
    },
    RouteName.searchLocationpage: (context) => const SearchLocation(),
    RouteName.updateLocationScreen: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args == null || args is! Map<dynamic, dynamic>) {
        return const Scaffold(body: Center(child: Text('Invalid route')));
      }
      return UpdateLocation(selectedLocation: args);
    },
    RouteName.chatPageScreen: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args == null || args is! Map) {
        return const Scaffold(body: Center(child: Text('Invalid route')));
      }
      return ChatPage(
        sender: args['sender'],
        chatId: args['chatID'].toString(),
        second: args['second'],
      );
    },
    RouteName.editProfileScreen: (context) => const EditProfileScreen(),
    RouteName.largeImageScreen: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args == null || args is! String) {
        return const Scaffold(body: Center(child: Text('Invalid route')));
      }
      return LargeImage(largeImage: args);
    },
    RouteName.onboarding: (context) => const OnboardingMain(),
    RouteName.mainNavigation: (context) => const MainNavigationScreen(),
    RouteName.updatePhoneScreen: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args == null || args is! UserModel) {
        return const Scaffold(body: Center(child: Text('Invalid route')));
      }
      return UpdateNumber(args);
    },
    RouteName.genderScreen: (context) => const Gender(),
    RouteName.settingPage: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args == null || args is! Map) {
        return const Scaffold(body: Center(child: Text('Invalid route')));
      }
      return SettingPage(
        currentUser: args['currentUser'] as UserModel,
        isPurchased: args['isPurchased'] ?? false,
        items: args['items'] ?? {},
      );
    },
    RouteName.showGenderScreen: (context) => const ShowGender(),
    RouteName.matchPage: (context) => const MatchScreen(),
    RouteName.sexualorientationScreen: (context) => const SexualOrientation(),
    RouteName.universityScreen: (context) => const UniversityPage(),
    // Redirect Dating to Explore since we're removing the Dating tab
    RouteName.datingHomePage: (context) => const ExploreScreen(),
    RouteName.profilePicSetScreen: (context) => const UserProfilePic(),
    RouteName.allowLocationScreen: (context) => const AllowLocation(),
    RouteName.otpScreen: (context) {
      // Safely extract arguments with null checks
      final arguments = ModalRoute.of(context)?.settings.arguments;

      // Validate arguments - if invalid, show loading state instead of navigating away
      // This prevents the "Page Not Found" flash
      if (arguments == null || arguments is! Map) {
        // Return a loading screen instead of trying to navigate back
        // This prevents any flash of "Page Not Found" screen
        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  color: Color(0xFF008037),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading...',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        );
      }

      final argsMap = arguments;

      // Validate required arguments exist
      if (argsMap['verificationId'] == null || argsMap['phoneNumber'] == null) {
        // Missing critical arguments - show error but don't navigate away immediately
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Error'),
            backgroundColor: Colors.white,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Missing verification details',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please try again.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF008037),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return OtpPage(
        codeController: argsMap['codeController']?.toString() ?? '',
        verificationId: argsMap['verificationId']!.toString(),
        phoneNumber: argsMap['phoneNumber']!.toString(),
        updatePhoneNumber: argsMap['updatenumber'] ?? false,
        isLogin: argsMap['isLogin'] ?? false,
      );
    },
    RouteName.userDobScreen: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args == null || args is! Map<String, dynamic>) {
        return const Scaffold(body: Center(child: Text('Invalid route')));
      }
      return UserDOB(args);
    },
    RouteName.userNameScreen: (context) => const UserName(),
    RouteName.nationalityScreen: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args == null || args is! Map<String, dynamic>) {
        return const Scaffold(body: Center(child: Text('Invalid route')));
      }
      return UserNationality(args);
    },
    // Keep legacy route alias for backward compatibility, but route all users
    // through the same canonical onboarding experience.
    RouteName.onboardingFlow: (context) => const OnboardingMain(),
    RouteName.exploreScreen: (context) =>
        const ExploreScreen(), // No back button by default
    RouteName.groupsScreen: (context) => const GroupsScreen(),
    RouteName.groupChatsScreen: (context) => const GroupListScreen(),

    // Settings screens
    RouteName.settingsScreen: (context) => const SettingsScreen(),
    RouteName.blockedUsers: (context) => const BlockedUsersScreen(),
    RouteName.notificationSettings: (context) =>
        const NotificationSettingsScreen(),
    RouteName.safetyCenter: (context) => const SafetyCenterScreen(),
    RouteName.helpCenter: (context) => const HelpCenterScreen(),
    RouteName.feedbackScreen: (context) => const FeedbackScreen(),
    RouteName.languageSettings: (context) => const LanguageSettingsScreen(),
    RouteName.locationSettings: (context) => const LocationSettingsScreen(),
    RouteName.accountDeletion: (context) => const AccountDeletionScreen(),

    // Events routes
    RouteName.eventsScreen: (context) => const EventsScreen(),
    RouteName.eventTemplateSelection: (context) =>
        const EventTemplateSelectionScreen(),
    RouteName.createEvent: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return BlocProvider(
        create: (context) => EventCreationBloc(
          userEventService: UserEventService(),
        ),
        child: CreateEventScreen(
          existingEvent: args?['existingEvent'],
          template: args?['template'],
        ),
      );
    },
    RouteName.myEvents: (context) => const MyEventsScreen(),
    RouteName.eventDetails: (context) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments == null) {
        return const Scaffold(body: Center(child: Text('Invalid route')));
      }

      // Handle both EventModel and EnhancedEventModel
      if (arguments is EnhancedEventModel) {
        return EventDetailsScreen(
          event: EventModel(
            id: arguments.id,
            externalId: arguments.externalId ?? arguments.id,
            name: arguments.name,
            description: arguments.description,
            startDate: arguments.startDate,
            endDate: arguments.endDate,
            imageUrl: arguments.primaryImageUrl.isNotEmpty
                ? arguments.primaryImageUrl
                : null,
            location: arguments.location,
            ticketUrl: arguments.ticketUrl,
            isFree: arguments.isFree,
            ticketPrice: arguments.ticketPrice,
            category: arguments.category,
            tags: arguments.tags,
            attendeeCount: arguments.attendeeCount,
            rsvpCount: arguments.rsvpCount,
            createdAt: arguments.createdAt,
            updatedAt: arguments.updatedAt,
            status: arguments.status,
            createdByUserId: arguments.createdByUserId ?? 'unknown',
          ),
        );
      } else if (arguments is EventModel) {
        return EventDetailsScreen(event: arguments);
      } else {
        // Fallback for any other type - this shouldn't happen but provides safety
        throw ArgumentError(
          'Invalid event type passed to EventDetailsScreen: ${arguments.runtimeType}',
        );
      }
    },

    // User detail route
    RouteName.userDetailScreen: (context) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments == null) {
        return const Scaffold(body: Center(child: Text('Invalid route')));
      }
      if (arguments is UserModel) {
        return UserDetailScreen(user: arguments);
      } else if (arguments is Map && arguments['user'] is UserModel) {
        return UserDetailScreen(
          user: arguments['user'] as UserModel,
          selectedMode: arguments['selectedMode'] as String?,
        );
      } else {
        throw ArgumentError(
          'Invalid user type passed to UserDetailScreen: ${arguments.runtimeType}',
        );
      }
    },
  };

  /// Generate route method for MaterialApp
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final String routeName = settings.name ?? '';

    // Debug logging to help identify route issues
    debugPrint('🔍 Router: Attempting to navigate to route: "$routeName"');

    // Handle Firebase Authentication deep link callbacks silently
    // Firebase phone auth uses /link?deep_link_id=... to redirect back to app after reCAPTCHA
    // The route name includes the full path with query parameters
    if (routeName.startsWith('/link')) {
      debugPrint(
          '✅ Router: Handling Firebase auth callback deep link: $routeName');

      // Simplified check: if route starts with /link and contains deep_link_id, treat as Firebase callback
      // This prevents "Page Not Found" errors - Firebase will handle the callback automatically
      if (routeName.contains('deep_link_id')) {
        debugPrint(
            '✅ Router: Firebase auth callback detected, processing silently');

        // Return a completely transparent route that immediately pops
        // This prevents any visible flash while Firebase processes the callback
        return PageRouteBuilder(
          settings: settings,
          // Make transition instant and transparent
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          opaque: false, // Make route transparent
          pageBuilder: (context, animation, secondaryAnimation) {
            // Return an empty transparent widget that immediately pops
            return const _FirebaseCallbackHandler();
          },
        );
      }
    }

    final WidgetBuilder? builder = allRoutes[routeName];

    if (builder != null) {
      debugPrint('✅ Router: Found route "$routeName", navigating...');
      return MaterialPageRoute(
        builder: (context) {
          try {
            debugPrint('🏗️ Router: Building widget for route "$routeName"');
            final widget = builder(context);
            debugPrint(
                '✅ Router: Widget built successfully for route "$routeName"');
            return widget;
          } catch (e, stackTrace) {
            debugPrint(
                '❌ Router: Error building widget for route "$routeName": $e');
            debugPrint('Stack trace: $stackTrace');
            // Return error widget instead of crashing
            return Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading screen',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Route: $routeName\nError: $e',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        },
        settings: settings,
      );
    }

    debugPrint('❌ Router: Route "$routeName" not found, showing error page');

    // Return a user-friendly error page with navigation options
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Page Not Found'),
          backgroundColor: const Color(0xFF008037),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Color(0xFF008037),
                ),
                const SizedBox(height: 24),
                Text(
                  'Page Not Found',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: const Color(0xFF008037),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'The page you\'re looking for doesn\'t exist.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    // Clear navigation stack and go to welcome
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      RouteName.welcomeScreen,
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Go to Home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008037),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // Clear navigation stack and go to main app
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      RouteName.mainNavigation,
                      (route) => false,
                    );
                  },
                  child: const Text('Go to Main App'),
                ),
              ],
            ),
          ),
        ),
      ),
      settings: settings,
    );
  }
}
