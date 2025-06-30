// ignore_for_file: public_member_api_docs, sort_constructors_first, unnecessary_string_interpolations

import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:naijasingles/common/providers/user_provider.dart';
import 'package:naijasingles/common/routes/route_name.dart';
import 'package:naijasingles/common/widgets/custom_snackbar.dart';
import 'package:naijasingles/common/widgets/hookup_circularbar.dart';
import 'package:otp_autofill/otp_autofill.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

import '../../../../../common/constants/colors.dart';
import '../../../../../common/data/repo/phone_auth_repo.dart';
import '../../../../../common/providers/theme_provider.dart';
import '../../../../../common/widgets/custom_button.dart';
import '../../../auth_status/bloc/registration/bloc/registration_bloc.dart';
import '../../bloc/phone_auth_bloc.dart';
import '../widgets/timer_widget.dart';

// ignore: must_be_immutable
class OtpPage extends StatefulWidget {
  String codeController;
  bool updatePhoneNumber;
  final String phoneNumber;
  final String verificationId;
  final bool isLogin; // Added to distinguish between login and registration
  
  OtpPage({
    Key? key,
    this.codeController = '',
    this.updatePhoneNumber = false,
    required this.phoneNumber,
    required this.verificationId,
    this.isLogin = false,
  }) : super(key: key);

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  int start = 30;
  NumberFormat formatter = NumberFormat("00");

  late OTPTextEditController controller;
  late OTPInteractor _otpInteractor;

  @override
  void dispose() {
    controller.stopListen();
    super.dispose();
  }

  @override
  void initState() {
    _initializeOtpInteractor();

    super.initState();
  }

  void _initializeOtpInteractor() {
    _otpInteractor = OTPInteractor();
    _otpInteractor.getAppSignature().then((value) => log('signature - $value'));

    controller = OTPTextEditController(
      codeLength: 6,
      onCodeReceive: (code) => log('Your Application receive code - $code'),
      otpInteractor: _otpInteractor,
    )..startListenUserConsent(
        (code) {
          log("code is $code");
          final exp = RegExp(r'(\d{6})');
          log("code is final  ${exp.stringMatch(code ?? '')}");
          return exp.stringMatch(code ?? '') ?? '';
        },
        strategies: [
          // SampleStrategy(),
        ],
      );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return PopScope(
      canPop: true,
      child: RepositoryProvider(
        create: (context) => PhoneAuthRepository(),
        child: BlocProvider(
          create: (context) => PhoneAuthBloc(
              phoneAuthRepository:
                  RepositoryProvider.of<PhoneAuthRepository>(context)),
          child: Scaffold(
            backgroundColor: Theme.of(context).primaryColor,
            body: Container(
              color: Theme.of(context).primaryColor,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 100),
                        width: 300,
                        child: Image.asset(
                          "asset/auth/verifyOtp.png",
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 50),
                      child: RichText(
                        text: TextSpan(
                            text: "Enter the code sent to ".tr().toString(),
                            children: [
                              TextSpan(
                                  text: widget.phoneNumber,
                                  style: TextStyle(
                                      color: primaryColor,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.bold,
                                      textBaseline: TextBaseline.alphabetic,
                                      fontSize: 15)),
                            ],
                            style: TextStyle(
                                fontFamily: 'Gellix',
                                color: themeProvider.isDarkMode
                                    ? Colors.white
                                    : Colors.black54,
                                fontSize: 15)),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                      child: PinCodeTextField(
                        controller: controller,
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
                          widget.codeController = value;
                        },
                        appContext: context,
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    BlocConsumer<PhoneAuthBloc, PhoneAuthState>(
                      listener: (context, state) {
                        if (state is PhoneAuthLoading) {}
                      },
                      builder: (context, state) {
                        return TimerWidget(
                          start: start,
                          resendText:
                              "Didn't receive the code? \t".tr().toString(),
                          phoneNumber: widget.phoneNumber,
                          onResendOtp: () {
                            context.read<PhoneAuthBloc>().add(
                                  SendOtpToPhoneEvent(
                                    phoneNumber: widget.phoneNumber,
                                  ),
                                );
                            _initializeOtpInteractor();
                          },
                        );
                      },
                    ),
                    const SizedBox(
                      height: 40,
                    ),
                    BlocConsumer<RegistrationBloc, RegistrationStates>(
                      builder: (context, state) {
                        if (state is RegistrationLoading) {
                          return const Hookup4uBar();
                        }
                        return const SizedBox.shrink();
                      },
                      listener: (context, state) {
                        if (state is AlreadyRegistered) {
                          log("state user ${state.user}");
                          Provider.of<UserProvider>(context, listen: false)
                              .currentUser = state.user;
                          
                          // If this is a login flow, go to main navigation
                          if (widget.isLogin) {
                            Navigator.of(context).pushReplacementNamed(
                                RouteName.mainNavigation);
                          } else {
                            // For registration or phone update
                            Navigator.of(context).pushReplacementNamed(
                                RouteName.tabScreen,
                                arguments: state.user);
                          }
                        } else if (state is NewRegistration) {
                          if (widget.isLogin) {
                            // If trying to login with a number that doesn't have an account
                            CustomSnackbar.showSnackBarSimple(
                              "No account found with this phone number. Please sign up first.",
                              context,
                            );
                            Navigator.pop(context);
                          } else {
                            // Normal registration flow
                            Navigator.pop(context);
                            Navigator.pushReplacementNamed(
                                context, RouteName.welcomeScreen);
                          }
                        } else if (state is RegistrationFailed) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(state.message)));
                        }
                      },
                    ),
                    BlocConsumer<PhoneAuthBloc, PhoneAuthState>(
                      builder: (context, state) {
                        if (state is PhoneAuthLoading) {
                          return const Hookup4uBar();
                        } else if (state is PhoneAuthVerified) {
                          return const SizedBox.shrink();
                        }
                        return CustomButton(
                            text: 'Verify'.tr().toString(),
                            color: AppColors.textPrimary,
                            active: true,
                            onTap: () {
                              if (widget.codeController.trim().isEmpty) {
                                CustomSnackbar.showSnackBarSimple(
                                  "otp can not empty".tr().toString(),
                                  context,
                                );
                              } else {
                                _verifyOtp(context: context);
                              }
                            });
                      },
                      listener: (context, state) {
                        if (state is PhoneAuthVerified) {
                          try {
                            if (state.user != null) {
                              state.user!.getIdToken().then((value) async {
                                if (value != null) {
                                  log("Got token after phone verification");
                                  BlocProvider.of<RegistrationBloc>(context)
                                      .add(CheckRegistration(token: value));
                                } else {
                                  log("Error: Token is null after phone verification");
                                  CustomSnackbar.showSnackBarSimple(
                                      'Authentication error: Token is null', context);
                                }
                              }).catchError((error) {
                                log("Error getting token after phone verification: $error");
                                CustomSnackbar.showSnackBarSimple(
                                    'Authentication error: $error', context);
                              });
                            } else {
                              log("Error: User is null after phone verification");
                              CustomSnackbar.showSnackBarSimple(
                                  'Authentication error: User is null', context);
                            }
                          } catch (e) {
                            log("Exception during token retrieval after phone verification: $e");
                            CustomSnackbar.showSnackBarSimple(
                                'Authentication error: $e', context);
                          }
                        } else if (state is PhoneupdateSuccess) {
                          Navigator.pushReplacementNamed(
                              context, RouteName.tabScreen);
                        } else if (state is PhoneAuthError) {
                          CustomSnackbar.showSnackBarSimple(
                              state.error, context);
                        }
                      },
                    ),
                    const SizedBox(
                      height: 10,
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _verifyOtp({required BuildContext context}) {
    if (widget.updatePhoneNumber) {
      context.read<PhoneAuthBloc>().add(OnPhoneNumberupdateEvent(
          phoneNumber: widget.phoneNumber,
          verificationId: widget.verificationId,
          token: widget.codeController));
      log("coming under update number");
    } else {
      context.read<PhoneAuthBloc>().add(VerifySentOtpEvent(
          otpCode: widget.codeController,
          verificationId: widget.verificationId));
    }
  }
}
