// ignore_for_file: deprecated_member_use, depend_on_referenced_packages

import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:naijasingles/common/providers/user_provider.dart';
import 'package:naijasingles/common/routes/route_name.dart';
import 'package:naijasingles/common/routes/router.dart';
import 'package:naijasingles/features/user/controllers/onboarding_controller.dart';
import 'package:naijasingles/services/enhanced_notification_service.dart';
import 'package:naijasingles/features/events/data/services/seed_events_service.dart';
import 'package:provider/provider.dart';

import 'common/constants/theme.dart';
import 'common/data/repo/phone_auth_repo.dart';
import 'common/providers/theme_provider.dart';
import 'common/utils/observer.dart';
import 'features/auth/auth_status/bloc/authstatus_bloc.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    log('🔥 Firebase initialized successfully');

    // Initialize Enhanced Notification Service
    await EnhancedNotificationService.initialize();
    log('🔔 Enhanced Notification Service initialized');

    // Initialize seed events if database is empty
    try {
      final seedService = SeedEventsService();
      await seedService.seedEventsIfEmpty();
      log('🎉 Events seeding completed');
    } catch (e) {
      log('⚠️ Events seeding error: $e');
    }
  } catch (e) {
    log('❌ Firebase initialization error: $e');
  }

  // Authentication state will be managed by the app flow

  // Add debug logging for auth state changes
  FirebaseAuth.instance.authStateChanges().listen(
    (User? user) {
      log("👤 Auth state changed: ${user?.uid ?? 'No user'}");
    },
    onError: (error) {
      log("❌ Auth state error: $error");
    },
  );

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
          ],
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ThemeProvider()),
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
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // Set navigator key for notification service
    EnhancedNotificationService.setNavigatorKey(navigatorKey);
    
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey, // Add navigator key
          title: 'Afropeep',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.isDarkMode
              ? MyThemes.darkTheme
              : MyThemes.lightTheme,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          initialRoute: RouteName.welcomeScreen,
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
