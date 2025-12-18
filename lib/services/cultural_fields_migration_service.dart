import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service to migrate existing users to include new cultural fields
class CulturalFieldsMigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Migrate all users to include cultural fields
  static Future<Map<String, dynamic>> migrateAllUsers() async {
    try {
      debugPrint('🔄 Starting cultural fields migration for all users...');

      final usersSnapshot = await _firestore.collection('users').get();
      final int totalUsers = usersSnapshot.docs.length;
      int migratedUsers = 0;
      int errorUsers = 0;
      final List<String> errors = [];

      debugPrint('📊 Found $totalUsers users to migrate');

      for (final doc in usersSnapshot.docs) {
        try {
          await _migrateUser(doc.id, doc.data());
          migratedUsers++;

          if (migratedUsers % 10 == 0) {
            debugPrint('✅ Migrated $migratedUsers/$totalUsers users');
          }
        } catch (e) {
          errorUsers++;
          errors.add('User ${doc.id}: $e');
          debugPrint('❌ Error migrating user ${doc.id}: $e');
        }
      }

      final result = {
        'totalUsers': totalUsers,
        'migratedUsers': migratedUsers,
        'errorUsers': errorUsers,
        'errors': errors,
        'success': errorUsers == 0,
      };

      debugPrint('🎉 Migration completed:');
      debugPrint('   Total users: $totalUsers');
      debugPrint('   Migrated: $migratedUsers');
      debugPrint('   Errors: $errorUsers');

      return result;
    } catch (e) {
      debugPrint('❌ Critical error during migration: $e');
      return {
        'totalUsers': 0,
        'migratedUsers': 0,
        'errorUsers': 1,
        'errors': ['Critical error: $e'],
        'success': false,
      };
    }
  }

  /// Migrate a single user
  static Future<bool> _migrateUser(
      String userId, Map<String, dynamic> userData,) async {
    try {
      // Check if user already has cultural fields
      if (_hasCulturalFields(userData)) {
        debugPrint('✅ User $userId already has cultural fields, skipping');
        return true;
      }

      // Extract cultural data from existing fields
      final culturalData = _extractCulturalData(userData);

      // Update user document with cultural fields
      await _firestore.collection('users').doc(userId).update(culturalData);

      debugPrint('✅ Migrated user $userId with cultural fields');
      return true;
    } catch (e) {
      debugPrint('❌ Error migrating user $userId: $e');
      return false;
    }
  }

  /// Check if user already has cultural fields
  static bool _hasCulturalFields(Map<String, dynamic> userData) => userData.containsKey('nationality') ||
        userData.containsKey('tribe') ||
        userData.containsKey('languages') ||
        userData.containsKey('religion') ||
        userData.containsKey('occupation');

  /// Extract cultural data from existing user data
  static Map<String, dynamic> _extractCulturalData(
      Map<String, dynamic> userData,) {
    final culturalData = <String, dynamic>{};

    // Extract nationality from living_in or other location fields
    if (userData.containsKey('living_in') && userData['living_in'] != null) {
      final livingIn = userData['living_in'].toString().toLowerCase();
      culturalData['nationality'] = _deriveNationality(livingIn);
    } else {
      culturalData['nationality'] = 'Nigerian'; // Default
    }

    // Extract tribe from profession or name
    if (userData.containsKey('profession') && userData['profession'] != null) {
      final profession = userData['profession'].toString().toLowerCase();
      culturalData['tribe'] = _deriveTribe(profession);
    } else if (userData.containsKey('name') && userData['name'] != null) {
      final name = userData['name'].toString().toLowerCase();
      culturalData['tribe'] = _deriveTribeFromName(name);
    } else {
      culturalData['tribe'] = 'Yoruba'; // Default
    }

    // Set default languages
    culturalData['languages'] = ['English']; // Default

    // Extract religion if available
    if (userData.containsKey('religion') && userData['religion'] != null) {
      culturalData['religion'] = userData['religion'];
    } else {
      culturalData['religion'] = ''; // Let user set later
    }

    // Extract occupation from profession or job_title
    if (userData.containsKey('profession') && userData['profession'] != null) {
      culturalData['occupation'] = userData['profession'];
    } else if (userData.containsKey('job_title') &&
        userData['job_title'] != null) {
      culturalData['occupation'] = userData['job_title'];
    } else {
      culturalData['occupation'] = ''; // Let user set later
    }

    return culturalData;
  }

  /// Derive nationality from location
  static String _deriveNationality(String location) {
    if (location.contains('nigeria') ||
        location.contains('lagos') ||
        location.contains('abuja')) {
      return 'Nigerian';
    } else if (location.contains('ghana') || location.contains('accra')) {
      return 'Ghanaian';
    } else if (location.contains('kenya') || location.contains('nairobi')) {
      return 'Kenyan';
    } else if (location.contains('south africa') ||
        location.contains('johannesburg') ||
        location.contains('cape town')) {
      return 'South African';
    } else if (location.contains('uk') ||
        location.contains('london') ||
        location.contains('manchester')) {
      return 'British-Nigerian';
    } else if (location.contains('usa') ||
        location.contains('america') ||
        location.contains('new york') ||
        location.contains('atlanta')) {
      return 'American-Nigerian';
    } else if (location.contains('canada') ||
        location.contains('toronto') ||
        location.contains('vancouver')) {
      return 'Canadian-Nigerian';
    }
    return 'Nigerian'; // Default
  }

  /// Derive tribe from profession
  static String _deriveTribe(String profession) {
    if (profession.contains('yoruba') ||
        profession.contains('igbo') ||
        profession.contains('hausa')) {
      return profession;
    }
    return 'Yoruba'; // Default
  }

  /// Derive tribe from name
  static String _deriveTribeFromName(String name) {
    if (name.contains('ade') ||
        name.contains('tunde') ||
        name.contains('kemi') ||
        name.contains('yemi')) {
      return 'Yoruba';
    } else if (name.contains('chi') ||
        name.contains('nkechi') ||
        name.contains('chukwu') ||
        name.contains('nnamdi')) {
      return 'Igbo';
    } else if (name.contains('ahmed') ||
        name.contains('fatima') ||
        name.contains('hassan') ||
        name.contains('aisha')) {
      return 'Hausa';
    }
    return 'Yoruba'; // Default
  }

  /// Migrate current user only
  static Future<bool> migrateCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ No current user to migrate');
        return false;
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        debugPrint('❌ User document not found');
        return false;
      }

      return await _migrateUser(user.uid, userDoc.data()!);
    } catch (e) {
      debugPrint('❌ Error migrating current user: $e');
      return false;
    }
  }

  /// Check if migration is needed
  static Future<bool> isMigrationNeeded() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;

      return !_hasCulturalFields(userDoc.data()!);
    } catch (e) {
      debugPrint('❌ Error checking migration status: $e');
      return false;
    }
  }
}
