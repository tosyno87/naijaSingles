import 'package:flutter/material.dart';
import 'package:naijasingles/common/routes/route_name.dart';
import 'package:naijasingles/common/utils/large_image.dart';
import 'package:naijasingles/features/auth/phone/ui/screens/phone_number.dart';
import 'package:naijasingles/features/auth/phone/ui/screens/update_phonenumber.dart';
import 'package:naijasingles/features/auth/welcome/welcome_screen.dart';
import 'package:naijasingles/features/auth/email_password/ui/screens/email_signup_screen.dart';
import 'package:naijasingles/features/auth/email_password/ui/screens/email_login_screen.dart';
import 'package:naijasingles/features/auth/email_password/ui/screens/email_password_reset_screen.dart';
import 'package:naijasingles/features/explore/explore_screen.dart';
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
import 'package:naijasingles/models/user_model.dart';
import '../../features/home/ui/screens/user_filter/settings.dart';
import 'package:naijasingles/features/user/ui/screens/user_dob.dart';
import 'package:naijasingles/features/user/ui/screens/user_gender.dart';
import 'package:naijasingles/features/user/ui/screens/user_name.dart';
import '../../features/auth/phone/ui/screens/otp_page.dart';
import '../../features/home/ui/screens/splash.dart';

abstract class AppRouter {
  // register here for routes
  static Map<String, WidgetBuilder> allRoutes = {
    RouteName.splashScreen: (context) => const Splash(),
    RouteName.loginScreen: (context) =>
        const EmailLoginScreen(), // Redirect to EmailLoginScreen
    RouteName.tabScreen: (context) => const Tabbar("active", false),
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
    RouteName.phoneNumberScreen: (context) => PhoneNumber(
          updatePhoneNumber: false,
        ),
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
    RouteName.welcomeScreen: (context) => const WelcomeScreen(),
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
    RouteName.otpScreen: (context) => OtpPage(
        codeController: (ModalRoute.of(context)!.settings.arguments
                as Map)['codeController']
            .toString(),
        verificationId: (ModalRoute.of(context)!.settings.arguments
                as Map)['verificationId']
            .toString(),
        phoneNumber:
            (ModalRoute.of(context)!.settings.arguments as Map)['phoneNumber']
                .toString(),
        updatePhoneNumber:
            (ModalRoute.of(context)!.settings.arguments as Map)['updatenumber'],
        isLogin:
            (ModalRoute.of(context)!.settings.arguments as Map)['isLogin'] ??
                false),
    RouteName.userDobScreen: (context) => UserDOB(
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>),
    RouteName.userNameScreen: (context) => const UserName(),
    RouteName.nationalityScreen: (context) => UserNationality(
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>),
    RouteName.onboardingFlow: (context) => const OnboardingFlow(),
    RouteName.exploreScreen: (context) =>
        const ExploreScreen(showBackButton: false), // No back button by default

    // Settings screens
    RouteName.blockedUsers: (context) => const BlockedUsersScreen(),
    RouteName.notificationSettings: (context) => const NotificationSettingsScreen(),

    // Main navigation routes (consolidated - removed duplicates)
    RouteName.mainNavigation: (context) => const MainNavigationScreen(),
    RouteName.onboarding: (context) => const OnboardingMain(),
    RouteName.home: (context) => const Tabbar("active", false),
    RouteName.discover: (context) => const Tabbar("discover", false),
  };

  /// Generate route method for MaterialApp
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final String routeName = settings.name ?? '';
    final WidgetBuilder? builder = allRoutes[routeName];

    if (builder != null) {
      return MaterialPageRoute(
        builder: builder,
        settings: settings,
      );
    }

    // Return a default route if the route is not found
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Page Not Found')),
        body: Center(
          child: Text('Route "$routeName" not found'),
        ),
      ),
      settings: settings,
    );
  }
}
