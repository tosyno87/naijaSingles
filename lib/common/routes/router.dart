import 'package:flutter/material.dart';
import 'package:naijasingles/common/routes/route_name.dart';
import 'package:naijasingles/common/utils/large_image.dart';
import 'package:naijasingles/features/auth/phone/ui/screens/phone_number.dart';
import 'package:naijasingles/features/auth/phone/ui/screens/update_phonenumber.dart';
import 'package:naijasingles/features/auth/welcome/welcome_screen.dart';
import 'package:naijasingles/features/home/ui/screens/splash.dart';
import 'package:naijasingles/features/auth/email_password/ui/screens/email_signup_screen.dart';
import 'package:naijasingles/features/auth/email_password/ui/screens/email_login_screen.dart';
import 'package:naijasingles/features/auth/email_password/ui/screens/email_password_reset_screen.dart';
import 'package:naijasingles/features/explore/explore_screen.dart';
import 'package:naijasingles/features/groups/ui/screens/groups_screen.dart';
import 'package:naijasingles/features/group_chat/screens/group_list_screen.dart';
import 'package:naijasingles/features/home/main_navigation_screen.dart';
import 'package:naijasingles/features/onboarding/onboarding_main.dart';
import 'package:naijasingles/features/profile/edit_profile_screen.dart';
import 'package:naijasingles/features/chat/ui/screens/chat_page.dart';
import 'package:naijasingles/features/home/ui/tab/tabbar.dart';
import 'package:naijasingles/features/match/ui/screen/match_page.dart';
import 'package:naijasingles/features/user/ui/screens/onboarding_flow.dart';
import 'package:naijasingles/features/user/ui/screens/show_gender.dart';
import 'package:naijasingles/features/user/ui/screens/update_user_location.dart';
import 'package:naijasingles/features/user/ui/screens/user_location.dart';
import 'package:naijasingles/features/user/ui/screens/user_nationality.dart';
import 'package:naijasingles/features/user/ui/screens/user_profile.dart';
import 'package:naijasingles/features/user/ui/screens/user_profile_pic_set.dart';
import 'package:naijasingles/features/user/ui/screens/user_search_location.dart';
import 'package:naijasingles/features/user/ui/screens/user_sexual_details.dart';
import 'package:naijasingles/features/user/ui/screens/user_university.dart';
import 'package:naijasingles/features/auth/auth_method/auth_method_selection_screen.dart';
import 'package:naijasingles/features/auth/auth_method/sign_in_method_selection_screen.dart';
import 'package:naijasingles/features/settings/blocked_users_screen.dart';
import 'package:naijasingles/features/settings/notification_settings_screen.dart';
import 'package:naijasingles/features/settings/safety_center_screen.dart';
import 'package:naijasingles/features/settings/help_center_screen.dart';
import 'package:naijasingles/features/settings/feedback_screen.dart';
import 'package:naijasingles/features/settings/language_settings_screen.dart';
import 'package:naijasingles/features/settings/location_settings_screen.dart';
import 'package:naijasingles/features/settings/account_deletion_screen.dart';
import 'package:naijasingles/features/profile/settings_screen.dart';
import 'package:naijasingles/models/user_model.dart';
import '../../features/home/ui/screens/user_filter/settings.dart';
import 'package:naijasingles/features/events/presentation/screens/events_screen.dart';
import 'package:naijasingles/features/events/presentation/screens/event_template_selection_screen.dart';
import 'package:naijasingles/features/events/data/models/enhanced_event_model.dart';
import 'package:naijasingles/features/events/data/models/event_model.dart';
import 'package:naijasingles/features/events/presentation/screens/create_event_screen.dart';
import 'package:naijasingles/features/events/presentation/screens/my_events_screen.dart';
import 'package:naijasingles/features/events/presentation/screens/event_details_screen.dart';
import 'package:naijasingles/features/events/presentation/bloc/event_creation_bloc.dart';
import 'package:naijasingles/features/events/data/services/user_event_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:naijasingles/features/user/ui/screens/user_dob.dart';
import 'package:naijasingles/features/user/ui/screens/user_gender.dart';
import 'package:naijasingles/features/user/ui/screens/user_name.dart';
import 'package:naijasingles/features/dating/screens/user_detail_screen.dart';
import '../../features/auth/phone/ui/screens/otp_page.dart';

abstract class AppRouter {
  // register here for routes
  static Map<String, WidgetBuilder> allRoutes = {
    // Root route - redirect to welcome (splash removed to eliminate flash)
    '/': (context) => const WelcomeScreen(),
    RouteName.splashScreen: (context) => const Splash(),
    RouteName.welcomeScreen: (context) {
      debugPrint('🎯 WelcomeScreen route builder called');
      try {
        final widget = const WelcomeScreen();
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
    RouteName.profileScreen: (context) => ProfilePage(
          isPuchased:
              (ModalRoute.of(context)!.settings.arguments as Map)['isPuchased'],
          items: (ModalRoute.of(context)!.settings.arguments as Map)['items'],
          purchases:
              (ModalRoute.of(context)!.settings.arguments as Map)['purchases'],
        ),
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
    RouteName.updateLocationScreen: (context) => UpdateLocation(
        selectedLocation: ModalRoute.of(context)!.settings.arguments
            as Map<dynamic, dynamic>),
    RouteName.chatPageScreen: (context) => ChatPage(
        sender: (ModalRoute.of(context)!.settings.arguments as Map)['sender'],
        chatId: (ModalRoute.of(context)!.settings.arguments as Map)['chatID']
            .toString(),
        second: (ModalRoute.of(context)!.settings.arguments as Map)['second']),
    RouteName.editProfileScreen: (context) => const EditProfileScreen(),
    RouteName.largeImageScreen: (context) => LargeImage(
        largeImage: ModalRoute.of(context)!.settings.arguments as String),
    RouteName.onboarding: (context) => const OnboardingMain(),
    RouteName.mainNavigation: (context) => const MainNavigationScreen(),
    RouteName.updatePhoneScreen: (context) =>
        UpdateNumber(ModalRoute.of(context)!.settings.arguments as UserModel),
    RouteName.genderScreen: (context) => const Gender(),
    RouteName.settingPage: (context) => SettingPage(
          currentUser: (ModalRoute.of(context)!.settings.arguments
              as Map)['currentUser'] as UserModel,
          isPurchased: (ModalRoute.of(context)!.settings.arguments
              as Map)['isPurchased'],
          items: (ModalRoute.of(context)!.settings.arguments as Map)['items'],
        ),
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
      
      if (arguments == null || arguments is! Map) {
        // If arguments are missing, navigate back to prevent "Page Not Found"
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error: Missing verification details. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
        // Return a placeholder while we navigate away
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      
      final argsMap = arguments as Map;
      
      return OtpPage(
        codeController: (argsMap['codeController']?.toString() ?? ''),
        verificationId: (argsMap['verificationId']?.toString() ?? ''),
        phoneNumber: (argsMap['phoneNumber']?.toString() ?? ''),
        updatePhoneNumber: argsMap['updatenumber'] ?? false,
        isLogin: argsMap['isLogin'] ?? false,
      );
    },
    RouteName.userDobScreen: (context) => UserDOB(
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>),
    RouteName.userNameScreen: (context) => const UserName(),
    RouteName.nationalityScreen: (context) => UserNationality(
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>),
    RouteName.onboardingFlow: (context) => const OnboardingFlow(),
    RouteName.exploreScreen: (context) =>
        const ExploreScreen(showBackButton: false), // No back button by default
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
      final arguments = ModalRoute.of(context)!.settings.arguments;

      // Handle both EventModel and EnhancedEventModel
      if (arguments is EnhancedEventModel) {
        return EventDetailsScreen(event: arguments.toEventModel());
      } else if (arguments is EventModel) {
        return EventDetailsScreen(event: arguments);
      } else {
        // Fallback for any other type - this shouldn't happen but provides safety
        throw ArgumentError(
            'Invalid event type passed to EventDetailsScreen: ${arguments.runtimeType}');
      }
    },

    // User detail route
    RouteName.userDetailScreen: (context) {
      final arguments = ModalRoute.of(context)!.settings.arguments;
      if (arguments is UserModel) {
        return UserDetailScreen(user: arguments);
      } else if (arguments is Map && arguments['user'] is UserModel) {
        return UserDetailScreen(
          user: arguments['user'] as UserModel,
          selectedMode: arguments['selectedMode'] as String?,
        );
      } else {
        throw ArgumentError(
            'Invalid user type passed to UserDetailScreen: ${arguments.runtimeType}');
      }
    },
  };

  /// Generate route method for MaterialApp
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final String routeName = settings.name ?? '';

    // Debug logging to help identify route issues
    debugPrint('🔍 Router: Attempting to navigate to route: "$routeName"');

    final WidgetBuilder? builder = allRoutes[routeName];

    if (builder != null) {
      debugPrint('✅ Router: Found route "$routeName", navigating...');
      return MaterialPageRoute(
        builder: (context) {
          try {
            debugPrint('🏗️ Router: Building widget for route "$routeName"');
            final widget = builder(context);
            debugPrint('✅ Router: Widget built successfully for route "$routeName"');
            return widget;
          } catch (e, stackTrace) {
            debugPrint('❌ Router: Error building widget for route "$routeName": $e');
            debugPrint('Stack trace: $stackTrace');
            // Return error widget instead of crashing
            return Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
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
            padding: const EdgeInsets.all(24.0),
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
