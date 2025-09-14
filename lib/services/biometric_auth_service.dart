import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_ios/local_auth_ios.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer';

/// Industry-standard biometric authentication service
/// Features:
/// - Face ID / Touch ID / Fingerprint support
/// - Secure credential storage
/// - Fallback authentication methods
/// - Biometric enrollment detection
/// - Security settings management
class BiometricAuthService {
  static final BiometricAuthService _instance = BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;
  BiometricAuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  // Biometric authentication settings
  static const String _biometricEnabledKey = 'biometric_auth_enabled';
  static const String _biometricEnrolledKey = 'biometric_enrolled';
  static const String _lastBiometricAuthKey = 'last_biometric_auth';

  /// Check if biometric authentication is available on device
  Future<bool> isBiometricAvailable() async {
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      
      log('🔐 Biometric availability check: available=$isAvailable, supported=$isDeviceSupported');
      
      return isAvailable && isDeviceSupported;
    } catch (e) {
      log('❌ Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();
      log('🔐 Available biometrics: $availableBiometrics');
      return availableBiometrics;
    } catch (e) {
      log('❌ Error getting available biometrics: $e');
      return [];
    }
  }

  /// Check if user has enrolled biometrics
  Future<bool> hasEnrolledBiometrics() async {
    try {
      final List<BiometricType> biometrics = await getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } catch (e) {
      log('❌ Error checking enrolled biometrics: $e');
      return false;
    }
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
      // Check if biometrics are available
      if (!await isBiometricAvailable()) {
        log('❌ Biometric authentication not available');
        return false;
      }

      // Check if user has enrolled biometrics
      if (!await hasEnrolledBiometrics()) {
        log('❌ No enrolled biometrics found');
        return false;
      }

      // Test biometric authentication
      final bool authenticated = await authenticateWithBiometrics(
        reason: 'Enable biometric authentication for quick access',
        useErrorDialogs: true,
      );

      if (authenticated) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_biometricEnabledKey, true);
        await prefs.setBool(_biometricEnrolledKey, true);
        await prefs.setString(_lastBiometricAuthKey, DateTime.now().toIso8601String());
        
        log('✅ Biometric authentication enabled successfully');
        return true;
      }

      return false;
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

  /// Authenticate with biometrics
  Future<bool> authenticateWithBiometrics({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      // Check if biometric auth is enabled
      if (!await isBiometricEnabled()) {
        log('❌ Biometric authentication not enabled');
        return false;
      }

      // Check if biometrics are available
      if (!await isBiometricAvailable()) {
        log('❌ Biometric authentication not available');
        return false;
      }

      final bool authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        authMessages: _getAuthMessages(),
        options: AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: stickyAuth,
          sensitiveTransaction: true,
        ),
      );

      if (authenticated) {
        // Update last authentication time
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastBiometricAuthKey, DateTime.now().toIso8601String());
        
        log('✅ Biometric authentication successful');
        return true;
      } else {
        log('❌ Biometric authentication failed');
        return false;
      }
    } catch (e) {
      log('❌ Error during biometric authentication: $e');
      return false;
    }
  }

  /// Get platform-specific authentication messages
  List<AuthMessages> _getAuthMessages() {
    if (Platform.isAndroid) {
      return [
        AndroidAuthMessages(
          signInTitle: 'Biometric Authentication',
          cancelButton: 'Cancel',
          deviceCredentialsRequiredTitle: 'Device Credentials Required',
          deviceCredentialsSetupDescription: 'Device credentials are not set up on your device. Go to Settings > Security > Screen lock to set up a screen lock.',
          goToSettingsButton: 'Go to Settings',
          goToSettingsDescription: 'Please set up your device credentials to enable biometric authentication.',
        ),
      ];
    } else if (Platform.isIOS) {
      return [
        IOSAuthMessages(
          cancelButton: 'Cancel',
          goToSettingsButton: 'Go to Settings',
          goToSettingsDescription: 'Please set up Touch ID or Face ID to enable biometric authentication.',
          lockOut: 'Biometric authentication is locked. Please use your passcode.',
        ),
      ];
    }
    return [];
  }

  /// Quick authentication for returning users
  Future<bool> quickAuthenticate() async {
    if (!await isBiometricEnabled()) {
      return false;
    }

    return await authenticateWithBiometrics(
      reason: 'Quick access to your account',
      useErrorDialogs: true,
    );
  }

  /// Setup biometric authentication for new users
  Future<bool> setupBiometricAuth(BuildContext context) async {
    try {
      // Check availability
      if (!await isBiometricAvailable()) {
        _showBiometricUnavailableDialog(context);
        return false;
      }

      // Check enrollment
      if (!await hasEnrolledBiometrics()) {
        _showBiometricNotEnrolledDialog(context);
        return false;
      }

      // Show setup dialog
      final bool shouldSetup = await _showBiometricSetupDialog(context);
      if (!shouldSetup) {
        return false;
      }

      // Enable biometric auth
      return await enableBiometricAuth();
    } catch (e) {
      log('❌ Error setting up biometric authentication: $e');
      return false;
    }
  }

  /// Show biometric setup dialog
  Future<bool> _showBiometricSetupDialog(BuildContext context) async {
    final biometrics = await getAvailableBiometrics();
    String biometricType = 'biometric';
    
    if (biometrics.contains(BiometricType.face)) {
      biometricType = 'Face ID';
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      biometricType = 'Touch ID';
    } else if (biometrics.contains(BiometricType.iris)) {
      biometricType = 'Iris';
    }

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              biometrics.contains(BiometricType.face) 
                  ? Icons.face 
                  : Icons.fingerprint,
              color: Colors.green,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text('Enable $biometricType'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Secure your account with $biometricType for quick and safe access.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Benefits:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('• Quick access without passwords'),
                  Text('• Enhanced security'),
                  Text('• Works offline'),
                  Text('• Industry standard'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Enable $biometricType'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Show biometric unavailable dialog
  void _showBiometricUnavailableDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 12),
            Text('Biometric Unavailable'),
          ],
        ),
        content: const Text(
          'Biometric authentication is not available on this device. You can still use the app with your password.',
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

  /// Show biometric not enrolled dialog
  void _showBiometricNotEnrolledDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 12),
            Text('Setup Required'),
          ],
        ),
        content: const Text(
          'Please set up biometric authentication in your device settings first.',
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

  /// Get biometric authentication status
  Future<BiometricAuthStatus> getAuthStatus() async {
    try {
      final bool isAvailable = await isBiometricAvailable();
      final bool isEnabled = await isBiometricEnabled();
      final bool hasEnrolled = await hasEnrolledBiometrics();
      final List<BiometricType> biometrics = await getAvailableBiometrics();

      return BiometricAuthStatus(
        isAvailable: isAvailable,
        isEnabled: isEnabled,
        hasEnrolled: hasEnrolled,
        availableBiometrics: biometrics,
        lastAuthTime: await _getLastAuthTime(),
      );
    } catch (e) {
      log('❌ Error getting auth status: $e');
      return BiometricAuthStatus(
        isAvailable: false,
        isEnabled: false,
        hasEnrolled: false,
        availableBiometrics: [],
        lastAuthTime: null,
      );
    }
  }

  /// Get last authentication time
  Future<DateTime?> _getLastAuthTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeString = prefs.getString(_lastBiometricAuthKey);
      if (timeString != null) {
        return DateTime.parse(timeString);
      }
      return null;
    } catch (e) {
      log('❌ Error getting last auth time: $e');
      return null;
    }
  }

  /// Check if biometric auth should be prompted
  Future<bool> shouldPromptForBiometric() async {
    try {
      if (!await isBiometricEnabled()) {
        return false;
      }

      final lastAuth = await _getLastAuthTime();
      if (lastAuth == null) {
        return true; // Never authenticated
      }

      // Prompt if last auth was more than 24 hours ago
      final now = DateTime.now();
      final difference = now.difference(lastAuth);
      return difference.inHours >= 24;
    } catch (e) {
      log('❌ Error checking biometric prompt: $e');
      return false;
    }
  }
}

/// Biometric authentication status model
class BiometricAuthStatus {
  final bool isAvailable;
  final bool isEnabled;
  final bool hasEnrolled;
  final List<BiometricType> availableBiometrics;
  final DateTime? lastAuthTime;

  const BiometricAuthStatus({
    required this.isAvailable,
    required this.isEnabled,
    required this.hasEnrolled,
    required this.availableBiometrics,
    this.lastAuthTime,
  });

  bool get canUseBiometric => isAvailable && isEnabled && hasEnrolled;
  
  String get biometricType {
    if (availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Touch ID';
    } else if (availableBiometrics.contains(BiometricType.iris)) {
      return 'Iris';
    }
    return 'Biometric';
  }

  @override
  String toString() {
    return 'BiometricAuthStatus(available: $isAvailable, enabled: $isEnabled, enrolled: $hasEnrolled, type: $biometricType)';
  }
}
