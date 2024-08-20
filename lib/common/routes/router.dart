import 'package:flutter/material.dart';
import 'package:hookup4u2/common/providers/user_provider.dart';
import 'package:hookup4u2/common/routes/route_name.dart';
import 'package:hookup4u2/common/utlis/large_image.dart';
import 'package:hookup4u2/features/auth/phone/ui/screens/phone_number.dart';
import 'package:hookup4u2/features/auth/phone/ui/screens/update_phonenumber.dart';

import 'package:hookup4u2/features/chat/ui/screens/chat_page.dart';

import 'package:hookup4u2/features/home/ui/tab/tabbar.dart';
import 'package:hookup4u2/features/match/ui/screen/match_page.dart';
import 'package:hookup4u2/features/user/ui/screens/edit_user_profile.dart';
import 'package:hookup4u2/features/user/ui/screens/show_gender.dart';
import 'package:hookup4u2/features/user/ui/screens/update_user_location.dart';
import 'package:hookup4u2/features/user/ui/screens/user_location.dart';
import 'package:hookup4u2/features/user/ui/screens/user_profile.dart';
import 'package:hookup4u2/features/user/ui/screens/user_profile_pic_set.dart';
import 'package:hookup4u2/features/user/ui/screens/user_search_location.dart';
import 'package:hookup4u2/features/user/ui/screens/user_sexual_details.dart';
import 'package:hookup4u2/features/user/ui/screens/user_university.dart';
import 'package:hookup4u2/models/user_model.dart';
import 'package:provider/provider.dart';
import '../../features/home/ui/screens/user_filter/settings.dart';
import '../../features/home/ui/screens/welcome.dart';
import 'package:hookup4u2/features/user/ui/screens/user_dob.dart';
import 'package:hookup4u2/features/user/ui/screens/user_gender.dart';
import 'package:hookup4u2/features/user/ui/screens/user_name.dart';

import '../../features/auth/phone/ui/screens/login_option_page.dart';
import '../../features/auth/phone/ui/screens/otp_page.dart';
import '../../features/home/ui/screens/splash.dart';

abstract class AppRouter {
  // register here for routes
  static Map<String, WidgetBuilder> allRoutes = {
    RouteName.splashScreen: (context) => const Splash(),
    RouteName.loginScreen: (context) => const LoginOption(),
    RouteName.tabScreen: (context) => const Tabbar("active", false),
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
    RouteName.editProfileScreen: (context) =>
        EditProfile(Provider.of<UserProvider>(context).currentUser!),
    RouteName.largeImageScreen: (context) => LargeImage(
        largeImage: ModalRoute.of(context)!.settings.arguments as String),
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
    RouteName.profilePicSetScreen: (context) => const UserProfilePic(),
    RouteName.allowLocationScreen: (context) => const AllowLocation(),
    RouteName.otpScreen: (context) => OtpPage(
        codeController: (ModalRoute.of(context)!.settings.arguments
                as Map)['codeController']
            .toString(),
        smsVerificationCode: (ModalRoute.of(context)!.settings.arguments
                as Map)['smsVerificationCode']
            .toString(),
        phoneNumber:
            (ModalRoute.of(context)!.settings.arguments as Map)['phoneNumber']
                .toString(),
        updatePhoneNumber: (ModalRoute.of(context)!.settings.arguments
            as Map)['updatenumber']),
    RouteName.welcomeScreen: (context) => const Welcome(),
    RouteName.userDobScreen: (context) => UserDOB(
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>),
    RouteName.userNameScreen: (context) => const UserName()
  };
}
