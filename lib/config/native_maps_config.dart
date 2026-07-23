import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Whether the native Google Maps SDK received a real API key at launch.
///
/// iOS reads `GMSApiKey` from Info.plist (Secrets.xcconfig). Creating a
/// [GoogleMap] without that key can hard-crash the process (TestFlight).
class NativeMapsConfig {
  NativeMapsConfig._();

  static const MethodChannel _channel =
      MethodChannel('com.app.naijasingles/maps_config');

  static bool? _cached;

  /// Returns true when native Maps was configured; false when missing.
  /// On non-iOS platforms, returns true (Android uses manifest placeholder).
  static Future<bool> isApiKeyConfigured({bool forceRefresh = false}) async {
    if (!forceRefresh && _cached != null) return _cached!;
    if (kIsWeb || !Platform.isIOS) {
      _cached = true;
      return true;
    }
    try {
      final Object? value =
          await _channel.invokeMethod<Object?>('isMapsApiKeyConfigured');
      _cached = value == true;
    } on Object {
      // Channel not ready / older build. In release, fail closed so we never
      // construct GoogleMap without a confirmed native key (TestFlight crash).
      _cached = !kReleaseMode;
    }
    return _cached!;
  }

  /// Clears the cached result so the next call re-queries the platform channel.
  static void clearCache() => _cached = null;

  /// Queries once, then retries after a short delay if the channel was not ready.
  static Future<bool> ensureConfigured() async {
    clearCache();
    final bool configured = await isApiKeyConfigured(forceRefresh: true);
    if (configured) return true;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    clearCache();
    return isApiKeyConfigured(forceRefresh: true);
  }
}
