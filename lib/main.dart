// ignore_for_file: deprecated_member_use, depend_on_referenced_packages

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'common/bloc/language/language_bloc.dart';
import 'common/bloc/streetview/streetview_bloc.dart';
import 'common/bloc/theme/theme_bloc.dart';
import 'common/bloc/user/user_bloc.dart';
import 'common/constants/theme.dart';
import 'common/data/repo/phone_auth_repo.dart';
import 'common/providers/language_provide.dart';
import 'common/providers/street_view_provider.dart';
import 'common/providers/user_provider.dart';
import 'common/routes/route_name.dart';
import 'common/routes/router.dart';
import 'common/utils/observer.dart';
import 'config/secure_config.dart';
import 'features/auth/auth_status/bloc/authstatus_bloc.dart';
import 'features/events/data/services/seed_events_service.dart';
import 'features/user/controllers/onboarding_controller.dart';
// import 'debug/auto_login_service.dart'; // Uncomment if needed for testing
import 'firebase_options.dart';
import 'features/notifications/data/services/notification_service.dart';
import 'services/secure_storage_service.dart';
import 'services/crashlytics_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Initialize Secure Configuration first
  // Note: In production, .env file may not be bundled - Firebase uses firebase_options.dart
  try {
    await SecureConfig.initialize();
    SecureConfig.validate();
    log('🔒 Secure configuration loaded successfully');
  } catch (e) {
    log('❌ Secure configuration error: $e');
    if (kDebugMode) {
      log('💡 Make sure you have created a .env file with your Firebase configuration');
    } else {
      log('⚠️ .env file not available in production - Firebase will use firebase_options.dart');
    }
    // Continue anyway - Firebase initialization will use firebase_options.dart
  }

  // Initialize Secure Storage Service
  try {
    await SecureStorageService().initialize();
    log('🔐 Secure storage service initialized successfully');
  } catch (e) {
    log('❌ Secure storage initialization error: $e');
    // Continue anyway - secure storage will use defaults
  }

  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    log('🔥 Firebase initialized successfully');

    // Configure Firebase Auth for iOS Simulator testing
    if (Platform.isIOS && kDebugMode) {
      // Disable app verification for testing on iOS Simulator
      // This allows phone auth to work without real SMS
      // IMPORTANT: Only use test phone numbers from Firebase Console
      // Go to: Firebase Console > Authentication > Sign-in method > Phone > Phone numbers for testing
      try {
        // Note: Flutter doesn't have direct access to Auth.auth().settings
        // Instead, we'll handle this in the phone auth repository
        log('📱 iOS Simulator detected - Test phone numbers should be configured in Firebase Console');
        log('💡 Configure test numbers at: Firebase Console > Auth > Sign-in method > Phone > Test phone numbers');
      } catch (e) {
        log('⚠️ Could not configure simulator settings: $e');
      }
    }

    // Initialize Crashlytics for crash reporting
    try {
      await CrashlyticsService().initialize();
      log('📊 Crashlytics initialized successfully');
    } catch (e) {
      log('❌ Crashlytics initialization error: $e');
      // Continue anyway - app should work without Crashlytics
    }

    // Initialize Notification Service
    await NotificationService.initialize();
    log('🔔 Notification Service initialized');

    // Initialize seed events if database is empty (only if user is authenticated)
    // Events seeding requires authentication per Firestore security rules
    // This will be handled after user login in UserProvider or similar
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final seedService = SeedEventsService();
        await seedService.seedEventsIfEmpty();
        log('🎉 Events seeding completed');
      } else {
        log('⏭️ Skipping events seeding - no authenticated user (expected at app startup)');
      }
    } catch (e) {
      // Silently skip if permission denied (expected when no user is authenticated)
      if (e.toString().contains('permission-denied')) {
        log('⏭️ Skipping events seeding - requires authentication (expected)');
      } else {
        log('⚠️ Events seeding error: $e');
      }
    }
  } catch (e) {
    log('❌ Firebase initialization error: $e');
  }

  // Authentication state will be managed by the app flow

  // Add debug logging for auth state changes and seed events on authentication
  FirebaseAuth.instance.authStateChanges().listen(
    (User? user) {
      log("👤 Auth state changed: ${user?.uid ?? 'No user'}");
      
      // Update Crashlytics user identifier
      if (user != null) {
        CrashlyticsService().setUserId(user.uid);
      } else {
        CrashlyticsService().clearUserId();
      }

      // Seed events when user authenticates (seedEventsIfEmpty checks if events exist, so safe to call multiple times)
      if (user != null) {
        // Use unawaited to properly handle the future without blocking the stream listener
        unawaited(
          SeedEventsService().seedEventsIfEmpty().then((_) {
            log('🎉 Events seeding completed (after authentication)');
          }).catchError((e) {
            // Silently skip if permission denied (shouldn't happen when authenticated, but handle gracefully)
            if (e.toString().contains('permission-denied')) {
              log('⚠️ Events seeding failed - permission denied (unexpected for authenticated user)');
            } else {
              log('⚠️ Events seeding error: $e');
            }
          }),
        );
      }
    },
    onError: (error) {
      log('❌ Auth state error: $error');
    },
  );

  // Auto-login for testing in debug mode
  // DISABLED: Commented out to ensure clean start with no authenticated user
  // Uncomment below if you need auto-login for testing purposes
  /*
  try {
    await AutoLoginService.autoLoginForTesting();
  } catch (e) {
    log('⚠️ Auto-login error: $e');
  }
  */

  // Ensure clean start: Sign out any existing authenticated user
  // This ensures new builds start with no user authenticated
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && kDebugMode) {
      log('🧹 Signing out existing user for clean start: ${currentUser.uid}');
      await FirebaseAuth.instance.signOut();
      log('✅ Signed out - app will start with no authenticated user');
    }
  } catch (e) {
    log('⚠️ Error signing out existing user: $e');
  }

  Bloc.observer = SimpleBlocObserver();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ]).then((_) {
    runApp(
      EasyLocalization(
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('es', 'ES'),
          Locale('fr', 'FR'),
          Locale('pt', 'PT'),
          Locale('ar', 'SA'),
          Locale('hi', 'IN'),
          Locale('zh', 'CN'),
          Locale('ja', 'JP'),
          Locale('ko', 'KR'),
          Locale('de', 'DE'),
          Locale('it', 'IT'),
          Locale('ru', 'RU'),
          Locale('tr', 'TR'),
          Locale('nl', 'NL'),
          Locale('sv', 'SE'),
          Locale('da', 'DK'),
          Locale('no', 'NO'),
          Locale('fi', 'FI'),
          Locale('pl', 'PL'),
          Locale('cs', 'CZ'),
          Locale('hu', 'HU'),
          Locale('ro', 'RO'),
          Locale('bg', 'BG'),
          Locale('hr', 'HR'),
          Locale('sk', 'SK'),
          Locale('sl', 'SI'),
          Locale('et', 'EE'),
          Locale('lv', 'LV'),
          Locale('lt', 'LT'),
          Locale('uk', 'UA'),
          Locale('he', 'IL'),
          Locale('th', 'TH'),
          Locale('vi', 'VN'),
          Locale('id', 'ID'),
          Locale('ms', 'MY'),
          Locale('tl', 'PH'),
        ],
        path: 'asset/translation',
        fallbackLocale: const Locale('en', 'US'),
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthstatusBloc>(
              create: (context) => AuthstatusBloc(
                phoneAuthRepository: PhoneAuthRepository(),
              ),
            ),
            BlocProvider<UserBloc>(
              create: (context) => UserBloc(),
            ),
            BlocProvider<ThemeBloc>(
              create: (context) => ThemeBloc(),
            ),
            BlocProvider<LanguageBloc>(
              create: (context) => LanguageBloc(),
            ),
          ],
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => UserProvider()),
              ChangeNotifierProvider(create: (_) => OnboardingController()),
            ],
            child: const MyApp(),
          ),
        ),
      ),
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Global navigator key for notification navigation
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // Set navigator key for notification service
    NotificationService.setNavigatorKey(navigatorKey);

    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        // Get theme mode from BLoC state
        final isDarkMode = themeState is ThemeLoaded
            ? themeState.isDarkMode
            : false; // Default to light mode if not loaded

        return MaterialApp(
          navigatorKey: navigatorKey, // Add navigator key
          title: 'Afropeep',
          debugShowCheckedModeBanner: false,
          theme: isDarkMode ? MyThemes.darkTheme : MyThemes.lightTheme,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          initialRoute: RouteName
              .welcomeScreen, // Direct to WelcomeScreen - no splash flash
          onGenerateRoute: AppRouter.generateRoute,
          // Add safety check for Navigator during hot reload
          builder: (context, child) {
            // Ensure Navigator has proper state during hot reload
            if (child == null) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return child;
          },
        );
      },
    );
  }
}
