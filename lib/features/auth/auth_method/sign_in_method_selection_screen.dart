import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/constants/app_colors.dart';
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
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
    );

    const Color googleBlue = Color(0xFF4285F4);
    const Color appleBlack = Color(0xFF000000);

    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = screenWidth * 0.80;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/backgrounds/welcome_couple.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1A3D2B), Color(0xFF006B2E)],
                ),
              ),
            ),
          ),

          // Stronger gradient — readable across the full content zone
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x40000000), // 25%
                  Color(0x33000000), // 20% — no clear gap
                  Color(0xCC000000), // 80%
                ],
                stops: [0.0, 0.35, 1.0],
              ),
            ),
          ),

          // Content pushed to bottom half
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                0,
                24,
                bottomPadding > 0 ? bottomPadding : 24,
              ),
              child: Column(
                children: [
                  const Spacer(),

                  // Wordmark (matches welcome screen)
                  Text(
                    'Afropeep',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.6,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Sign in',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Choose how you'd like to sign in",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xB3FFFFFF),
                    ),
                  ),

                  const SizedBox(height: 32),

                  if (Platform.isIOS) ...[
                    Center(
                      child: SizedBox(
                        width: buttonWidth,
                        child: AfropeepPrimaryButton(
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
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Center(
                    child: SizedBox(
                      width: buttonWidth,
                      child: BlocProvider(
                        create: (context) => GoogleLoginBloc(),
                        child: BlocConsumer<GoogleLoginBloc, GoogleLoginStates>(
                          listener: (context, state) {
                            if (state is GoogleLoginSuccess) {
                              unawaited(
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/main_navigation',
                                ),
                              );
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
                              BlocProvider.of<GoogleLoginBloc>(context).add(
                                const GoogleLoginRequested(),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Center(
                    child: SizedBox(
                      width: buttonWidth,
                      child: AfropeepPrimaryButton(
                        icon: Icons.phone_outlined,
                        text: 'Continue with Phone',
                        backgroundColor: AppColors.primaryGreen,
                        textColor: Colors.white,
                        onPressed: () {
                          unawaited(
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PhoneNumber(
                                  updatePhoneNumber: false,
                                  isSignIn: true,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: const Color(0xB3FFFFFF),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          unawaited(
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PhoneNumber(
                                  updatePhoneNumber: false,
                                ),
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'Create one',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
