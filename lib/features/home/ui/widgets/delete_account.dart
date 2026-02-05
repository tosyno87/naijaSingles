import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../../../../common/widgets/custom_snackbar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../../common/bloc/user/user_bloc.dart';
import '../../../../common/constants/colors.dart';
import '../../../../common/constants/constants.dart';
import '../../../../common/data/repo/facebooklogin_repo.dart';
import '../../../../common/data/repo/phone_auth_repo.dart';
import '../../../../common/providers/user_provider.dart';
import '../../../../common/routes/route_name.dart';
import '../../../../common/widgets/text_button.dart';

class DeleteAccountWidget extends StatefulWidget {
  const DeleteAccountWidget({super.key});

  @override
  State<DeleteAccountWidget> createState() => _DeleteAccountWidgetState();
}

class _DeleteAccountWidgetState extends State<DeleteAccountWidget> {
  final FirebaseAuth _auth = firebaseAuthInstance;
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  final TextEditingController _confirmationController = TextEditingController();

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextButtonWidget(
        text: 'Delete Account',
        onTap: () async {
          showDialog(
            context: context,
            builder: (BuildContext context) => Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      surface: Colors.white,
                    ),
                dialogTheme:
                    const DialogThemeData(backgroundColor: Colors.white),
              ),
              child: AlertDialog(
                backgroundColor: Colors.white,
                title: Text('Delete Account'.tr().toString()),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Do you want to delete your account?'.tr().toString()),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      "We're sorry to see you go, but we understand your decision. Deleting your account will permanently remove all your personal information and data associated with it."
                          .tr()
                          .toString(),
                    ),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: Text(
                      'No'.tr().toString(),
                      style: const TextStyle(color: primaryColor),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      // Show final confirmation dialog with DELETE input
                      _showFinalConfirmationDialog();
                    },
                    child: Text(
                      'Yes'.tr().toString(),
                      style: const TextStyle(color: primaryColor),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        icon: Icons.delete_forever_outlined,
      );

  void _showFinalConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                surface: Colors.white,
              ),
          dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
        ),
        child: AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Final Confirmation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Type "DELETE" to confirm account deletion:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmationController,
                decoration: InputDecoration(
                  hintText: 'Type DELETE here',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              const Text(
                '⚠️ This action cannot be undone. All your data will be permanently deleted.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _confirmationController.clear();
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed:
                  _confirmationController.text.trim().toUpperCase() == 'DELETE'
                      ? () {
                          Navigator.of(context).pop();
                          _confirmationController.clear();
                          _performAccountDeletion();
                        }
                      : null,
              child: Text(
                'Confirm Delete',
                style: TextStyle(
                  color: _confirmationController.text.trim().toUpperCase() ==
                          'DELETE'
                      ? Colors.red
                      : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performAccountDeletion() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    try {
      // Check authentication method and handle accordingly
      final providerData = user.providerData;
      final bool isGoogleUser =
          providerData.any((info) => info.providerId == 'google.com');
      final bool isFacebookUser =
          providerData.any((info) => info.providerId == 'facebook.com');
      final bool isPhoneUser =
          providerData.any((info) => info.providerId == 'phone');

      if (isGoogleUser) {
        // For Google users, try direct deletion first
        await _deleteGoogleUser(user);
      } else if (isFacebookUser) {
        // For Facebook users, try direct deletion first
        await _deleteFacebookUser(user);
      } else if (isPhoneUser) {
        // For phone users, try direct deletion first
        await _deletePhoneUser(user);
      } else {
        // Fallback for other auth methods
        await _deleteUserWithReauth(user);
      }
    } catch (e) {
      log('Error in account deletion: ${e.toString()}');
      if (context.mounted) {
        CustomSnackbar.showSnackBarSimple(
          'Failed to delete account. Please try again.'.tr().toString(),
          context,
        );
      }
    }
  }

  Future<void> _deleteGoogleUser(User user) async {
    try {
      await user.delete();
      await _cleanupUserData(user);
      await _showSuccessAndNavigate();
    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
        // Show Google re-auth dialog
        _showGoogleReauthDialog();
      } else {
        rethrow;
      }
    }
  }

  Future<void> _deleteFacebookUser(User user) async {
    try {
      await user.delete();
      await _cleanupUserData(user);
      await _showSuccessAndNavigate();
    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
        // Show Facebook re-auth dialog
        _showFacebookReauthDialog();
      } else {
        rethrow;
      }
    }
  }

  Future<void> _deletePhoneUser(User user) async {
    try {
      await user.delete();
      await _cleanupUserData(user);
      await _showSuccessAndNavigate();
    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
        // Show phone re-auth dialog
        _showPhoneReauthDialog();
      } else {
        rethrow;
      }
    }
  }

  Future<void> _deleteUserWithReauth(User user) async {
    try {
      await user.delete();
      await _cleanupUserData(user);
      await _showSuccessAndNavigate();
    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
        // Show generic re-auth dialog
        _showGenericReauthDialog();
      } else {
        rethrow;
      }
    }
  }

  Future<void> _cleanupUserData(User user) async {
    await PhoneAuthRepository().deleteUser(user);
    await PhoneAuthRepository().signOut();
  }

  Future<void> _showSuccessAndNavigate() async {
    if (context.mounted) {
      CustomSnackbar.showSnackBarSimple(
        'Account deleted successfully'.tr().toString(),
        context,
      );
      // Capture bloc/provider before navigation (context may be unmounted after)
      final userBloc = context.read<UserBloc>();
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteName.welcomeScreen,
        (route) => false,
      ).then((value) {
        userBloc.add(const UserDataUpdated(null));
        userBloc.add(const UserListenStopped());
        userProvider.currentUser = null;
      });
    }
  }

  void _showGoogleReauthDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Re-authentication Required'),
        content: const Text(
          'Please sign in with Google again to confirm account deletion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Implement Google re-auth here
              // This would require Google Sign-In re-authentication
              CustomSnackbar.showSnackBarSimple(
                'Google re-authentication not yet implemented',
                context,
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showFacebookReauthDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Re-authentication Required'),
        content: const Text(
          'Please sign in with Facebook again to confirm account deletion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final User? fbUser =
                    await FaceBookLoginRepositoryImpl().signInWithFacebook();
                if (fbUser != null) {
                  await fbUser.delete();
                  await _cleanupUserData(fbUser);
                  await _showSuccessAndNavigate();
                }
              } catch (e) {
                CustomSnackbar.showSnackBarSimple(
                  'Facebook re-authentication failed',
                  context,
                );
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showPhoneReauthDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Re-authentication Required'),
        content: const Text(
          'Please verify your phone number again to confirm account deletion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Implement phone re-auth here
              CustomSnackbar.showSnackBarSimple(
                'Phone re-authentication not yet implemented',
                context,
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showGenericReauthDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Re-authentication Required'),
        content:
            const Text('Please sign in again to confirm account deletion.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
