import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../common/bloc/user/user_bloc.dart';
import '../../../../common/constants/app_colors.dart';
import '../../../../common/constants/constants.dart';
import '../../../../common/routes/route_name.dart';
import '../../../../services/secure_storage_service.dart';

void showLogoutDialog(BuildContext context) {
  final FirebaseAuth auth = firebaseAuthInstance;
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  Future<void> clearUserData() async {
    final userBloc = context.read<UserBloc>();
    userBloc.add(const UserDataUpdated(null));
    userBloc.add(const UserListenStopped());

    // Clear secure storage (authentication tokens, user IDs, etc.)
    try {
      final secureStorage = SecureStorageService();
      await secureStorage.clearAuthData();
      debugPrint('✅ Secure storage cleared on logout');
    } catch (e) {
      debugPrint('⚠️ Error clearing secure storage: $e');
      // Continue with logout even if secure storage clear fails
    }

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
    builder: (BuildContext context) => AlertDialog(
      title: Text('Logout'.tr().toString()),
      content: Text('Do you want to logout your account?'.tr().toString()),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'No'.tr().toString(),
            style: const TextStyle(color: AppColors.primaryGreen),
          ),
        ),
        TextButton(
          onPressed: () async {
            // Cancel subscriptions and clear user data BEFORE sign out
            await clearUserData();
            // Sign out from Firebase Auth
            await auth.signOut();
            // Small delay to ensure subscriptions are fully canceled
            await Future.delayed(const Duration(milliseconds: 100));
            if (context.mounted) {
              // Navigate to welcome screen to show all sign-in options (phone, Google, Apple)
              Navigator.pushNamedAndRemoveUntil(
                context,
                RouteName.welcomeScreen,
                (route) => false,
              );
            }
          },
          child: Text(
            'Yes'.tr().toString(),
            style: const TextStyle(color: AppColors.primaryGreen),
          ),
        ),
      ],
    ),
  );
}
