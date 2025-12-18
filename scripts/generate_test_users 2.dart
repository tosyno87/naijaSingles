#!/usr/bin/env dart

import 'dart:math';

/// Standalone test user data generator (preview mode)
/// This script generates test user data without requiring Firebase connection
/// Perfect for planning and previewing before actual generation

void main(List<String> arguments) {
  print('🎯 Afropeep Test Data Generator - Preview Mode');
  print('================================================\n');

  if (arguments.isEmpty || arguments[0] == 'help') {
    _showHelp();
    return;
  }

  final command = arguments[0];
  final city = arguments.length > 1 ? arguments[1] : 'all';
  final count = arguments.length > 2 ? int.tryParse(arguments[2]) ?? 20 : 20;

  switch (command) {
    case 'preview':
      _previewTestUsers(city, count);
      break;
    case 'stats':
      _showStats(city, count);
      break;
    default:
      print('❌ Unknown command: $command\n');
      _showHelp();
  }
}

void _showHelp() {
  print('Usage: dart scripts/generate_test_users.dart <command> [city] [count]\n');
  print('Commands:');
  print('  preview [city] [count]   Preview test users that will be created');
  print('                          city: atlanta|miami|houston|all (default: all)');
  print('                          count: users per city (default: 20)');
  print('');
  print('  stats [city] [count]     Show statistics about test data');
  print('');
  print('Examples:');
  print('  dart scripts/generate_test_users.dart preview all 20');
  print('  dart scripts/generate_test_users.dart preview miami 10');
  print('  dart scripts/generate_test_users.dart stats houston 15');
  print('');
  print('💡 To actually create users in Firebase, use the Flutter app admin panel');
  print('   or implement the TestDataGeneratorService in your app.');
}

void _previewTestUsers(String cityKey, int count) {
  print('🔍 Preview: Test Users to be Generated');
  print('========================================\n');

  final cities = cityKey == 'all'
      ? ['atlanta', 'miami', 'houston']
      : [cityKey];

  for (final city in cities) {
    _generateForCity(city, count);
    print('');
  }

  print('✅ Preview completed!');
  print('💡 This is a preview only - no users were created');
  print('📊 Run "stats" command to see summary statistics');
}

void _showStats(String cityKey, int count) {
  print('📊 Test Data Statistics');
  print('=======================\n');

  final cities = cityKey == 'all'
      ? {'atlanta': count, 'miami': count, 'houston': count}
      : {cityKey: count};

  int totalUsers = 0;
  int totalMales = 0;
  int totalFemales = 0;

  cities.forEach((city, userCount) {
    final males = userCount ~/ 2;
    final females = userCount ~/ 2;
    totalUsers += userCount;
    totalMales += males;
    totalFemales += females;
  });

  print('👥 Total Test Users: $totalUsers');
  print('   👨 Males: $totalMales');
  print('   👩 Females: $totalFemales\n');

  print('🏙️ By City:');
  cities.forEach((city, userCount) {
    final cityName = _getCityName(city);
    print('   📍 $cityName: $userCount users (${userCount ~/ 2}👨, ${userCount ~/ 2}👩)');
  });

  print('\n📅 Age Distribution:');
  print('   🎂 20s: ~${(totalUsers * 0.4).round()} users');
  print('   🎂 30s: ~${(totalUsers * 0.4).round()} users');
  print('   🎂 40s: ~${(totalUsers * 0.2).round()} users');

  print('\n💡 Each profile includes:');
  print('   ✅ Realistic name and demographics');
  print('   ✅ Geographic coordinates within city');
  print('   ✅ 3-8 diverse interests');
  print('   ✅ Profile bio and occupation');
  print('   ✅ 2-4 profile photos');
  print('   ✅ Matching preferences');
}

void _generateForCity(String cityKey, int count) {
  final cityName = _getCityName(cityKey);
  final cityCoords = _getCityCoords(cityKey);

  print('🏙️ $cityName (${cityCoords['lat']}, ${cityCoords['lng']})');
  print('=' * (cityName.length + 20));

  final maleCount = count ~/ 2;
  final femaleCount = count ~/ 2;

  print('\n👨 Male Users ($maleCount):');
  for (int i = 0; i < maleCount; i++) {
    _printUser('male', cityKey, i + 1);
  }

  print('\n👩 Female Users ($femaleCount):');
  for (int i = 0; i < femaleCount; i++) {
    _printUser('female', cityKey, i + 1);
  }
}

void _printUser(String gender, String city, int index) {
  final random = Random(DateTime.now().millisecondsSinceEpoch + index);
  final user = _generateUserData(gender, city, random);

  print('   ${index.toString().padLeft(2)}. ${user['name']} (${user['age']}) - ${user['occupation']}');
  print('       📧 ${user['email']}');
  print('       📍 ${user['location']}');
  print('       🎯 ${user['interests'].take(3).join(', ')}');
  print('       💬 "${user['bio']}"');
}

Map<String, dynamic> _generateUserData(String gender, String city, Random random) {
  final firstName = gender == 'male'
      ? _maleNames[random.nextInt(_maleNames.length)]
      : _femaleNames[random.nextInt(_femaleNames.length)];
  final lastName = _lastNames[random.nextInt(_lastNames.length)];
  final age = 22 + random.nextInt(24); // 22-45
  final occupation = _occupations[random.nextInt(_occupations.length)];

  final interestCount = 3 + random.nextInt(6);
  final interests = <String>[];
  while (interests.length < interestCount) {
    final interest = _interests[random.nextInt(_interests.length)];
    if (!interests.contains(interest)) {
      interests.add(interest);
    }
  }

  final cityCoords = _getCityCoords(city);
  final lat = (cityCoords['lat']! + (random.nextDouble() - 0.5) * 0.1).toStringAsFixed(4);
  final lng = (cityCoords['lng']! + (random.nextDouble() - 0.5) * 0.1).toStringAsFixed(4);

  return {
    'name': '$firstName $lastName',
    'email': 'test_${city}_${gender}_${random.nextInt(10000)}@test.com',
    'age': age,
    'gender': gender,
    'occupation': occupation,
    'interests': interests,
    'location': '($lat, $lng)',
    'bio': _generateBio(interests, occupation),
  };
}

String _generateBio(List<String> interests, String occupation) {
  final bios = [
    'Loving life! $occupation who enjoys ${interests.first.toLowerCase()}. Looking to meet new people!',
    'Passionate about ${interests.first.toLowerCase()} and ${interests.length > 1 ? interests[1].toLowerCase() : 'good times'}. Let\'s connect!',
    'Adventure seeker and ${interests.first.toLowerCase()} enthusiast. $occupation by day, fun by night!',
    'Into ${interests.take(2).join(' & ').toLowerCase()}. Looking for genuine connections!',
    'Life is short, make it count! Love ${interests.first.toLowerCase()} and meeting new people.',
  ];
  return bios[Random().nextInt(bios.length)];
}

String _getCityName(String cityKey) => {
    'atlanta': 'Atlanta, GA',
    'miami': 'Miami, FL',
    'houston': 'Houston, TX',
  }[cityKey] ?? cityKey;

Map<String, double> _getCityCoords(String cityKey) => {
    'atlanta': {'lat': 33.7490, 'lng': -84.3880},
    'miami': {'lat': 25.7617, 'lng': -80.1918},
    'houston': {'lat': 29.7604, 'lng': -95.3698},
  }[cityKey] ?? {'lat': 0.0, 'lng': 0.0};

// Test data constants
const List<String> _maleNames = [
  'James', 'Michael', 'William', 'David', 'Richard', 'Joseph', 'Thomas',
  'Christopher', 'Charles', 'Daniel', 'Matthew', 'Anthony', 'Mark',
  'Donald', 'Steven', 'Paul', 'Andrew', 'Joshua', 'Kenneth', 'Kevin',
];

const List<String> _femaleNames = [
  'Mary', 'Patricia', 'Jennifer', 'Linda', 'Elizabeth', 'Barbara',
  'Susan', 'Jessica', 'Sarah', 'Karen', 'Nancy', 'Lisa', 'Betty',
  'Helen', 'Sandra', 'Donna', 'Carol', 'Ruth', 'Sharon', 'Michelle',
];

const List<String> _lastNames = [
  'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller',
  'Davis', 'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez',
  'Wilson', 'Anderson', 'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin',
];

const List<String> _interests = [
  'Travel', 'Photography', 'Music', 'Cooking', 'Fitness', 'Reading',
  'Movies', 'Dancing', 'Sports', 'Art', 'Technology', 'Fashion',
  'Food', 'Adventure', 'Yoga', 'Gaming', 'Hiking', 'Coffee',
  'Wine', 'Volunteering', 'Languages', 'Business', 'Education',
];

const List<String> _occupations = [
  'Software Engineer', 'Marketing Manager', 'Teacher', 'Doctor', 'Lawyer',
  'Artist', 'Entrepreneur', 'Sales Representative', 'Designer', 'Consultant',
  'Nurse', 'Accountant', 'Chef', 'Photographer', 'Writer', 'Engineer',
  'Business Analyst', 'Project Manager', 'Real Estate Agent', 'Therapist',
];
