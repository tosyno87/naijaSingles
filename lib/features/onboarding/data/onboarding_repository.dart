import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../../../common/utils/app_logger.dart';
import '../bloc/onboarding_data.dart';

/// Repository for saving onboarding data to Firestore and Storage
class OnboardingRepository {
  Future<void> saveUserData({
    required OnboardingData data,
    required String userId,
  }) async {
    final essentialData = _buildEssentialData(data);

    AppLogger.info('🔍 Saving essential user data to Firestore...');

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .set(essentialData, SetOptions(merge: true));

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'onboardingCompleted': true,
      'profileSetupComplete': true,
      'isProfileComplete': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.updateDisplayName(data.fullName);
    }

    AppLogger.info('✅ Essential user data saved successfully');
  }

  Future<void> uploadProfilePictures({
    required OnboardingData data,
    required String userId,
  }) async {
    final validPhotos = data.profilePhotos.whereType<File>().toList();

    if (validPhotos.isEmpty) {
      log('⚠️ No photos to upload');
      return;
    }

    log('📸 Starting upload of ${validPhotos.length} profile pictures');

    final photoUrls = <String>[];

    for (var i = 0; i < validPhotos.length; i++) {
      final photo = validPhotos[i];

      if (!photo.existsSync()) {
        log('❌ Photo $i does not exist');
        continue;
      }

      final fileSize = await photo.length();
      const maxSize = 10 * 1024 * 1024;
      if (fileSize > maxSize) {
        log('❌ Photo $i too large');
        continue;
      }

      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('users/$userId/profile_photo_$i.jpg');

        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'photoIndex': i.toString(),
          },
        );

        final bytes = await photo.readAsBytes();
        final uploadTask = storageRef.putData(bytes, metadata);

        final snapshot = await uploadTask.timeout(
          const Duration(minutes: 2),
          onTimeout: () =>
              throw TimeoutException('Photo upload timed out'),
        );

        final url = await snapshot.ref.getDownloadURL();
        photoUrls.add(url);
      } catch (e) {
        log('❌ Error uploading photo $i: $e');
      }
    }

    if (photoUrls.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set(
            {
              'profilePicture': photoUrls[0],
              'photos': photoUrls,
              'Pictures': photoUrls,
              'imageUrl': photoUrls,
              'profilePhotoCount': photoUrls.length,
              'lastPhotoUpdate': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
    }
  }

  Map<String, dynamic> _buildEssentialData(OnboardingData d) {
    String getHeightFtIn() {
      final totalInches = d.height / 2.54;
      final feet = (totalInches / 12).floor();
      final inches = (totalInches % 12).round();
      return '$feet\'$inches"';
    }

    return {
      'name': d.fullName,
      'userName': d.fullName,
      'dateOfBirth': d.dateOfBirth?.toIso8601String(),
      'age': d.age,
      'gender': d.gender,
      'tribe': d.tribe,
      'bio': d.bio,
      'interests': d.interests,
      'height': d.height,
      'height_ft_in': getHeightFtIn(),
      'height_cm': d.height.round(),
      'heightDisplay': getHeightFtIn(),
      'heightUnit': d.heightUnit,
      'lookingFor': d.lookingFor,
      'relationshipIntent': d.relationshipIntent,
      'interestedIn': d.interestedIn,
      'intent': d.intent,
      'nationality': d.nationality,
      'education': d.education,
      'occupation': d.occupation,
      'fashionStyle': d.fashionStyle,
      'weekendVibe': d.weekendVibe,
      'religion': d.religion,
      'languages': d.languages,
      'genres': d.genres,
      'values': d.values,
      'dealbreakers': d.dealbreakers,
      'drinkingPreference': d.drinkingPreference,
      'smokingPreference': d.smokingPreference,
      'lastActive': DateTime.now().toIso8601String(),
      'isProfileComplete': true,
      'isBlocked': false,
      'isPremium': false,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'editInfo': {'userGender': d.gender, 'userName': d.fullName},
      'preferences': {
        'interestedIn': d.interestedIn,
        'ageRange': d.ageRange,
        'lookingFor': d.lookingFor,
        'relationshipIntent': d.relationshipIntent,
        'maximumDistance': d.maxDistance,
      },
      'showGender': d.interestedIn,
      'ageRange': {'min': d.ageRange[0].toString(), 'max': d.ageRange[1].toString()},
      'userGender': d.gender,
      'age_range': {'min': d.ageRange[0].toString(), 'max': d.ageRange[1].toString()},
      'maximum_distance': d.maxDistance,
      'maxDistance': d.maxDistance,
      'location': {
        'latitude': d.latitude ?? 6.5244,
        'longitude': d.longitude ?? 3.3792,
        'address': d.locationName ?? 'Location not set',
        'city': d.locationName ?? 'Location not set',
      },
      'locationName': d.locationName,
      'latitude': d.latitude ?? 6.5244,
      'longitude': d.longitude ?? 3.3792,
      'onboardingCompleted': true,
      'profileSetupComplete': true,
    };
  }
}
