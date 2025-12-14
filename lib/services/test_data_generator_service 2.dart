import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class TestDataGeneratorService {
  static const String _testUserPrefix = 'test_user_';

  // City coordinates for realistic location testing
  static const Map<String, Map<String, dynamic>> _cities = {
    'atlanta': {
      'lat': 33.7490,
      'lng': -84.3880,
      'name': 'Atlanta, GA',
    },
    'miami': {
      'lat': 25.7617,
      'lng': -80.1918,
      'name': 'Miami, FL',
    },
    'houston': {
      'lat': 29.7604,
      'lng': -95.3698,
      'name': 'Houston, TX',
    },
  };

  // Diverse names for realistic profiles
  static const List<String> _maleNames = [
    'James',
    'Michael',
    'William',
    'David',
    'Richard',
    'Joseph',
    'Thomas',
    'Christopher',
    'Charles',
    'Daniel',
    'Matthew',
    'Anthony',
    'Mark',
    'Donald',
    'Steven',
    'Paul',
    'Andrew',
    'Joshua',
    'Kenneth',
    'Kevin'
  ];

  static const List<String> _femaleNames = [
    'Mary',
    'Patricia',
    'Jennifer',
    'Linda',
    'Elizabeth',
    'Barbara',
    'Susan',
    'Jessica',
    'Sarah',
    'Karen',
    'Nancy',
    'Lisa',
    'Betty',
    'Helen',
    'Sandra',
    'Donna',
    'Carol',
    'Ruth',
    'Sharon',
    'Michelle'
  ];

  static const List<String> _lastNames = [
    'Smith',
    'Johnson',
    'Williams',
    'Brown',
    'Jones',
    'Garcia',
    'Miller',
    'Davis',
    'Rodriguez',
    'Martinez',
    'Hernandez',
    'Lopez',
    'Gonzalez',
    'Wilson',
    'Anderson',
    'Thomas',
    'Taylor',
    'Moore',
    'Jackson',
    'Martin'
  ];

  // Diverse interests for matching algorithms
  static const List<String> _interests = [
    'Travel',
    'Photography',
    'Music',
    'Cooking',
    'Fitness',
    'Reading',
    'Movies',
    'Dancing',
    'Sports',
    'Art',
    'Technology',
    'Fashion',
    'Food',
    'Adventure',
    'Yoga',
    'Gaming',
    'Hiking',
    'Coffee',
    'Wine',
    'Volunteering',
    'Languages',
    'Business',
    'Education'
  ];

  // Realistic age ranges for dating app
  static const List<int> _ages = [
    22,
    23,
    24,
    25,
    26,
    27,
    28,
    29,
    30,
    31,
    32,
    33,
    34,
    35,
    36,
    37,
    38,
    39,
    40,
    41,
    42,
    43,
    44,
    45
  ];

  // Education levels
  static const List<String> _educationLevels = [
    'High School',
    'Some College',
    'Bachelor\'s Degree',
    'Master\'s Degree',
    'PhD'
  ];

  // Occupations
  static const List<String> _occupations = [
    'Software Engineer',
    'Marketing Manager',
    'Teacher',
    'Doctor',
    'Lawyer',
    'Artist',
    'Entrepreneur',
    'Sales Representative',
    'Designer',
    'Consultant',
    'Nurse',
    'Accountant',
    'Chef',
    'Photographer',
    'Writer',
    'Engineer',
    'Business Analyst',
    'Project Manager',
    'Real Estate Agent',
    'Therapist'
  ];

  /// Generate test users for a specific city
  static Future<void> generateTestUsersForCity({
    required String cityKey,
    required int maleCount,
    required int femaleCount,
    bool dryRun = false,
  }) async {
    final city = _cities[cityKey]!;
    final random = Random();

    print(
        '🏙️ Generating $maleCount males and $femaleCount females for ${city['name']}');

    // Generate male users
    for (int i = 0; i < maleCount; i++) {
      final userData = _generateUserData(
        gender: 'male',
        city: city,
        cityKey: cityKey,
        random: random,
      );

      if (dryRun) {
        print(
            '👤 Would create male user: ${userData['name']} (${userData['age']} years old)');
      } else {
        await _createTestUser(userData);
      }
    }

    // Generate female users
    for (int i = 0; i < femaleCount; i++) {
      final userData = _generateUserData(
        gender: 'female',
        city: city,
        cityKey: cityKey,
        random: random,
      );

      if (dryRun) {
        print(
            '👤 Would create female user: ${userData['name']} (${userData['age']} years old)');
      } else {
        await _createTestUser(userData);
      }
    }

    print('✅ Completed generating test users for ${city['name']}');
  }

  /// Generate all test users for all cities
  static Future<void> generateAllTestUsers({
    int usersPerCity = 20,
    bool dryRun = false,
  }) async {
    print('🚀 Starting test user generation...');
    print(
        '📊 Target: $usersPerCity users per city (${usersPerCity ~/ 2} male, ${usersPerCity ~/ 2} female)');

    for (final cityKey in _cities.keys) {
      await generateTestUsersForCity(
        cityKey: cityKey,
        maleCount: usersPerCity ~/ 2,
        femaleCount: usersPerCity ~/ 2,
        dryRun: dryRun,
      );

      // Add delay between cities to avoid rate limiting
      if (!dryRun) {
        await Future.delayed(Duration(seconds: 2));
      }
    }

    print('🎉 All test users generated successfully!');
  }

  /// Generate realistic user data
  static Map<String, dynamic> _generateUserData({
    required String gender,
    required Map<String, dynamic> city,
    required String cityKey,
    required Random random,
  }) {
    final firstName = gender == 'male'
        ? _maleNames[random.nextInt(_maleNames.length)]
        : _femaleNames[random.nextInt(_femaleNames.length)];
    final lastName = _lastNames[random.nextInt(_lastNames.length)];
    final age = _ages[random.nextInt(_ages.length)];
    final birthDate = DateTime.now().subtract(Duration(days: age * 365));

    // Generate realistic location with some variation
    final lat =
        city['lat']! + (random.nextDouble() - 0.5) * 0.1; // ±0.05 degrees
    final lng =
        city['lng']! + (random.nextDouble() - 0.5) * 0.1; // ±0.05 degrees

    // Generate interests (3-8 interests per user)
    final interestCount = 3 + random.nextInt(6);
    final userInterests = Set<String>();
    while (userInterests.length < interestCount) {
      userInterests.add(_interests[random.nextInt(_interests.length)]);
    }

    // Generate bio based on interests and occupation
    final occupation = _occupations[random.nextInt(_occupations.length)];
    final education = _educationLevels[random.nextInt(_educationLevels.length)];
    final bio = _generateBio(
        gender, age, occupation, education, userInterests.toList());

    return {
      'name': '$firstName $lastName',
      'email':
          '${_testUserPrefix}${cityKey}_${gender}_${random.nextInt(10000)}@test.com',
      'age': age,
      'birthDate': Timestamp.fromDate(birthDate),
      'gender': gender,
      'location': GeoPoint(lat, lng),
      'city': city['name'],
      'cityKey': cityKey,
      'interests': userInterests.toList(),
      'occupation': occupation,
      'education': education,
      'bio': bio,
      'isTestUser': true,
      'testUserType': 'dating_app_test',
      'profileCompleted': true,
      'photos': _generateTestPhotos(gender, random),
      'createdAt': Timestamp.now(),
      'lastActive': Timestamp.now(),
      'preferences': {
        'ageRange': {
          'min': age - 3,
          'max': age + 5,
        },
        'maxDistance': 50, // 50 miles
        'interestedIn': gender == 'male' ? ['female'] : ['male'],
      },
    };
  }

  /// Generate realistic bio text
  static String _generateBio(String gender, int age, String occupation,
      String education, List<String> interests) {
    final bios = [
      'Loving life in my city! $occupation by day, ${interests[0].toLowerCase()} enthusiast by night. Looking for someone to share adventures with!',
      'Passionate about ${interests.take(2).join(' and ').toLowerCase()}. $education background. Let\'s grab coffee and see where it goes!',
      'Living my best life! Love ${interests[0].toLowerCase()}, ${interests.length > 1 ? interests[1].toLowerCase() : 'good conversation'}, and meeting new people.',
      'Adventure seeker and ${interests[0].toLowerCase()} lover. $occupation who believes in work-life balance. Let\'s explore together!',
      'Positive vibes only! Enjoy ${interests.take(3).join(', ').toLowerCase()}. Looking for genuine connections and fun times.',
    ];

    return bios[Random().nextInt(bios.length)];
  }

  /// Generate test profile photos (placeholder URLs)
  static List<String> _generateTestPhotos(String gender, Random random) {
    // In a real implementation, you'd use actual test photos
    // For now, we'll use placeholder URLs
    final photoCount = 2 + random.nextInt(3); // 2-4 photos
    return List.generate(
        photoCount,
        (index) =>
            'https://via.placeholder.com/400x600/4A90E2/FFFFFF?text=${gender == 'male' ? 'M' : 'F'}+${index + 1}');
  }

  /// Create test user in Firebase
  static Future<void> _createTestUser(Map<String, dynamic> userData) async {
    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      // Create auth user
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: userData['email'],
        password: 'testpassword123', // Standard test password
      );

      // Create user document
      await firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData);

      print('✅ Created test user: ${userData['name']} (${userData['email']})');
    } catch (e) {
      print('❌ Failed to create test user ${userData['name']}: $e');
    }
  }

  /// Clean up test users
  static Future<void> cleanupTestUsers() async {
    print('🧹 Cleaning up test users...');

    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;

    // Get all test users
    final querySnapshot = await firestore
        .collection('users')
        .where('isTestUser', isEqualTo: true)
        .get();

    for (final doc in querySnapshot.docs) {
      try {
        // Delete Firestore document
        await doc.reference.delete();

        // Delete auth user
        final user = auth.currentUser;
        if (user?.email == doc.data()['email']) {
          await user!.delete();
        }

        print('🗑️ Deleted test user: ${doc.data()['name']}');
      } catch (e) {
        print('❌ Failed to delete test user ${doc.data()['name']}: $e');
      }
    }

    print('✅ Test user cleanup completed');
  }

  /// Get test user statistics
  static Future<Map<String, dynamic>> getTestUserStats() async {
    final firestore = FirebaseFirestore.instance;

    final querySnapshot = await firestore
        .collection('users')
        .where('isTestUser', isEqualTo: true)
        .get();

    final users = querySnapshot.docs.map((doc) => doc.data()).toList();

    final stats = {
      'totalTestUsers': users.length,
      'byGender': <String, int>{},
      'byCity': <String, int>{},
      'ageDistribution': <String, int>{},
    };

    for (final user in users) {
      // Gender distribution
      final gender = user['gender'] as String;
      final genderMap = stats['byGender'] as Map<String, int>;
      genderMap[gender] = (genderMap[gender] ?? 0) + 1;

      // City distribution
      final city = user['city'] as String;
      final cityMap = stats['byCity'] as Map<String, int>;
      cityMap[city] = (cityMap[city] ?? 0) + 1;

      // Age distribution
      final age = user['age'] as int;
      final ageGroup = '${(age ~/ 10) * 10}s';
      final ageMap = stats['ageDistribution'] as Map<String, int>;
      ageMap[ageGroup] = (ageMap[ageGroup] ?? 0) + 1;
    }

    return stats;
  }
}
