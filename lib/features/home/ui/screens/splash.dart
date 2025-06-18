import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/providers/theme_provider.dart';
import '../../../../common/providers/user_provider.dart';
import '../../../../common/routes/route_name.dart';
import '../../../../common/widgets/afropeep_logo.dart';
import '../../../auth/auth_status/bloc/authstatus_bloc.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  SplashState createState() => SplashState();
}

class SplashState extends State<Splash> {
  bool _hasNavigated = false;
  
  @override
  void initState() {
    super.initState();
    
    // Add a delay to show the splash screen
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_hasNavigated) {
        _checkAuthAndNavigate();
      }
    });
  }
  
  void _checkAuthAndNavigate() {
    try {
      if (!mounted || _hasNavigated) return;
      
      final authBloc = BlocProvider.of<AuthstatusBloc>(context);
      final state = authBloc.state;
      
      log("Current auth state: $state");
      
      if (state is AuthenticatedState) {
        _hasNavigated = true;
        log("User is authenticated, navigating to main screen");
        Navigator.pushReplacementNamed(context, RouteName.mainNavigation);
      } else if (state is UnauthenticatedState) {
        _hasNavigated = true;
        log("User is not authenticated, navigating to login screen");
        Navigator.pushReplacementNamed(context, RouteName.loginScreen);
      } else if (state is AuthFailed) {
        _hasNavigated = true;
        log("Authentication failed: ${state.message}");
        // Show error and navigate to login
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Authentication error: ${state.message}")),
        );
        Navigator.pushReplacementNamed(context, RouteName.loginScreen);
      }
    } catch (e) {
      log("Error in _checkAuthAndNavigate: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: BlocListener<AuthstatusBloc, AuthstatusState>(
        listener: (context, state) {
          log("Auth state changed in splash: $state");
          
          if (!mounted || _hasNavigated) return;
          
          if (state is AuthenticatedState) {
            _hasNavigated = true;
            log("User authenticated in listener: ${state.user.uid}");
            Navigator.pushReplacementNamed(context, RouteName.mainNavigation);
          } else if (state is UnauthenticatedState) {
            _hasNavigated = true;
            log("User not authenticated in listener");
            Navigator.pushReplacementNamed(context, RouteName.loginScreen);
          } else if (state is AuthFailed) {
            _hasNavigated = true;
            log("Authentication failed in listener: ${state.message}");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Authentication error: ${state.message}")),
            );
            Navigator.pushReplacementNamed(context, RouteName.loginScreen);
          }
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              const AfropeepLogo(size: 100),
              
              const SizedBox(height: 20),
              
              // App name
              Text(
                "NaijaSingles",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode ? Colors.white : Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
