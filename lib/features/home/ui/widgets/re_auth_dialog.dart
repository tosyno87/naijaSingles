import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../../common/bloc/theme/theme_bloc.dart';
import '../../../../common/bloc/user/user_bloc.dart';
import '../../../../common/constants/app_colors.dart';
import '../../../../common/data/repo/phone_auth_repo.dart';
import '../../../../common/routes/route_name.dart';
import '../../../../common/widgets/custom_snackbar.dart';

class ReAuthDialog extends StatefulWidget {
  const ReAuthDialog({
    required this.verificationId,
    required this.auth,
    super.key,
  });
  final String verificationId;
  final FirebaseAuth auth;

  @override
  State<ReAuthDialog> createState() => _ReAuthDialogState();
}

class _ReAuthDialogState extends State<ReAuthDialog> {
  TextEditingController otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final themeBloc = context.watch<ThemeBloc>();
    final isDarkMode = themeBloc.isDarkMode;
    return AlertDialog(
      titlePadding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
      title: RichText(
        text: TextSpan(
          text: 'Enter the code sent to '.tr().toString(),
          children: [
            TextSpan(
              text: widget.auth.currentUser?.phoneNumber,
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
                textBaseline: TextBaseline.alphabetic,
                fontSize: 15,
              ),
            ),
          ],
          style: GoogleFonts.montserrat(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 18,
          ),
        ),
        textAlign: TextAlign.center,
      ),
      content: PinCodeTextField(
        controller: otpController,
        keyboardType: TextInputType.number,
        length: 6,
        animationType: AnimationType.fade,
        pinTheme: PinTheme(
          shape: PinCodeFieldShape.box,
          borderRadius: BorderRadius.circular(10),
          fieldHeight: 50,
          fieldWidth: 35,
          inactiveFillColor: Colors.white,
          inactiveColor: AppColors.primaryGreen,
          selectedColor: Colors.green,
          selectedFillColor: Colors.white,
          activeFillColor: Colors.white,
          activeColor: Colors.green,
        ),
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
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.primaryGreen),
          ),
        ),
        TextButton(
          onPressed: () async {
            final String otp = otpController.text.trim();
            if (otp.isNotEmpty) {
              // Call your reauthentication method here
              // For demonstration purpose, I'm just printing the OTP
              log('Submitted OTP: $otp');
              await reauthenticateWithPhone(
                context: context,
                auth: widget.auth,
                verificationId: widget.verificationId,
                verificationCode: otp,
              );
            } else {
              CustomSnackbar.showSnackBarSimple(
                'otp can not empty'.tr().toString(),
                context,
              );
            }
          },
          child: Text(
            'Submit'.tr().toString(),
            style: const TextStyle(color: AppColors.primaryGreen),
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
    final AuthCredential credential = PhoneAuthProvider.credential(
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
        'Something Went Wrong'.tr().toString(),
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
    if (!context.mounted) return;
    CustomSnackbar.showSnackBarSimple(
      'Account deleted Successfully'.tr().toString(),
      context,
    );
    final userBloc = context.read<UserBloc>();
    await Navigator.pushNamedAndRemoveUntil(
      context,
      RouteName.welcomeScreen,
      (route) => false,
    );
    userBloc.add(const UserDataUpdated(null));
    userBloc.add(const UserListenStopped());
  } catch (e) {
    log('Error deleting user account: $e');
    if (context.mounted) {
      CustomSnackbar.showSnackBarSimple(
        'Something Went Wrong'.tr().toString(),
        context,
      );
    }
  }
}
