import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

import 'env/development.dart';
import 'env/production.dart';
import 'env/staging.dart';
import 'firebase_options.dart';

/// Environment configuration enum
enum Env { dev, staging, prod }

/// Environment detection based on compile-time flags
class Environment {
  static Env get current => () {
        const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
        switch (flavor) {
          case 'staging':
            return Env.staging;
          case 'production':
            return Env.prod;
          default:
            return Env.dev;
        }
      }();

  /// Get the appropriate configuration based on current environment
  static T config<T>() {
    switch (current) {
      case Env.staging:
        return _getStagingConfig<T>();
      case Env.prod:
        return _getProductionConfig<T>();
      default:
        return _getDevelopmentConfig<T>();
    }
  }

  // Type-safe configuration getters
  static T _getProductionConfig<T>() {
    if (T == Color) return ProductionConfig.primaryGreen as T;
    if (T == String) return ProductionConfig.appNamePostfix as T;
    throw UnimplementedError('Configuration not found for $T in production');
  }

  static T _getStagingConfig<T>() {
    if (T == Color) return StagingConfig.primaryGreen as T;
    if (T == String) return StagingConfig.appNamePostfix as T;
    throw UnimplementedError('Configuration not found for $T in staging');
  }

  static T _getDevelopmentConfig<T>() {
    if (T == Color) return DevelopmentConfig.primaryGreen as T;
    if (T == String) return DevelopmentConfig.appNamePostfix as T;
    throw UnimplementedError('Configuration not found for $T in development');
  }

  // Convenience getters for commonly used values
  static Color get primaryGreen => config<Color>();
  static String get appNamePostfix => config<String>();

  static String get appName {
    switch (current) {
      case Env.staging:
        return 'Afropeep${StagingConfig.appNamePostfix}';
      case Env.prod:
        return 'Afropeep${ProductionConfig.appNamePostfix}';
      default:
        return 'Afropeep${DevelopmentConfig.appNamePostfix}';
    }
  }

  static String get appVersion {
    switch (current) {
      case Env.staging:
        return StagingConfig.appVersion;
      case Env.prod:
        return ProductionConfig.appVersion;
      default:
        return DevelopmentConfig.appVersion;
    }
  }

  static String get environment {
    switch (current) {
      case Env.staging:
        return StagingConfig.environment;
      case Env.prod:
        return ProductionConfig.environment;
      default:
        return DevelopmentConfig.environment;
    }
  }

  static String get firebaseProjectId {
    // Allow override via environment variable first
    const fromEnv = String.fromEnvironment('FIREBASE_PROJECT_ID');
    if (fromEnv.isNotEmpty) return fromEnv;

    // Fall back to environment-specific defaults
    switch (current) {
      case Env.staging:
        return StagingConfig.firebaseProjectId;
      case Env.prod:
        return ProductionConfig.firebaseProjectId;
      default:
        return DevelopmentConfig.firebaseProjectId;
    }
  }

  static String get applicationIdSuffix {
    switch (current) {
      case Env.staging:
        return StagingConfig.applicationIdSuffix;
      case Env.prod:
        return ProductionConfig.applicationIdSuffix;
      default:
        return DevelopmentConfig.applicationIdSuffix;
    }
  }

  static String get baseApiUrl {
    switch (current) {
      case Env.staging:
        return StagingConfig.baseApiUrl;
      case Env.prod:
        return ProductionConfig.baseApiUrl;
      default:
        return DevelopmentConfig.baseApiUrl;
    }
  }

  static String get baseWebUrl {
    switch (current) {
      case Env.staging:
        return StagingConfig.baseWebUrl;
      case Env.prod:
        return ProductionConfig.baseWebUrl;
      default:
        return DevelopmentConfig.baseWebUrl;
    }
  }

  static bool get enableDebugLogs {
    switch (current) {
      case Env.staging:
        return StagingConfig.enableDebugLogs;
      case Env.prod:
        return ProductionConfig.enableDebugLogs;
      default:
        return DevelopmentConfig.enableDebugLogs;
    }
  }

  static bool get enableAnalytics {
    switch (current) {
      case Env.staging:
        return StagingConfig.enableAnalytics;
      case Env.prod:
        return ProductionConfig.enableAnalytics;
      default:
        return DevelopmentConfig.enableAnalytics;
    }
  }

  static bool get enableCrashlytics {
    switch (current) {
      case Env.staging:
        return StagingConfig.enableCrashlytics;
      case Env.prod:
        return ProductionConfig.enableCrashlytics;
      default:
        return DevelopmentConfig.enableCrashlytics;
    }
  }

  static bool get requireStrongPasswords {
    switch (current) {
      case Env.staging:
        return StagingConfig.requireStrongPasswords;
      case Env.prod:
        return ProductionConfig.requireStrongPasswords;
      default:
        return DevelopmentConfig.requireStrongPasswords;
    }
  }

  static int get sessionTimeoutMinutes {
    switch (current) {
      case Env.staging:
        return StagingConfig.sessionTimeoutMinutes;
      case Env.prod:
        return ProductionConfig.sessionTimeoutMinutes;
      default:
        return DevelopmentConfig.sessionTimeoutMinutes;
    }
  }

  /// Check if current environment is production
  static bool get isProduction => current == Env.prod;

  /// Check if current environment is staging
  static bool get isStaging => current == Env.staging;

  /// Check if current environment is development
  static bool get isDevelopment => current == Env.dev;

  /// Get Firebase options for current environment
  static FirebaseOptions get firebaseOptions =>
      DefaultFirebaseOptions.currentPlatform;

  /// Debug information about current environment
  static Map<String, dynamic> get debugInfo => {
        'environment': environment,
        'flavor': const String.fromEnvironment('FLAVOR', defaultValue: 'dev'),
        'firebaseProjectId': firebaseProjectId,
        'appVersion': appVersion,
        'appName': appName,
        'enableDebugLogs': enableDebugLogs,
        'enableAnalytics': enableAnalytics,
        'enableCrashlytics': enableCrashlytics,
      };
}
