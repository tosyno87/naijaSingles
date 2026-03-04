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
  bool _isAuthenticated = false;
  bool _isLoading = true;

  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _buttonController;

  late Animation<double> _logoScale;
  late Animation<double> _textOpacity;
  late Animation<Offset> _buttonSlide;
  late Animation<double> _backgroundOpacity;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Logo bounce-in animation with fade
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _logoScale = Tween<double>(
      begin: 0.3,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );

    // Text fade-in animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _textOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeInOut,
      ),
    );

    // Button slide-in animation
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _buttonController,
        curve: Curves.easeOutBack,
      ),
    );

    // Background pattern fade-in animation
    _backgroundOpacity = Tween<double>(
      begin: 0,
      end: 0.02,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animations with delays - check mounted before each call
    if (mounted) {
      _logoController.forward();
    }
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _textController.forward();
      }
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _buttonController.forward();
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Add small delay to ensure smooth rendering
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      final currentUser = FirebaseAuth.instance.currentUser;

      if (mounted) {
        setState(() {
          _isAuthenticated = currentUser != null;
          _isLoading = false;
        });
        log("User authentication status: ${_isAuthenticated ? 'Authenticated' : 'Not authenticated'}");

        // If user is authenticated and has completed profile, navigate to main app
        // This happens automatically when they click "Continue to App" but we can also do it here
        // However, we want to show the welcome screen first, so we'll let user click the button
      }
    } catch (e) {
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
    // Set system UI overlay style for status bar
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
    );

    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundOpacity,
        builder: (context, child) => DecoratedBox(
          decoration: BoxDecoration(
            // Clean white background
            color: Colors.white,
            image: DecorationImage(
              image: const AssetImage('assets/images/african_pattern.png'),
              fit: BoxFit.cover,
              opacity: _backgroundOpacity.value, // Animated opacity for polish
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),

                        // Clean Afropeep Logo with bounce-in and fade animation
                        AnimatedBuilder(
                          animation: _logoScale,
                          builder: (context, child) => Transform.scale(
                            scale: _logoScale.value,
                            child: Opacity(
                              opacity: _logoScale.value.clamp(0.0, 1.0),
                              child: _buildCleanLogo(),
                            ),
                          ),
                        ),

                        const SizedBox(
                            height: 32,), // Increased spacing for massive logo

                        // Animated progress bar instead of decorative line
                        AnimatedBuilder(
                          animation: _textOpacity,
                          builder: (context, child) => Opacity(
                            opacity: _textOpacity.value,
                            child: _buildAnimatedProgressBar(),
                          ),
                        ),

                        const SizedBox(height: 40), // Increased spacing

                        // Welcome message with animation
                        AnimatedBuilder(
                          animation: _textOpacity,
                          builder: (context, child) => Opacity(
                            opacity: _textOpacity.value,
                            child: Text(
                              'Welcome to Afropeep — community, culture, and connection for Africans everywhere.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.italic,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24), // Increased spacing

                        // Rotating greeting in African languages with animation
                        AnimatedBuilder(
                          animation: _textOpacity,
                          builder: (context, child) => Opacity(
                            opacity: _textOpacity.value,
                            child: const RotatingGreetingWidget(),
                          ),
                        ),

                        const SizedBox(height: 32), // Increased spacing

                        // Main tagline with animation
                        AnimatedBuilder(
                          animation: _textOpacity,
                          builder: (context, child) => Opacity(
                            opacity: _textOpacity.value,
                            child: Text(
                              'Connect Your Tribe From Anywhere',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                            height: 40,), // Fixed spacing instead of Spacer

                        // Show loading indicator while checking auth status
                        if (_isLoading)
                          const CircularProgressIndicator(
                            color: AppColors.primaryGreen,
                          ),

                        // Show different buttons based on authentication status
                        if (!_isLoading) ...[
                          // Continue to App button for authenticated users
                          if (_isAuthenticated)
                            SlideTransition(
                              position: _buttonSlide,
                              child: _buildGradientButton(
                                text: 'Continue to App',
                                onPressed: () {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    RouteName.mainNavigation,
                                  );
                                },
                              ),
                            ),

                          // Create Account and Login buttons for unauthenticated users
                          if (!_isAuthenticated) ...[
                            // Create Account Button - Direct to phone sign-up
                            SlideTransition(
                              position: _buttonSlide,
                              child: _buildGradientButton(
                                text: 'Create Account',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PhoneNumber(
                                        updatePhoneNumber: false,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(
                                height: 16,), // Modern spacing between buttons

                            // Login Button - Secondary style
                            SlideTransition(
                              position: _buttonSlide,
                              child: _buildOutlinedButton(
                                text: 'Login',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SignInMethodSelectionScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],

                        // Dynamic bottom spacing based on safe area
                        SizedBox(
                          height: MediaQuery.of(context).padding.bottom > 0
                              ? MediaQuery.of(context).padding.bottom + 32
                              : 40,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Clean logo without glow - stands confidently on its own
  Widget _buildCleanLogo() {
    return const AfropeepLogo(size: 280); // Doubled size - hero element
  }

  // Animated progress bar
  Widget _buildAnimatedProgressBar() => TweenAnimationBuilder<double>(
        duration: const Duration(seconds: 2),
        tween: Tween(begin: 0, end: 1),
        builder: (context, value, child) => Container(
          width: 200,
          height: 2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            gradient: LinearGradient(
              colors: [
                AppColors.primaryGreen.withValues(alpha: 0.1),
                AppColors.primaryGreen.withValues(alpha: 0.3),
                AppColors.primaryGreen.withValues(alpha: 0.1),
              ],
            ),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      );

  // Afropeep-branded button widget
  Widget _buildAfropeepButton({
    required String text,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) =>
      TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 1500),
        tween: Tween(begin: 0.98, end: 1),
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: isPrimary
              ? _buildPrimaryButton(text: text, onPressed: onPressed)
              : _buildSecondaryButton(text: text, onPressed: onPressed),
        ),
      );

  // Primary button: Green gradient with white text
  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
  }) =>
      Container(
        width: double.infinity,
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
            HapticFeedback.lightImpact();
            onPressed();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.textOnPrimary,
            shadowColor: Colors.transparent,
            minimumSize: const Size(double.infinity, 56),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
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

  // Secondary button: Ghost style with green border
  Widget _buildSecondaryButton({
    required String text,
    required VoidCallback onPressed,
  }) =>
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.backgroundColor.withValues(alpha: 0.5), // Light cream fill
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.primaryGreen,
            width: 2,
          ),
        ),
        child: OutlinedButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.primaryGreen,
            side: BorderSide.none,
            minimumSize: const Size(double.infinity, 56),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
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
              color: AppColors.primaryGreen,
            ),
          ),
        ),
      );

  // Legacy methods kept for compatibility - now use _buildAfropeepButton
  Widget _buildGradientButton({
    required String text,
    required VoidCallback onPressed,
  }) =>
      _buildAfropeepButton(
        text: text,
        onPressed: onPressed,
        isPrimary: true,
      );

  Widget _buildOutlinedButton({
    required String text,
    required VoidCallback onPressed,
  }) =>
      _buildAfropeepButton(
        text: text,
        onPressed: onPressed,
        isPrimary: false,
      );
}
