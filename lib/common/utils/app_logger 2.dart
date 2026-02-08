import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Centralized logging utility for the app
/// Replaces print() statements with proper logging
///
/// Usage:
/// ```dart
/// AppLogger.debug('Debug message');
/// AppLogger.info('Info message');
/// AppLogger.warning('Warning message');
/// AppLogger.error('Error message', error: e, stackTrace: st);
/// ```
class AppLogger {
  /// Debug-level logging (verbose, development only)
  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      developer.log(
        message,
        name: 'DEBUG',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Info-level logging (general information)
  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'INFO',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Warning-level logging (warnings that don't break functionality)
  static void warning(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'WARNING',
      error: error,
      stackTrace: stackTrace,
      level: 900, // Warning level
    );
  }

  /// Error-level logging (errors that need attention)
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: 'ERROR',
      error: error,
      stackTrace: stackTrace,
      level: 1000, // Error level
    );
  }
}
