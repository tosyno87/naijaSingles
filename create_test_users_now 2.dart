import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

// Import your Firebase options
import 'firebase_options.dart';

void main() async {
  print('🚀 Afropeep Test User Generator');
  print('================================\n');

  try {
    // Initialize Firebase
    print('🔥 Connecting to Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Connected to Firebase!\n');

    // Generate test users
    await generateAllTestUsers();

    print('\n🎉 All test users created successfully!');
    print('📊 Check Firebase Console to verify:\n');
    print('   Authentication → Users (should see 60 test users)');
    print('   Firestore → users collection (filter: isTestUser == true)');
    
    exit(0);
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}

Future<void> generateAllTestUsers() async {
  final cities = {
    'atlanta': {'lat': 33.7490, 'lng': -84.3880, 'name': 'Atlanta, GA'},
    'miami': {'lat': 25.7617, 'lng': -80.1918, 'name': 'Miami, FL'},
    'houston': {'lat': 29.7604, 'lng': -95.3698, 'name': 'Houston, TX'},
  };

  int totalCreated = 0;
  int totalFailed = 0;

  for (final cityEntry in cities.entries) {
    final cityKey = cityEntry.key;
    final city = cityEntry.value;
    
    print('🏙️  ${city['name']}');
    print('=' * 40);

    // Generate 10 males
    for (int i = 0; i < 10; i++) {
      try {
        await createTestUser('male', cityKey, city);
        totalCreated++;
        print('  ✅ Male ${i + 1}/10');
        await Future.delayed(const Duration(milliseconds: 500)); // Rate limit delay
      } catch (e) {
        totalFailed++;
        print('  ❌ Male ${i + 1}/10 failed: $e');
      }
    }

    // Generate 10 females
    for (int i = 0; i < 10; i++) {
      try {
        await createTestUser('female', cityKey, city);
        totalCreated++;
        print('  ✅ Female ${i + 1}/10');
        await Future.delayed(const Duration(milliseconds: 500)); // Rate limit delay
      } catch (e) {
        totalFailed++;
        print('  ❌ Female ${i + 1}/10 failed: $e');
      }
    }

    print('');
  }

  print('📊 Summary:');
  print('   ✅ Created: $totalCreated users');
  if (totalFailed > 0) {
    print('   ❌ Failed: $totalFailed users');
  }
}

Future<void> createTestUser(String gender, String cityKey, Map<String, dynamic> city) async {
  final random = Random();
  final userData = generateUserData(gender, cityKey, city, random);

  try {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    // Create auth user
    final userCredential = await auth.createUserWithEmailAndPassword(
      email: userData['email'],
      password: 'testpassword123',
    );

    // Create user document
    await firestore
        .collection('users')
        .doc(userCredential.user!.uid)
        .set(userData);

    // Sign out to allow next user creation
    await auth.signOut();

  } catch (e) {
    rethrow;
  }
}

Map<String, dynamic> generateUserData(String gender, String cityKey, Map<String, dynamic> city, Random random) {
  final firstName = gender == 'male'
      ? maleNames[random.nextInt(maleNames.length)]
      : femaleNames[random.nextInt(femaleNames.length)];
  final lastName = lastNames[random.nextInt(lastNames.length)];
  final age = 22 + random.nextInt(24); // 22-45
  final birthDate = DateTime.now().subtract(Duration(days: age * 365));

  // Generate realistic location
  final lat = (city['lat'] as num).toDouble() + (random.nextDouble() - 0.5) * 0.1;
  final lng = (city['lng'] as num).toDouble() + (random.nextDouble() - 0.5) * 0.1;

  // Generate interests
  final interestCount = 3 + random.nextInt(6);
  final userInterests = <String>{};
  while (userInterests.length < interestCount) {
    userInterests.add(interests[random.nextInt(interests.length)]);
  }

  final occupation = occupations[random.nextInt(occupations.length)];
  final education = educationLevels[random.nextInt(educationLevels.length)];

  return {
    'name': '$firstName $lastName',
    'email': 'test_${cityKey}_${gender}_${random.nextInt(10000)}@test.com',
    'age': age,
    'birthDate': Timestamp.fromDate(birthDate),
    'gender': gender,
    'location': GeoPoint(lat, lng),
    'city': city['name'],
    'cityKey': cityKey,
    'interests': userInterests.toList(),
    'occupation': occupation,
    'education': education,
    'bio': generateBio(userInterests.toList(), occupation),
    'isTestUser': true,
    'testUserType': 'dating_app_test',
    'profileCompleted': true,
    'photos': generateTestPhotos(gender, random),
    'createdAt': Timestamp.now(),
    'lastActive': Timestamp.now(),
    'preferences': {
      'ageRange': {
        'min': age - 3,
        'max': age + 5,
      },
      'maxDistance': 50,
      'interestedIn': gender == 'male' ? ['female'] : ['male'],
    },
  };
}

String generateBio(List<String> interests, String occupation) {
  final bios = [
    'Loving life in my city! $occupation by day, ${interests[0].toLowerCase()} enthusiast by night. Looking for someone to share adventures with!',
    'Passionate about ${interests.take(2).join(' and ').toLowerCase()}. Looking for genuine connections and fun times.',
    'Living my best life! Love ${interests[0].toLowerCase()}, ${interests.length > 1 ? interests[1].toLowerCase() : 'good conversation'}, and meeting new people.',
    'Adventure seeker and ${interests[0].toLowerCase()} lover. $occupation who believes in work-life balance. Let\'s explore together!',
    'Positive vibes only! Enjoy ${interests.take(3).join(', ').toLowerCase()}. Looking for genuine connections and fun times.',
  ];
  return bios[Random().nextInt(bios.length)];
}

List<String> generateTestPhotos(String gender, Random random) {
  final photoCount = 2 + random.nextInt(3);
  return List.generate(photoCount, (index) =>
      'https://via.placeholder.com/400x600/4A90E2/FFFFFF?text=${gender == 'male' ? 'M' : 'F'}+${index + 1}',);
}

// Test data constants
const List<String> maleNames = [
  'James', 'Michael', 'William', 'David', 'Richard', 'Joseph', 'Thomas',
  'Christopher', 'Charles', 'Daniel', 'Matthew', 'Anthony', 'Mark',
  'Donald', 'Steven', 'Paul', 'Andrew', 'Joshua', 'Kenneth', 'Kevin',
];

const List<String> femaleNames = [
  'Mary', 'Patricia', 'Jennifer', 'Linda', 'Elizabeth', 'Barbara',
  'Susan', 'Jessica', 'Sarah', 'Karen', 'Nancy', 'Lisa', 'Betty',
  'Helen', 'Sandra', 'Donna', 'Carol', 'Ruth', 'Sharon', 'Michelle',
];

const List<String> lastNames = [
  'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller',
  'Davis', 'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez',
  'Wilson', 'Anderson', 'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin',
];

const List<String> interests = [
  'Travel', 'Photography', 'Music', 'Cooking', 'Fitness', 'Reading',
  'Movies', 'Dancing', 'Sports', 'Art', 'Technology', 'Fashion',
  'Food', 'Adventure', 'Yoga', 'Gaming', 'Hiking', 'Coffee',
  'Wine', 'Volunteering', 'Languages', 'Business', 'Education',
];

const List<String> occupations = [
  'Software Engineer', 'Marketing Manager', 'Teacher', 'Doctor', 'Lawyer',
  'Artist', 'Entrepreneur', 'Sales Representative', 'Designer', 'Consultant',
  'Nurse', 'Accountant', 'Chef', 'Photographer', 'Writer', 'Engineer',
  'Business Analyst', 'Project Manager', 'Real Estate Agent', 'Therapist',
];

const List<String> educationLevels = [
  'High School', 'Some College', 'Bachelor\'s Degree', 'Master\'s Degree', 'PhD',
];

