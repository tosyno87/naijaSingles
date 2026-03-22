// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:dlibphonenumber/dlibphonenumber.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../common/constants/app_colors.dart';
import '../../../../../common/data/repo/phone_auth_repo.dart';
import '../../../../../common/widgets/afropeep_app_bar.dart';
import '../../../../../common/widgets/afropeep_primary_button.dart';
import '../../../../../common/widgets/auth_icon_container.dart';
import '../../../../../common/widgets/custom_snackbar.dart';
import '../../bloc/phone_auth_bloc.dart';
import 'otp_page.dart';

// ignore: must_be_immutable
class PhoneNumber extends StatefulWidget {
  bool updatePhoneNumber;
  final bool isSignIn;

  PhoneNumber({
    required this.updatePhoneNumber,
    super.key,
    this.isSignIn = false,
  });

  @override
  State<PhoneNumber> createState() => _PhoneNumberState();
}

class _PhoneNumberState extends State<PhoneNumber> {
  static const bool _verboseAuthLogs =
      bool.fromEnvironment('VERBOSE_AUTH_LOGS');
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isValidNumber = false;
  bool _isLoading = false;

  String countryCode = '+1';
  String _regionCode = 'US';
  TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  void _authDebugLog(String message) {
    if (_verboseAuthLogs) {
      log(message);
    }
  }

  @override
  void initState() {
    super.initState();
    phoneNumberController.addListener(_validatePhoneNumber);
  }

  @override
  void dispose() {
    phoneNumberController.removeListener(_validatePhoneNumber);
    phoneNumberController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _validatePhoneNumber() {
    if (!mounted) return;
    final raw = phoneNumberController.text.trim();
    final phoneDigits = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (phoneDigits.isEmpty) {
      setState(() => isValidNumber = false);
      return;
    }
    bool isValid = false;
    try {
      final phoneUtil = PhoneNumberUtil.instance;
      final fullNumber = countryCode + phoneDigits;
      final parsed = phoneUtil.parse(fullNumber, _regionCode);
      isValid = phoneUtil.isValidNumber(parsed);
    } on Object catch (e) {
      _authDebugLog('Phone validation parse failed: ${e.runtimeType}');
    }
    if (mounted) {
      setState(() => isValidNumber = isValid);
      _authDebugLog('Phone validation updated: valid=$isValid');
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
    );

    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = screenWidth * 0.80;

    return RepositoryProvider(
      create: (context) => PhoneAuthRepository(),
      child: BlocProvider(
        create: (context) => PhoneAuthBloc(
          phoneAuthRepository:
              RepositoryProvider.of<PhoneAuthRepository>(context),
        ),
        child: Scaffold(
          key: _scaffoldKey,
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.black,
          appBar: AfropeepAppBar(
            title:
                widget.isSignIn ? 'Sign In with Phone' : 'Sign Up with Phone',
            titleColor: Colors.white,
            backButtonColor: Colors.white,
          ),
          body: BlocListener<PhoneAuthBloc, PhoneAuthState>(
            listener: (context, state) {
              if (state is PhoneAuthCodeSentSuccess) {
                _authDebugLog('Phone auth code sent; opening OTP screen');
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });

                  unawaited(
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => OtpPage(
                          phoneNumber: countryCode + phoneNumberController.text,
                          verificationId: state.verificationId,
                          codeController: _codeController.text,
                          updatePhoneNumber: widget.updatePhoneNumber,
                          isLogin: widget.isSignIn,
                        ),
                      ),
                    ),
                  );
                }
              }

              if (state is PhoneAuthError) {
                log('Error: ${state.error}');

                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });

                  final String errorMessage = state.error;

                  // User-facing messages only; debug hints stay in dev builds
                  String userMessage = errorMessage;
                  if (state.error.contains('invalid-phone-number')) {
                    userMessage =
                        'The phone number you entered is invalid. Please check it and try again.';
                  } else if (state.error.contains('quota-exceeded')) {
                    userMessage =
                        'Too many attempts. Please wait a few minutes and try again.';
                  }

                  if (kDebugMode) {
                    String debugHint = '';
                    if (state.error.contains('invalid-phone-number')) {
                      String countrySpecificHint = '';
                      if (countryCode == '+1') {
                        countrySpecificHint =
                            '\n\n⚠️ US/Canada numbers must be exactly 10 digits (not including country code +1)';
                        countrySpecificHint +=
                            '\nExample: 2179044453 (10 digits), not 21790444533 (11 digits)';
                      }
                      debugHint =
                          '\n\n📋 Troubleshooting:$countrySpecificHint\n1. Check console logs for the EXACT number sent\n2. In Firebase Console, add test number WITHOUT spaces/dashes\n3. Format: +12179044453 (not +1 217 904 445 33)';
                    } else if (state.error
                        .contains('missing-verification-code')) {
                      debugHint =
                          '\n\n📋 Test number not found!\n1. Check console logs for exact number sent\n2. Add that EXACT number (no spaces) to Firebase Console\n3. Set a verification code (e.g., 123456)';
                    } else if (state.error
                        .contains('invalid-verification-code')) {
                      debugHint =
                          '\n\n📋 Wrong verification code!\nUse the code you set in Firebase Console test numbers';
                    } else {
                      debugHint =
                          '\n\n💡 For iOS Simulator: Use test phone numbers from Firebase Console.\nCheck console logs for exact number format needed.';
                    }
                    userMessage = '$errorMessage$debugHint';
                  }

                  CustomSnackbar.showSnackBarSimple(
                    userMessage,
                    context,
                  );
                }
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/backgrounds/welcome_couple.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF1A3D2B), Color(0xFF006B2E)],
                      ),
                    ),
                  ),
                ),

                // Heavier gradient for form readability
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x59000000), // 35%
                        Color(0x33000000), // 20%
                        Color(0xD9000000), // 85% — strong for input contrast
                      ],
                      stops: [0.0, 0.25, 1.0],
                    ),
                  ),
                ),

                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const AuthIconContainer(
                              icon: Icons.phone_android,
                              backgroundColor: Color(0x33FFFFFF),
                              iconColor: Colors.white,
                            ),
                            const SizedBox(height: 32),
                            if (kDebugMode && Platform.isIOS)
                              Container(
                                margin: const EdgeInsets.only(bottom: 20),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.shade200
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.blue.shade200,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '💡 iOS Simulator: Use test phone numbers from Firebase Console',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 12,
                                          color: Colors.blue.shade100,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Text(
                              'Enter your phone number',
                              style: GoogleFonts.montserrat(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "We'll send you a verification code",
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                color: const Color(0xB3FFFFFF),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 40),
                            Container(
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isValidNumber
                                      ? AppColors.primaryGreen
                                      : Colors.grey.shade300,
                                  width: isValidNumber ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: CountryCodePicker(
                                      onChanged: (CountryCode code) {
                                        if (mounted) {
                                          setState(() {
                                            countryCode = code.dialCode ?? '+1';
                                            _regionCode = code.code ?? 'US';
                                            _validatePhoneNumber();
                                          });
                                        }
                                      },
                                      initialSelection: 'US',
                                      favorite: const [
                                        'US',
                                        'GH',
                                        'ZA',
                                        'KE',
                                        'US',
                                        'GB',
                                      ],
                                      textStyle: GoogleFonts.montserrat(
                                        color: AppColors.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      dialogTextStyle: GoogleFonts.montserrat(
                                        color: Colors.black,
                                        fontSize: 16,
                                      ),
                                      searchStyle: GoogleFonts.montserrat(
                                        color: Colors.black,
                                        fontSize: 16,
                                      ),
                                      dialogBackgroundColor: Colors.white,
                                      boxDecoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      barrierColor: Colors.black54,
                                      backgroundColor: Colors.white,
                                      dialogSize: Size(
                                        MediaQuery.of(context).size.width * 0.9,
                                        MediaQuery.of(context).size.height *
                                            0.7,
                                      ),
                                      headerTextStyle: GoogleFonts.montserrat(
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      searchDecoration: InputDecoration(
                                        hintText: 'Search country',
                                        hintStyle: GoogleFonts.montserrat(
                                          color: Colors.grey.shade600,
                                          fontSize: 16,
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.search,
                                          color: AppColors.primaryGreen,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: AppColors.primaryGreen,
                                            width: 1.5,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 30,
                                    width: 1,
                                    color: Colors.grey.withValues(alpha: 0.3),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: phoneNumberController,
                                      keyboardType: TextInputType.phone,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 16,
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Phone number',
                                        hintStyle: GoogleFonts.montserrat(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        _PhoneNumberFormatter(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                            Center(
                              child: SizedBox(
                                width: buttonWidth,
                                child: Builder(
                                  builder: (builderContext) =>
                                      AfropeepPrimaryButton(
                                    text: 'Continue',
                                    isLoading: _isLoading,
                                    disabledBackgroundColor:
                                        Colors.white.withValues(alpha: 0.15),
                                    onPressed: isValidNumber && !_isLoading
                                        ? () {
                                            _authDebugLog(
                                              'Phone auth button tapped: '
                                              'isValid=$isValidNumber '
                                              'isLoading=$_isLoading',
                                            );

                                            setState(() {
                                              _isLoading = true;
                                            });

                                            final cleanPhoneNumber =
                                                phoneNumberController.text
                                                    .replaceAll(' ', '')
                                                    .replaceAll('-', '')
                                                    .replaceAll('(', '')
                                                    .replaceAll(')', '')
                                                    .trim();

                                            final fullPhoneNumber =
                                                countryCode + cleanPhoneNumber;

                                            _authDebugLog(
                                              'Phone auth request prepared: '
                                              'country=$countryCode '
                                              'digits=${cleanPhoneNumber.length}',
                                            );

                                            final bloc =
                                                BlocProvider.of<PhoneAuthBloc>(
                                              builderContext,
                                            );
                                            bloc.add(
                                              SendOtpToPhoneEvent(
                                                phoneNumber: fullPhoneNumber,
                                              ),
                                            );
                                          }
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'By continuing, you agree to receive SMS messages for verification and may be subject to carrier fees.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: const Color(0x99FFFFFF),
                              ),
                            ),
                            const SizedBox(height: 40),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.isSignIn
                                      ? "Don't have an account? "
                                      : 'Already have an account? ',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    color: const Color(0xB3FFFFFF),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    if (widget.isSignIn) {
                                      unawaited(
                                        Navigator.pushReplacementNamed(
                                          context,
                                          '/auth_method_selection',
                                        ),
                                      );
                                    } else {
                                      unawaited(
                                        Navigator.pushReplacementNamed(
                                          context,
                                          '/sign_in_method_selection',
                                        ),
                                      );
                                    }
                                  },
                                  child: Text(
                                    widget.isSignIn ? 'Create one' : 'Sign in',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final digitsOnly = newValue.text.replaceAll(' ', '');

    final buffer = StringBuffer();
    for (int i = 0; i < digitsOnly.length; i++) {
      buffer.write(digitsOnly[i]);
      if ((i + 1) % 3 == 0 && i != digitsOnly.length - 1) {
        buffer.write(' ');
      }
    }

    final formattedText = buffer.toString();

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
