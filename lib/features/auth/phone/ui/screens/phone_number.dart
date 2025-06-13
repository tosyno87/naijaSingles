// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:developer';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:naijasingles/common/data/repo/phone_auth_repo.dart';
import 'package:naijasingles/common/routes/route_name.dart';
import 'package:naijasingles/common/widgets/custom_snackbar.dart';
import 'package:naijasingles/common/widgets/hookup_circularbar.dart';
import 'package:naijasingles/features/home/ui/screens/welcome.dart';
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
  bool isValidNumber = false;

  String countryCode = '+1'; // Changed default to USA code
  TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    
    return RepositoryProvider(
      create: (context) => PhoneAuthRepository(),
      child: BlocProvider(
        create: (context) => PhoneAuthBloc(
            phoneAuthRepository:
                RepositoryProvider.of<PhoneAuthRepository>(context)),
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.green[700]),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
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
              log("phone auth code sent success listener called");
              log("phone ${phoneNumberController.text}");
              
              // Show loading indicator
              showDialog(
                barrierDismissible: false,
                context: context,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF2E8B57),
                  ),
                ),
              );
              
              // Navigate after delay
              Future.delayed(const Duration(seconds: 2), () {
                Navigator.pop(context); // Close loading dialog
                Navigator.pushNamed(context, RouteName.otpScreen,
                    arguments: {
                      'phoneNumber': countryCode + phoneNumberController.text,
                      'codeController': _codeController.text,
                      'smsVerificationCode': state.verificationId,
                      "updatenumber": widget.updatePhoneNumber
                    });
              });
            }

            //Show error message if any error occurs while verifying phone number and otp code
            if (state is PhoneAuthError) {
              log("phone auth error listener called");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }, child: BlocBuilder<PhoneAuthBloc, PhoneAuthState>(
                  builder: (context, state) {
            if (state is PhoneAuthLoading) {
              log("phone auth loading ui called");
              return const Hookup4uBar();
            }
            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(height: screenSize.height * 0.04),
                      
                      // Phone icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green[50],
                        ),
                        child: Icon(
                          Icons.phone_android,
                          size: 40,
                          color: Colors.green[700],
                        ),
                      ),
                      
                      SizedBox(height: screenSize.height * 0.04),
                      
                      // Header
                      Text(
                        "Verify your number",
                        style: TextStyle(
                          color: Colors.green[800],
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Subtitle
                      Text(
                        "We'll text you a code to get started",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                      
                      SizedBox(height: screenSize.height * 0.06),
                      
                      // Phone number input
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                          child: Row(
                            children: [
                              // Country code picker
                              Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      width: 1.0, 
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                ),
                                child: CountryCodePicker(
                                  onChanged: (value) {
                                    countryCode = value.dialCode!;
                                    _validatePhoneNumber(phoneNumberController.text);
                                  },
                                  initialSelection: 'US', // USA
                                  favorite: ['+1', 'US'],
                                  showCountryOnly: false,
                                  showOnlyCountryWhenClosed: false,
                                  alignLeft: false,
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
                      ),
                      
                      SizedBox(height: screenSize.height * 0.04),
                      
                      // DEV MODE: Test Phone Auth Button
                      if (kDebugMode)
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              context.read<PhoneAuthBloc>().add(UseTestPhoneAuthEvent());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              "DEV MODE: Use Test Phone",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      
                      SizedBox(height: screenSize.height * 0.04),
                      
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
                      
                      SizedBox(height: screenSize.height * 0.06),
                      
                      // Continue button
                      SizedBox(
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
                            backgroundColor: Colors.green[700],
                            disabledBackgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: isValidNumber ? 2 : 0,
                          ),
                          child: Text(
                            "Continue",
                            style: TextStyle(
                              color: isValidNumber ? Colors.white : Colors.grey[600],
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          })),
        ),
      ),
    );
  }

  void _validatePhoneNumber(String value) {
    setState(() {
      isValidNumber = validateMobile(value.trim());
    });
  }

  void _sendOtp({required String phoneNumber, required BuildContext context}) {
    final phoneNumberWithCode = "$countryCode$phoneNumber";
    log("SendOtpToPhoneEvent($phoneNumberWithCode)");
    
    context.read<PhoneAuthBloc>().add(
          SendOtpToPhoneEvent(
            phoneNumber: phoneNumberWithCode,
          ),
        );
  }

  bool validateMobile(String value) {
    String pattern = r'(^(?:[+0]9)?[0-9]{9,12}$)';
    RegExp regExp = RegExp(pattern);
    if (value.isEmpty) {
      return false;
    } else if (regExp.hasMatch(value.trim())) {
      return true;
    }
    return regExp.hasMatch(value.trim());
  }
}
