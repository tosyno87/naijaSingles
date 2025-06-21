import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../common/widgets/custom_snackbar.dart';
import '../../bloc/email_auth_bloc.dart';
import 'email_password_reset_screen.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({Key? key}) : super(key: key);

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Afropeep MVP theme colors
  static const Color backgroundColor = Color(0xFFFDF0E7);
  static const Color afropeepGreen = Color(0xFF007A33);
  static const Color cardBackground = Color(0xFFF7E8DA);
  static const Color textDarkBrown = Color(0xFF3A1D0F);
  static const Color textLightBrown = Color(0xFF8B6C59);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Log In',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textDarkBrown,
          ),
        ),
        backgroundColor: backgroundColor,
        foregroundColor: textDarkBrown,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDarkBrown),
      ),
      body: BlocProvider(
        create: (context) => EmailAuthBloc(),
        child: BlocConsumer<EmailAuthBloc, EmailAuthState>(
          listener: (context, state) {
            if (state is EmailAuthSuccess) {
              // Navigate to home screen
              Navigator.pushReplacementNamed(context, '/main_navigation');
            } else if (state is EmailAuthError) {
              CustomSnackbar.showSnackBarSimple(
                state.error,
                context,
              );
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Center(
                      child: Container(
                        height: 80,
                        width: 80,
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Image.asset(
                          'assets/images/logo2.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    
                    // Header
                    Text(
                      'Welcome Back',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: textDarkBrown,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Log in with your email and password',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: textLightBrown,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: textDarkBrown),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: textDarkBrown),
                        hintText: 'Enter your email address',
                        hintStyle: TextStyle(color: textLightBrown),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.email_outlined, color: textDarkBrown),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: textDarkBrown.withOpacity(0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: afropeepGreen, width: 2),
                        ),
                        filled: true,
                        fillColor: cardBackground,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(color: textDarkBrown),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: textDarkBrown),
                        hintText: 'Enter your password',
                        hintStyle: TextStyle(color: textLightBrown),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.lock_outline, color: textDarkBrown),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: textDarkBrown,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: textDarkBrown.withOpacity(0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: afropeepGreen, width: 2),
                        ),
                        filled: true,
                        fillColor: cardBackground,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EmailPasswordResetScreen(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: afropeepGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        child: Text(
                          'Forgot Password?',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            color: afropeepGreen,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Login Button
                    ElevatedButton(
                      onPressed: state is EmailAuthLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                context.read<EmailAuthBloc>().add(
                                      EmailSignInRequested(
                                        email: _emailController.text.trim(),
                                        password: _passwordController.text,
                                      ),
                                    );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: afropeepGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 4,
                        disabledBackgroundColor: afropeepGreen.withOpacity(0.6),
                      ),
                      child: state is EmailAuthLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Log In',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Don't have an account
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Don\'t have an account?',
                          style: GoogleFonts.poppins(
                            color: textLightBrown,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/email_signup');
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: afropeepGreen,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          child: Text(
                            'Sign Up',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: afropeepGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
