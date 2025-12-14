import 'package:flutter/material.dart';

/// Development environment configuration
class DevelopmentConfig {
  static const Color primaryGreen = Color(0xFF059669); // Default green
  static const String appNamePostfix = ' (Dev)';
  static const String appVersion = '1.0.0-dev';
  static const String environment = 'development';

  // Firebase project ID for development (use emulator or dev project)
  static const String firebaseProjectId = 'naijasingles-dev';

  // App identifiers with dev suffix
  static const String applicationIdSuffix = '.dev';

  // API URLs (localhost or dev endpoints)
  static const String baseApiUrl = 'http://localhost:3000';
  static const String baseWebUrl = 'http://localhost:8080';

  // Feature flags - enable all debugging for development
  static const bool enableDebugLogs = true;
  static const bool enableAnalytics = false;
  static const bool enableCrashlytics = false;

  // App store configuration (not applicable for dev)
  static const String appStoreId = 'com.naijasingles.app.dev';
  static const String playStoreId = 'com.naijasingles.app.dev';

  // Security settings - very relaxed for development
  static const bool requireStrongPasswords = false;
  static const int sessionTimeoutMinutes = 120;
}
