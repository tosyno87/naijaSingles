// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'common/bloc/language/language_bloc.dart';
import 'common/bloc/theme/theme_bloc.dart';
import 'common/bloc/user/user_bloc.dart';
import 'common/constants/theme.dart';
import 'common/data/repo/phone_auth_repo.dart';
import 'common/routes/route_name.dart';
import 'common/routes/router.dart';
import 'common/utils/observer.dart';
import 'config/secure_config.dart';
import 'features/auth/auth_status/bloc/authstatus_bloc.dart';
import 'features/events/data/services/seed_events_service.dart';
import 'features/notifications/data/services/notification_service.dart';
import 'features/onboarding/bloc/onboarding_bloc.dart';
import 'features/onboarding/data/repositories/onboarding_repository.dart';
// import 'debug/auto_login_service.dart'; // Uncomment if needed for testing
import 'firebase_options.dart';
import 'services/crashlytics_service.dart';
import 'services/secure_storage_service.dart';

Future<void> main() async {
  const bool preserveDebugSessionForE2E =
      bool.fromEnvironment('PRESERVE_DEBUG_SESSION_FOR_E2E');
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Initialize Secure Configuration first
  // Note: In production, .env file may not be bundled - Firebase uses firebase_options.dart
  try {
    await SecureConfig.initialize();
    SecureConfig.validate();
    log('🔒 Secure configuration loaded successfully');
  } on Object catch (e) {
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
  } on Object catch (e) {
    log('❌ Secure storage initialization error: $e');
    // Continue anyway - secure storage will use defaults
  }

  // Initialize Firebase — handle native SDK already having the default app
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    log('🔥 Firebase initialized successfully');
  } on Object catch (e) {
    if (e.toString().contains('duplicate-app')) {
      log('ℹ️ Firebase already initialized by native SDK — using existing app');
    } else {
      log('❌ Firebase initialization error: $e');
    }
  }

  // App Check (non-blocking — failures must not poison Storage)
  try {
    await FirebaseAppCheck.instance.activate(
      // ignore: deprecated_member_use
      appleProvider:
          kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
    );
    log('🛡️ Firebase App Check activated');
  } on Object catch (e) {
    log('⚠️ App Check activation failed (continuing without it): $e');
  }

  // Configure Firebase Auth for iOS Simulator testing
  if (Platform.isIOS && kDebugMode) {
    log('📱 iOS Simulator detected — configure test numbers in Firebase Console');
  }

  // Initialize Crashlytics for crash reporting
  try {
    await CrashlyticsService().initialize();
    log('📊 Crashlytics initialized successfully');
  } on Object catch (e) {
    log('❌ Crashlytics initialization error: $e');
  }

  // Initialize Notification Service (skip in launch harness mode for deterministic startup)
  if (!preserveDebugSessionForE2E) {
    try {
      await NotificationService.initialize();
      log('🔔 Notification Service initialized');
    } on Object catch (e) {
      log('❌ Notification Service initialization error: $e');
    }
  } else {
    log('🧪 Skipping Notification Service initialization for E2E harness');
  }

  // Seed events only in debug mode to prevent fake data in production
  if (kDebugMode) {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final seedService = SeedEventsService();
        await seedService.seedEventsIfEmpty();
        log('🎉 Events seeding completed (debug only)');
      }
    } on Object catch (e) {
      log('⚠️ Events seeding error (debug only): $e');
    }
  }

  // Authentication state will be managed by the app flow

  // Add debug logging for auth state changes and seed events on authentication
  FirebaseAuth.instance.authStateChanges().listen(
    (User? user) {
      log("👤 Auth state changed: ${user?.uid ?? 'No user'}");

      // Update Crashlytics user identifier
      if (user != null) {
        unawaited(CrashlyticsService().setUserId(user.uid));
      } else {
        unawaited(CrashlyticsService().clearUserId());
      }

      if (kDebugMode && user != null) {
        unawaited(
          SeedEventsService().seedEventsIfEmpty().then((_) {
            log('🎉 Events seeding completed (debug only, after auth)');
          }).catchError((e) {
            log('⚠️ Events seeding error (debug only): $e');
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
  } on Object catch (e) {
    log('⚠️ Auto-login error: $e');
  }
  */

  // Ensure clean start: Sign out any existing authenticated user
  // This ensures new builds start with no user authenticated
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && kDebugMode && !preserveDebugSessionForE2E) {
      log('🧹 Signing out existing user for clean start: ${currentUser.uid}');
      await FirebaseAuth.instance.signOut();
      log('✅ Signed out - app will start with no authenticated user');
    } else if (currentUser != null &&
        kDebugMode &&
        preserveDebugSessionForE2E) {
      log('🧪 Preserving debug auth session for E2E harness: ${currentUser.uid}');
    }
  } on Object catch (e) {
    log('⚠️ Error signing out existing user: $e');
  }

  Bloc.observer = SimpleBlocObserver();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ]);
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
        child: BlocProvider<OnboardingBloc>(
          create: (context) => OnboardingBloc(
            repository: OnboardingRepository(),
            userBloc: context.read<UserBloc>(),
          ),
          child: const MyApp(),
        ),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Global navigator key for notification navigation
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // Set navigator key for notification service
    NotificationService.navigatorKey = navigatorKey;

    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        // Get theme mode from BLoC state
        final isDarkMode = themeState is ThemeLoaded &&
            themeState.isDarkMode; // Default to light mode if not loaded

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
