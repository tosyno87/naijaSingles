import 'package:flutter/material.dart';

/// Staging environment configuration
class StagingConfig {
  static const Color primaryGreen =
      Color(0xFF059669); // Darker green for staging
  static const String appNamePostfix = ' (Alpha)';
  static const String appVersion = '1.0.0-alpha';
  static const String environment = 'staging';

  // Firebase project ID for staging
  static const String firebaseProjectId = 'naijasingles-74a75';

  // App identifiers with staging suffix
  static const String applicationIdSuffix = '.staging';

  // API URLs (staging endpoints)
  static const String baseApiUrl = 'https://staging-api.naijasingles.com';
  static const String baseWebUrl = 'https://staging.naijasingles.com';

  // Feature flags - enable more debugging for staging
  static const bool enableDebugLogs = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashlytics = true;

  // App store configuration (TestFlight/Internal Testing)
  static const String appStoreId = 'com.naijasingles.app.staging';
  static const String playStoreId = 'com.naijasingles.app.staging';

  // Security settings - more relaxed for testing
  static const bool requireStrongPasswords = false;
  static const int sessionTimeoutMinutes = 60;
}
