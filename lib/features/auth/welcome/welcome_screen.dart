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
  late Animation<double> _buttonFade;
  late Animation<double> _backgroundOpacity;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOutBack),
    );

    // NEW: Fade-in animation for buttons
    _buttonFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeIn),
    );

    _backgroundOpacity = Tween<double>(begin: 0.0, end: 0.02).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
    );

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
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ));

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        top: true,
        bottom: true,
        maintainBottomViewPadding: true,
        child: AnimatedBuilder(
          animation: _backgroundOpacity,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE9F5EC), // Mint green background
                image: DecorationImage(
                  image: const AssetImage('assets/images/african_pattern.png'),
                  fit: BoxFit.cover,
                  opacity: _backgroundOpacity.value,
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top Section
                          Column(
                            children: [
                              const SizedBox(height: 20),
                              AnimatedBuilder(
                                animation: _logoScale,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _logoScale.value,
                                    child: Opacity(
                                      opacity:
                                          _logoScale.value.clamp(0.0, 1.0),
                                      child: _buildCleanLogo(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              AnimatedBuilder(
                                animation: _textOpacity,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _textOpacity.value,
                                    child: _buildAnimatedProgressBar(),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
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
                            ],
                          ),

                          // Middle Section
                          Column(
                            children: [
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
                              const SizedBox(height: 24),
                              AnimatedBuilder(
                                animation: _textOpacity,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _textOpacity.value,
                                    child: const RotatingGreetingWidget(),
                                  );
                                },
                              ),
                            ],
                          ),

                          const Spacer(),

                          // Bottom Section
                          Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  MediaQuery.of(context).viewInsets.bottom > 0
                                      ? 20
                                      : MediaQuery.of(context)
                                              .viewPadding
                                              .bottom +
                                          50,
                            ),
                            child: FadeTransition(
                              opacity: _buttonFade,
                              child: Column(
                                children: [
                                  if (_isLoading)
                                    const CircularProgressIndicator(
                                      color: Color(0xFF008037),
                                    ),
                                  if (!_isLoading) ...[
                                    if (_isAuthenticated)
                                      SlideTransition(
                                        position: _buttonSlide,
                                        child: _buildGradientButton(
                                          text: "Continue to App",
                                          onPressed: () {
                                            Navigator.pushReplacementNamed(
                                              context,
                                              RouteName.mainNavigation,
                                            );
                                          },
                                        ),
                                      ),
                                    if (!_isAuthenticated) ...[
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
                                      const SizedBox(height: 24),
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
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCleanLogo() {
    return const AfropeepLogo(size: 160);
  }

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