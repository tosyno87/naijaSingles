import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:naijasingles/common/providers/theme_provider.dart';
import 'package:naijasingles/common/routes/route_name.dart';
import 'package:naijasingles/common/widgets/afropeep_logo.dart';
import 'package:naijasingles/features/auth/phone/ui/widgets/facebook_button.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../../../common/constants/colors.dart';
import '../../../../../common/providers/user_provider.dart';
import '../../../../../common/utils/app_exit.dart';
import '../../../../../common/widgets/custom_snackbar.dart';
import '../../../auth_status/bloc/registration/bloc/registration_bloc.dart';
import '../../../facebook_login/facebook_login_bloc.dart';
import '../../../facebook_login/facebook_login_events.dart';
import '../../../facebook_login/facebook_login_states.dart';
import '../widgets/privacy_policy.dart';

class LoginOption extends StatefulWidget {
  const LoginOption({super.key});

  @override
  State<LoginOption> createState() => _LoginOptionState();
}

// Removed SingleTickerProviderStateMixin to fix the _ticker error
class _LoginOptionState extends State<LoginOption> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          return;
        }
        final bool shouldPop = await onWillPop(context);
        if (shouldPop) {
          SystemChannels.platform.invokeMethod('SystemNavigator.pop');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: MultiBlocListener(
          listeners: [
            BlocListener<FacebookLoginBloc, FacebookLoginStates>(
              listener: (context, state) {
                if (state is FacebookLoginLoading) {
                  CustomSnackbar.showSnackBarSimple(
                      'Please wait. Loading..'.tr().toString(), context);
                }

                if (state is FacebookLoginFailed) {
                  CustomSnackbar.showSnackBarSimple(state.message, context);
                }

                if (state is FacebookLoginSuccess) {
                  log("Success called facebook");
                  state.user?.getIdToken().then((value) async {
                    // call registration after facebook_login
                    log("Success called facebook with $value");
                    context
                        .read<RegistrationBloc>()
                        .add(CheckRegistration(token: value!));
                  });
                }
              },
            ),
            BlocListener<RegistrationBloc, RegistrationStates>(
              listener: (context, state) {
                if (state is RegistrationLoading) {
                  CustomSnackbar.showSnackBarSimple(
                      'Please wait. Loading..'.tr().toString(), context);
                }
                if (state is AlreadyRegistered) {
                  Provider.of<UserProvider>(context, listen: false)
                      .currentUser = state.user;
                  UserProvider().listenAuthChanges();
                  Navigator.of(context)
                      .pushNamed(RouteName.tabScreen, arguments: state.user);
                } else if (state is NewRegistration) {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, RouteName.welcomeScreen);
                } else if (state is RegistrationFailed) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
            )
          ],
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Colors.green[50]!,
                  Colors.green[100]!,
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: screenSize.height * 0.08),
                      
                      // Logo
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: AfropeepLogo(size: 70),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Text(
                        "Afropeep",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                          letterSpacing: 1.2,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Text(
                        "Find your perfect match in the African community",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                      
                      SizedBox(height: screenSize.height * 0.08),
                      
                      // Login buttons
                      Column(
                        children: [
                          // Facebook login button
                          _buildSocialButton(
                            icon: Icons.facebook,
                            text: "Continue with Facebook",
                            color: Colors.green[700]!,
                            onTap: () {
                              context.read<FacebookLoginBloc>()
                                  .add(FacebookLoginRequest());
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Phone login button
                          _buildSocialButton(
                            icon: Icons.phone,
                            text: "Continue with Phone",
                            color: Colors.white,
                            textColor: Colors.green[700]!,
                            borderColor: Colors.green[700]!,
                            onTap: () {
                              Navigator.pushNamed(context, RouteName.phoneNumberScreen);
                            },
                          ),
                        ],
                      ),
                      
                      SizedBox(height: screenSize.height * 0.04),
                      
                      // Terms text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          "By continuing, you agree with our Terms of Service and Privacy Policy",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Privacy links
                      const PrivacyPolicy(),
                      
                      SizedBox(height: screenSize.height * 0.04),
                      
                      // Help text
                      TextButton(
                        onPressed: () {
                          // Handle trouble logging in
                        },
                        child: Text(
                          "Trouble logging in?",
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      SizedBox(height: screenSize.height * 0.02),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSocialButton({
    required IconData icon,
    required String text,
    required Color color,
    Color textColor = Colors.white,
    Color? borderColor,
    required VoidCallback onTap,
  }) {
    return Material(
      elevation: borderColor != null ? 0 : 2,
      shadowColor: color.withOpacity(0.4),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(30),
            border: borderColor != null
                ? Border.all(color: borderColor, width: 1.5)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 22),
              const SizedBox(width: 12),
              Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
