import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../common/widgets/custom_snackbar.dart';
import '../phone/ui/screens/phone_number.dart';
import '../google_sign_in/google_sign_in_bloc.dart';

class AuthMethodSelectionScreen extends StatelessWidget {
  const AuthMethodSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style for status bar
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ));

    // Define colors
    const Color backgroundColor = Color(0xFFFFF6E5); // Warm cream/beige
    const Color primaryColor = Color(0xFF008037); // Deep Green
    const Color googleBlue = Color(0xFF4285F4);
    const Color appleBlack = Color(0xFF000000);

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
          "Sign In Options",
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
                  
                  // Header text
                  Text(
                    "Choose how you want to sign in",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    "Select your preferred sign-in method to continue",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // Phone Number Button
                  _buildAuthMethodButton(
                    context: context,
                    icon: Icons.phone_android,
                    text: "Sign in with Phone Number",
                    color: primaryColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PhoneNumber(updatePhoneNumber: false),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Email Button
                  _buildAuthMethodButton(
                    context: context,
                    icon: Icons.email_outlined,
                    text: "Sign in with Email",
                    color: Colors.deepOrange,
                    onTap: () {
                      Navigator.pushNamed(context, '/email_signup');
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Google Sign In Button
                  BlocProvider(
                    create: (context) => GoogleSignInBloc(),
                    child: BlocConsumer<GoogleSignInBloc, GoogleSignInState>(
                      listener: (context, state) {
                        if (state is GoogleSignInSuccess) {
                          // Navigate to onboarding or home based on user status
                          Navigator.pushReplacementNamed(context, '/onboarding');
                        } else if (state is GoogleSignInFailure) {
                          CustomSnackbar.showSnackBarSimple(
                            state.error,
                            context,
                          );
                        }
                      },
                      builder: (context, state) {
                        return _buildAuthMethodButton(
                          context: context,
                          icon: Icons.g_mobiledata_rounded,
                          text: "Sign in with Google",
                          color: googleBlue,
                          isLoading: state is GoogleSignInLoading,
                          onTap: () {
                            BlocProvider.of<GoogleSignInBloc>(context).add(
                              GoogleSignInRequested(),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  
                  // Apple Sign In Button (iOS only)
                  if (Platform.isIOS) ...[
                    const SizedBox(height: 20),
                    _buildAuthMethodButton(
                      context: context,
                      icon: Icons.apple,
                      text: "Sign in with Apple",
                      color: appleBlack,
                      onTap: () {
                        // Implement Apple Sign In
                        CustomSnackbar.showSnackBarSimple(
                          "Apple Sign In will be implemented soon",
                          context,
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthMethodButton({
    required BuildContext context,
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    text,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
