import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
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
  Future<bool> authenticateAndStoreCredentials({
    required String email,
    required String password,
    String? reason,
  }) async {
    log('⚠️ Biometric authentication temporarily disabled due to dependency conflict');
    return false;
  }

  /// Get stored credentials using biometric authentication
  Future<Map<String, String>?> getStoredCredentials({
    String? reason,
  }) async {
    log('⚠️ Biometric authentication temporarily disabled due to dependency conflict');
    return null;
  }

  /// Clear stored biometric credentials
  Future<bool> clearStoredCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_biometricEnabledKey);
      await prefs.remove(_biometricEnrolledKey);
      await prefs.remove(_lastBiometricAuthKey);
      log('✅ Biometric credentials cleared');
      return true;
    } catch (e) {
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
    showDialog(
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
  String getBiometricHelpText() => 'Biometric authentication is temporarily disabled due to dependency conflicts. '
        'This feature will be re-enabled in a future update.';
}
