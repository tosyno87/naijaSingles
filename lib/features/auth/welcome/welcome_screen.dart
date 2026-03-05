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
import 'widgets/rotating_greeting_widget.dart';

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
      begin: const Offset(0, 0.5),
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Photo background (top) + cream fill (bottom)
          Column(
            children: [
              SizedBox(
                height: screenHeight * 0.55,
                width: double.infinity,
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
              const Expanded(child: ColoredBox(color: _creamBackground)),
            ],
          ),

          // Top vignette for status bar + logo readability
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.18,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),

          // Gradient transition from photo into cream
          Positioned(
            top: screenHeight * 0.36,
            left: 0,
            right: 0,
            height: screenHeight * 0.21,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _creamBackground.withValues(alpha: 0),
                    _creamBackground.withValues(alpha: 0.7),
                    _creamBackground,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // Content layer
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 32),

                // Logo + brand name overlaid on photo
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: _buildLogoSection(),
                  ),
                ),

                const Spacer(),

                // Greeting + tagline in the cream area
                FadeTransition(
                  opacity: _contentFade,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const RotatingGreetingWidget(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        textColor: Color(0xFF2D2D2D),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Find your tribe anywhere',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF666666),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Buttons
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  ),

                if (!_isLoading)
                  SlideTransition(
                    position: _buttonSlide,
                    child: FadeTransition(
                      opacity: _buttonFade,
                      child: _buildButtons(screenWidth),
                    ),
                  ),

                SizedBox(height: bottomPadding > 0 ? bottomPadding + 16 : 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AfropeepLogo(size: 100),
          const SizedBox(height: 8),
          Text(
            'Afropeep',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildButtons(double screenWidth) {
    final buttonWidth = screenWidth * 0.82;

    if (_isAuthenticated) {
      return Center(
        child: SizedBox(
          width: buttonWidth,
          child: _buildPrimaryButton(
            text: 'Continue to App',
            onPressed: () {
              unawaited(
                Navigator.pushReplacementNamed(
                  context,
                  RouteName.mainNavigation,
                ),
              );
            },
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
              onPressed: () {
                unawaited(
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PhoneNumber(updatePhoneNumber: false),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: SizedBox(
            width: buttonWidth,
            child: _buildSecondaryButton(
              text: 'Log in',
              onPressed: () {
                unawaited(
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const SignInMethodSelectionScreen(),
                    ),
                  ),
                );
              },
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
      Container(
        decoration: BoxDecoration(
          color: _creamBackground,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFE0D5C5),
            width: 1.5,
          ),
        ),
        child: OutlinedButton(
          onPressed: () {
            unawaited(HapticFeedback.lightImpact());
            onPressed();
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.primaryGreenDark,
            side: BorderSide.none,
            minimumSize: const Size(double.infinity, 54),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: Text(
            text,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: AppColors.primaryGreenDark,
            ),
          ),
        ),
      );
}
