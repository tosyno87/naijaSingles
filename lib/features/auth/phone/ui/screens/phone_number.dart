// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:developer';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookup4u2/common/data/repo/phone_auth_repo.dart';
import 'package:hookup4u2/common/routes/route_name.dart';
import 'package:hookup4u2/common/widets/custom_button.dart';
import 'package:hookup4u2/common/widets/custom_snackbar.dart';
import 'package:hookup4u2/common/widets/hookup_circularbar.dart';
import 'package:hookup4u2/features/home/ui/screens/welcome.dart';
import 'package:provider/provider.dart';

import '../../../../../common/constants/colors.dart';
import '../../../../../common/providers/theme_provider.dart';
import '../../bloc/phone_auth_bloc.dart';

// ignore: must_be_immutable
class PhoneNumber extends StatefulWidget {
  bool updatePhoneNumber;
  PhoneNumber({
    Key? key,
    required this.updatePhoneNumber,
  }) : super(key: key);

  @override
  State<PhoneNumber> createState() => _PhoneNumberState();
}

class _PhoneNumberState extends State<PhoneNumber> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool cont = false;

  String countryCode = '+91';
  TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return RepositoryProvider(
      create: (context) => PhoneAuthRepository(),
      child: BlocProvider(
        create: (context) => PhoneAuthBloc(
            phoneAuthRepository:
                RepositoryProvider.of<PhoneAuthRepository>(context)),
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Theme.of(context).primaryColor,
          body: BlocListener<PhoneAuthBloc, PhoneAuthState>(
              listener: (context, state) {
            if (state is PhoneAuthVerified) {
              log("phone auth success listener called");
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const Welcome(),
                ),
              );
            }

            if (state is PhoneAuthCodeSentSuccess) {
              log("phone auth code sent  success listener called");
              log("phonrrr ${phoneNumberController.text}");
              showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (_) {
                    Future.delayed(const Duration(seconds: 2), () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, RouteName.otpScreen,
                          arguments: {
                            'phoneNumber':
                                countryCode + phoneNumberController.text,
                            'codeController': _codeController.text,
                            'smsVerificationCode': state.verificationId,
                            "updatenumber": widget.updatePhoneNumber
                          });
                    });
                    return Center(

                        // Aligns the container to center
                        child: Container(

                            // A simplified version of dialog.
                            width: 100.0,
                            height: 120.0,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.circular(20)),
                            child: Column(
                              children: <Widget>[
                                Image.asset(
                                  "asset/auth/verified.jpg",
                                  height: 60,
                                  color: primaryColor,
                                  colorBlendMode: BlendMode.color,
                                ),
                                Text(
                                  "OTP\nSent".tr().toString(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      decoration: TextDecoration.none,
                                      color: themeProvider.isDarkMode
                                          ? Colors.black
                                          : Colors.black,
                                      fontSize: 20),
                                )
                              ],
                            )));
                  });
            }

            //Show error message if any error occurs while verifying phone number and otp code
            if (state is PhoneAuthError) {
              log("phone auth error listener called");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                ),
              );
            }
          }, child: BlocBuilder<PhoneAuthBloc, PhoneAuthState>(
                  builder: (context, state) {
            if (state is PhoneAuthLoading) {
              log("phone auth loading ui called");
              return const Hookup4uBar();
            }
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 50),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Image.asset(
                      "asset/auth/MobileNumber.png",
                      fit: BoxFit.cover,
                      height: 300,
                      width: MediaQuery.of(context).size.width,
                    ),
                    // Icon(
                    //   Icons.mobile_screen_share,
                    //   size: 50,
                    // ),
                    ListTile(
                      title: Text(
                        "Verify Your Number".tr().toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: themeProvider.isDarkMode
                                ? Colors.white
                                : primaryColor,
                            fontSize: 27,
                            fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Please enter Your mobile Number to\n receive a verification code. Message and data\n rates may apply"
                            .tr()
                            .toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 50, horizontal: 45),
                        child: ListTile(
                            leading: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                      width: 1.0, color: primaryColor),
                                ),
                              ),
                              child: CountryCodePicker(
                                dialogBackgroundColor:
                                    Theme.of(context).primaryColor,

                                onChanged: (value) {
                                  countryCode = value.dialCode!;
                                },
                                // Initial selection and favorite can be one of code ('IT') OR dial_code('+39')
                                initialSelection: 'IN',
                                favorite: [countryCode, 'IN'],
                                // optional. Shows only country name and flag
                                showCountryOnly: false,
                                // optional. Shows only country name and flag when popup is closed.
                                showOnlyCountryWhenClosed: false,
                                // optional. aligns the flag and the Text left
                                alignLeft: false,
                              ),
                            ),
                            // ignore: avoid_unnecessary_containers
                            title: Container(
                              child: TextFormField(
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(fontSize: 20),
                                cursorColor: primaryColor,
                                controller: phoneNumberController,
                                onChanged: (value) {
                                  setState(() {
                                    cont = true;
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: "Enter your number".tr().toString(),
                                  hintStyle: const TextStyle(fontSize: 18),
                                  focusColor: primaryColor,
                                  focusedBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: primaryColor)),
                                  enabledBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: primaryColor)),
                                ),
                              ),
                            ))),
                    cont
                        ? CustomButton(
                            text: "CONTINUE".tr().toString(),
                            onTap: () async {
                              if (validateMobile(
                                  phoneNumberController.text.trim())) {
                                _sendOtp(
                                    phoneNumber: phoneNumberController.text,
                                    context: context);
                              } else {
                                log("coming not verified");
                                CustomSnackbar.showSnackBarSimple(
                                    "please enter valid number", context);
                              }
                            },
                            color: textColor,
                            active: true)
                        : Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            height: MediaQuery.of(context).size.height * .065,
                            width: MediaQuery.of(context).size.width * .75,
                            child: Center(
                                child: Text(
                              "CONTINUE".tr().toString(),
                              style: TextStyle(
                                  fontSize: 15,
                                  color: themeProvider.isDarkMode
                                      ? Colors.white70
                                      : darkPrimaryColor,
                                  fontWeight: FontWeight.bold),
                            ))),
                  ],
                ),
              ),
            );
          })),
        ),
      ),
    );
  }

  void _sendOtp({required String phoneNumber, required BuildContext context}) {
    final phoneNumberWithCode = "$countryCode$phoneNumber";

    context.read<PhoneAuthBloc>().add(
          SendOtpToPhoneEvent(
            phoneNumber: phoneNumberWithCode,
          ),
        );
  }

  bool validateMobile(String value) {
    String patttern = r'(^(?:[+0]9)?[0-9]{9,12}$)';
    RegExp regExp = RegExp(patttern);
    if (value.isEmpty) {
      return false;
    } else if (regExp.hasMatch(value.trim())) {
      return true;
    }
    return regExp.hasMatch(value.trim());
  }
}
