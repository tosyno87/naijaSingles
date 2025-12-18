import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/constants/app_colors.dart';
import '../../../common/widgets/afropeep_logo.dart';
import '../../../common/widgets/afropeep_primary_button.dart';
import '../../../common/widgets/custom_snackbar.dart';
import '../google_login/google_login_bloc.dart';
import '../google_login/google_login_events.dart';
import '../google_login/google_login_states.dart';
import '../phone/ui/screens/phone_number.dart';

class SignInMethodSelectionScreen extends StatelessWidget {
  const SignInMethodSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style for status bar
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ),);

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
              builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 24,
                        right: 24,
                        bottom: MediaQuery.of(context).padding.bottom > 0
                            ? MediaQuery.of(context).padding.bottom + 16
                            : 24,
                        top: 16,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),

                          // Afropeep Logo - larger size for better visibility
                          const AfropeepLogo(size: 100),

                          const SizedBox(height: 32),

                          // Header text - "Sign in"
                          Text(
                            'Sign in',
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
                            AfropeepPrimaryButton(
                              icon: Icons.apple,
                              text: 'Continue with Apple',
                              backgroundColor: appleBlack,
                              textColor: Colors.white,
                              variant: AuthButtonVariant.secondary,
                              onPressed: () {
                                CustomSnackbar.showSnackBarSimple(
                                  'Apple Sign In will be implemented soon',
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
                                      context, '/main_navigation',);
                                } else if (state is GoogleLoginFailed) {
                                  CustomSnackbar.showSnackBarSimple(
                                    state.message,
                                    context,
                                  );
                                }
                              },
                              builder: (context, state) => AfropeepPrimaryButton(
                                  icon: Icons.g_mobiledata_rounded,
                                  text: 'Continue with Google',
                                  backgroundColor: googleBlue,
                                  textColor: Colors.white,
                                  variant: AuthButtonVariant.secondary,
                                  isLoading: state is GoogleLoginLoading,
                                  onPressed: () {
                                    BlocProvider.of<GoogleLoginBloc>(context)
                                        .add(
                                      const GoogleLoginRequested(),
                                    );
                                  },
                                ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Phone Number Button - Primary (last, most prominent)
                          AfropeepPrimaryButton(
                            icon: Icons.phone_outlined,
                            text: 'Continue with Phone',
                            backgroundColor: primaryColor,
                            textColor: Colors.white,
                            onPressed: () {
                              // Use pushReplacement to remove this screen from stack
                              // This prevents both screens from being visible during transition
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PhoneNumber(
                                      updatePhoneNumber: false, isSignIn: true,),
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
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Create one',
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
                ),
            ),
          ),
        ],
      ),
    );
  }

}
