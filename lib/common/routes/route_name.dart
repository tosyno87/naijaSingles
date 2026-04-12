class RouteName {
  // ===== CORE APP ROUTES =====
  static const String welcomeScreen = '/welcome';
  static const String mainNavigation = '/main_navigation';
  static const String onboarding = '/onboarding';

  // ===== AUTHENTICATION ROUTES =====
  static const String authMethodSelection = '/auth_method_selection';
  static const String signInMethodSelection = '/sign_in_method_selection';
  static const String emailSignup = '/email_signup';
  static const String emailLogin = '/email_login';
  static const String emailPasswordReset = '/email_password_reset';
  static const String phoneNumberScreen = '/phone_number';
  static const String otpScreen = '/otp';

  // ===== PROFILE & USER ROUTES =====
  static const String profileScreen = '/profile';
  static const String editProfileScreen = '/edit_profile';
  static const String culturalProfile = '/cultural_profile';
  static const String profilePicSetScreen = '/user_pic';
  static const String largeImageScreen = '/large_image';

  // ===== ONBOARDING ROUTES =====
  static const String genderScreen = '/gender';
  static const String showGenderScreen = '/showgender';
  static const String userNameScreen = '/user_name';
  static const String userDobScreen = '/user_dob';
  static const String nationalityScreen = '/nationality';
  static const String universityScreen = '/user_university';
  static const String allowLocationScreen = '/allow_userLocation';
  static const String searchLocationpage = '/search';
  static const String updateLocationScreen = '/updatelocation';

  // ===== DISCOVERY & MATCHING ROUTES =====
  static const String exploreScreen = '/explore';
  static const String groupsScreen = '/groups';
  static const String groupChatsScreen = '/group_chats';
  static const String matchPage = '/match';
  static const String chatPageScreen = '/chat_page';
  static const String userDetailScreen = '/user_detail';

  // ===== SETTINGS ROUTES =====
  static const String settingPage = '/setting';
  static const String settingsScreen = '/settings';
  static const String blockedUsers = '/blocked_users';
  static const String notificationSettings = '/notification_settings';
  static const String safetyCenter = '/safety_center';
  static const String helpCenter = '/help_center';
  static const String languageSettings = '/language_settings';
  static const String accountDeletion = '/account_deletion';
  static const String feedbackScreen = '/feedback';
  static const String updatePhoneScreen = '/update_number';
  static const String phoneEmailSettings = '/settings_phone_email';
  static const String connectedAccountsSettings = '/settings_connected_accounts';
  static const String emailNotificationsSettings = '/settings_email_notifications';
  static const String downloadMyData = '/settings_download_my_data';

  // ===== EVENTS ROUTES =====
  static const String eventsScreen = '/events';
  static const String eventTemplateSelection = '/event-template-selection';
  static const String myEvents = '/my_events';
  static const String createEvent = '/create_event';
  static const String eventDetails = '/event_details';

  // ===== LEGACY ROUTES (for backward compatibility) =====
  static const String splashScreen = '/splash';
  static const String loginScreen = '/login';
  static const String tabScreen = '/tabbar';
  static const String datingHomePage = '/dating';

  /// Legacy onboarding route alias. Redirects to [onboarding].
  static const String onboardingFlow = '/onboarding_flow';
  static const String mvpOnboarding = '/mvp_onboarding';
  static const String home = '/home';
  static const String discover = '/discover';
}
