import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../common/utils/app_logger.dart';

/// Secure configuration service that loads sensitive values from environment variables
/// This prevents API keys and other secrets from being committed to source control
class SecureConfig {
  static bool _initialized = false;

  /// Initialize the configuration by loading environment variables
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await dotenv.load();
      _initialized = true;
      if (kDebugMode) {
        AppLogger.info('✅ Secure configuration loaded successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.warning('⚠️ Failed to load .env file', error: e);
        AppLogger.warning('⚠️ Make sure to create .env file from env.example');
      }
      // In production, .env file may not be bundled - use fallback values
      // Firebase will use firebase_options.dart which has hardcoded values
      if (kReleaseMode) {
        AppLogger.warning('⚠️ .env file not found in production - using Firebase defaults');
        _initialized = true; // Mark as initialized to allow fallback behavior
      }
    }
  }

  /// Get Firebase Web API Key
  static String get firebaseWebApiKey {
    if (!_initialized || dotenv.env['FIREBASE_WEB_API_KEY'] == null) {
      // Fallback for production when .env is not available
      // These should match your actual Firebase project values
      if (kReleaseMode) {
        return 'AIzaSyDummyKeyForProduction'; // Will be overridden by firebase_options.dart
      }
      throw Exception('FIREBASE_WEB_API_KEY not found in environment');
    }
    return dotenv.env['FIREBASE_WEB_API_KEY']!;
  }

  /// Get Firebase Android API Key
  static String get firebaseAndroidApiKey =>
      dotenv.env['FIREBASE_ANDROID_API_KEY'] ??
      (throw Exception('FIREBASE_ANDROID_API_KEY not found in environment'));

  /// Get Firebase iOS API Key
  static String get firebaseIosApiKey =>
      dotenv.env['FIREBASE_IOS_API_KEY'] ??
      (throw Exception('FIREBASE_IOS_API_KEY not found in environment'));

  /// Get Firebase Project ID
  static String get firebaseProjectId =>
      dotenv.env['FIREBASE_PROJECT_ID'] ??
      (throw Exception('FIREBASE_PROJECT_ID not found in environment'));

  /// Get Firebase Messaging Sender ID
  static String get firebaseMessagingSenderId =>
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ??
      (throw Exception(
        'FIREBASE_MESSAGING_SENDER_ID not found in environment',
      ));

  /// Get Firebase Storage Bucket
  static String get firebaseStorageBucket =>
      dotenv.env['FIREBASE_STORAGE_BUCKET'] ??
      (throw Exception('FIREBASE_STORAGE_BUCKET not found in environment'));

  /// Get Firebase Auth Domain
  static String get firebaseAuthDomain =>
      dotenv.env['FIREBASE_AUTH_DOMAIN'] ??
      (throw Exception('FIREBASE_AUTH_DOMAIN not found in environment'));

  /// Get Firebase iOS Client ID
  static String get firebaseIosClientId =>
      dotenv.env['FIREBASE_IOS_CLIENT_ID'] ??
      (throw Exception('FIREBASE_IOS_CLIENT_ID not found in environment'));

  /// Get Firebase iOS Bundle ID
  static String get firebaseIosBundleId =>
      dotenv.env['FIREBASE_IOS_BUNDLE_ID'] ??
      (throw Exception('FIREBASE_IOS_BUNDLE_ID not found in environment'));

  /// Get Google Maps API Key
  static String? get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'];

  /// Get current environment
  static String get environment =>
      dotenv.env['APP_ENVIRONMENT'] ?? 'development';

  /// Check if running in production
  static bool get isProduction => environment == 'production';

  /// Check if running in development
  static bool get isDevelopment => environment == 'development';

  /// Validate that all required configuration is present
  /// In production, validation is optional since Firebase uses firebase_options.dart
  static void validate() {
    if (!_initialized) {
      if (kReleaseMode) {
        // In production, .env may not be available - Firebase uses firebase_options.dart
        AppLogger.warning('⚠️ SecureConfig not initialized - using Firebase defaults');
        return;
      }
      throw Exception('SecureConfig not initialized. Call initialize() first.');
    }

    final requiredKeys = [
      'FIREBASE_WEB_API_KEY',
      'FIREBASE_ANDROID_API_KEY',
      'FIREBASE_IOS_API_KEY',
      'FIREBASE_PROJECT_ID',
      'FIREBASE_MESSAGING_SENDER_ID',
      'FIREBASE_STORAGE_BUCKET',
      'FIREBASE_AUTH_DOMAIN',
      'FIREBASE_IOS_CLIENT_ID',
      'FIREBASE_IOS_BUNDLE_ID',
    ];

    final missingKeys = <String>[];
    for (final key in requiredKeys) {
      if (dotenv.env[key] == null || dotenv.env[key]!.isEmpty) {
        missingKeys.add(key);
      }
    }

    if (missingKeys.isNotEmpty) {
      if (kReleaseMode) {
        // In production, allow missing keys - Firebase will use firebase_options.dart
        AppLogger.warning('⚠️ Some environment variables missing - using Firebase defaults');
        return;
      }
      throw Exception(
        'Missing required environment variables: ${missingKeys.join(', ')}',
      );
    }

    if (kDebugMode) {
      AppLogger.info('✅ All required configuration validated successfully');
    }
  }
}
