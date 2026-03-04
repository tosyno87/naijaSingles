import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../common/routes/route_name.dart';
import '../../../../../common/widgets/custom_snackbar.dart';

class PhoneNumber extends StatefulWidget {
  const PhoneNumber({required this.updatePhoneNumber, super.key});
  final bool updatePhoneNumber;

  @override
  State<PhoneNumber> createState() => _PhoneNumberState();
}

class _PhoneNumberState extends State<PhoneNumber> {
  final TextEditingController _phoneController = TextEditingController();
  String _selectedCountryCode = '+1'; // Default to US
  bool _isLoading = false;

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
    super.dispose();
  }

  void _verifyPhoneNumber() {
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

    // For now, just navigate to the existing phone number screen
    // This is a temporary solution until we implement the proper phone login flow
    Navigator.pushNamed(
      context,
      RouteName.phoneNumberScreen,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style for status bar
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
    );

    // Define colors - Consistent with phone signup screen
    const Color backgroundColor = Colors.white; // White background (MVP color)
    const Color primaryColor = Color(0xFF008037); // Deep Green
    const Color textColor = Color(0xFF3E1F0D); // Deep brown
    const Color subtextColor = Color(0xFF6E6E6E); // Gray for subtext
    const Color iconBackgroundColor =
        Color(0xFFDFF5E2); // Light green for icon background

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
          'Sign In with Phone',
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
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                    'Enter your phone number',
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
                  DecoratedBox(
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
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedCountryCode,
                            icon: const Icon(Icons.arrow_drop_down),
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
                                  (Map<String, String> value) =>
                                      DropdownMenuItem<String>(
                                    value: value['code'],
                                    child: Text(
                                        "${value['code']} (${value['name']})",),
                                  ),
                                )
                                .toList(),
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
                              hintText: 'Phone number',
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

                  const SizedBox(height: 40),

                  // Continue Button - Styled like phone signup
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyPhoneNumber,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isLoading ? Colors.grey.shade400 : primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: _isLoading ? 1 : 3,
                        shadowColor: _isLoading
                            ? Colors.transparent
                            : primaryColor.withValues(alpha: 0.3),
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
                              'Continue',
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Don't have an account? Sign up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/welcome');
                        },
                        child: Text(
                          'Sign Up',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
