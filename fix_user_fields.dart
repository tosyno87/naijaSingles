import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:naijasingles/firebase_options.dart';

/// Script to fix missing fields in user documents
/// This will add the required fields for proper filtering
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  print('🔧 Starting user field fix process...');
  
  try {
    final firestore = FirebaseFirestore.instance;
    final usersCollection = firestore.collection('users');
    
    // Get all users
    final snapshot = await usersCollection.get();
    print('📊 Found ${snapshot.docs.length} users to process');
    
    int updatedCount = 0;
    int errorCount = 0;
    
    for (final doc in snapshot.docs) {
      try {
        final data = doc.data();
        final userId = doc.id;
        
        print('👤 Processing user: $userId - ${data['name'] ?? 'No name'}');
        
        // Prepare updates
        final Map<String, dynamic> updates = {};
        
        // 1. Add isProfileComplete field
        if (!data.containsKey('isProfileComplete')) {
          final isComplete = _calculateProfileCompleteness(data);
          updates['isProfileComplete'] = isComplete;
          print('   ✅ Added isProfileComplete: $isComplete');
        }
        
        // 2. Add hasDatingProfile field
        if (!data.containsKey('hasDatingProfile')) {
          final hasDatingProfile = _hasDatingProfile(data);
          updates['hasDatingProfile'] = hasDatingProfile;
          print('   ✅ Added hasDatingProfile: $hasDatingProfile');
        }
        
        // 3. Add lastActive field if missing
        if (!data.containsKey('lastActive')) {
          updates['lastActive'] = FieldValue.serverTimestamp();
          print('   ✅ Added lastActive: now');
        }
        
        // 4. Ensure lookingFor field exists
        if (!data.containsKey('lookingFor') || data['lookingFor'] == null) {
          updates['lookingFor'] = 'Dating';
          print('   ✅ Added lookingFor: Dating');
        }
        
        // 5. Ensure isBlocked field exists
        if (!data.containsKey('isBlocked')) {
          updates['isBlocked'] = false;
          print('   ✅ Added isBlocked: false');
        }
        
        // 6. Ensure showGender field exists
        if (!data.containsKey('showGender') || data['showGender'] == null) {
          updates['showGender'] = 'everyone';
          print('   ✅ Added showGender: everyone');
        }
        
        // 7. Add age range fields if missing
        if (!data.containsKey('ageRangeMin') && data['age'] != null) {
          final age = data['age'] as int?;
          if (age != null) {
            updates['ageRangeMin'] = (age - 5).clamp(18, 100);
            updates['ageRangeMax'] = (age + 5).clamp(18, 100);
            print('   ✅ Added ageRangeMin/Max based on age: $age');
          }
        }
        
        // 8. Add maxDistance if missing
        if (!data.containsKey('maxDistance') || data['maxDistance'] == null) {
          updates['maxDistance'] = 100;
          print('   ✅ Added maxDistance: 100');
        }
        
        // Update the document if there are changes
        if (updates.isNotEmpty) {
          await usersCollection.doc(userId).update(updates);
          updatedCount++;
          print('   ✅ Updated user $userId with ${updates.length} fields');
        } else {
          print('   ⏭️ No updates needed for user $userId');
        }
        
      } catch (e) {
        print('   ❌ Error processing user ${doc.id}: $e');
        errorCount++;
      }
    }
    
    print('\n🎉 Field fix process completed!');
    print('✅ Successfully updated: $updatedCount users');
    print('❌ Errors encountered: $errorCount users');
    
  } catch (e) {
    print('❌ Fatal error: $e');
  }
}

/// Calculate profile completeness score
bool _calculateProfileCompleteness(Map<String, dynamic> data) {
  int score = 0;
  const int totalFields = 8;
  
  // Essential fields for a complete profile
  if (data['name'] != null && data['name'].toString().isNotEmpty) score++;
  if (data['age'] != null) score++;
  if (data['gender'] != null && data['gender'].toString().isNotEmpty) score++;
  if (data['bio'] != null && data['bio'].toString().isNotEmpty) score++;
  if (data['photos'] != null && (data['photos'] as List).isNotEmpty) score++;
  if (data['latitude'] != null && data['longitude'] != null) score++;
  if (data['lookingFor'] != null && data['lookingFor'].toString().isNotEmpty) score++;
  if (data['showGender'] != null && data['showGender'].toString().isNotEmpty) score++;
  
  // Consider profile complete if 6+ out of 8 fields are filled
  return score >= 6;
}

/// Check if user has dating profile
bool _hasDatingProfile(Map<String, dynamic> data) {
  // Check if user has dating-relevant information
  final hasBio = data['bio'] != null && data['bio'].toString().isNotEmpty;
  final hasPhotos = data['photos'] != null && (data['photos'] as List).isNotEmpty;
  final lookingForDating = data['lookingFor'] == 'Dating' || 
                          data['lookingFor'] == 'Romance' || 
                          data['lookingFor'] == 'Relationship';
  
  return hasBio && hasPhotos && lookingForDating;
}
