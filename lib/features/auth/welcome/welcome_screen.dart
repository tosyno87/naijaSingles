import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/constants/app_colors.dart';
import '../../../common/routes/route_name.dart';
import '../../../common/widgets/afropeep_logo.dart';
import '../auth_method/sign_in_method_selection_screen.dart';
import '../phone/ui/screens/phone_number.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  static const _creamBackground = Color(0xFFFFF6E5);

  bool _isAuthenticated = false;
  bool _isLoading = true;

  late AnimationController _logoController;
  late AnimationController _contentController;
  late AnimationController _buttonController;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _contentFade;
  late Animation<Offset> _buttonSlide;
  late Animation<double> _buttonFade;

  @override
  void initState() {
    super.initState();
    unawaited(_checkAuthStatus());
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOut,
    );
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _contentFade = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeInOut,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOutCubic),
    );
    _buttonFade = CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeIn,
    );

    if (mounted) unawaited(_logoController.forward());
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) unawaited(_contentController.forward());
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) unawaited(_buttonController.forward());
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _contentController.dispose();
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
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final heroHeight = screenHeight * 0.48;
    const cardOverlap = 28.0;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Hero photo
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight,
            child: Image.asset(
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
          ),

          // Dark gradient overlay (cinematic: dark edges, clear center)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.45),
                  ],
                  stops: const [0.0, 0.35, 1.0],
                ),
              ),
            ),
          ),

          // Logo centered on hero
          Positioned(
            top: topPadding + 32,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _logoFade,
              child: ScaleTransition(
                scale: _logoScale,
                child: const AfropeepLogo(size: 100),
              ),
            ),
          ),

          // Content card overlapping hero
          Positioned(
            top: heroHeight - cardOverlap,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: _creamBackground,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  36,
                  24,
                  bottomPadding > 0 ? bottomPadding + 12 : 28,
                ),
                child: Column(
                  children: [
                    // Title + value prop
                    FadeTransition(
                      opacity: _contentFade,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Find Your Tribe Anywhere',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2D2D2D),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Where African culture meets modern dating',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF666666),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Buttons
                    if (_isLoading)
                      const CircularProgressIndicator(
                        color: AppColors.primaryGreen,
                      ),

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
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(double screenWidth) {
    final buttonWidth = screenWidth * 0.82;

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
        const SizedBox(height: 14),
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
              color: AppColors.primaryGreen.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
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
          backgroundColor: Colors.white.withValues(alpha: 0.6),
          foregroundColor: AppColors.primaryGreenDark,
          side: BorderSide(
            color: AppColors.primaryGreenDark.withValues(alpha: 0.3),
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
            color: AppColors.primaryGreenDark,
          ),
        ),
      );
}
