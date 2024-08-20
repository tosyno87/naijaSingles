// ignore_for_file: deprecated_member_use, depend_on_referenced_packages

import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hookup4u2/common/providers/user_provider.dart';
import 'package:hookup4u2/common/routes/route_name.dart';
import 'package:hookup4u2/common/routes/router.dart';
import 'package:hookup4u2/features/auth/facebook_login/facebook_login_bloc.dart';
import 'package:hookup4u2/features/explore/bloc/explore_map_bloc.dart';
import 'package:hookup4u2/features/home/ui/screens/splash.dart';
import 'package:hookup4u2/features/payment/ui/in-app%20purcahse/get%20Products/getproducts_bloc.dart';
import 'package:hookup4u2/features/street_view/bloc/streetviewdata_bloc.dart';
import 'package:hookup4u2/services/location/bloc/userlocation_bloc.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:provider/provider.dart';

import 'common/constants/theme.dart';
import 'common/data/repo/phone_auth_repo.dart';
import 'common/data/repo/user_location_repo.dart';
import 'common/providers/theme_provider.dart';
import 'common/utlis/observer.dart';
import 'features/auth/auth_status/bloc/authstatus_bloc.dart';
import 'features/auth/auth_status/bloc/registration/bloc/registration_bloc.dart';
import 'features/blockUser/bloc/bloc_user_list_bloc.dart';
import 'features/home/bloc/searchuser_bloc.dart';
import 'features/home/bloc/swipebloc_bloc.dart';
import 'features/home/ui/screens/user_filter/bloc/userfilter_bloc.dart';
import 'features/match/bloc/match_bloc.dart';
import 'features/payment/ui/in-app purcahse/buy Products/buyproducts_bloc.dart';
import 'features/report/bloc/report_bloc.dart';
import 'features/user/bloc/update_user_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  MobileAds.instance.initialize();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
    apiKey: 'xxxxxxxxxxxxxxxxxxxxxxxx',
    appId: 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
    messagingSenderId: 'xxxxxxxxxx',
    projectId: 'xxxxxxxxxx',
  ));

  Bloc.observer = SimpleBlocObserver();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ]).then((_) {
    InAppPurchaseAndroidPlatformAddition.enablePendingPurchases();
    runApp(EasyLocalization(
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
        child: ChangeNotifierProvider(
            create: (_) {
              return UserProvider();
            },
            child: const MyHomePage())));
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
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => AuthstatusBloc(
                  phoneAuthRepository:
                      RepositoryProvider.of<PhoneAuthRepository>(context))
                ..add(AuthRequestEvent()),
            ),
            BlocProvider<RegistrationBloc>(
                create: (BuildContext context) => RegistrationBloc(
                    phoneAuthRepository:
                        RepositoryProvider.of<PhoneAuthRepository>(context))),
            BlocProvider<UserBloc>(
                create: (BuildContext context) => UserBloc()),
            BlocProvider<GetInAppProductsBloc>(
                create: (BuildContext context) => GetInAppProductsBloc()),
            BlocProvider<BuyConsumableInAppProductsBloc>(
                create: (BuildContext context) =>
                    BuyConsumableInAppProductsBloc()),
            BlocProvider<UserfilterBloc>(
                create: (BuildContext context) => UserfilterBloc()),
            BlocProvider<SearchUserBloc>(
                create: (BuildContext context) => SearchUserBloc()),
            BlocProvider<SearchUserForMapBloc>(
                create: (BuildContext context) => SearchUserForMapBloc()),
            BlocProvider<StreetviewdataBloc>(
                create: (BuildContext context) => StreetviewdataBloc()),
            BlocProvider<MatchUserBloc>(
                create: (BuildContext context) => MatchUserBloc()),
            BlocProvider<ReportBloc>(
                create: (BuildContext context) => ReportBloc()),
            BlocProvider<SwipeBloc>(
                create: (BuildContext context) => SwipeBloc()),
            BlocProvider<BlocUserListBloc>(
                create: (BuildContext context) => BlocUserListBloc()),
            BlocProvider<UserLocationBloc>(
              create: (context) => UserLocationBloc(
                  userLocationReporistory:
                      RepositoryProvider.of<UserLocationReporistory>(context)),
            ),
            BlocProvider<FacebookLoginBloc>(
              create: (context) => FacebookLoginBloc(),
            ),
          ],
          child: ChangeNotifierProvider(
            create: (context) => ThemeProvider(),
            builder: (context, state) {
              final themeProvider = Provider.of<ThemeProvider>(context);
              return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  themeMode: themeProvider.themeMode,
                  theme: MyThemes.lightTheme,
                  darkTheme: MyThemes.darkTheme,
                  routes: AppRouter.allRoutes,
                  localizationsDelegates: context.localizationDelegates,
                  supportedLocales: context.supportedLocales,
                  locale: context.locale,
                  home: MultiBlocListener(
                      listeners: [
                        BlocListener<AuthstatusBloc, AuthstatusState>(
                            listener: (context, state) {
                          if (state is UnauthenticatedState ||
                              state is AuthFailed) {
                            log("failed called ");
                            Navigator.pushReplacementNamed(
                                context, RouteName.loginScreen);
                          } else if (state is AuthenticatedState) {
                            log("success called ");

                            state.user.getIdToken().then((value) {
                              BlocProvider.of<RegistrationBloc>(context)
                                  .add(CheckRegistration(token: value!));
                            });
                            // for registration
                          }
                        }),
                      ],
                      child: BlocListener<RegistrationBloc, RegistrationStates>(
                          listener: (context, state) {
                            if (state is AlreadyRegistered) {
                              Provider.of<UserProvider>(context, listen: false)
                                  .currentUser = state.user;
                              log("navigate to already");
                              Navigator.pushReplacementNamed(
                                  context, RouteName.tabScreen,
                                  arguments: state.user);
                            } else if (state is NewRegistration) {
                              log("from new registration");
                              Navigator.pushReplacementNamed(
                                  context, RouteName.welcomeScreen);
                            }
                          },
                          child: const Splash())));
            },
          ),
        ));
  }
}
