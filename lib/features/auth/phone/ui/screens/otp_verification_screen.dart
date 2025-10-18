import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../../../common/routes/route_name.dart';
import '../../../../../common/widgets/custom_snackbar.dart';
import '../../../auth_status/bloc/registration/bloc/registration_bloc.dart';
import '../../bloc/phone_auth_bloc.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final bool updatePhoneNumber;

  const OtpVerificationScreen({
    Key? key,
    required this.phoneNumber,
    required this.verificationId,
    required this.updatePhoneNumber,
  }) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  Timer? _timer;
  int _remainingTime = 60; // 60 seconds countdown
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        _timer?.cancel();
      }
    });
  }

  void _resendOtp() {
    if (_canResend) {
      setState(() {
        _canResend = false;
        _remainingTime = 60;
      });

      _startTimer();

      BlocProvider.of<PhoneAuthBloc>(context).add(
        SendOtpToPhoneEvent(phoneNumber: widget.phoneNumber),
      );
    }
  }

  void _verifyOtp() {
    if (_otpController.text.length == 6) {
      BlocProvider.of<PhoneAuthBloc>(context).add(
        VerifySentOtpEvent(
          otpCode: _otpController.text.trim(),
          verificationId: widget.verificationId,
        ),
      );
    } else {
      CustomSnackbar.showSnackBarSimple(
        "Please enter a valid 6-digit code",
        context,
      );
    }
  }

  String _formatTime(int seconds) {
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Define colors
    const Color backgroundColor = Color(0xFFE8F5E8); // Soft mint green background
    const Color primaryColor = Color(0xFF008037); // Deep Green
    const Color accentColor = Color(0xFFE74C3C); // Coral Red
    const Color textColor = Color(0xFF333333);

    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Verify OTP",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background texture watermark
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Header image
                  Image.asset(
                    'asset/auth/verifyOtp.png',
                    height: 180,
                  ),

                  const SizedBox(height: 32),

                  // Header text
                  Text(
                    "Verification Code",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Phone number display
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: "Enter the code sent to ",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                      children: [
                        TextSpan(
                          text: widget.phoneNumber,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // OTP input field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: PinCodeTextField(
                      appContext: context,
                      length: 6,
                      obscureText: false,
                      animationType: AnimationType.fade,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(12),
                        fieldHeight: 56,
                        fieldWidth: 44,
                        activeFillColor: Colors.white,
                        inactiveFillColor: Colors.white,
                        selectedFillColor: Colors.white,
                        activeColor: primaryColor,
                        inactiveColor: Colors.grey.shade300,
                        selectedColor: accentColor,
                      ),
                      animationDuration: const Duration(milliseconds: 300),
                      backgroundColor: Colors.transparent,
                      enableActiveFill: true,
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      onCompleted: (v) {
                        // Auto-verify when all digits are entered
                        _verifyOtp();
                      },
                      onChanged: (value) {
                        // No need to do anything here
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Timer and resend option
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive code? ",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      _canResend
                          ? TextButton(
                              onPressed: _resendOtp,
                              child: Text(
                                "Resend",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            )
                          : Text(
                              _formatTime(_remainingTime),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: accentColor,
                              ),
                            ),
                    ],
                  ),

                  const Spacer(),

                  // Verify labelLarge
                  MultiBlocListener(
                    listeners: [
                      BlocListener<PhoneAuthBloc, PhoneAuthState>(
                        listener: (context, state) {
                          if (state is PhoneAuthError) {
                            CustomSnackbar.showSnackBarSimple(
                              state.error,
                              context,
                            );
                          } else if (state is PhoneAuthVerified) {
                            if (widget.updatePhoneNumber) {
                              // Handle phone number update
                              Navigator.pop(context);
                              Navigator.pop(context);
                              CustomSnackbar.showSnackBarSimple(
                                "Phone number updated successfully",
                                context,
                              );
                            } else {
                              // Check if user is registered
                              state.user?.getIdToken().then((value) {
                                if (value != null) {
                                  BlocProvider.of<RegistrationBloc>(context)
                                      .add(CheckRegistration(token: value));
                                }
                              });
                            }
                          }
                        },
                      ),
                      BlocListener<RegistrationBloc, RegistrationStates>(
                        listener: (context, state) {
                          if (state is AlreadyRegistered) {
                            // User already exists, go to main screen
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              RouteName.mainNavigation,
                              (route) => false,
                            );
                          } else if (state is NewRegistration) {
                            // New user, go to onboarding
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              RouteName.onboarding,
                              (route) => false,
                            );
                          }
                        },
                      ),
                    ],
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: BlocBuilder<PhoneAuthBloc, PhoneAuthState>(
                        builder: (context, state) {
                          return ElevatedButton(
                            onPressed:
                                state is PhoneAuthLoading ? null : _verifyOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  primaryColor.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            child: state is PhoneAuthLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    "Verify",
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: screenSize.height * 0.08),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
