import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:country_code_picker/country_code_picker.dart';
import '../../../../../common/widgets/custom_snackbar.dart';
import '../../bloc/phone_auth_bloc.dart';
import 'otp_verification_screen.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final bool updatePhoneNumber;

  const PhoneVerificationScreen({
    Key? key,
    required this.updatePhoneNumber,
  }) : super(key: key);

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  String countryCode = '+234'; // Default to Nigeria
  final TextEditingController phoneNumberController = TextEditingController();
  bool isValidNumber = false;

  @override
  void dispose() {
    phoneNumberController.dispose();
    super.dispose();
  }

  void _validatePhoneNumber(String value) {
    // Simple validation - at least 9 digits
    setState(() {
      isValidNumber = value.trim().length >= 9;
    });
  }

  void _sendOtp({required String phoneNumber, required BuildContext context}) {
    final formattedNumber = countryCode + phoneNumber.trim();
    
    BlocProvider.of<PhoneAuthBloc>(context).add(
      SendOtpToPhoneEvent(phoneNumber: formattedNumber),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define colors
    const Color backgroundColor = Color(0xFFFFF6E5); // Warm cream/beige
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
          "Phone Verification",
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
                    'asset/auth/verifyPhone.png',
                    height: 180,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Header text
                  Text(
                    "Verify Your Phone Number",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    "We'll send you a verification code to confirm your identity",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Phone number input
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
                        // Country code picker
                        CountryCodePicker(
                          onChanged: (CountryCode code) {
                            setState(() {
                              countryCode = code.dialCode!;
                            });
                          },
                          initialSelection: 'NG',
                          favorite: const ['NG', 'US', 'GB', 'CA'],
                          showCountryOnly: false,
                          showOnlyCountryWhenClosed: false,
                          alignLeft: false,
                          padding: EdgeInsets.zero,
                          textStyle: TextStyle(
                            color: Colors.green[800],
                            fontSize: 16,
                          ),
                          dialogBackgroundColor: Colors.white,
                          boxDecoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          dialogTextStyle: TextStyle(
                            color: Colors.green[800],
                          ),
                        ),
                        
                        // Phone number field
                        Expanded(
                          child: TextFormField(
                            keyboardType: TextInputType.phone,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.green[800],
                            ),
                            cursorColor: Colors.green[700],
                            controller: phoneNumberController,
                            onChanged: _validatePhoneNumber,
                            decoration: InputDecoration(
                              hintText: "Enter your number",
                              hintStyle: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[500],
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Privacy notice
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "By continuing, you agree to receive SMS messages for verification and may incur charges from your carrier.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Continue labelLarge
                  BlocConsumer<PhoneAuthBloc, PhoneAuthState>(
                    listener: (context, state) {
                      if (state is PhoneAuthError) {
                        CustomSnackbar.showSnackBarSimple(
                          state.error,
                          context,
                        );
                      } else if (state is PhoneAuthCodeSentSuccess) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OtpVerificationScreen(
                              phoneNumber: countryCode + phoneNumberController.text.trim(),
                              verificationId: state.verificationId,
                              updatePhoneNumber: widget.updatePhoneNumber,
                            ),
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      return SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isValidNumber
                              ? () {
                                  _sendOtp(
                                    phoneNumber: phoneNumberController.text,
                                    context: context,
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: primaryColor.withValues(alpha: 0.5),
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
                                  "Continue",
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      );
                    },
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
