import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

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

  Future<void> _checkAuthAndNavigate() async {
    try {
      if (!mounted || _hasNavigated) return;

      // Safety check for Navigator state during hot reload
      if (!Navigator.canPop(context) &&
          Navigator.of(context).widget.initialRoute == null) {
        log('Navigator state issue detected, skipping navigation');
        return;
      }

      // Trigger auth check - navigation will be handled by BlocListener
      final authBloc = BlocProvider.of<AuthstatusBloc>(context);
      authBloc.add(AuthRequestEvent());

      // Wait for auth state to be determined with timeout
      // The BlocListener will handle navigation when state changes
      const maxWaitTime = Duration(seconds: 3);
      final startTime = DateTime.now();

      while (DateTime.now().difference(startTime) < maxWaitTime &&
          !_hasNavigated) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;

        final currentState = authBloc.state;
        if (currentState is AuthenticatedState ||
            currentState is UnauthenticatedState ||
            currentState is AuthFailed) {
          // State is determined, BlocListener should have handled it
          // If not, handle it here
          if (!_hasNavigated && mounted) {
            if (currentState is AuthenticatedState) {
              _hasNavigated = true;
              log('Timeout fallback: User authenticated, navigating to main screen');
              Navigator.pushReplacementNamed(context, RouteName.mainNavigation);
              return;
            } else {
              _hasNavigated = true;
              log('Timeout fallback: Navigating to welcome screen');
              Navigator.pushReplacementNamed(context, RouteName.welcomeScreen);
              return;
            }
          }
        }
      }

      // Final fallback: navigate to welcome screen if still stuck
      if (!mounted || _hasNavigated) return;

      _hasNavigated = true;
      log('Final fallback: Navigating to welcome screen');
      Navigator.pushReplacementNamed(context, RouteName.welcomeScreen);
    } catch (e) {
      log('Error in _checkAuthAndNavigate: $e');
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        Navigator.pushReplacementNamed(context, RouteName.welcomeScreen);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Modern splash screen colors - white background matching app theme
    const Color backgroundColor = Colors.white; // White background (MVP color)
    const Color primaryGreen = Color(0xFF008037); // Afropeep green
    const Color textColor =
        Color(0xFF3B3B3B); // Dark brown/charcoal (not pure black)

    return Scaffold(
      backgroundColor: backgroundColor,
      body: BlocListener<AuthstatusBloc, AuthstatusState>(
        listener: (context, state) {
          log('Auth state changed in splash listener: $state');

          // Only handle if we haven't navigated yet
          if (!mounted || _hasNavigated) return;

          // Safety check for Navigator state during hot reload
          if (!Navigator.canPop(context) &&
              Navigator.of(context).widget.initialRoute == null) {
            log('Navigator state issue detected in listener, skipping navigation');
            return;
          }

          // Navigate based on auth state
          if (state is AuthenticatedState) {
            _hasNavigated = true;
            log('User authenticated in listener: ${state.user.uid}');
            Navigator.pushReplacementNamed(context, RouteName.mainNavigation);
          } else if (state is UnauthenticatedState) {
            _hasNavigated = true;
            log('User not authenticated in listener - going to welcome');
            Navigator.pushReplacementNamed(context, RouteName.welcomeScreen);
          } else if (state is AuthFailed) {
            _hasNavigated = true;
            log('Authentication failed in listener: ${state.message}');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Authentication error: ${state.message}')),
              );
              Navigator.pushReplacementNamed(context, RouteName.welcomeScreen);
            }
          }
          // If still loading or initial state, wait for _checkAuthAndNavigate to handle it
        },
        child: Stack(
          children: [
            // Optional: Very subtle gradient from white to soft green tint at bottom
            Positioned.fill(
              child: Opacity(
                opacity: 0.05, // 5% opacity for very subtle effect
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        backgroundColor,
                        const Color(0xFF27A957).withValues(alpha: 
                            0.1), // Very subtle green tint at bottom
                      ],
                      stops: const [0.7, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Main content - centered with breathing space
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo - green on light background
                  // If logo image is transparent, it will show in its natural color
                  // If we need to force green, we'd use ColorFilter, but let's try without first
                  const AfropeepLogo(size: 120),

                  const SizedBox(height: 24),

                  // App name - single wordmark in dark brown/charcoal
                  Text(
                    'Afropeep',
                    style: GoogleFonts.montserrat(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: textColor, // Dark brown/charcoal, not pure black
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Subtle loading indicator at bottom (only shown if initialization takes time)
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      primaryGreen
                          .withValues(alpha: 0.6), // Soft green, not too prominent
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
