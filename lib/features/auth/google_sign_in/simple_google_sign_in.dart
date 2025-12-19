import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SimpleGoogleSignIn {
  factory SimpleGoogleSignIn() => _instance;
  SimpleGoogleSignIn._internal();
  // Create a singleton instance
  static final SimpleGoogleSignIn _instance = SimpleGoogleSignIn._internal();

  // Firebase and Google Sign-In instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Simple method to sign in with Google
  Future<User?> signIn() async {
    try {
      log('Starting simple Google Sign-In process...');

      // Sign out first to ensure a fresh sign-in attempt
      await _googleSignIn.signOut();
      log('Signed out from previous Google session');

      // Begin interactive sign-in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      log("Google Sign-In result: ${googleUser != null ? 'Success' : 'Canceled/Failed'}");

      if (googleUser == null) {
        log('Google Sign-In was canceled by user');
        return null;
      }

      // Get authentication details
      log('Getting Google authentication details...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      log('Got auth tokens - Access token: ${googleAuth.accessToken != null}, ID token: ${googleAuth.idToken != null}');

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      log('Signing in to Firebase with Google credential...');
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        log('Google Sign-In successful. User: ${user.uid}');
        return user;
      } else {
        log('Failed to sign in with Google - user is null');
        return null;
      }
    } catch (e) {
      log('Error in simple Google Sign-In: $e');
      return null;
    }
  }
}

// A simple labelLarge widget that uses the SimpleGoogleSignIn class
class SimpleGoogleSignInButton extends StatefulWidget {
  const SimpleGoogleSignInButton({
    required this.onSignInComplete,
    super.key,
  });
  final Function(User?) onSignInComplete;

  @override
  State<SimpleGoogleSignInButton> createState() =>
      _SimpleGoogleSignInButtonState();
}

class _SimpleGoogleSignInButtonState extends State<SimpleGoogleSignInButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) => ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        onPressed: _isLoading ? null : _handleSignIn,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'asset/auth/google_logo.png',
              height: 24,
              width: 24,
            ),
            const SizedBox(width: 12),
            if (_isLoading)
              const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Text(
                'Sign in with Google',
                style: TextStyle(fontSize: 16),
              ),
          ],
        ),
      );

  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await SimpleGoogleSignIn().signIn();
      widget.onSignInComplete(user);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
