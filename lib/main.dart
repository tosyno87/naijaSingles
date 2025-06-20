// ignore_for_file: deprecated_member_use, depend_on_referenced_packages

import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:naijasingles/common/providers/user_provider.dart';
import 'package:naijasingles/common/routes/route_name.dart';
import 'package:naijasingles/common/routes/router.dart';
import 'package:naijasingles/features/auth/facebook_login/facebook_login_bloc.dart';
import 'package:naijasingles/features/auth/google_login/google_login_bloc.dart';
import 'package:naijasingles/features/explore/bloc/explore_map_bloc.dart';
import 'package:naijasingles/features/home/ui/screens/splash.dart';
import 'package:naijasingles/features/payment/ui/in_app_purchase/buy_products/buyproducts_bloc.dart';
import 'package:naijasingles/features/payment/ui/in_app_purchase/get_products/getproducts_bloc.dart';
import 'package:naijasingles/features/street_view/bloc/streetviewdata_bloc.dart';
import 'package:naijasingles/features/user/controllers/onboarding_controller.dart';
import 'package:naijasingles/services/location/bloc/userlocation_bloc.dart';
import 'package:provider/provider.dart';

import 'common/constants/theme.dart';
import 'common/data/repo/phone_auth_repo.dart';
import 'common/data/repo/user_location_repo.dart';
import 'common/data/repo/user_messaging_repo.dart';
import 'common/data/repo/user_search_repo.dart';
import 'common/providers/theme_provider.dart';
import 'common/utils/observer.dart';
import 'features/auth/auth_status/bloc/authstatus_bloc.dart';
import 'features/auth/auth_status/bloc/registration/bloc/registration_bloc.dart';
import 'features/blockUser/bloc/bloc_user_list_bloc.dart';
import 'features/home/bloc/searchuser_bloc.dart';
import 'features/home/bloc/swipebloc_bloc.dart';
import 'features/home/ui/screens/user_filter/bloc/userfilter_bloc.dart';
import 'features/match/bloc/match_bloc.dart';
import 'features/report/bloc/report_bloc.dart';
import 'features/user/bloc/update_user_bloc.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  
  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    log("🔥 Firebase initialized successfully");
  } catch (e) {
    log("❌ Error initializing Firebase: $e");
  }
  
  // Reset authentication state for testing
  try {
    await FirebaseAuth.instance.signOut();
    log("🔄 Reset authentication state");
  } catch (e) {
    log("⚠️ Error resetting auth state: $e");
  }
  
  // Add debug logging for auth state changes
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    log("👤 Auth state changed: ${user?.uid ?? 'No user'}");
  });

  // Set up error handling for Firebase Auth
  FirebaseAuth.instance.authStateChanges().listen(
    (User? user) {
      log("Auth state changed: ${user?.uid ?? 'No user'}");
    },
    onError: (error) {
      log("Auth state error: $error");
    },
  );

  Bloc.observer = SimpleBlocObserver();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ]).then((_) {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: EasyLocalization(
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('es', 'ES'),
            Locale('fr', 'FR'),
            Locale('de', 'DE'),
            Locale('ru', 'RU'),
            Locale('hi', 'IN')
          ],
          saveLocale: true,
          path: 'asset/translation',
          child: const MyHomePage(),
        ),
      ),
    );
  });
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
        create: (context) => PhoneAuthRepository(),
        child: MultiProvider(
          providers: [
            // Add the OnboardingController provider here
            ChangeNotifierProvider<OnboardingController>(
              create: (_) => OnboardingController(),
            ),
            // User provider
            ChangeNotifierProvider<UserProvider>(
              create: (_) => UserProvider(),
            ),
            // Theme provider is already added at the app level
          ],
          child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => AuthstatusBloc(
                  phoneAuthRepository:
                      RepositoryProvider.of<PhoneAuthRepository>(context))
                ..add(AuthRequestEvent()),
            ),
            BlocProvider(
              create: (context) => RegistrationBloc(
                  phoneAuthRepository:
                      RepositoryProvider.of<PhoneAuthRepository>(context)),
            ),
            BlocProvider(
              create: (context) => FacebookLoginBloc(),
            ),
            BlocProvider(
              create: (context) => GoogleLoginBloc(),
            ),
            BlocProvider(
              create: (context) => SwipeBloc(
                leftSwipe: UserSearchRepo.leftSwipe,
                rightSwipe: UserSearchRepo.rightSwipe,
                getUserList: UserSearchRepo.getUserList,
              ),
            ),
            BlocProvider(
              create: (context) => SearchUserBloc(),
            ),
            BlocProvider(
              create: (context) => UserfilterBloc(),
            ),
            BlocProvider(
              create: (context) => MatchUserBloc(
                getMatches: UserMessagingRepo.getMatches,
              ),
            ),
            BlocProvider(
              create: (context) => BlocUserListBloc(),
            ),
            BlocProvider(
              create: (context) => ReportBloc(),
            ),
            BlocProvider(
              create: (context) => UserBloc(),
            ),
            BlocProvider(
              create: (context) => UserLocationBloc(
                  userLocationReporistory: UserLocationReporistoryImpl()),
            ),
            BlocProvider(
              create: (context) => SearchUserForMapBloc(),
            ),
            BlocProvider(
              create: (context) => StreetviewdataBloc(),
            ),
            BlocProvider(
              create: (context) => GetInAppProductsBloc(),
            ),
            BlocProvider(
              create: (context) => BuyConsumableInAppProductsBloc(),
            ),
          ],
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return MaterialApp(
                title: 'NaijaSingles',
                debugShowCheckedModeBanner: false,
                theme: themeProvider.isDarkMode
                    ? MyThemes.darkTheme
                    : MyThemes.lightTheme,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                routes: AppRouter.allRoutes,
                initialRoute: RouteName.splashScreen,
              );
            },
          ),
        )));
  }
}
