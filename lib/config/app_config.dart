import 'package:flutter/foundation.dart';

import 'secure_config.dart';

// App Configuration Constants
class AppConfig {
  // App Information
  static const String appName = 'Afropeep';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String baseUrl = 'https://api.naijasingles.com';

  // Feature Flags
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enablePushNotifications = true;

  // Social Media Links
  static const String instagramUrl = 'https://instagram.com/afropeep';
  static const String twitterUrl = 'https://twitter.com/afropeep';
  static const String facebookUrl = 'https://facebook.com/afropeep';

  // Support
  static const String supportEmail = 'support@afropeep.com';
  static const String privacyPolicyUrl = 'https://afropeep.com/privacy';
  static const String termsOfServiceUrl = 'https://afropeep.com/terms';

  /// Community guidelines (settings / safety).
  static const String communityGuidelinesUrl =
      'https://afropeep.com/community-guidelines';

  /// Android `applicationId` (Google Play) — must match Play Console for receipt checks.
  static const String androidApplicationId = 'com.app.naijasingles';

  /// Rollout guard: set `--dart-define=SUBSCRIPTION_VERIFY_ROLLOUT=false` only while
  /// the callable is not live (users will not get premium until verification succeeds).
  static const bool subscriptionVerifyRollout = bool.fromEnvironment(
    'SUBSCRIPTION_VERIFY_ROLLOUT',
    defaultValue: true,
  );
}

// Privacy policy and terms URLs
const String termConditionUrl = 'https://afropeep.com/terms';
const String privacyUrl = 'https://afropeep.com/privacy';

// Add google map key for google places search
String get googleMapsKey {
  final key = SecureConfig.googleMapsApiKey ?? '';
  if (key.isEmpty && kDebugMode) {
    debugPrint(
      'WARNING: Google Maps API key is empty. '
      'Set GOOGLE_MAPS_API_KEY in your .env file.',
    );
  }
  return key;
}

/// Key used for Places Autocomplete / Place Details / Geocoding HTTP.
/// Prefer [SecureConfig.googleMapsWebApiKey] (no app bundle restriction).
String get googleMapsPlacesHttpKey {
  final String key = SecureConfig.googleMapsWebApiKey ?? '';
  if (key.isEmpty && kDebugMode) {
    debugPrint(
      'WARNING: Google Maps Places HTTP key is empty. '
      'Set GOOGLE_MAPS_WEB_API_KEY (API-restricted, no app restriction).',
    );
  }
  return key;
}

//for support to user add you mail
const adminMail = 'support@afropeep.com';
// add bucket id from firebase or google-services-json
String get bucketId => SecureConfig.firebaseStorageBucket;
//for pagination set limit

const int perPageData = 20;
