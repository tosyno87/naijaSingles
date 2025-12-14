import 'secure_config.dart';

// App Configuration Constants
class AppConfig {
  // App Information
  static const String appName = 'NaijaSingles';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String baseUrl = 'https://api.naijasingles.com';

  // Feature Flags
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enablePushNotifications = true;

  // Social Media Links
  static const String instagramUrl = 'https://instagram.com/naijasingles';
  static const String twitterUrl = 'https://twitter.com/naijasingles';
  static const String facebookUrl = 'https://facebook.com/naijasingles';

  // Support
  static const String supportEmail = 'support@naijasingles.com';
  static const String privacyPolicyUrl = 'https://naijasingles.com/privacy';
  static const String termsOfServiceUrl = 'https://naijasingles.com/terms';
}

// Privacy policy and terms URLs
const String termConditionUrl = 'https://naijasingles.com/terms';
const String privacyUrl = 'https://naijasingles.com/privacy';

// Add google map key for google places search
String get googleMapsKey => SecureConfig.googleMapsApiKey ?? '';
//for support to user add you mail
const adminMail = 'support@naijasingles.com';
// add bucket id from firebase or google-services-json
String get bucketId => SecureConfig.firebaseStorageBucket;
//for pagination set limit

const int perPageData = 20;
