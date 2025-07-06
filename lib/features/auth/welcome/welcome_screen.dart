import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../common/routes/route_name.dart';
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

    // Define colors
    const Color backgroundColor = Color(0xFFFFF6E5); // Warm cream/beige
    const Color primaryColor = Color(0xFF008037); // Deep Green
    const Color accentColor = Color(0xFFEF476F); // Warm coral red
    const Color textColor = Color(0xFF3E1F0D); // Deep brown

    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1),

              // Logo - Stylized Afropeep text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: const Color(0xFF008037),
                    size: 32,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Afropeep",
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4E2600), // Deep brown
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.auto_awesome,
                    color: const Color(0xFFEF476F), // Coral accent
                    size: 32,
                  ),
                ],
              ),

              // African pattern decorative element
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 180,
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF008037).withValues(alpha: 0.3),
                      const Color(0xFF008037),
                      const Color(0xFFEF476F),
                      const Color(0xFFEF476F).withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 24),

              // Tagline instead of app name
              Text(
                "Connect Your African Soul",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  color: textColor.withValues(alpha: 0.8),
                ),
              ),

              const SizedBox(height: 8),

              // Rotating greeting in African languages
              const RotatingGreetingWidget(),

              const SizedBox(height: 16),

              // Tagline
              Text(
                "Connect Your Tribe From Anywhere",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),

              const Spacer(flex: 2),

              // Show loading indicator while checking auth status
              if (_isLoading)
                const CircularProgressIndicator(
                  color: primaryColor,
                ),

              // Show different labelLarges based on authentication status
              if (!_isLoading) ...[
                // Continue to App labelLarge for authenticated users
                if (_isAuthenticated)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                            context, RouteName.mainNavigation);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        "Continue to App",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                // Create Account and Login labelLarges for unauthenticated users
                if (!_isAuthenticated) ...[
                  // Create Account Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AuthMethodSelectionScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        "Create Account",
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const SignInMethodSelectionScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: const BorderSide(color: primaryColor, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "Login",
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
