import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import '../../../common/utils/auth_router.dart';
import '../auth_method/auth_method_selection_screen.dart';
import '../auth_method/sign_in_method_selection_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
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
    );
    unawaited(_kenBurnsController.repeat(reverse: true));

    _kenBurnsScale = Tween<double>(begin: 1, end: 1.06).animate(
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
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        if (mounted) unawaited(_buttonController.forward());
      }),
    );
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

      if (currentUser != null) {
        log('User has session — skipping Welcome, navigating via AuthRouter');
        if (mounted) {
          await AuthRouter.navigateAfterAuth(context);
        }
        return;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        log('User not authenticated — showing Welcome (Create Account / Log in)');
      }
    } on Object catch (e) {
      log('Error checking auth status: $e');
      if (mounted) {
        setState(() {
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
                ..scaleByVector3(
                  Vector3(
                    _kenBurnsScale.value,
                    _kenBurnsScale.value,
                    1,
                  ),
                )
                ..translateByVector3(
                  Vector3(0, _kenBurnsTranslateY.value, 0),
                ),
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
                  const SizedBox(height: 44),

                  // Wordmark — clean, premium: title case, thicker, larger
                  FadeTransition(
                    opacity: _textFade,
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
                            color: const Color(0xB3FFFFFF),
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
                    builder: (context) => const AuthMethodSelectionScreen(),
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
                    builder: (context) => const SignInMethodSelectionScreen(),
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
      SizedBox(
        height: 56,
        width: double.infinity,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              unawaited(HapticFeedback.lightImpact());
              onPressed();
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
                        color: const Color(0xFF18B866).withValues(alpha: 0.28),
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
                      end: const Alignment(0, -0.3),
                      colors: [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // 3. Content
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 15,
                    ),
                    child: Text(
                      text,
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
