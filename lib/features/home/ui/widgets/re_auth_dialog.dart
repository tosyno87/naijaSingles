import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hookup4u2/common/constants/colors.dart';
import 'package:hookup4u2/common/data/repo/phone_auth_repo.dart';
import 'package:hookup4u2/common/providers/theme_provider.dart';
import 'package:hookup4u2/common/providers/user_provider.dart';
import 'package:hookup4u2/common/routes/route_name.dart';
import 'package:hookup4u2/common/widets/custom_snackbar.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

class ReAuthDialog extends StatefulWidget {
  final String verificationId;
  final FirebaseAuth auth;

  const ReAuthDialog({
    super.key,
    required this.verificationId,
    required this.auth,
  });

  @override
  State<ReAuthDialog> createState() => _ReAuthDialogState();
}

class _ReAuthDialogState extends State<ReAuthDialog> {
  TextEditingController otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return AlertDialog(
      titlePadding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
      title: RichText(
        text: TextSpan(
            text: "Enter the code sent to ".tr().toString(),
            children: [
              TextSpan(
                  text: widget.auth.currentUser?.phoneNumber,
                  style: TextStyle(
                      color: primaryColor,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold,
                      textBaseline: TextBaseline.alphabetic,
                      fontSize: 15)),
            ],
            style: TextStyle(
                fontFamily: 'Gellix',
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                fontSize: 18)),
        textAlign: TextAlign.center,
      ),
      content: PinCodeTextField(
        controller: otpController,
        keyboardType: TextInputType.number,
        length: 6,
        obscureText: false,
        animationType: AnimationType.fade,
        pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(10),
            fieldHeight: 50,
            fieldWidth: 35,
            inactiveFillColor: Colors.white,
            inactiveColor: primaryColor,
            selectedColor: Colors.green,
            selectedFillColor: Colors.white,
            activeFillColor: Colors.white,
            activeColor: Colors.green),
        //shape: PinCodeFieldShape.underline,
        animationDuration: const Duration(milliseconds: 300),
        //fieldHeight: 50,
        //fieldWidth: 35,
        onChanged: (value) {
          otpController.text = value;
        },
        appContext: context,
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
          },
          child: Text(
            'Cancel',
            style: TextStyle(color: primaryColor),
          ),
        ),
        TextButton(
          onPressed: () async {
            String otp = otpController.text.trim();
            if (otp.isNotEmpty) {
              // Call your reauthentication method here
              // For demonstration purpose, I'm just printing the OTP
              log('Submitted OTP: $otp');
              await reauthenticateWithPhone(
                  context: context,
                  auth: widget.auth,
                  verificationId: widget.verificationId,
                  verificationCode: otp);
            } else {
              CustomSnackbar.showSnackBarSimple(
                "otp can not empty".tr().toString(),
                context,
              );
            }
          },
          child: Text(
            'Submit'.tr().toString(),
            style: TextStyle(color: primaryColor),
          ),
        ),
      ],
    );
  }
}

// Function to re-authenticate user with their phone number

Future<void> reauthenticateWithPhone({
  required FirebaseAuth auth,
  required BuildContext context,
  required String verificationId,
  required String verificationCode,
}) async {
  try {
    AuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: verificationCode,
    );

    await auth.currentUser?.reauthenticateWithCredential(credential);
    log('Re-authentication successful!');
    if (context.mounted) {
      // Delete user account
      await deleteUserAndNavigateToLogin(auth, context);
    }
  } catch (e) {
    log('Error re-authenticating user: $e');
    if (context.mounted) {
      CustomSnackbar.showSnackBarSimple(
        "Something Went Wrong".tr().toString(),
        context,
      );
    }
  }
}

Future<void> deleteUserAndNavigateToLogin(
  FirebaseAuth auth,
  BuildContext context,
) async {
  try {
    final User? user = auth.currentUser;

    // Delete user account
    await user?.delete();

    // Delete user data from Firestore collections
    await PhoneAuthRepository().deleteUser(user!);
    await PhoneAuthRepository().signOut();
    if (context.mounted) {
      // Show success message
      CustomSnackbar.showSnackBarSimple(
        "Account deleted Successfully".tr().toString(),
        context,
      );
      // Navigate to login screen
      Navigator.pushReplacementNamed(context, RouteName.loginScreen)
          .then((value) {
        // Update user provider
        Provider.of<UserProvider>(context, listen: false).currentUser = null;
      });
    }
  } catch (e) {
    log('Error deleting user account: $e');
    if (context.mounted) {
      CustomSnackbar.showSnackBarSimple(
        "Something Went Wrong".tr().toString(),
        context,
      );
    }
  }
}
