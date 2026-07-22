import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../common/utils/app_logger.dart';

/// Secure configuration service that loads sensitive values from environment variables
/// This prevents API keys and other secrets from being committed to source control
class SecureConfig {
  static bool _initialized = false;
  static bool _dotenvLoaded = false;

  /// Production Firebase defaults when `.env` is absent (matches firebase_options).
  static const String _fallbackStorageBucket =
      'naijasingles-74a75.appspot.com';
  static const String _fallbackProjectId = 'naijasingles-74a75';

  /// Initialize the configuration by loading environment variables
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Prefer local bundled env (assets/env/app.env from sync script).
      // Fall back to optional root `.env` asset if present.
      // isOptional: missing file must not leave dotenv uninitialized.
      const String fromDefine = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
      try {
        await dotenv.load(
          fileName: 'assets/env/app.env',
          isOptional: false,
          mergeWith: fromDefine.isEmpty
              ? const <String, String>{}
              : <String, String>{'GOOGLE_MAPS_API_KEY': fromDefine},
        );
      } on Object {
        await dotenv.load(
          fileName: '.env',
          isOptional: true,
          mergeWith: fromDefine.isEmpty
              ? const <String, String>{}
              : <String, String>{'GOOGLE_MAPS_API_KEY': fromDefine},
        );
      }
      _initialized = true;
      _dotenvLoaded = dotenv.env.isNotEmpty;
      if (kDebugMode) {
        if (_dotenvLoaded) {
          AppLogger.info('✅ Secure configuration loaded successfully');
        } else {
          AppLogger.info(
            'ℹ️ .env empty or missing; using firebase_options.dart defaults',
          );
        }
      }
    } on Object catch (e) {
      _initialized = true;
      _dotenvLoaded = false;
      if (kDebugMode) {
        AppLogger.info(
          'ℹ️ .env not loaded; using firebase_options.dart defaults',
        );
        AppLogger.debug('SecureConfig .env load error: $e');
      } else if (kReleaseMode) {
        AppLogger.warning(
          '⚠️ .env file not found in production - using Firebase defaults',
        );
      }
    }
  }

  /// Safe read — never throws [NotInitializedError].
  static String? _env(String key) {
    if (!dotenv.isInitialized) return null;
    final String? value = dotenv.env[key];
    if (value == null || value.isEmpty) return null;
    return value;
  }

  /// Get Firebase Web API Key
  static String get firebaseWebApiKey {
    final String? value = _env('FIREBASE_WEB_API_KEY');
    if (value != null) return value;
    if (kReleaseMode) {
      return 'AIzaSyDummyKeyForProduction'; // overridden by firebase_options.dart
    }
    throw Exception('FIREBASE_WEB_API_KEY not found in environment');
  }

  /// Get Firebase Android API Key
  static String get firebaseAndroidApiKey =>
      _env('FIREBASE_ANDROID_API_KEY') ??
      (throw Exception('FIREBASE_ANDROID_API_KEY not found in environment'));

  /// Get Firebase iOS API Key
  static String get firebaseIosApiKey =>
      _env('FIREBASE_IOS_API_KEY') ??
      (throw Exception('FIREBASE_IOS_API_KEY not found in environment'));

  /// Get Firebase Project ID
  static String get firebaseProjectId =>
      _env('FIREBASE_PROJECT_ID') ?? _fallbackProjectId;

  /// Get Firebase Messaging Sender ID
  static String get firebaseMessagingSenderId =>
      _env('FIREBASE_MESSAGING_SENDER_ID') ??
      (throw Exception(
        'FIREBASE_MESSAGING_SENDER_ID not found in environment',
      ));

  /// Get Firebase Storage Bucket
  static String get firebaseStorageBucket =>
      _env('FIREBASE_STORAGE_BUCKET') ?? _fallbackStorageBucket;

  /// Get Firebase Auth Domain
  static String get firebaseAuthDomain =>
      _env('FIREBASE_AUTH_DOMAIN') ?? '$_fallbackProjectId.firebaseapp.com';

  /// Get Firebase iOS Client ID
  static String get firebaseIosClientId =>
      _env('FIREBASE_IOS_CLIENT_ID') ??
      (throw Exception('FIREBASE_IOS_CLIENT_ID not found in environment'));

  /// Get Firebase iOS Bundle ID
  static String get firebaseIosBundleId =>
      _env('FIREBASE_IOS_BUNDLE_ID') ?? 'com.app.naijasingles';

  /// Get Google Maps API Key
  static String? get googleMapsApiKey {
    const String fromDefine = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
    if (fromDefine.isNotEmpty) return fromDefine;
    return _env('GOOGLE_MAPS_API_KEY');
  }

  /// Get current environment
  static String get environment =>
      _env('APP_ENVIRONMENT') ?? 'development';

  /// Check if running in production
  static bool get isProduction => environment == 'production';

  /// Check if running in development
  static bool get isDevelopment => environment == 'development';

  /// Validate that all required configuration is present
  /// In production, validation is optional since Firebase uses firebase_options.dart
  static void validate() {
    if (!_initialized) {
      if (kReleaseMode) {
        AppLogger.warning(
          '⚠️ SecureConfig not initialized - using Firebase defaults',
        );
        return;
      }
      throw Exception('SecureConfig not initialized. Call initialize() first.');
    }
    if (!_dotenvLoaded) {
      if (kDebugMode) {
        AppLogger.info(
          'ℹ️ SecureConfig validation skipped; using firebase_options.dart',
        );
      }
      return;
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
      if (_env(key) == null) {
        missingKeys.add(key);
      }
    }

    if (missingKeys.isNotEmpty) {
      if (kReleaseMode) {
        AppLogger.warning(
          '⚠️ Some environment variables missing - using Firebase defaults',
        );
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
