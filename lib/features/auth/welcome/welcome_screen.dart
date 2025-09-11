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

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isAuthenticated = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
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

    // final screenSize = MediaQuery.of(context).size; // Available for future use

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // Subtle Afrocentric pattern background
          color: AppColors.backgroundColor,
          image: DecorationImage(
            image: const AssetImage('assets/images/african_pattern.png'),
            fit: BoxFit.cover,
            opacity: 0.03, // Very subtle pattern
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 1),

                // Enhanced Afropeep Logo with green glow
                _buildEnhancedLogo(),
                
                const SizedBox(height: 24),
                
                // Stylized Afropeep text with Montserrat
                Text(
                  "Afropeep",
                  style: GoogleFonts.montserrat(
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: 1.2,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 16),

                // Animated progress bar instead of decorative line
                _buildAnimatedProgressBar(),

                const SizedBox(height: 32),

                // Welcome message
                Text(
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

                const SizedBox(height: 16),

                // Rotating greeting in African languages
                const RotatingGreetingWidget(),

                const SizedBox(height: 24),

                // Main tagline
                Text(
                  "Connect Your Tribe From Anywhere",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),

                const Spacer(flex: 2),

                // Show loading indicator while checking auth status
                if (_isLoading)
                  const CircularProgressIndicator(
                    color: AppColors.primaryGreen,
                  ),

                // Show different buttons based on authentication status
                if (!_isLoading) ...[
                  // Continue to App button for authenticated users
                  if (_isAuthenticated)
                    _buildGradientButton(
                      text: "Continue to App",
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                            context, RouteName.mainNavigation);
                      },
                    ),

                  // Create Account and Login buttons for unauthenticated users
                  if (!_isAuthenticated) ...[
                    // Create Account Button
                    _buildGradientButton(
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

                    const SizedBox(height: 16),

                    // Login Button
                    _buildOutlinedButton(
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
                  ],
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Enhanced logo with green glow effect
  Widget _buildEnhancedLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.primaryGreen.withOpacity(0.1),
            AppColors.primaryGreen.withOpacity(0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primaryGreen.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: const AfropeepLogo(size: 60),
        ),
      ),
    );
  }

  // Animated progress bar
  Widget _buildAnimatedProgressBar() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 2),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Container(
          width: 200,
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: AppColors.primaryGreen.withOpacity(0.2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(2),
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
              onPressed: onPressed,
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
