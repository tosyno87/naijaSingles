import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'secure_storage_service.dart';

/// Stub implementation of biometric authentication service
/// This is used when local_auth packages are not available due to dependency conflicts
class BiometricAuthService {
  factory BiometricAuthService() => _instance;
  BiometricAuthService._internal();
  static final BiometricAuthService _instance =
      BiometricAuthService._internal();

  // Biometric authentication settings
  static const String _biometricEnabledKey = 'biometric_auth_enabled';
  static const String _biometricEnrolledKey = 'biometric_enrolled';
  static const String _lastBiometricAuthKey = 'last_biometric_auth';

  /// Check if biometric authentication is available on device
  Future<bool> isBiometricAvailable() async {
    log('⚠️ Biometric authentication temporarily disabled due to dependency conflict');
    return false;
  }

  /// Get available biometric types
  Future<List<String>> getAvailableBiometrics() async {
    log('⚠️ Biometric authentication temporarily disabled due to dependency conflict');
    return [];
  }

  /// Check if user has enrolled biometrics
  Future<bool> hasEnrolledBiometrics() async {
    log('⚠️ Biometric authentication temporarily disabled due to dependency conflict');
    return false;
  }

  /// Check if biometric authentication is enabled by user
  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricEnabledKey) ?? false;
    } on Object catch (e) {
      log('❌ Error checking biometric enabled status: $e');
      return false;
    }
  }

  /// Enable biometric authentication
  Future<bool> enableBiometricAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, true);
      log('✅ Biometric authentication enabled');
      return true;
    } on Object catch (e) {
      log('❌ Error enabling biometric authentication: $e');
      return false;
    }
  }

  /// Disable biometric authentication
  Future<bool> disableBiometricAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, false);
      log('✅ Biometric authentication disabled');
      return true;
    } on Object catch (e) {
      log('❌ Error disabling biometric authentication: $e');
      return false;
    }
  }

  /// Authenticate using biometrics
  Future<bool> authenticateWithBiometrics({
    String? reason,
    String? cancelButton,
    bool stickyAuth = true,
  }) async {
    log('⚠️ Biometric authentication temporarily disabled due to dependency conflict');
    return false;
  }

  /// Authenticate with biometrics and store credentials
  /// Uses secure storage for sensitive credential data
  Future<bool> authenticateAndStoreCredentials({
    required String email,
    required String password,
    String? reason,
  }) async {
    log('⚠️ Biometric authentication temporarily disabled due to dependency conflict');

    // When biometric auth is re-enabled, use secure storage for credentials
    // Example implementation (commented out until biometric auth is enabled):
    /*
    try {
      final credentials = jsonEncode({
        'email': email,
        'password': password,
      });
      final secureStorage = SecureStorageService();
      await secureStorage.storeBiometricCredentials(credentials);
      log('✅ Biometric credentials stored securely');
      return true;
    } on Object catch (e) {
      log('❌ Error storing biometric credentials: $e');
      return false;
    }
    */
    return false;
  }

  /// Get stored credentials using biometric authentication
  /// Retrieves credentials from secure storage
  Future<Map<String, String>?> getStoredCredentials({
    String? reason,
  }) async {
    log('⚠️ Biometric authentication temporarily disabled due to dependency conflict');

    // When biometric auth is re-enabled, retrieve from secure storage
    // Example implementation (commented out until biometric auth is enabled):
    /*
    try {
      final secureStorage = SecureStorageService();
      final credentialsJson = await secureStorage.getBiometricCredentials();
      if (credentialsJson != null) {
        final credentials = jsonDecode(credentialsJson) as Map<String, dynamic>;
        return {
          'email': credentials['email'] as String,
          'password': credentials['password'] as String,
        };
      }
      return null;
    } on Object catch (e) {
      log('❌ Error retrieving biometric credentials: $e');
      return null;
    }
    */
    return null;
  }

  /// Clear stored biometric credentials
  /// Clears both secure storage credentials and SharedPreferences settings
  Future<bool> clearStoredCredentials() async {
    try {
      // Clear secure storage credentials
      try {
        final secureStorage = SecureStorageService();
        await secureStorage.deleteBiometricCredentials();
        log('✅ Biometric credentials cleared from secure storage');
      } on Object catch (e) {
        log('⚠️ Error clearing secure storage credentials: $e');
        // Continue to clear SharedPreferences
      }

      // Clear SharedPreferences settings (non-sensitive)
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_biometricEnabledKey);
      await prefs.remove(_biometricEnrolledKey);
      await prefs.remove(_lastBiometricAuthKey);
      log('✅ Biometric settings cleared');
      return true;
    } on Object catch (e) {
      log('❌ Error clearing biometric credentials: $e');
      return false;
    }
  }

  /// Check if biometric authentication is recommended
  Future<bool> isBiometricRecommended() async {
    log('⚠️ Biometric authentication temporarily disabled due to dependency conflict');
    return false;
  }

  /// Get biometric authentication status
  Future<Map<String, dynamic>> getBiometricStatus() async => {
        'available': false,
        'enabled': await isBiometricEnabled(),
        'enrolled': false,
        'recommended': false,
        'lastAuth': null,
        'message':
            'Biometric authentication temporarily disabled due to dependency conflict',
      };

  /// Show biometric settings dialog
  Future<void> showBiometricSettingsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Biometric Authentication'),
        content: const Text(
          'Biometric authentication is temporarily disabled due to dependency conflicts. '
          'This feature will be re-enabled in a future update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Initialize biometric authentication
  Future<void> initializeBiometricAuth() async {
    log('⚠️ Biometric authentication initialization skipped due to dependency conflict');
  }

  /// Handle biometric authentication errors
  void handleBiometricError(PlatformException error) {
    log('❌ Biometric error: ${error.code} - ${error.message}');
  }

  /// Get biometric authentication help text
  String getBiometricHelpText() =>
      'Biometric authentication is temporarily disabled due to dependency conflicts. '
      'This feature will be re-enabled in a future update.';
}
