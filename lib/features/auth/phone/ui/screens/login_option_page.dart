import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookup4u2/common/providers/theme_provider.dart';
import 'package:hookup4u2/common/routes/route_name.dart';
import 'package:hookup4u2/features/auth/phone/ui/widgets/facebook_button.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../../../common/constants/colors.dart';
import '../../../../../common/providers/user_provider.dart';
import '../../../../../common/utlis/app_exit.dart';
import '../../../../../common/widets/custom_snackbar.dart';
import '../../../auth_status/bloc/registration/bloc/registration_bloc.dart';
import '../../../facebook_login/facebook_login_bloc.dart';
import '../../../facebook_login/facebook_login_events.dart';
import '../../../facebook_login/facebook_login_states.dart';
import '../widgets/privacy_policy.dart';
import '../widgets/wave_clipper.dart';

class LoginOption extends StatefulWidget {
  const LoginOption({super.key});

  @override
  State<LoginOption> createState() => _LoginOptionState();
}

class _LoginOptionState extends State<LoginOption> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          return;
        }
        final bool shouldPop = await onWillPop(context);
        if (shouldPop) {
          SystemChannels.platform.invokeMethod('SystemNavigator.pop');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          automaticallyImplyLeading: false,
          elevation: 0,
        ),
        backgroundColor: Theme.of(context).primaryColor,
        body: MultiBlocListener(
          listeners: [
            BlocListener<FacebookLoginBloc, FacebookLoginStates>(
              listener: (context, state) {
                if (state is FacebookLoginLoading) {
                  CustomSnackbar.showSnackBarSimple(
                      'Please wait. Loading..'.tr().toString(), context);
                }

                if (state is FacebookLoginFailed) {
                  CustomSnackbar.showSnackBarSimple(state.message, context);
                }

                if (state is FacebookLoginSuccess) {
                  log("Success called facebook");
                  state.user?.getIdToken().then((value) async {
                    // call registration after facebook_login
                    log("Success called facebook with $value");
                    context
                        .read<RegistrationBloc>()
                        .add(CheckRegistration(token: value!));
                  });
                }
              },
            ),
            BlocListener<RegistrationBloc, RegistrationStates>(
              listener: (context, state) {
                if (state is RegistrationLoading) {
                  CustomSnackbar.showSnackBarSimple(
                      'Please wait. Loading..'.tr().toString(), context);
                }
                if (state is AlreadyRegistered) {
                  // log("state user ${state.user}");
                  Provider.of<UserProvider>(context, listen: false)
                      .currentUser = state.user;
                  UserProvider().listenAuthChanges();
                  Navigator.of(context)
                      .pushNamed(RouteName.tabScreen, arguments: state.user);
                } else if (state is NewRegistration) {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, RouteName.welcomeScreen);
                } else if (state is RegistrationFailed) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
            )
          ],
          child: Container(
            decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50)),
                color: Theme.of(context).primaryColor),
            child: ListView(
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    ClipPath(
                      clipper: WaveClipper2(),
                      child: Container(
                        width: double.infinity,
                        height: 280,
                        decoration: BoxDecoration(
                            gradient: themeProvider.isDarkMode
                                ? LinearGradient(colors: [
                                    darkPrimaryColor,
                                    primaryColor.withOpacity(.6)
                                  ])
                                : LinearGradient(colors: [
                                    darkPrimaryColor,
                                    primaryColor.withOpacity(.15)
                                  ])),
                        child: const Column(),
                      ),
                    ),
                    ClipPath(
                      clipper: WaveClipper3(),
                      child: Container(
                        width: double.infinity,
                        height: 280,
                        decoration: BoxDecoration(
                            gradient: themeProvider.isDarkMode
                                ? LinearGradient(colors: [
                                    darkPrimaryColor,
                                    primaryColor.withOpacity(.5)
                                  ])
                                : LinearGradient(colors: [
                                    darkPrimaryColor,
                                    primaryColor.withOpacity(.2)
                                  ])),
                        child: const Column(),
                      ),
                    ),
                    ClipPath(
                      clipper: WaveClipper1(),
                      child: Container(
                        width: double.infinity,
                        height: 280,
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [primaryColor, primaryColor])),
                        child: Column(
                          children: <Widget>[
                            const SizedBox(
                              height: 15,
                            ),
                            Image.asset("asset/hookup4u-Logo-BW.png",
                                fit: BoxFit.contain, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Column(children: <Widget>[
                  SizedBox(
                    //height: MediaQuery.of(context).size.height * .1,
                    height: MediaQuery.of(context).size.height * .02,
                  ),
                  Text(
                    "By tapping 'Log in', you agree with our \n Terms.Learn how we process your data in \n our Privacy Policy and Cookies Policy."
                        .tr()
                        .toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black54,
                        fontSize: 15),
                  ),
                  FaceBookButton(onTap: () async {
                    context
                        .read<FacebookLoginBloc>()
                        .add(FacebookLoginRequest());
                  }),
                  OutlinedButton(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * .065,
                      width: MediaQuery.of(context).size.width * .75,
                      child: Center(
                          child: Text(
                              "LOG IN WITH PHONE NUMBER".tr().toString(),
                              style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold))),
                    ),
                    onPressed: () {
                      // requestSmsPermission();
                      Navigator.pushNamed(context, RouteName.phoneNumberScreen);
                    },
                  ),
                ]),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        "Trouble logging in?".tr().toString(),
                        style: TextStyle(
                            color: themeProvider.isDarkMode
                                ? Colors.white
                                : Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                ),
                const PrivacyPolicy(),
                SizedBox(
                  height: MediaQuery.of(context).size.height * .03,
                ),
                // only uncomment for language dropdowm all working
                // const LanguageSelectionDropdown()
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> requestSmsPermission() async {
  final status = await Permission.sms.request();

  if (status.isGranted) {
    // Permission has been granted, you can now read SMS
    // Your code to read SMS goes here
  } else {
    // Permission denied

    await Permission.sms.request();
    // Handle permission denial gracefully
  }
}

// Future<void> launchURL(String url) async {
//   if (!await launchUrl(
//     Uri.parse(url),
//   )) {
//     throw Exception('Could not launch $url');
//   }
// }
