import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../common/widgets/custom_snackbar.dart';
import '../phone/ui/screens/phone_number.dart';
import '../google_login/google_login_bloc.dart';
import '../google_login/google_login_events.dart';
import '../google_login/google_login_states.dart';
import '../email_password/ui/screens/email_login_screen.dart';
import '../auth_method/auth_method_selection_screen.dart';

class SignInMethodSelectionScreen extends StatelessWidget {
  const SignInMethodSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style for status bar
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ));

    // Define colors based on MVP styling
    const Color backgroundColor = Color(0xFFFFF6E5); // Cream background
    const Color primaryColor = Color(0xFF008037); // Green
    const Color accentColor = Color(0xFFEF476F); // Pink/Coral
    const Color googleBlue = Color(0xFF3B82F6); // Google blue
    const Color appleBlack = Color(0xFF000000); // Apple black
    const Color textColor = Color(0xFF3B3B3B); // Text dark gray
    const Color textLightBrown = Color(0xFF8B6C59); // Light brown for subtitle

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
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
                  const SizedBox(height: 24),

                  // Header text - Bold Montserrat
                  Text(
                    "Sign In or Create Account",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtitle - Regular Montserrat, light brown
                  Text(
                    "Choose how you'd like to continue",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: textLightBrown,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Phone Number Button
                  _buildAuthMethodButton(
                    context: context,
                    icon: Icons.phone_android,
                    text: "Continue with Phone",
                    color: primaryColor,
                    onTap: () {
                      // Navigate to phone login screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PhoneNumber(
                              updatePhoneNumber: false, isSignIn: true),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Email Button
                  _buildAuthMethodButton(
                    context: context,
                    icon: Icons.email_outlined,
                    text: "Continue with Email",
                    color: accentColor,
                    onTap: () {
                      // Navigate to email login screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EmailLoginScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Google Sign In Button
                  BlocProvider(
                    create: (context) => GoogleLoginBloc(),
                    child: BlocConsumer<GoogleLoginBloc, GoogleLoginStates>(
                      listener: (context, state) {
                        if (state is GoogleLoginSuccess) {
                          // Navigate to home screen on successful sign-in
                          Navigator.pushReplacementNamed(
                              context, '/main_navigation');
                        } else if (state is GoogleLoginFailed) {
                          CustomSnackbar.showSnackBarSimple(
                            state.message,
                            context,
                          );
                        }
                      },
                      builder: (context, state) {
                        return _buildAuthMethodButton(
                          context: context,
                          icon: Icons.g_mobiledata_rounded,
                          text: "Continue with Google",
                          color: googleBlue,
                          isLoading: state is GoogleLoginLoading,
                          onTap: () {
                            BlocProvider.of<GoogleLoginBloc>(context).add(
                              const GoogleLoginRequested(),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Apple Sign In Button (iOS only)
                  if (Platform.isIOS) ...[
                    const SizedBox(height: 16),
                    _buildAuthMethodButton(
                      context: context,
                      icon: Icons.apple,
                      text: "Continue with Apple",
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

                  const Spacer(),

                  // Don't have an account? Create one
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AuthMethodSelectionScreen(),
                            ),
                          );
                        },
                        child: Text(
                          "Create one",
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
      height: 56, // 56dp height as specified
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16), // 16dp radius as specified
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFF6E5)
                .withValues(alpha: 0.5), // Soft cream shadow
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  Icon(icon, size: 24, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    text,
                    style: GoogleFonts.montserrat(
                      // Montserrat font as specified
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
