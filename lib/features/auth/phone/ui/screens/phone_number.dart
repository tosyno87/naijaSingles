// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:developer';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naijasingles/common/data/repo/phone_auth_repo.dart';
import 'package:naijasingles/common/routes/route_name.dart';
import 'package:naijasingles/common/widgets/custom_snackbar.dart';
import '../../bloc/phone_auth_bloc.dart';

// ignore: must_be_immutable
class PhoneNumber extends StatefulWidget {
  bool updatePhoneNumber;
  final bool isSignIn;

  PhoneNumber({
    Key? key,
    required this.updatePhoneNumber,
    this.isSignIn = false,
  }) : super(key: key);

  @override
  State<PhoneNumber> createState() => _PhoneNumberState();
}

class _PhoneNumberState extends State<PhoneNumber> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isValidNumber = false;
  bool _isLoading = false;

  String countryCode = '+234'; // Default to Nigeria code
  TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Add listener to validate phone number
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
    if (mounted) {
      setState(() {
        isValidNumber = phoneNumberController.text.trim().length >= 6;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style for status bar
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ));

    // Define colors based on MVP styling
    const Color backgroundColor = Color(0xFFFFF6E5); // Cream background
    const Color primaryColor = Color(0xFF008037); // Deep Green
    const Color textColor = Color(0xFF3E1F0D); // Deep brown
    const Color subtextColor = Color(0xFF6E6E6E); // Gray for subtext
    const Color iconBackgroundColor =
        Color(0xFFDFF5E2); // Light green for icon background

    return RepositoryProvider(
      create: (context) => PhoneAuthRepository(),
      child: BlocProvider(
        create: (context) => PhoneAuthBloc(
            phoneAuthRepository:
                RepositoryProvider.of<PhoneAuthRepository>(context)),
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: primaryColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              widget.isSignIn ? "Sign In with Phone" : "Sign Up with Phone",
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            centerTitle: true,
          ),
          body: BlocListener<PhoneAuthBloc, PhoneAuthState>(
            listener: (context, state) {
              if (state is PhoneAuthVerified) {
                log("phone auth success listener called");
                // Navigate based on sign in or sign up
                if (widget.isSignIn) {
                  Navigator.pushReplacementNamed(
                      context, RouteName.mainNavigation);
                } else {
                  Navigator.pushReplacementNamed(context, RouteName.onboarding);
                }
              }

              if (state is PhoneAuthCodeSentSuccess) {
                log("phone auth code sent success listener called");
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });

                  Navigator.pushNamed(context, RouteName.otpScreen, arguments: {
                    'phoneNumber': countryCode + phoneNumberController.text,
                    'codeController': _codeController.text,
                    'verificationId': state.verificationId,
                    "updatenumber": widget.updatePhoneNumber,
                    "isLogin": widget.isSignIn,
                  });
                }
              }

              if (state is PhoneAuthError) {
                log("phone auth error listener called");
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                  CustomSnackbar.showSnackBarSimple(
                    state.error,
                    context,
                  );
                }
              }
            },
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Phone icon with Afrocentric style
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
                            Icons.phone_android,
                            color: primaryColor,
                            size: 50,
                          ),
                        ),

                        const SizedBox(height: 32),

                        Text(
                          "Enter your phone number",
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "We'll send you a verification code",
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            color: subtextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // Phone number input with country code
                        Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                            border: Border.all(
                              color: isValidNumber
                                  ? primaryColor
                                  : Colors.transparent,
                              width: isValidNumber ? 1.5 : 0,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Country code picker
                              Container(
                                padding: const EdgeInsets.only(left: 8),
                                child: CountryCodePicker(
                                  onChanged: (CountryCode code) {
                                    if (mounted) {
                                      setState(() {
                                        countryCode = code.dialCode!;
                                      });
                                    }
                                  },
                                  initialSelection: 'NG',
                                  favorite: const [
                                    'NG',
                                    'GH',
                                    'ZA',
                                    'KE',
                                    'US',
                                    'GB'
                                  ],
                                  showCountryOnly: false,
                                  showOnlyCountryWhenClosed: false,
                                  alignLeft: false,
                                  textStyle: GoogleFonts.montserrat(
                                    color: const Color(0xFF3E1F0D),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  dialogTextStyle: GoogleFonts.montserrat(
                                    color: const Color(0xFF3E1F0D),
                                    fontSize: 16,
                                  ),
                                  searchStyle: GoogleFonts.montserrat(
                                    color: Colors.black,
                                    fontSize: 16,
                                  ),
                                  dialogBackgroundColor:
                                      const Color(0xFFFFF6E5),
                                  boxDecoration: BoxDecoration(
                                    color: const Color(0xFFFFF6E5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  barrierColor: Colors.black54,
                                  backgroundColor: const Color(0xFFFFF6E5),
                                  dialogSize: Size(
                                      MediaQuery.of(context).size.width * 0.9,
                                      MediaQuery.of(context).size.height * 0.7),
                                  headerTextStyle: GoogleFonts.montserrat(
                                    color: const Color(0xFF3E1F0D),
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
                                      color: Color(0xFF008037),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF008037),
                                        width: 1.5,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),

                              // Vertical divider
                              Container(
                                height: 30,
                                width: 1,
                                color: Colors.grey.withValues(alpha: 0.3),
                              ),

                              // Phone number input
                              Expanded(
                                child: TextField(
                                  controller: phoneNumberController,
                                  keyboardType: TextInputType.phone,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    color: textColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "Phone number",
                                    hintStyle: GoogleFonts.montserrat(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  inputFormatters: [
                                    // Add space after every 3 digits
                                    FilteringTextInputFormatter.digitsOnly,
                                    _PhoneNumberFormatter(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Continue labelLarge
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: (!isValidNumber || _isLoading)
                                ? null
                                : () {
                                    setState(() {
                                      _isLoading = true;
                                    });

                                    // Remove spaces from phone number
                                    final cleanPhoneNumber =
                                        phoneNumberController.text
                                            .replaceAll(' ', '');

                                    context.read<PhoneAuthBloc>().add(
                                          SendOtpToPhoneEvent(
                                            phoneNumber:
                                                countryCode + cleanPhoneNumber,
                                          ),
                                        );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isValidNumber
                                  ? primaryColor
                                  : Colors.grey.shade400,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade400,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: isValidNumber ? 3 : 1,
                              shadowColor: isValidNumber
                                  ? primaryColor.withValues(alpha: 0.3)
                                  : Colors.transparent,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    "Continue",
                                    style: GoogleFonts.montserrat(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Consent text
                        Text(
                          "By continuing, you agree to receive SMS messages for verification and may be subject to carrier fees.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: const Color(0xFF999999),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Account toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.isSignIn
                                  ? "Don't have an account? "
                                  : "Already have an account? ",
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: textColor,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (widget.isSignIn) {
                                  Navigator.pushReplacementNamed(
                                      context, '/auth_method_selection');
                                } else {
                                  Navigator.pushReplacementNamed(
                                      context, '/sign_in_method_selection');
                                }
                              },
                              child: Text(
                                widget.isSignIn ? "Create one" : "Sign in",
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
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
          ),
        ),
      ),
    );
  }
}

// Custom formatter to add spaces after every 3 digits
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all spaces
    final digitsOnly = newValue.text.replaceAll(' ', '');

    // Add a space after every 3 digits
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
