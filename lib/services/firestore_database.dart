import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../common/constants/constants.dart';
import '../models/user_model.dart';

class FireStoreClass {
  // Method for uploading profile during registration
  static Future<UploadTask?> uploadprofile({
    required String currentUserId,
    required File file,
  }) async {
    try {
      final int timestamp = DateTime.now().millisecondsSinceEpoch;

      // Use default Firebase Storage instance
      final Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('users/$currentUserId/$timestamp.jpg');

      log('Uploading profile to: users/$currentUserId/$timestamp.jpg');

      // Check if file exists and is readable
      if (!file.existsSync()) {
        log('File does not exist: ${file.path}');
        return null;
      }

      final UploadTask uploadTask = storageReference.putFile(file);

      try {
        final snapshot = await uploadTask;
        final fileURL = await snapshot.ref.getDownloadURL();
        log('Updating profile picture with URL: $fileURL');
        await firebaseFireStoreInstance
            .collection('users')
            .doc(currentUserId)
            .set(
          {
            'Pictures': FieldValue.arrayUnion([fileURL]),
          },
          SetOptions(merge: true),
        );
      } on Object catch (e) {
        log('Error in upload task: $e');
        return null;
      }
      return uploadTask;
    } on Object catch (e) {
      log('Error in uploadprofile: $e');
      return null;
    }
  }

  // Method for uploading verification images
  static Future<String?> uploadVerification({
    required String userId,
    required File file,
  }) async {
    try {
      final int timestamp = DateTime.now().millisecondsSinceEpoch;

      // Use default Firebase Storage instance
      final Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('verification/$userId/$timestamp.jpg');

      log('Uploading verification to: verification/$userId/$timestamp.jpg');

      // Check if file exists and is readable
      if (!file.existsSync()) {
        log('File does not exist: ${file.path}');
        return null;
      }

      final UploadTask uploadTask = storageReference.putFile(file);

      try {
        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        // Keep verification metadata in a private subcollection, not on the
        // public profile root document.
        await firebaseFireStoreInstance
            .collection('users')
            .doc(userId)
            .collection('verification')
            .doc('current')
            .set(
          {
            'status': 'pending',
            'imageUrl': downloadUrl,
            'submittedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        log('Verification image uploaded: $downloadUrl');
        return downloadUrl;
      } on Object catch (e) {
        log('Error in verification upload task: $e');
        return null;
      }
    } on Object catch (e) {
      log('Error in uploadVerification: $e');
      return null;
    }
  }

  static Future<UploadTask?> uploadFile({
    required String checktype,
    required UserModel currentUser,
    required File file,
  }) async {
    try {
      final int timestamp = DateTime.now().millisecondsSinceEpoch;

      // Use default Firebase Storage instance instead of custom bucket
      // This will use the storage bucket from your Firebase project
      final Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('users/${currentUser.id}/$timestamp.jpg');

      log('Uploading profile to: users/${currentUser.id}/$timestamp.jpg');

      // Check if file exists and is readable
      if (!file.existsSync()) {
        log('File does not exist: ${file.path}');
        return null;
      }

      final UploadTask uploadTask = storageReference.putFile(file);

      try {
        final snapshot = await uploadTask;
        final fileURL = await snapshot.ref.getDownloadURL();

        if (checktype == 'profile') {
          log('Updating profile picture with URL: $fileURL');
        }

        await firebaseFireStoreInstance
            .collection('users')
            .doc(currentUser.id)
            .set(
          {
            'Pictures': FieldValue.arrayUnion([fileURL]),
          },
          SetOptions(merge: true),
        );
      } on Object catch (e) {
        log('Error in upload task: $e');
        return null;
      }
      return uploadTask;
    } on Object catch (e) {
      log('Error in uploadFile: $e');
      return null;
    }
  }
}
