import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hookup4u2/common/widets/custom_snackbar.dart';
import 'package:hookup4u2/features/home/ui/widgets/re_auth_dialog.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/constants/constants.dart';
import '../../../../common/data/repo/facebooklogin_repo.dart';
import '../../../../common/data/repo/phone_auth_repo.dart';
import '../../../../common/providers/user_provider.dart';
import '../../../../common/routes/route_name.dart';
import '../../../../common/widets/text_button.dart';

class DeleteAccountWidget extends StatefulWidget {
  const DeleteAccountWidget({super.key});

  @override
  State<DeleteAccountWidget> createState() => _DeleteAccountWidgetState();
}

class _DeleteAccountWidgetState extends State<DeleteAccountWidget> {
  final FirebaseAuth _auth = firebaseAuthInstance;
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  @override
  Widget build(BuildContext context) {
    return TextButtonWidget(
      text: "Delete Account",
      onTap: () async {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
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
                          .toString()),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text('No'.tr().toString(),
                      style: TextStyle(color: primaryColor)),
                ),
                TextButton(
                  onPressed: () async {
                    final User? user = _auth.currentUser;
                    if (user == null) return;
                    await user.delete().then((_) async {
                      // Delete user data from Firestore collections
                      await PhoneAuthRepository().deleteUser(user);
                      await PhoneAuthRepository().signOut();
                      if (context.mounted) {
                        // Show success message
                        CustomSnackbar.showSnackBarSimple(
                          "Account deleted Successfully".tr().toString(),
                          context,
                        );
                        // Navigate to login screen
                        Navigator.pushReplacementNamed(
                                context, RouteName.loginScreen)
                            .then((value) {
                          // Update user provider
                          Provider.of<UserProvider>(context, listen: false)
                              .currentUser = null;
                        });
                      }
                    }).catchError((e) {
                      log("error in deleting user ${e.toString()}");

                      // for handling the recent login error
                      if (e is FirebaseAuthException &&
                          e.code == 'requires-recent-login') {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Recent Login Required'.tr().toString(),
                                      style: TextStyle(
                                          fontSize: 18, color: primaryColor),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'To ensure the security of your account, we require you to log in again for verification purposes. Please log in again and then delete account.'
                                          .tr()
                                          .toString(),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text(
                                            'Close'.tr().toString(),
                                            style:
                                                TextStyle(color: primaryColor),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            // Check if user has logged in with Facebook
                                            if (_auth.currentUser!.providerData
                                                .any((userInfo) =>
                                                    userInfo.providerId ==
                                                    'facebook.com')) {
                                              try {
                                                // Perform Facebook re-authentication
                                                final User? fbUser =
                                                    await FaceBookLoginRepositoryImpl()
                                                        .signInWithFacebook();

                                                if (fbUser != null) {
                                                  // Facebook re-authentication successful
                                                  log('Facebook re-authentication successful');

                                                  await fbUser
                                                      .delete()
                                                      .then((_) async {
                                                    // Delete user data from Firestore collections
                                                    await PhoneAuthRepository()
                                                        .deleteUser(fbUser);
                                                    await PhoneAuthRepository()
                                                        .signOut();
                                                    if (context.mounted) {
                                                      // Show success message
                                                      CustomSnackbar
                                                          .showSnackBarSimple(
                                                        "Account deleted Successfully"
                                                            .tr()
                                                            .toString(),
                                                        context,
                                                      );

                                                      // Navigate to login screen
                                                      Navigator.pushReplacementNamed(
                                                              context,
                                                              RouteName
                                                                  .loginScreen)
                                                          .then((value) async {
                                                        // Update user provider
                                                        Provider.of<UserProvider>(
                                                                context,
                                                                listen: false)
                                                            .currentUser = null;
                                                      });
                                                    }
                                                  });
                                                } else {
                                                  // Handle Facebook re-authentication failure
                                                  log('Facebook re-authentication failed');
                                                  if (context.mounted) {
                                                    CustomSnackbar
                                                        .showSnackBarSimple(
                                                      "Something Went Wrong"
                                                          .tr()
                                                          .toString(),
                                                      context,
                                                    );
                                                  }
                                                }
                                              } catch (e) {
                                                log('Error re-authenticating with Facebook: $e');
                                                // Handle re-authentication error
                                              }
                                            } else {
                                              await _auth.verifyPhoneNumber(
                                                phoneNumber: _auth
                                                    .currentUser?.phoneNumber,
                                                verificationCompleted:
                                                    (PhoneAuthCredential
                                                        credential) {},
                                                verificationFailed:
                                                    (FirebaseAuthException e) {
                                                  log('Verification failed: ${e.message}');
                                                  CustomSnackbar.showSnackBarSimple(
                                                      e.message ??
                                                          "Something Went Wrong"
                                                              .tr()
                                                              .toString(),
                                                      context);
                                                },
                                                codeSent:
                                                    (String verificationId,
                                                        int? resendToken) {
                                                  showDialog(
                                                      context: context,
                                                      builder: (BuildContext
                                                          context) {
                                                        return ReAuthDialog(
                                                            auth: _auth,
                                                            verificationId:
                                                                verificationId);
                                                      });
                                                },
                                                codeAutoRetrievalTimeout:
                                                    (String verificationId) {},
                                              );
                                            }
                                          },
                                          child: Text(
                                            'Yes'.tr().toString(),
                                            style:
                                                TextStyle(color: primaryColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }
                    });
                  },
                  child: Text('Yes'.tr().toString(),
                      style: TextStyle(color: primaryColor)),
                ),
              ],
            );
          },
        );
      },
      icon: Icons.delete_forever_outlined,
    );
  }
}
