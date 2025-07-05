import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'user_privacy_service.dart';
import 'location_privacy_service.dart';

/// Service for migrating user data to privacy-aware structure
class PrivacyMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Migrate current user's data to privacy structure
  Future<bool> migrateCurrentUserData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;
      
      return await migrateUserData(currentUser.uid);
    } catch (e) {
      debugPrint('Error migrating current user data: $e');
      return false;
    }
  }
  
  /// Migrate specific user's data to privacy structure
  Future<bool> migrateUserData(String userId) async {
    try {
      debugPrint('🔄 Starting privacy migration for user: $userId');
      
      // Get current user document
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        debugPrint('❌ User document not found: $userId');
        return false;
      }
      
      final userData = userDoc.data()!;
      debugPrint('📊 Current user data keys: ${userData.keys.toList()}');
      
      // Check if already migrated
      final publicDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('public')
          .doc('profile')
          .get();
      
      if (publicDoc.exists) {
        debugPrint('✅ User already migrated: $userId');
        return true;
      }
      
      // Create default privacy settings
      const defaultPrivacy = UserPrivacySettings();
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('private')
          .doc('privacy')
          .set(defaultPrivacy.toMap());
      
      // Separate public and private data
      final publicData = _extractPublicData(userData, defaultPrivacy);
      final privateData = _extractPrivateData(userData);
      
      // Create public profile
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('public')
          .doc('profile')
          .set(publicData);
      
      // Create private profile
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('private')
          .doc('sensitive')
          .set(privateData);
      
      // Update main user document (remove sensitive data)
      await _cleanMainUserDocument(userId, userData);
      
      debugPrint('✅ Privacy migration completed for user: $userId');
      return true;
      
    } catch (e) {
      debugPrint('❌ Error migrating user data: $e');
      return false;
    }
  }
  
  /// Extract public data based on privacy settings
  Map<String, dynamic> _extractPublicData(
    Map<String, dynamic> userData, 
    UserPrivacySettings privacy
  ) {
    Map<String, dynamic> publicData = {
      'name': userData['name'] ?? '',
      'bio': userData['bio'] ?? '',
      'photos': userData['photos'] ?? [],
      'interests': userData['interests'] ?? [],
      'lookingFor': userData['lookingFor'] ?? '',
      'relationshipIntent': userData['relationshipIntent'] ?? '',
      'createdAt': userData['createdAt'],
      'lastActive': userData['lastActive'],
      'isOnline': userData['isOnline'] ?? false,
    };
    
    // Add data based on privacy settings
    if (privacy.showAge) {
      publicData['age'] = userData['age'];
      publicData['showMyAge'] = userData['showMyAge'];
      publicData['dateOfBirth'] = userData['dateOfBirth'];
    }
    
    if (privacy.showTribe) {
      publicData['tribe'] = userData['tribe'];
    }
    
    if (privacy.showOrientation) {
      publicData['sexualOrientation'] = userData['sexualOrientation'];
    }
    
    if (privacy.showLocation) {
      // Create privacy-aware location data
      final lat = userData['latitude'] as double?;
      final lng = userData['longitude'] as double?;
      
      if (lat != null && lng != null) {
        final locationData = LocationPrivacyService.createPrivateLocation(
          latitude: lat,
          longitude: lng,
          precision: LocationPrecision.medium, // Default to medium precision
          city: userData['living_in'] ?? userData['city'] ?? '',
          state: userData['state'] ?? '',
          country: userData['country'] ?? 'Nigeria',
        );
        
        publicData.addAll(locationData);
      }
      
      publicData['living_in'] = userData['living_in'];
      publicData['city'] = userData['city'];
      publicData['state'] = userData['state'];
      publicData['country'] = userData['country'];
    }
    
    // Add non-sensitive profile data
    publicData['height'] = userData['height'];
    publicData['heightDisplay'] = userData['heightDisplay'];
    publicData['height_ft_in'] = userData['height_ft_in'];
    publicData['education'] = userData['education'];
    publicData['religion'] = userData['religion'];
    publicData['drinking'] = userData['drinking'];
    publicData['smoking'] = userData['smoking'];
    publicData['kids'] = userData['kids'];
    publicData['pets'] = userData['pets'];
    publicData['languages'] = userData['languages'];
    
    return publicData;
  }
  
  /// Extract private/sensitive data
  Map<String, dynamic> _extractPrivateData(Map<String, dynamic> userData) {
    return {
      'phoneNumber': userData['phoneNumber'],
      'email': userData['email'],
      'address': userData['address'],
      'latitude': userData['latitude'],
      'longitude': userData['longitude'],
      'coordinates': userData['coordinates'],
      'currentCoordinates': userData['currentCoordinates'],
      'company': userData['company'],
      'jobTitle': userData['jobTitle'],
      'workAddress': userData['workAddress'],
      'homeAddress': userData['homeAddress'],
      'emergencyContact': userData['emergencyContact'],
      'socialMediaLinks': userData['socialMediaLinks'],
      'deviceInfo': userData['deviceInfo'],
      'loginHistory': userData['loginHistory'],
      'paymentInfo': userData['paymentInfo'],
      'subscriptionData': userData['subscriptionData'],
      'migrationDate': FieldValue.serverTimestamp(),
    };
  }
  
  /// Clean main user document by removing sensitive data
  Future<void> _cleanMainUserDocument(String userId, Map<String, dynamic> userData) async {
    // Fields to remove from main document
    final sensitiveFields = [
      'phoneNumber',
      'email', // Keep email for auth purposes, but limit access
      'address',
      'latitude',
      'longitude',
      'coordinates',
      'currentCoordinates',
      'company',
      'jobTitle',
      'workAddress',
      'homeAddress',
      'emergencyContact',
      'socialMediaLinks',
      'deviceInfo',
      'loginHistory',
      'paymentInfo',
      'subscriptionData',
    ];
    
    Map<String, dynamic> updates = {};
    for (String field in sensitiveFields) {
      if (userData.containsKey(field)) {
        updates[field] = FieldValue.delete();
      }
    }
    
    // Add migration marker
    updates['privacyMigrated'] = true;
    updates['migrationDate'] = FieldValue.serverTimestamp();
    
    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(userId).update(updates);
    }
  }
  
  /// Migrate all users (admin function - use carefully)
  Future<void> migrateAllUsers() async {
    try {
      debugPrint('🚀 Starting bulk user migration...');
      
      final usersSnapshot = await _firestore.collection('users').get();
      int totalUsers = usersSnapshot.docs.length;
      int migratedCount = 0;
      int errorCount = 0;
      
      debugPrint('📊 Found $totalUsers users to migrate');
      
      for (var doc in usersSnapshot.docs) {
        try {
          final success = await migrateUserData(doc.id);
          if (success) {
            migratedCount++;
          } else {
            errorCount++;
          }
          
          // Progress update every 10 users
          if ((migratedCount + errorCount) % 10 == 0) {
            debugPrint('📈 Progress: $migratedCount migrated, $errorCount errors, ${totalUsers - migratedCount - errorCount} remaining');
          }
          
          // Small delay to avoid overwhelming Firestore
          await Future.delayed(const Duration(milliseconds: 100));
          
        } catch (e) {
          debugPrint('❌ Error migrating user ${doc.id}: $e');
          errorCount++;
        }
      }
      
      debugPrint('✅ Bulk migration completed:');
      debugPrint('   Total users: $totalUsers');
      debugPrint('   Successfully migrated: $migratedCount');
      debugPrint('   Errors: $errorCount');
      
    } catch (e) {
      debugPrint('❌ Error in bulk migration: $e');
    }
  }
  
  /// Check if user data has been migrated
  Future<bool> isUserMigrated(String userId) async {
    try {
      final publicDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('public')
          .doc('profile')
          .get();
      
      return publicDoc.exists;
    } catch (e) {
      debugPrint('Error checking migration status: $e');
      return false;
    }
  }
  
  /// Get migration status for current user
  Future<Map<String, dynamic>> getMigrationStatus() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {'migrated': false, 'error': 'No authenticated user'};
      }
      
      final isMigrated = await isUserMigrated(currentUser.uid);
      
      if (isMigrated) {
        final publicDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('public')
            .doc('profile')
            .get();
        
        final privateDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('private')
            .doc('sensitive')
            .get();
        
        return {
          'migrated': true,
          'publicDataExists': publicDoc.exists,
          'privateDataExists': privateDoc.exists,
          'migrationDate': publicDoc.data()?['migrationDate'],
        };
      } else {
        return {'migrated': false};
      }
      
    } catch (e) {
      return {'migrated': false, 'error': e.toString()};
    }
  }
  
  /// Rollback migration (for testing purposes)
  Future<bool> rollbackMigration(String userId) async {
    try {
      debugPrint('🔄 Rolling back migration for user: $userId');
      
      // Get private data
      final privateDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('private')
          .doc('sensitive')
          .get();
      
      if (privateDoc.exists) {
        final privateData = privateDoc.data()!;
        
        // Restore sensitive data to main document
        await _firestore.collection('users').doc(userId).update({
          ...privateData,
          'privacyMigrated': FieldValue.delete(),
          'migrationDate': FieldValue.delete(),
        });
      }
      
      // Delete subcollections
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('public')
          .doc('profile')
          .delete();
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('private')
          .doc('sensitive')
          .delete();
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('private')
          .doc('privacy')
          .delete();
      
      debugPrint('✅ Migration rollback completed for user: $userId');
      return true;
      
    } catch (e) {
      debugPrint('❌ Error rolling back migration: $e');
      return false;
    }
  }
}
