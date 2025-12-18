import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Debug utility to check database population and user filtering
class DatabaseDebug {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check total users in database
  static Future<void> checkDatabasePopulation() async {
    try {
      debugPrint('🔍 Checking database population...');

      // Get total user count
      final allUsersQuery = await _firestore.collection('users').get();
      debugPrint('📊 Total users in database: ${allUsersQuery.docs.length}');

      if (allUsersQuery.docs.isEmpty) {
        debugPrint('❌ No users found in database! You need to add test users.');
        return;
      }

      // Analyze user data
      int usersWithAge = 0;
      int usersWithGender = 0;
      int usersWithLocation = 0;
      int usersInAgeRange = 0;

      for (final doc in allUsersQuery.docs) {
        final data = doc.data();

        // Check age
        if (data['age'] != null) {
          usersWithAge++;
          final age = data['age'] as int;
          if (age >= 18 && age <= 35) {
            usersInAgeRange++;
          }
        }

        // Check gender
        if (data['gender'] != null && data['gender'].toString().isNotEmpty) {
          usersWithGender++;
        }

        // Check location
        if (data['latitude'] != null && data['longitude'] != null) {
          usersWithLocation++;
        }

        // Log user details
        debugPrint(
            '👤 User ${doc.id}: age=${data['age']}, gender=${data['gender']}, lat=${data['latitude']}, lng=${data['longitude']}',);
      }

      debugPrint('📈 Database Analysis:');
      debugPrint(
          '   Users with age: $usersWithAge/${allUsersQuery.docs.length}',);
      debugPrint(
          '   Users with gender: $usersWithGender/${allUsersQuery.docs.length}',);
      debugPrint(
          '   Users with location: $usersWithLocation/${allUsersQuery.docs.length}',);
      debugPrint(
          '   Users in age range 18-35: $usersInAgeRange/${allUsersQuery.docs.length}',);
    } catch (e) {
      debugPrint('❌ Error checking database: $e');
    }
  }

  /// Check what users are being excluded for current user
  static Future<void> checkUserExclusions(String currentUserId) async {
    try {
      debugPrint('🚫 Checking user exclusions for: $currentUserId');

      // Check CheckedUser collection
      final checkedUsers = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('CheckedUser')
          .get();

      debugPrint('👀 Already checked users: ${checkedUsers.docs.length}');
      for (final doc in checkedUsers.docs) {
        debugPrint('   - ${doc.id}');
      }

      // Check blocked users
      final blockedUsers = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blockedlist')
          .get();

      debugPrint('🚫 Blocked users: ${blockedUsers.docs.length}');
      for (final doc in blockedUsers.docs) {
        debugPrint('   - ${doc.id}');
      }

      // Check matches
      final matches = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('Matches')
          .get();

      debugPrint('💕 Existing matches: ${matches.docs.length}');
      for (final doc in matches.docs) {
        debugPrint('   - ${doc.id}');
      }
    } catch (e) {
      debugPrint('❌ Error checking exclusions: $e');
    }
  }

  /// Test the exact query being used
  static Future<void> testUserQuery(String currentUserId) async {
    try {
      debugPrint('🧪 Testing user query...');

      // Replicate the exact query from PaginatedUserService
      Query query = _firestore.collection('users');

      // Filter by age range (18-35)
      query = query
          .where('age', isGreaterThanOrEqualTo: 18)
          .where('age', isLessThanOrEqualTo: 35);

      // Order by lastActive
      query = query.orderBy('lastActive', descending: true);

      final querySnapshot = await query.limit(50).get();

      debugPrint('📊 Query results: ${querySnapshot.docs.length} users');

      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        debugPrint(
            '👤 Found user: ${doc.id} (age: ${data['age']}, gender: ${data['gender']})',);
      }
    } catch (e) {
      debugPrint('❌ Error testing query: $e');

      // Try simpler query without ordering
      try {
        debugPrint('🔄 Trying simpler query...');
        final simpleQuery = await _firestore
            .collection('users')
            .where('age', isGreaterThanOrEqualTo: 18)
            .where('age', isLessThanOrEqualTo: 35)
            .limit(10)
            .get();

        debugPrint('📊 Simple query results: ${simpleQuery.docs.length} users');
      } catch (e2) {
        debugPrint('❌ Simple query also failed: $e2');
      }
    }
  }

  /// Create test users for development
  static Future<void> createTestUsers() async {
    try {
      debugPrint('👥 Creating test users...');

      final testUsers = [
        {
          'name': 'Adaora',
          'age': 25,
          'gender': 'female',
          'bio': 'Love traveling and good food!',
          'latitude': 6.5244,
          'longitude': 3.3792,
          'lastActive': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'isProfileComplete': true,
        },
        {
          'name': 'Kemi',
          'age': 28,
          'gender': 'female',
          'bio': 'Entrepreneur and fitness enthusiast',
          'latitude': 6.5355,
          'longitude': 3.3087,
          'lastActive': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'isProfileComplete': true,
        },
        {
          'name': 'Tunde',
          'age': 30,
          'gender': 'male',
          'bio': 'Software developer who loves music',
          'latitude': 6.4474,
          'longitude': 3.3903,
          'lastActive': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'isProfileComplete': true,
        },
        {
          'name': 'Funmi',
          'age': 26,
          'gender': 'female',
          'bio': 'Artist and creative soul',
          'latitude': 6.6018,
          'longitude': 3.3515,
          'lastActive': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'isProfileComplete': true,
        },
        {
          'name': 'Emeka',
          'age': 32,
          'gender': 'male',
          'bio': 'Business analyst and sports fan',
          'latitude': 6.5795,
          'longitude': 3.3211,
          'lastActive': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'isProfileComplete': true,
        },
      ];

      final batch = _firestore.batch();

      for (final userData in testUsers) {
        final userRef = _firestore.collection('users').doc();
        batch.set(userRef, userData);
      }

      await batch.commit();

      debugPrint('✅ Created ${testUsers.length} test users');
    } catch (e) {
      debugPrint('❌ Error creating test users: $e');
    }
  }

  /// Clear user exclusions for testing
  static Future<void> clearUserExclusions(String currentUserId) async {
    try {
      debugPrint('🧹 Clearing user exclusions for: $currentUserId');

      // Clear CheckedUser collection
      final checkedUsers = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('CheckedUser')
          .get();

      final batch = _firestore.batch();

      for (final doc in checkedUsers.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      debugPrint('✅ Cleared ${checkedUsers.docs.length} checked users');
    } catch (e) {
      debugPrint('❌ Error clearing exclusions: $e');
    }
  }
}
