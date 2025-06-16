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
      // Rich earthy background with gradient
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8B4513), // Earthy brown
              Color(0xFF3D1C02), // Deep brown
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                
                // Adinkra symbol header
                Center(
                  child: Column(
                    children: [
                      // Sankofa symbol (represents learning from the past)
                      Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFFD700), // Gold
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            "♥",
                            style: TextStyle(
                              fontSize: 50,
                              color: const Color(0xFFFFD700), // Gold
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 5,
                                  offset: const Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "NaijaSingles",
                        style: GoogleFonts.pacifico(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD700), // Gold
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 5,
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Where Love Meets Heritage",
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          color: Colors.orange[100],
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Kente pattern divider
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFE57C23), // Orange
                        Color(0xFFFFD700), // Gold
                        Color(0xFF006400), // Green
                        Color(0xFFE57C23), // Orange
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Email input with African mask icon
                _buildTextField(
                  controller: _emailController,
                  label: "Email",
                  hint: "Enter your email",
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: Color(0xFFFFD700), // Gold
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                
                const SizedBox(height: 20),
                
                // Password input with shield icon
                _buildTextField(
                  controller: _passwordController,
                  label: "Password",
                  hint: "Enter your password",
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFFFFD700), // Gold
                  ),
                  isPassword: true,
                  obscureText: _obscurePassword,
                  toggleObscureText: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Login button with African pattern
                _buildButton(
                  text: "CONNECT",
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
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.5),
                      ),
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
                            style: GoogleFonts.lato(
                              color: Colors.red[100],
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
                          // Custom loading indicator with African colors
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                const Color(0xFFFFD700), // Gold
                              ),
                              backgroundColor: Colors.orange.withOpacity(0.2),
                              strokeWidth: 4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Connecting...",
                            style: GoogleFonts.lato(
                              color: Colors.orange[100],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 40),
                
                // African proverb footer
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "\"If you want to go quickly, go alone. If you want to go far, go together.\"",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        fontStyle: FontStyle.italic,
                        color: Colors.orange[100],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Widget prefixIcon,
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
          style: GoogleFonts.lato(
            color: Colors.orange[100],
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.brown.shade900.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE57C23).withOpacity(0.5), // Orange border
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && obscureText,
            keyboardType: keyboardType,
            style: GoogleFonts.lato(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.lato(
                color: Colors.orange[100]!.withOpacity(0.5),
                fontSize: 16,
              ),
              prefixIcon: prefixIcon,
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility : Icons.visibility_off,
                        color: Colors.orange[100]!.withOpacity(0.7),
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
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: const Color(0xFFE57C23).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? const Color(0xFFE57C23) // Orange
              : Colors.transparent,
          foregroundColor:
              isPrimary ? Colors.white : const Color(0xFFFFD700), // Gold
          disabledBackgroundColor:
              isPrimary ? Colors.brown.withOpacity(0.3) : Colors.transparent,
          disabledForegroundColor: Colors.grey[500],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isPrimary
                ? BorderSide.none
                : const BorderSide(color: Color(0xFFFFD700)), // Gold border
          ),
          elevation: isPrimary ? 0 : 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(
          text,
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
