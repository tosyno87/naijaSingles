import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hookup4u2/common/constants/colors.dart';
import 'package:hookup4u2/common/routes/route_name.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants/constants.dart';
import '../../../../common/providers/user_provider.dart';

void showLogoutDialog(BuildContext context) {
  final FirebaseAuth auth = firebaseAuthInstance;
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  Future<void> clearUserData() async {
    // Clear any cached user data
    UserProvider userProvider =
        Provider.of<UserProvider>(context, listen: false);
    userProvider.currentUser = null; // Reset user data in provider
    userProvider.cancelCurrentUserSubscription(); // Cancel any subscriptions

    // Clear Firebase Messaging token
    try {
      await firebaseMessaging.deleteToken();
    } catch (e) {
      // Handle error
      debugPrint('Error deleting Firebase Messaging token: $e');
    }
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Logout'.tr().toString()),
        content: Text('Do you want to logout your account?'.tr().toString()),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No'.tr().toString(),
                style: TextStyle(color: primaryColor)),
          ),
          TextButton(
            onPressed: () async {
              // Clear any cached user data
              await clearUserData();
              // Sign out from Firebase Auth
              await auth.signOut();
              if (context.mounted) {
                // Navigate to the login screen
                Navigator.pushReplacementNamed(context, RouteName.loginScreen);
              }
            },
            child: Text(
              'Yes'.tr().toString(),
              style: TextStyle(color: primaryColor),
            ),
          ),
        ],
      );
    },
  );
}
