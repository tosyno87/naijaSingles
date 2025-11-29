// ignore_for_file: public_member_api_docs, sort_constructors_first, unnecessary_string_interpolations

import 'dart:developer';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naijasingles/common/providers/user_provider.dart';
import 'package:naijasingles/common/routes/route_name.dart';
import 'package:naijasingles/common/widgets/custom_snackbar.dart';
import 'package:naijasingles/common/widgets/hookup_circularbar.dart';
import 'package:otp_autofill/otp_autofill.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

import '../../../../../common/data/repo/phone_auth_repo.dart';
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

  OTPTextEditController? controller;
  OTPInteractor? _otpInteractor;
  
  // Local state to track OTP code length for button enable/disable
  String _currentOtpCode = '';

  @override
  void dispose() {
    controller?.stopListen();
    super.dispose();
  }

  @override
  void initState() {
    // OTP autofill is Android-only. On iOS, use built-in TextField autofill
    if (Platform.isAndroid) {
      _initializeOtpInteractor();
    } else {
      log('📱 iOS detected - using built-in OTP autofill (no package needed)');
    }
    super.initState();
  }

  void _initializeOtpInteractor() {
    try {
      _otpInteractor = OTPInteractor();
      _otpInteractor!.getAppSignature().then((value) => log('signature - $value')).catchError((error) {
        log('⚠️ Error getting app signature: $error');
      });

      controller = OTPTextEditController(
        codeLength: 6,
        onCodeReceive: (code) => log('Your Application receive code - $code'),
        otpInteractor: _otpInteractor!,
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
    } catch (e) {
      log('⚠️ Error initializing OTP interactor: $e');
      // On error, controller will be null and app will use regular TextField
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style for status bar
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ));

    // MVP Color Scheme
    const Color backgroundColor = Colors.white; // White background (MVP color)
    const Color primaryColor = Color(0xFF008037); // Deep green MVP color
    const Color textColor = Color(0xFF2D2D2D); // Dark text
    const Color subtextColor = Color(0xFF6E6E6E); // Gray for subtext
    const Color iconBackgroundColor = Color(0xFFDFF5E2); // Light green for icon background

    return PopScope(
      canPop: true,
      child: RepositoryProvider(
        create: (context) => PhoneAuthRepository(),
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => PhoneAuthBloc(
                  phoneAuthRepository:
                      RepositoryProvider.of<PhoneAuthRepository>(context)),
            ),
            BlocProvider(
              create: (context) => RegistrationBloc(
                  phoneAuthRepository:
                      RepositoryProvider.of<PhoneAuthRepository>(context)),
            ),
          ],
          child: Scaffold(
            backgroundColor: backgroundColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: primaryColor),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                "Verify Phone".tr().toString(),
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              centerTitle: true,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(height: 40),
                    
                    // Verification icon with MVP styling
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: iconBackgroundColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.verified_user,
                        color: primaryColor,
                        size: 50,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    Text(
                      "Enter verification code".tr().toString(),
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Subtitle with phone number
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: "We sent a code to ".tr().toString(),
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          color: subtextColor,
                        ),
                        children: [
                          TextSpan(
                            text: widget.phoneNumber,
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // OTP Input Fields
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: PinCodeTextField(
                        controller: controller ?? TextEditingController(),
                        keyboardType: TextInputType.number,
                        length: 6,
                        obscureText: false,
                        animationType: AnimationType.fade,
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(16),
                          fieldHeight: 60,
                          fieldWidth: 48,
                          inactiveFillColor: Colors.white,
                          inactiveColor: Colors.grey.shade300,
                          selectedColor: primaryColor,
                          selectedFillColor: Colors.white,
                          activeFillColor: Colors.white,
                          activeColor: primaryColor,
                          borderWidth: 2,
                        ),
                        animationDuration: const Duration(milliseconds: 300),
                        enableActiveFill: true,
                        textStyle: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _currentOtpCode = value;
                            widget.codeController = value;
                          });
                          log('📝 OTP changed: length=${value.length}, code=$value');
                        },
                        appContext: context,
                      ),
                    ),

                    const SizedBox(height: 32),
                    // Resend code section
                    BlocConsumer<PhoneAuthBloc, PhoneAuthState>(
                      listener: (context, state) {
                        if (state is PhoneAuthLoading) {}
                      },
                      builder: (context, state) {
                        return TimerWidget(
                          start: start,
                          resendText:
                              "Didn't receive the code? ".tr().toString(),
                          phoneNumber: widget.phoneNumber,
                          onResendOtp: () {
                            context.read<PhoneAuthBloc>().add(
                                  SendOtpToPhoneEvent(
                                    phoneNumber: widget.phoneNumber,
                                  ),
                                );
                            if (Platform.isAndroid) {
                              _initializeOtpInteractor();
                            }
                          },
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
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
                            Navigator.of(context)
                                .pushReplacementNamed(RouteName.mainNavigation);
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
                            // New user sign-up - navigate to onboarding to create profile
                            log('✅ New user registration - navigating to onboarding');
                            Navigator.pop(context);
                            Navigator.pushReplacementNamed(
                                context, RouteName.onboarding);
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
                        
                        // Use local state to track OTP length for reactive button state
                        final isValidCode = _currentOtpCode.trim().length == 6;
                        
                        log('🔘 Button state check: codeLength=${_currentOtpCode.length}, isValidCode=$isValidCode');
                        
                        return SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isValidCode
                                ? () {
                                    _verifyOtp(context: context);
                                  }
                                : () {
                                    if (widget.codeController.trim().isEmpty) {
                                      CustomSnackbar.showSnackBarSimple(
                                        "OTP cannot be empty".tr().toString(),
                                        context,
                                      );
                                    } else {
                                      CustomSnackbar.showSnackBarSimple(
                                        "Please enter all 6 digits".tr().toString(),
                                        context,
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isValidCode
                                  ? primaryColor
                                  : Colors.grey.shade400,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade400,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: isValidCode ? 3 : 1,
                              shadowColor: isValidCode
                                  ? primaryColor.withValues(alpha: 0.3)
                                  : Colors.transparent,
                            ),
                            child: Text(
                              'Verify'.tr().toString(),
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
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
                                      'Authentication error: Token is null',
                                      context);
                                }
                              }).catchError((error) {
                                log("Error getting token after phone verification: $error");
                                CustomSnackbar.showSnackBarSimple(
                                    'Authentication error: $error', context);
                              });
                            } else {
                              log("Error: User is null after phone verification");
                              CustomSnackbar.showSnackBarSimple(
                                  'Authentication error: User is null',
                                  context);
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
