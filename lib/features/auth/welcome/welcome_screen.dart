import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/constants/app_colors.dart';
import '../../../common/routes/route_name.dart';
import '../auth_method/sign_in_method_selection_screen.dart';
import '../phone/ui/screens/phone_number.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  bool _isAuthenticated = false;
  bool _isLoading = true;

  // Ken Burns — perpetual slow zoom + pan
  late AnimationController _kenBurnsController;
  late Animation<double> _kenBurnsScale;
  late Animation<double> _kenBurnsTranslateY;

  // Entrance — fast and snappy
  late AnimationController _textController;
  late Animation<double> _textFade;
  late AnimationController _buttonController;
  late Animation<Offset> _buttonSlide;
  late Animation<double> _buttonFade;

  @override
  void initState() {
    super.initState();
    unawaited(_checkAuthStatus());
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Ken Burns: 12s, reverse loop
    _kenBurnsController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat(reverse: true);

    _kenBurnsScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _kenBurnsController, curve: Curves.easeInOut),
    );
    _kenBurnsTranslateY = Tween<double>(begin: 0, end: -14).animate(
      CurvedAnimation(parent: _kenBurnsController, curve: Curves.easeInOut),
    );

    // Text entrance: 250ms
    _textController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _textFade = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    );

    // Button entrance: 350ms, delayed 120ms after text
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOutCubic),
    );
    _buttonFade = CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeIn,
    );

    if (mounted) unawaited(_textController.forward());
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) unawaited(_buttonController.forward());
    });
  }

  @override
  void dispose() {
    _kenBurnsController.dispose();
    _textController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      final currentUser = FirebaseAuth.instance.currentUser;

      if (mounted) {
        setState(() {
          _isAuthenticated = currentUser != null;
          _isLoading = false;
        });
        log("User authentication status: ${_isAuthenticated ? 'Authenticated' : 'Not authenticated'}");
      }
    } on Object catch (e) {
      log('Error checking auth status: $e');
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
    );

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full-screen hero with Ken Burns + cinematic color grade
          AnimatedBuilder(
            animation: _kenBurnsController,
            builder: (context, child) => Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..scale(_kenBurnsScale.value, _kenBurnsScale.value)
                ..translate(0.0, _kenBurnsTranslateY.value),
              child: child,
            ),
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                1.10, 0, 0, 0, -13, // R: +10% contrast
                0, 1.08, 0, 0, -10, // G: slightly warm
                0, 0, 1.04, 0, -5, // B: warmest channel
                0, 0, 0, 1, 0,
              ]),
              child: Image.asset(
                'assets/images/backgrounds/welcome_couple.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
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
            ),
          ),

          // 2. Subtle blur behind bottom content (glass effect)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: screenHeight * 0.42,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
          ),

          // 3. Top gradient — brand area (45% black -> transparent)
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
                    Color(0x00000000), // transparent
                  ],
                ),
              ),
            ),
          ),

          // 4. Bottom gradient — CTA area (transparent -> 65% black)
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
                    Color(0x00000000), // transparent
                    Color(0xA6000000), // 65% black
                  ],
                ),
              ),
            ),
          ),

          // 5. Content
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
                  const SizedBox(height: 20),

                  // Wordmark
                  FadeTransition(
                    opacity: _textFade,
                    child: Text(
                      'Afropeep',
                      style: GoogleFonts.montserrat(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Headline + value prop
                  FadeTransition(
                    opacity: _textFade,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Find Your Tribe Anywhere',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Where African culture meets modern dating',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xB3FFFFFF),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Buttons
                  if (_isLoading)
                    const CircularProgressIndicator(color: Colors.white),

                  if (!_isLoading)
                    SlideTransition(
                      position: _buttonSlide,
                      child: FadeTransition(
                        opacity: _buttonFade,
                        child: _buildButtons(screenWidth),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(double screenWidth) {
    final buttonWidth = screenWidth * 0.80;

    if (_isAuthenticated) {
      return Center(
        child: SizedBox(
          width: buttonWidth,
          child: _buildPrimaryButton(
            text: 'Continue to App',
            onPressed: () => unawaited(
              Navigator.pushReplacementNamed(
                context,
                RouteName.mainNavigation,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: SizedBox(
            width: buttonWidth,
            child: _buildPrimaryButton(
              text: 'Create Account',
              onPressed: () => unawaited(
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PhoneNumber(updatePhoneNumber: false),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: SizedBox(
            width: buttonWidth,
            child: _buildSecondaryButton(
              text: 'Log in',
              onPressed: () => unawaited(
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const SignInMethodSelectionScreen(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
  }) =>
      Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            unawaited(HapticFeedback.lightImpact());
            onPressed();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            minimumSize: const Size(double.infinity, 54),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: Text(
            text,
            style: GoogleFonts.montserrat(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      );

  Widget _buildSecondaryButton({
    required String text,
    required VoidCallback onPressed,
  }) =>
      OutlinedButton(
        onPressed: () {
          unawaited(HapticFeedback.lightImpact());
          onPressed();
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.12),
          foregroundColor: Colors.white,
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.4),
          ),
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      );
}
