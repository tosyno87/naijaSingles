import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../common/data/repo/phone_auth_repo.dart';
import '../../../common/routes/route_name.dart';
import '../../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithEmail() async {
    // Validate inputs
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      setState(() => _error = 'Please enter a valid email address');
      return;
    }
    
    if (_passwordController.text.isEmpty || _passwordController.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }
    
    setState(() {
      _loading = true;
      _error = null;
    });
    
    try {
      // Use AuthService instead of direct Firebase call
      await _authService.signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        RouteName.mvpOnboarding,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred during login.';
      }
      setState(() => _error = errorMessage);
    } catch (e) {
      setState(() => _error = 'An unexpected error occurred.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loginWithTestPhone() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = PhoneAuthRepository();
      await repo.signInWithTestPhone();
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        RouteName.mvpOnboarding,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style for status bar
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              
              // Logo and headline
              Center(
                child: Column(
                  children: [
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BCD4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          "NS",
                          style: GoogleFonts.montserrat(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Welcome to NaijaSingles",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Where Love Meets Culture",
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: Colors.grey[400],
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Email input
              _buildTextField(
                controller: _emailController,
                label: "Email",
                hint: "Enter your email",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              
              const SizedBox(height: 20),
              
              // Password input
              _buildTextField(
                controller: _passwordController,
                label: "Password",
                hint: "Enter your password",
                icon: Icons.lock_outline,
                isPassword: true,
                obscureText: _obscurePassword,
                toggleObscureText: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              
              const SizedBox(height: 32),
              
              // Login button with simple implementation to avoid animation issues
              _buildButton(
                text: "LOGIN",
                onPressed: _loading ? null : _loginWithEmail,
                isPrimary: true,
              ),
              
              const SizedBox(height: 16),
              
              // Test phone login button
              _buildButton(
                text: "USE TEST PHONE",
                onPressed: _loading ? null : _loginWithTestPhone,
                isPrimary: false,
              ),
              
              const SizedBox(height: 24),
              
              // Error message
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: GoogleFonts.montserrat(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Loading indicator
              if (_loading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFF00BCD4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Logging in...",
                          style: GoogleFonts.montserrat(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? toggleObscureText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && obscureText,
            keyboardType: keyboardType,
            style: GoogleFonts.robotoMono(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.robotoMono(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              prefixIcon: Icon(
                icon,
                color: const Color(0xFF00BCD4),
                size: 20,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      onPressed: toggleObscureText,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback? onPressed,
    required bool isPrimary,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? const Color(0xFF00BCD4) : Colors.transparent,
          foregroundColor: isPrimary ? Colors.white : const Color(0xFF00BCD4),
          disabledBackgroundColor: isPrimary ? Colors.grey[700] : Colors.transparent,
          disabledForegroundColor: Colors.grey[600],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isPrimary
                ? BorderSide.none
                : const BorderSide(color: Color(0xFF00BCD4)),
          ),
          elevation: isPrimary ? 4 : 0,
          shadowColor: isPrimary ? const Color(0xFF00BCD4).withOpacity(0.5) : Colors.transparent,
        ),
        child: Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
