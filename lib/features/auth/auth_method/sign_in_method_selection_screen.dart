import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../common/widgets/custom_snackbar.dart';
import '../../../common/widgets/afropeep_logo.dart';
import '../../../common/constants/app_colors.dart';
import '../phone/ui/screens/phone_number.dart';
import '../google_login/google_login_bloc.dart';
import '../google_login/google_login_events.dart';
import '../google_login/google_login_states.dart';

// Auth button variant enum for styling
enum AuthButtonVariant { primary, secondary }

// Modern dating app style auth button widget
class _AfropeepAuthButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onTap;
  final bool isLoading;
  final AuthButtonVariant variant;

  const _AfropeepAuthButton({
    required this.icon,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.variant,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPrimary = variant == AuthButtonVariant.primary;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28), // Pill shape
          ),
          elevation: isPrimary ? 4 : 0,
          shadowColor: isPrimary
              ? Colors.black.withOpacity(0.15)
              : Colors.transparent,
        ),
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: textColor,
                  strokeWidth: 2,
                ),
              )
            : Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: textColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        text,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class SignInMethodSelectionScreen extends StatelessWidget {
  const SignInMethodSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style for status bar
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ));

    // Define colors for modern dating app style
    const Color backgroundColor = Colors.white;
    const Color primaryColor = AppColors.primaryGreen; // #008037
    const Color googleBlue = Color(0xFF4285F4); // Google blue
    const Color appleBlack = Color(0xFF000000); // Apple black
    const Color textColor = AppColors.textPrimary;
    const Color textSecondary = AppColors.textSecondary;

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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 24.0,
                        right: 24.0,
                        bottom: MediaQuery.of(context).padding.bottom > 0
                            ? MediaQuery.of(context).padding.bottom + 16
                            : 24,
                        top: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),

                          // Afropeep Logo - small size
                          const AfropeepLogo(size: 64),

                          const SizedBox(height: 24),

                          // Header text - "Sign in"
                          Text(
                            "Sign in",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              letterSpacing: -0.5,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Subtitle
                          Text(
                            "Choose how you'd like to sign in",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Button order: Apple (iOS only) → Google → Phone (primary)
                          // Apple Sign In Button (iOS only) - Secondary (first on iOS)
                          if (Platform.isIOS) ...[
                            _AfropeepAuthButton(
                              icon: Icons.apple,
                              text: "Continue with Apple",
                              backgroundColor: appleBlack,
                              textColor: Colors.white,
                              variant: AuthButtonVariant.secondary,
                              onTap: () {
                                CustomSnackbar.showSnackBarSimple(
                                  "Apple Sign In will be implemented soon",
                                  context,
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Google Sign In Button - Secondary (first on Android, second on iOS)
                          BlocProvider(
                            create: (context) => GoogleLoginBloc(),
                            child: BlocConsumer<GoogleLoginBloc, GoogleLoginStates>(
                              listener: (context, state) {
                                if (state is GoogleLoginSuccess) {
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
                                return _AfropeepAuthButton(
                                  icon: Icons.g_mobiledata_rounded,
                                  text: "Continue with Google",
                                  backgroundColor: googleBlue,
                                  textColor: Colors.white,
                                  variant: AuthButtonVariant.secondary,
                                  isLoading: state is GoogleLoginLoading,
                                  onTap: () {
                                    BlocProvider.of<GoogleLoginBloc>(context)
                                        .add(
                                      const GoogleLoginRequested(),
                                    );
                                  },
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Phone Number Button - Primary (last, most prominent)
                          _AfropeepAuthButton(
                            icon: Icons.phone_outlined,
                            text: "Continue with Phone",
                            backgroundColor: primaryColor,
                            textColor: Colors.white,
                            variant: AuthButtonVariant.primary,
                            onTap: () {
                              // Use pushReplacement to remove this screen from stack
                              // This prevents both screens from being visible during transition
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PhoneNumber(
                                      updatePhoneNumber: false, isSignIn: true),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 32),

                          // Don't have an account? Create one
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  color: textSecondary,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  // Use pushReplacement to remove this screen from stack
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PhoneNumber(
                                        updatePhoneNumber: false,
                                        isSignIn: false, // Sign-up mode
                                      ),
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

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}
