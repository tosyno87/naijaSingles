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
      required File file}) async {
    try {
      final int timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Use default Firebase Storage instance
      Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('users/$currentUserId/$timestamp.jpg');
      
      log("Uploading profile to: users/$currentUserId/$timestamp.jpg");
      
      // Check if file exists and is readable
      if (!file.existsSync()) {
        log("File does not exist: ${file.path}");
        return null;
      }
      
      UploadTask uploadTask = storageReference.putFile(file);
      
      try {
        await uploadTask.then((p0) {
          storageReference.getDownloadURL().then((fileURL) async {
            try {
              log("Updating profile picture with URL: $fileURL");
              await firebaseFireStoreInstance
                  .collection("users")
                  .doc(currentUserId)
                  .set({"Pictures": [fileURL]},
                      SetOptions(merge: true));
            } catch (e) {
              log("Error updating Firestore with image URL: $e");
            }
          });
        });
      } catch (e) {
        log("Error in upload task: $e");
      }
      return uploadTask;
    } catch (e) {
      log("Error in uploadprofile: $e");
      return null;
    }
  }

  // Method for uploading verification images
  static Future<String?> uploadVerification({
      required String userId,
      required File file}) async {
    try {
      final int timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Use default Firebase Storage instance
      Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('verification/$userId/$timestamp.jpg');
      
      log("Uploading verification to: verification/$userId/$timestamp.jpg");
      
      // Check if file exists and is readable
      if (!file.existsSync()) {
        log("File does not exist: ${file.path}");
        return null;
      }
      
      UploadTask uploadTask = storageReference.putFile(file);
      
      try {
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        
        // Update user document with verification status
        await firebaseFireStoreInstance
            .collection("users")
            .doc(userId)
            .set({
              "verification": {
                "status": "pending",
                "imageUrl": downloadUrl,
                "submittedAt": FieldValue.serverTimestamp()
              }
            }, SetOptions(merge: true));
            
        log("Verification image uploaded: $downloadUrl");
        return downloadUrl;
      } catch (e) {
        log("Error in verification upload task: $e");
        return null;
      }
    } catch (e) {
      log("Error in uploadVerification: $e");
      return null;
    }
  }

  static Future<UploadTask?> uploadFile(
      {required String checktype,
      required UserModel currentUser,
      required File file}) async {
    try {
      final int timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Use default Firebase Storage instance instead of custom bucket
      // This will use the storage bucket from your Firebase project
      Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('users/${currentUser.id}/$timestamp.jpg');
      
      log("Uploading profile to: users/${currentUser.id}/$timestamp.jpg");
      
      // Check if file exists and is readable
      if (!file.existsSync()) {
        log("File does not exist: ${file.path}");
        return null;
      }
      
      UploadTask uploadTask = storageReference.putFile(file);
      
      try {
        await uploadTask.then((p0) {
          storageReference.getDownloadURL().then((fileURL) async {
            // Initialize Pictures array if it doesn't exist
            DocumentSnapshot userDoc = await firebaseFireStoreInstance
                .collection("users")
                .doc(currentUser.id)
                .get();
                
            List<String> pictures = [];
            if (userDoc.exists && userDoc.data() is Map<String, dynamic>) {
              Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
              if (userData.containsKey('Pictures') && userData['Pictures'] is List) {
                pictures = List<String>.from(userData['Pictures']);
              }
            }
            
            // Add new image URL
            pictures.add(fileURL);
            
            try {
              if (checktype == 'profile') {
                log("Updating profile picture with URL: $fileURL");
                await firebaseFireStoreInstance
                    .collection("users")
                    .doc(currentUser.id)
                    .set({"Pictures": pictures},
                        SetOptions(merge: true));
              } else {
                await firebaseFireStoreInstance
                    .collection("users")
                    .doc(currentUser.id)
                    .update({"Pictures": pictures});
              }
            } catch (e) {
              log("Error updating Firestore with image URL: $e");
            }
          });
        });
      } catch (e) {
        log("Error in upload task: $e");
      }
      return uploadTask;
    } catch (e) {
      log("Error in uploadFile: $e");
      return null;
    }
  }
}
