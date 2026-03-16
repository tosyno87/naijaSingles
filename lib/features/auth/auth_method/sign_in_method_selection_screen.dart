import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/utils/auth_router.dart';
import '../../../common/utils/privacy_page.dart';
import '../../../common/widgets/custom_snackbar.dart';
import '../../../config/app_config.dart';
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

    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final screenHeight = size.height;
    final buttonWidth = screenWidth * 0.80;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    // Proportional top offset so "Afropeep" sits in upper third (Hinge-style)
    final topBrandOffset = screenHeight * 0.12;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 20,
          ),
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

          // Match welcome screen: localized bands only (no full-screen darkening)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.28,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x73000000), // 45% black
                    Color(0x00000000),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: screenHeight * 0.55,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00000000),
                    Color(0xA6000000), // 65% black
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                0,
                24,
                bottomPadding > 0 ? bottomPadding : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: topBrandOffset),

                  // Wordmark — clean, premium: title case, thicker, larger
                  Center(
                    child: Text(
                      'Afropeep',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  SizedBox(
                    width: buttonWidth,
                    child: Text.rich(
                      TextSpan(
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                          color: const Color(0xB3FFFFFF),
                        ),
                        children: [
                          const TextSpan(
                            text: 'By continuing, you agree to our ',
                          ),
                          TextSpan(
                            text: 'Terms',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              color: Color(0xB3FFFFFF),
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                unawaited(
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PrivacyPolicyPage(
                                        url: termConditionUrl,
                                        tittle: 'Terms of Service',
                                      ),
                                    ),
                                  ),
                                );
                              },
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              color: Color(0xB3FFFFFF),
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                unawaited(
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PrivacyPolicyPage(
                                        url: privacyUrl,
                                        tittle: 'Privacy Policy',
                                      ),
                                    ),
                                  ),
                                );
                              },
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Center(
                    child: SizedBox(
                      width: buttonWidth,
                      height: 56,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
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
                          borderRadius: BorderRadius.circular(28),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // 1. Multi-stop gradient (depth)
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFF22D879), // top
                                      Color(0xFF18B866), // middle
                                      Color(0xFF0E7C45), // bottom
                                    ],
                                    stops: [0.0, 0.5, 1.0],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF18B866)
                                          .withValues(alpha: 0.28),
                                      blurRadius: 20,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                              ),
                              // 2. Top highlight (top 35%, subtle shine)
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: const Alignment(0, -0.3), // ~35% down
                                    colors: [
                                      Colors.white.withValues(alpha: 0.12),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              // 3. Content: text only (match welcome primary button)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 15,
                                  ),
                                  child: Text(
                                    'Continue with phone',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Center(
                    child: SizedBox(
                      width: buttonWidth,
                      child: BlocProvider(
                        create: (context) => GoogleLoginBloc(),
                        child: BlocConsumer<GoogleLoginBloc, GoogleLoginStates>(
                          listener: (context, state) {
                            if (state is GoogleLoginSuccess) {
                              unawaited(
                                AuthRouter.navigateAfterAuth(context),
                              );
                            } else if (state is GoogleLoginFailed) {
                              CustomSnackbar.showSnackBarSimple(
                                state.message,
                                context,
                              );
                            }
                          },
                          builder: (context, state) => TextButton.icon(
                            onPressed: state is GoogleLoginLoading
                                ? null
                                : () {
                                    BlocProvider.of<GoogleLoginBloc>(context)
                                        .add(
                                      const GoogleLoginRequested(),
                                    );
                                  },
                            icon: state is GoogleLoginLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    Icons.g_mobiledata_rounded,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    size: 28,
                                  ),
                            label: Text(
                              'Continue with Google',
                              style: GoogleFonts.montserrat(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  Colors.white.withValues(alpha: 0.9),
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 24,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                                side: BorderSide(
                                  color: googleBlue.withValues(alpha: 0.45),
                                ),
                              ),
                              backgroundColor: const Color(0x1AFFFFFF),
                            ),
                          ),
                        ),
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
                          fontWeight: FontWeight.w400,
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
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
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
