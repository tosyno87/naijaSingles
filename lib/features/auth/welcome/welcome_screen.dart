import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../common/routes/route_name.dart';
import '../../../common/widgets/afropeep_logo.dart';
import '../../../common/constants/app_colors.dart';
import '../auth_method/auth_method_selection_screen.dart';
import '../auth_method/sign_in_method_selection_screen.dart';
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
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    // Text fade-in animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    // Button slide-in animation
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeOutBack,
    ));

    // Background pattern fade-in animation
    _backgroundOpacity = Tween<double>(
      begin: 0.0,
      end: 0.02,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    // Start animations with delays
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _textController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      _buttonController.forward();
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
      final currentUser = FirebaseAuth.instance.currentUser;
      setState(() {
        _isAuthenticated = currentUser != null;
        _isLoading = false;
      });
      log("User authentication status: ${_isAuthenticated ? 'Authenticated' : 'Not authenticated'}");
    } catch (e) {
      log("Error checking auth status: $e");
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style for status bar
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ));

    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundOpacity,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              // Soft mint green background
              color: AppColors.backgroundColor,
              image: DecorationImage(
                image: const AssetImage('assets/images/african_pattern.png'),
                fit: BoxFit.cover,
                opacity: _backgroundOpacity.value, // Animated opacity for polish
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // Top content with flexible space
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20), // Reduced spacing for better fit

                            // Clean Afropeep Logo with bounce-in and fade animation
                            AnimatedBuilder(
                              animation: _logoScale,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _logoScale.value,
                                  child: Opacity(
                                    opacity: _logoScale.value.clamp(0.0, 1.0),
                                    child: _buildCleanLogo(),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 32), // Increased spacing for massive logo

                            // Animated progress bar instead of decorative line
                            AnimatedBuilder(
                              animation: _textOpacity,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _textOpacity.value,
                                  child: _buildAnimatedProgressBar(),
                                );
                              },
                            ),

                            const SizedBox(height: 40), // Increased spacing

                            // Welcome message with animation
                            AnimatedBuilder(
                              animation: _textOpacity,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _textOpacity.value,
                                  child: Text(
                                    "Welcome to Afropeep, your journey to meaningful connections starts here.",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 24), // Increased spacing

                            // Rotating greeting in African languages with animation
                            AnimatedBuilder(
                              animation: _textOpacity,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _textOpacity.value,
                                  child: const RotatingGreetingWidget(),
                                );
                              },
                            ),

                            const SizedBox(height: 32), // Increased spacing

                            // Main tagline with animation
                            AnimatedBuilder(
                              animation: _textOpacity,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _textOpacity.value,
                                  child: Text(
                                    "Connect Your Tribe From Anywhere",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                      height: 1.3,
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 40), // Fixed spacing instead of Spacer

                            // Content ends here - buttons moved to bottom section
                          ],
                        ),
                      ),
                    ),
                    
                    // Bottom buttons section with safe area padding
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Column(
                        children: [
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
                                  text: "Continue to App",
                                  onPressed: () {
                                    Navigator.pushReplacementNamed(
                                        context, RouteName.mainNavigation);
                                  },
                                ),
                              ),

                            // Create Account and Login buttons for unauthenticated users
                            if (!_isAuthenticated) ...[
                              // Create Account Button
                              SlideTransition(
                                position: _buttonSlide,
                                child: _buildGradientButton(
                                  text: "Create Account",
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AuthMethodSelectionScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(height: 16), // Proper spacing between buttons

                              // Login Button
                              SlideTransition(
                                position: _buttonSlide,
                                child: _buildOutlinedButton(
                                  text: "Login",
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Clean logo without glow - stands confidently on its own
  Widget _buildCleanLogo() {
    return const AfropeepLogo(size: 180); // Further reduced size for better fit
  }

  // Animated progress bar
  Widget _buildAnimatedProgressBar() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 2),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Container(
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
        );
      },
    );
  }

  // Gradient button with shadow and pulse effect
  Widget _buildGradientButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1500),
      tween: Tween(begin: 0.95, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppColors.buttonShadow,
            ),
            child: ElevatedButton(
              onPressed: () {
                // Add gentle haptic feedback
                HapticFeedback.lightImpact();
                onPressed();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.textOnPrimary,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                text,
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Outlined button with green border
  Widget _buildOutlinedButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primaryGreen,
          width: 2,
        ),
      ),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}