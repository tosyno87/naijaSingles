import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../common/constants/app_colors.dart';
import '../../../../../common/widgets/afropeep_app_bar.dart';
import '../../../../../common/widgets/afropeep_primary_button.dart';
import '../../../../../common/widgets/afropeep_text_field.dart';
import '../../../../../common/widgets/auth_icon_container.dart';
import '../../../../../common/widgets/custom_snackbar.dart';
import '../../bloc/email_auth_bloc.dart';

class EmailPasswordResetScreen extends StatefulWidget {
  const EmailPasswordResetScreen({super.key});

  @override
  State<EmailPasswordResetScreen> createState() =>
      _EmailPasswordResetScreenState();
}

class _EmailPasswordResetScreenState extends State<EmailPasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  // Using centralized AppColors - no need for local color constants

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style for status bar
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ),);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: const AfropeepAppBar(
        title: 'Reset Password',
      ),
      body: BlocProvider(
        create: (context) => EmailAuthBloc(),
        child: BlocConsumer<EmailAuthBloc, EmailAuthState>(
          listener: (context, state) {
            if (state is EmailPasswordResetSent) {
              CustomSnackbar.showSnackBarSimple(
                'Password reset email sent. Check your inbox.',
                context,
              );
              Navigator.pop(context);
            } else if (state is EmailAuthError) {
              CustomSnackbar.showSnackBarSimple(
                state.error,
                context,
              );
            }
          },
          builder: (context, state) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Center(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Lock reset icon using reusable widget
                          const AuthIconContainer(
                            icon: Icons.lock_reset_outlined,
                          ),

                          const SizedBox(height: 32),

                          // Header
                          Text(
                            'Forgot Your Password?',
                            style: GoogleFonts.montserrat(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Enter your email address and we\'ll send you a link to reset your password',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),

                          // Email Field using reusable widget
                          AfropeepTextField(
                            controller: _emailController,
                            hintText: 'Email',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            onChanged: () => setState(() {}),
                            validationChecker: (text) => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(text),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 40),

                          // Send Reset Link Button using reusable widget
                          AfropeepPrimaryButton(
                            text: 'Send Reset Link',
                            isLoading: state is EmailAuthLoading,
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                context.read<EmailAuthBloc>().add(
                                      EmailPasswordResetRequested(
                                        email: _emailController.text.trim(),
                                      ),
                                    );
                              }
                            },
                          ),

                          const SizedBox(height: 24),

                          // Back to Login
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Back to Login',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
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
}
