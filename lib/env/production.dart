import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart' show DefaultFirebaseOptions;

/// Production environment configuration
class ProductionConfig {
  static const Color primaryGreen = Color(0xFF10B981); // Emerald green
  static const String appNamePostfix = '';
  static const String appVersion = '1.0.0';
  static const String environment = 'production';
  
  // Firebase project ID for production
  static const String firebaseProjectId = 'naijasingles-74a75';
  
  // App identifiers
  static const String applicationIdSuffix = '';
  
  // API URLs (if applicable)
  static const String baseApiUrl = 'https://api.naijasingles.com';
  static const String baseWebUrl = 'https://naijasingles.com';
  
  // Feature flags
  static const bool enableDebugLogs = false;
  static const bool enableAnalytics = true;
  static const bool enableCrashlytics = true;
  
  // App store configuration
  static const String appStoreId = 'com.naijasingles.app'; // Replace with actual ID
  static const String playStoreId = 'com.naijasingles.app'; // Replace with actual ID
  
  // Security settings
  static const bool requireStrongPasswords = true;
  static const int sessionTimeoutMinutes = 30;
}
