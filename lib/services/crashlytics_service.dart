import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../env.dart';

/// Service for Firebase Crashlytics crash reporting and analytics
/// 
/// This service provides:
/// - Automatic crash reporting
/// - Custom error logging
/// - User identification
/// - Custom keys for debugging
/// - Non-fatal error tracking
class CrashlyticsService {
  factory CrashlyticsService() => _instance;
  CrashlyticsService._internal();
  
  static final CrashlyticsService _instance = CrashlyticsService._internal();

  bool _initialized = false;

  /// Initialize Crashlytics service
  /// Should be called after Firebase.initializeApp()
  Future<void> initialize() async {
    if (_initialized) {
      log('⚠️ Crashlytics already initialized');
      return;
    }

    try {
      // Only enable Crashlytics in production and staging (not in development)
      if (Environment.enableCrashlytics) {
        // Pass all uncaught errors to Crashlytics
        FlutterError.onError = (errorDetails) {
          unawaited(
            FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails),
          );
        };

        // Pass all uncaught asynchronous errors to Crashlytics
        PlatformDispatcher.instance.onError = (error, stack) {
          unawaited(
            FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
          );
          return true;
        };

        // Set user identifier if user is logged in
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await setUserId(currentUser.uid);
        }

        // Set custom keys for debugging
        await setCustomKeys();

        _initialized = true;
        log('✅ Crashlytics initialized successfully');
      } else {
        log('⏭️ Crashlytics disabled in development mode');
        _initialized = true; // Mark as initialized to prevent re-initialization
      }
    } catch (e) {
      log('❌ Error initializing Crashlytics: $e');
      // Don't throw - app should continue even if Crashlytics fails
    }
  }

  /// Set user identifier for crash reports
  Future<void> setUserId(String userId) async {
    if (!_initialized || !Environment.enableCrashlytics) return;

    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId);
      log('✅ Crashlytics user ID set: $userId');
    } catch (e) {
      log('⚠️ Error setting Crashlytics user ID: $e');
    }
  }

  /// Clear user identifier (on logout)
  Future<void> clearUserId() async {
    if (!_initialized || !Environment.enableCrashlytics) return;

    try {
      await FirebaseCrashlytics.instance.setUserIdentifier('');
      log('✅ Crashlytics user ID cleared');
    } catch (e) {
      log('⚠️ Error clearing Crashlytics user ID: $e');
    }
  }

  /// Set custom keys for debugging
  Future<void> setCustomKeys() async {
    if (!_initialized || !Environment.enableCrashlytics) return;

    try {
      await FirebaseCrashlytics.instance.setCustomKey('app_version', Environment.appVersion);
      await FirebaseCrashlytics.instance.setCustomKey('environment', Environment.environment);
      await FirebaseCrashlytics.instance.setCustomKey('firebase_project', Environment.firebaseProjectId);
      log('✅ Crashlytics custom keys set');
    } catch (e) {
      log('⚠️ Error setting Crashlytics custom keys: $e');
    }
  }

  /// Log a non-fatal error
  /// Use this for errors that don't crash the app but should be tracked
  Future<void> logError(
    exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    if (!_initialized || !Environment.enableCrashlytics) return;

    try {
      if (reason != null) {
        await FirebaseCrashlytics.instance.log(reason);
      }
      await FirebaseCrashlytics.instance.recordError(
        exception,
        stackTrace,
        fatal: fatal,
      );
      log('📊 Error logged to Crashlytics: $exception');
    } catch (e) {
      log('⚠️ Error logging to Crashlytics: $e');
    }
  }

  /// Log a custom message
  /// Use this for important events or debugging information
  Future<void> logMessage(String message) async {
    if (!_initialized || !Environment.enableCrashlytics) return;

    try {
      await FirebaseCrashlytics.instance.log(message);
      if (kDebugMode) {
        log('📝 Crashlytics log: $message');
      }
    } catch (e) {
      log('⚠️ Error logging message to Crashlytics: $e');
    }
  }

  /// Set additional custom key-value pairs for debugging
  Future<void> setCustomKey(String key, value) async {
    if (!_initialized || !Environment.enableCrashlytics) return;

    try {
      await FirebaseCrashlytics.instance.setCustomKey(key, value);
    } catch (e) {
      log('⚠️ Error setting custom key: $e');
    }
  }

  /// Check if Crashlytics is enabled
  bool get isEnabled => _initialized && Environment.enableCrashlytics;
}

