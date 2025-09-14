import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Secure configuration service that loads sensitive values from environment variables
/// This prevents API keys and other secrets from being committed to source control
class SecureConfig {
  static bool _initialized = false;
  
  /// Initialize the configuration by loading environment variables
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await dotenv.load(fileName: ".env");
      _initialized = true;
      if (kDebugMode) {
        print('✅ Secure configuration loaded successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to load .env file: $e');
        print('⚠️ Make sure to create .env file from env.example');
      }
      // In production, we should fail fast if config is missing
      if (kReleaseMode) {
        throw Exception('Missing environment configuration');
      }
    }
  }
  
  /// Get Firebase Web API Key
  static String get firebaseWebApiKey {
    return dotenv.env['FIREBASE_WEB_API_KEY'] ?? 
           (throw Exception('FIREBASE_WEB_API_KEY not found in environment'));
  }
  
  /// Get Firebase Android API Key
  static String get firebaseAndroidApiKey {
    return dotenv.env['FIREBASE_ANDROID_API_KEY'] ?? 
           (throw Exception('FIREBASE_ANDROID_API_KEY not found in environment'));
  }
  
  /// Get Firebase iOS API Key
  static String get firebaseIosApiKey {
    return dotenv.env['FIREBASE_IOS_API_KEY'] ?? 
           (throw Exception('FIREBASE_IOS_API_KEY not found in environment'));
  }
  
  /// Get Firebase Project ID
  static String get firebaseProjectId {
    return dotenv.env['FIREBASE_PROJECT_ID'] ?? 
           (throw Exception('FIREBASE_PROJECT_ID not found in environment'));
  }
  
  /// Get Firebase Messaging Sender ID
  static String get firebaseMessagingSenderId {
    return dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? 
           (throw Exception('FIREBASE_MESSAGING_SENDER_ID not found in environment'));
  }
  
  /// Get Firebase Storage Bucket
  static String get firebaseStorageBucket {
    return dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 
           (throw Exception('FIREBASE_STORAGE_BUCKET not found in environment'));
  }
  
  /// Get Firebase Auth Domain
  static String get firebaseAuthDomain {
    return dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? 
           (throw Exception('FIREBASE_AUTH_DOMAIN not found in environment'));
  }
  
  /// Get Firebase iOS Client ID
  static String get firebaseIosClientId {
    return dotenv.env['FIREBASE_IOS_CLIENT_ID'] ?? 
           (throw Exception('FIREBASE_IOS_CLIENT_ID not found in environment'));
  }
  
  /// Get Firebase iOS Bundle ID
  static String get firebaseIosBundleId {
    return dotenv.env['FIREBASE_IOS_BUNDLE_ID'] ?? 
           (throw Exception('FIREBASE_IOS_BUNDLE_ID not found in environment'));
  }
  
  /// Get Google Maps API Key
  static String? get googleMapsApiKey {
    return dotenv.env['GOOGLE_MAPS_API_KEY'];
  }
  
  /// Get current environment
  static String get environment {
    return dotenv.env['APP_ENVIRONMENT'] ?? 'development';
  }
  
  /// Check if running in production
  static bool get isProduction => environment == 'production';
  
  /// Check if running in development
  static bool get isDevelopment => environment == 'development';
  
  /// Validate that all required configuration is present
  static void validate() {
    if (!_initialized) {
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
      throw Exception('Missing required environment variables: ${missingKeys.join(', ')}');
    }
    
    if (kDebugMode) {
      print('✅ All required configuration validated successfully');
    }
  }
}
