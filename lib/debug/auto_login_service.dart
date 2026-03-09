import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service to automatically log in a test user for development/testing.
///
/// Credentials are injected via --dart-define at build time.
/// Only callable in debug mode — [kDebugMode] gate prevents execution in release.
class AutoLoginService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _testEmail = String.fromEnvironment(
    'TEST_EMAIL',
    defaultValue: 'test@naijasingles.com',
  );
  static const String _testPassword = String.fromEnvironment(
    'TEST_PASSWORD',
  );

  /// Automatically sign in a test user for development
  static Future<bool> autoLoginForTesting() async {
    if (!kDebugMode) {
      debugPrint('Auto-login only available in debug mode');
      return false;
    }
    if (_testPassword.isEmpty) {
      debugPrint('Auto-login skipped: pass --dart-define=TEST_PASSWORD=...');
      return false;
    }

    try {
      debugPrint('🔄 Attempting auto-login for testing...');

      // Check if already signed in
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        debugPrint('✅ Already signed in as: ${currentUser.uid}');
        return true;
      }

      // Sign in with test credentials
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _testEmail,
        password: _testPassword,
      );

      if (userCredential.user != null) {
        debugPrint('✅ Auto-login successful: ${userCredential.user!.uid}');
        return true;
      }

      return false;
    } on Object catch (e) {
      debugPrint('❌ Auto-login failed: $e');

      // If test user doesn't exist, try to create it
      try {
        debugPrint('🔄 Creating test user...');
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: _testEmail,
          password: _testPassword,
        );

        if (userCredential.user != null) {
          debugPrint(
            '✅ Test user created and signed in: ${userCredential.user!.uid}',
          );
          return true;
        }
      } on Object catch (createError) {
        debugPrint('❌ Failed to create test user: $createError');
      }

      return false;
    }
  }

  /// Sign out the test user
  static Future<void> signOutTestUser() async {
    if (!kDebugMode) return;

    try {
      await _auth.signOut();
      debugPrint('✅ Test user signed out');
    } on Object catch (e) {
      debugPrint('❌ Error signing out: $e');
    }
  }

  /// Check if current user is the test user
  static bool isTestUser() {
    if (!kDebugMode) return false;

    final currentUser = _auth.currentUser;
    return currentUser?.email == _testEmail;
  }
}
