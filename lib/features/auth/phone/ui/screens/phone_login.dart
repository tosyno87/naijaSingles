import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../common/widgets/custom_snackbar.dart';
import '../../../../../common/routes/route_name.dart';

class PhoneNumber extends StatefulWidget {
  final bool updatePhoneNumber;

  const PhoneNumber({Key? key, required this.updatePhoneNumber}) : super(key: key);

  @override
  State<PhoneNumber> createState() => _PhoneNumberState();
}

class _PhoneNumberState extends State<PhoneNumber> {
  final TextEditingController _phoneController = TextEditingController();
  String _selectedCountryCode = '+234'; // Default to Nigeria
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

    final phoneNumber = _selectedCountryCode + _phoneController.text.trim();
    
    // For now, just navigate to the existing phone number screen
    // This is a temporary solution until we implement the proper phone login flow
    Navigator.pushNamed(
      context,
      RouteName.phoneNumberScreen,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define colors
    const Color backgroundColor = Color(0xFFFFF6E5); // Warm cream/beige
    const Color primaryColor = Color(0xFF008037); // Deep Green
    const Color textColor = Color(0xFF3E1F0D); // Deep brown

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
          "Sign In with Phone",
          style: GoogleFonts.poppins(
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
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "We'll send you a verification code",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: textColor.withValues(alpha: 0.7),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        style: GoogleFonts.poppins(
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
                            .map<DropdownMenuItem<String>>((Map<String, String> value) {
                          return DropdownMenuItem<String>(
                            value: value['code'],
                            child: Text("${value['code']} (${value['name']})"),
                          );
                        }).toList(),
                      ),
                    ),
                    
                    // Phone number input
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: "Phone number",
                          hintStyle: GoogleFonts.poppins(
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
                  onPressed: _isLoading ? null : _verifyPhoneNumber,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: primaryColor.withValues(alpha: 0.5),
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
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const Spacer(),
              
              // Don't have an account? Sign up
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/welcome');
                    },
                    child: Text(
                      "Sign Up",
                      style: GoogleFonts.poppins(
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
  }
}
