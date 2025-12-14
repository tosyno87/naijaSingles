import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service to automatically log in a test user for development/testing
class AutoLoginService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Test user credentials - replace with your actual test user
  static const String _testEmail = 'test@naijasingles.com';
  static const String _testPassword = 'testpassword123';

  /// Automatically sign in a test user for development
  static Future<bool> autoLoginForTesting() async {
    if (!kDebugMode) {
      debugPrint('Auto-login only available in debug mode');
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
    } catch (e) {
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
              '✅ Test user created and signed in: ${userCredential.user!.uid}',);
          return true;
        }
      } catch (createError) {
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
    } catch (e) {
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
