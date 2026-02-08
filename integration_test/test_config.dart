import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Configuration for African diaspora integration testing
class DiasporaTestConfig {
  static const String testEnvironment = 'integration_test';

  /// US phone numbers for testing diaspora registration
  static const Map<String, String> testPhoneNumbers = {
    'atlanta': '+1 404 555 0123', // Atlanta, GA
    'washington_dc': '+1 202 555 0124', // Washington, DC
    'new_york': '+1 212 555 0125', // New York, NY
    'houston': '+1 713 555 0126', // Houston, TX
    'chicago': '+1 312 555 0127', // Chicago, IL
    'los_angeles': '+1 213 555 0128', // Los Angeles, CA
    'boston': '+1 617 555 0129', // Boston, MA
    'minneapolis': '+1 612 555 0130', // Minneapolis, MN
  };

  /// African countries for testing cultural background
  static const List<String> testAfricanCountries = [
    'Nigeria',
    'Ghana',
    'Ethiopia',
    'Kenya',
    'South Africa',
    'Senegal',
    'Somalia',
    'Egypt',
    'Morocco',
    'Uganda',
  ];

  /// African ethnicities for testing cultural matching
  static const Map<String, List<String>> testEthnicities = {
    'Nigeria': ['Yoruba', 'Igbo', 'Hausa', 'Fulani', 'Ijaw'],
    'Ghana': ['Akan', 'Ewe', 'Ga', 'Dagbani', 'Twi'],
    'Ethiopia': ['Oromo', 'Amhara', 'Tigray', 'Somali', 'Sidama'],
    'Kenya': ['Kikuyu', 'Luhya', 'Luo', 'Kalenjin', 'Kamba'],
    'South Africa': ['Zulu', 'Xhosa', 'Afrikaans', 'Pedi', 'Tswana'],
  };

  /// Languages for testing multi-language support
  static const List<String> testLanguages = [
    'English',
    'Yoruba',
    'Igbo',
    'Hausa',
    'Swahili',
    'Amharic',
    'Twi',
    'French',
    'Arabic',
    'Portuguese',
  ];

  /// US cities with large African diaspora communities
  static const Map<String, Map<String, dynamic>> diasporaCities = {
    'Atlanta': {
      'state': 'GA',
      'zip': '30309',
      'african_population': 200000,
      'primary_communities': ['Nigerian', 'Ghanaian', 'Ethiopian'],
    },
    'Washington': {
      'state': 'DC',
      'zip': '20001',
      'african_population': 150000,
      'primary_communities': ['Ethiopian', 'Nigerian', 'Somali'],
    },
    'New York': {
      'state': 'NY',
      'zip': '10001',
      'african_population': 120000,
      'primary_communities': ['Nigerian', 'Ghanaian', 'Senegalese'],
    },
    'Houston': {
      'state': 'TX',
      'zip': '77001',
      'african_population': 100000,
      'primary_communities': ['Nigerian', 'Ethiopian', 'Sudanese'],
    },
  };

  /// Professional backgrounds common in African diaspora
  static const List<String> testProfessions = [
    'Software Engineer',
    'Doctor',
    'Nurse',
    'Teacher',
    'Accountant',
    'Engineer',
    'Lawyer',
    'Business Analyst',
    'Consultant',
    'Researcher',
    'Pharmacist',
    'MBA Student',
  ];

  /// Immigration statuses for diaspora testing
  static const List<String> testImmigrationStatuses = [
    'US Citizen',
    'Permanent Resident',
    'H1B Visa',
    'F1 Student Visa',
    'O1 Visa',
    'Green Card Holder',
    'Naturalized Citizen',
    'Dual Citizen',
  ];

  /// Education levels common in African diaspora
  static const List<String> testEducationLevels = [
    'Bachelor\'s Degree',
    'Master\'s Degree',
    'PhD',
    'MBA',
    'Medical Degree',
    'Law Degree',
    'Engineering Degree',
    'Some College',
    'Associate Degree',
  ];

  /// Setup method channel mocks for testing
  static Future<void> setupTestEnvironment() async {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();

    // Mock location services for US cities
    const MethodChannel('flutter.baseflow.com/geolocator')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getCurrentPosition':
          // Return Atlanta coordinates by default
          return {
            'latitude': 33.7490,
            'longitude': -84.3880,
            'accuracy': 5.0,
            'altitude': 320.0,
            'heading': 0.0,
            'speed': 0.0,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          };
        case 'getLocationAccuracy':
          return 'high';
        case 'requestPermission':
          return 'granted';
        default:
          return null;
      }
    });

    // Mock phone authentication for US numbers
    const MethodChannel('plugins.flutter.io/firebase_auth')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'Auth#verifyPhoneNumber':
          // Mock successful verification for test numbers
          final phoneNumber = methodCall.arguments['phoneNumber'] as String;
          if (testPhoneNumbers.values.contains(phoneNumber)) {
            return {'verificationId': 'test_verification_id'};
          }
          return null;
        case 'Auth#signInWithCredential':
          return {
            'user': {
              'uid':
                  'test_diaspora_user_${DateTime.now().millisecondsSinceEpoch}',
              'phoneNumber': methodCall.arguments['phoneNumber'],
              'displayName': 'Test Diaspora User',
            },
          };
        default:
          return null;
      }
    });

    print('✅ Diaspora test environment setup complete');
  }

  /// Get random test data for diaspora user
  static Map<String, dynamic> getRandomDiasporaUserData() {
    final random = DateTime.now().millisecondsSinceEpoch % 1000;
    final countryIndex = random % testAfricanCountries.length;
    final country = testAfricanCountries[countryIndex];
    final cityIndex = random % diasporaCities.keys.length;
    final city = diasporaCities.keys.elementAt(cityIndex);

    return {
      'phoneNumber':
          testPhoneNumbers.values.elementAt(random % testPhoneNumbers.length),
      'country': country,
      'ethnicity': testEthnicities[country]?.first ?? 'Other',
      'city': city,
      'state': diasporaCities[city]!['state'],
      'profession': testProfessions[random % testProfessions.length],
      'education': testEducationLevels[random % testEducationLevels.length],
      'immigration_status':
          testImmigrationStatuses[random % testImmigrationStatuses.length],
      'languages': [
        'English',
        testLanguages[
            1 + (random % (testLanguages.length - 1))], // Skip English
      ],
    };
  }

  /// Cleanup test environment
  static void cleanup() {
    const MethodChannel('flutter.baseflow.com/geolocator')
        .setMockMethodCallHandler(null);
    const MethodChannel('plugins.flutter.io/firebase_auth')
        .setMockMethodCallHandler(null);

    print('✅ Diaspora test environment cleanup complete');
  }
}
