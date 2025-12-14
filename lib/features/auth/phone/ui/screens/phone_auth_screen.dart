import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naijasingles/common/data/repo/phone_auth_repo.dart';
import 'package:naijasingles/common/widgets/custom_snackbar.dart';
import '../../bloc/phone_auth_bloc.dart';
import 'otp_page.dart';

class PhoneAuthScreen extends StatefulWidget {
  final bool isSignIn;
  final bool updatePhoneNumber;

  const PhoneAuthScreen({
    Key? key,
    this.isSignIn = false,
    this.updatePhoneNumber = false,
  }) : super(key: key);

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String _selectedCountryCode = '+1'; // Default to US
  bool _isLoading = false;
  final TextEditingController _codeController = TextEditingController();

  final List<Map<String, String>> _countryCodes = [
    {'code': '+234', 'name': 'Nigeria'},
    {'code': '+233', 'name': 'Ghana'},
    {'code': '+27', 'name': 'South Africa'},
    {'code': '+254', 'name': 'Kenya'},
    {'code': '+256', 'name': 'Uganda'},
    {'code': '+255', 'name': 'Tanzania'},
    {'code': '+251', 'name': 'Ethiopia'},
    {'code': '+1', 'name': 'USA/Canada'},
    {'code': '+44', 'name': 'UK'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style for status bar
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ));

    // Define colors based on MVP styling
    const Color backgroundColor = Colors.white; // White background (MVP color)
    const Color primaryColor = Color(0xFF008037); // Green
    const Color textColor = Color(0xFF3E1F0D); // Deep brown
    const Color textLightBrown = Color(0xFF8B6C59); // Light brown for subtitle

    return RepositoryProvider(
      create: (context) => PhoneAuthRepository(),
      child: BlocProvider(
        create: (context) => PhoneAuthBloc(
          phoneAuthRepository:
              RepositoryProvider.of<PhoneAuthRepository>(context),
        ),
        child: BlocConsumer<PhoneAuthBloc, PhoneAuthState>(
          listener: (context, state) {
            // Don't handle PhoneAuthVerified here - let OTP screen handle it
            // This prevents premature navigation before registration check completes
            // The OTP screen will handle navigation after checking registration status

            if (state is PhoneAuthCodeSentSuccess) {
              log("phone auth code sent success listener called");
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });

                // Use direct MaterialPageRoute instead of named route to avoid router issues
                // This ensures smooth transition without any "Page Not Found" flash
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => OtpPage(
                      phoneNumber: _selectedCountryCode + _phoneController.text,
                      verificationId: state.verificationId,
                      codeController: _codeController.text,
                      updatePhoneNumber: widget.updatePhoneNumber,
                      isLogin: widget.isSignIn,
                    ),
                  ),
                );
              }
            }

            if (state is PhoneAuthError) {
              setState(() {
                _isLoading = false;
              });
              CustomSnackbar.showSnackBarSimple(
                state.error,
                context,
              );
            }
          },
          builder: (context, state) {
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
                  widget.isSignIn ? "Sign In with Phone" : "Sign Up with Phone",
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
                centerTitle: true,
              ),
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Enter your phone number",
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "We'll send you a verification code",
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          color: textLightBrown,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Phone number input with country code
                      Container(
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
                        ),
                        child: Row(
                          children: [
                            // Country code dropdown
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                border: Border(
                                  right: BorderSide(
                                    color: Colors.grey.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: DropdownButton<String>(
                                value: _selectedCountryCode,
                                icon: const Icon(Icons.arrow_drop_down),
                                iconSize: 24,
                                elevation: 16,
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  color: textColor,
                                ),
                                underline: Container(
                                  height: 0,
                                ),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedCountryCode = newValue!;
                                  });
                                },
                                items: _countryCodes
                                    .map<DropdownMenuItem<String>>(
                                        (Map<String, String> value) {
                                  return DropdownMenuItem<String>(
                                    value: value['code'],
                                    child: Text(
                                        "${value['code']} (${value['name']})"),
                                  );
                                }).toList(),
                              ),
                            ),

                            // Phone number input
                            Expanded(
                              child: TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  color: textColor,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Phone number",
                                  hintStyle: GoogleFonts.montserrat(
                                    color: Colors.grey,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Continue labelLarge
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  if (_phoneController.text.isEmpty) {
                                    CustomSnackbar.showSnackBarSimple(
                                      'Please enter your phone number',
                                      context,
                                    );
                                    return;
                                  }

                                  setState(() {
                                    _isLoading = true;
                                  });

                                  final phoneNumber = _selectedCountryCode +
                                      _phoneController.text.trim();

                                  context.read<PhoneAuthBloc>().add(
                                        SendOtpToPhoneEvent(
                                          phoneNumber: phoneNumber,
                                        ),
                                      );
                                },
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
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const Spacer(),

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
            );
          },
        ),
      ),
    );
  }
}
