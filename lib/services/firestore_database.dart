import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:naijasingles/config/app_config.dart';

import '../common/constants/constants.dart';
import '../models/user_model.dart';

class FireStoreClass {
  static Future<UploadTask?> uploadFile(
      {required String checktype,
      required UserModel currentUser,
      required File file}) async {
    try {
      final int timestamp = DateTime.now().millisecondsSinceEpoch;
      Reference storageReference = FirebaseStorage.instanceFor(bucket: bucketId)
          .ref()
          .child('users/${currentUser.id}/$timestamp.jpg');
      
      // Check if file exists and is readable
      if (!file.existsSync()) {
        log("File does not exist: ${file.path}");
        return null;
      }
      
      UploadTask uploadTask = storageReference.putFile(file);
      
      try {
        await uploadTask.then((p0) {
          storageReference.getDownloadURL().then((fileURL) async {
            Map<String, dynamic> updateObject = {
              "Pictures": FieldValue.arrayUnion([
                fileURL,
              ])
            };
            try {
              if (checktype == 'profile') {
                //currentUser.imageUrl.removeAt(0);
                currentUser.imageUrl!.insert(0, fileURL);
                log("Updating profile picture");
                await firebaseFireStoreInstance
                    .collection("Users")
                    .doc(currentUser.id)
                    .set({"Pictures": currentUser.imageUrl},
                        SetOptions(merge: true));
              } else {
                await firebaseFireStoreInstance
                    .collection("Users")
                    .doc(currentUser.id)
                    .set(updateObject, SetOptions(merge: true));
                currentUser.imageUrl!.add(fileURL);
              }
            } catch (err) {
              log("Error updating Firestore: ${err.toString()}");
              rethrow;
            }
          }).catchError((err) {
            log("Error getting download URL: ${err.toString()}");
            return null;
          });
        }).catchError((err) {
          log("Error in upload task: ${err.toString()}");
          return null;
        });
        
        return uploadTask;
      } catch (e) {
        log("Error in upload task completion: ${e.toString()}");
        return null;
      }
    } on FirebaseException catch (e) {
      log("Firebase error in upload file: ${e.message}");
      return null;
    } catch (e) {
      log("General error in upload file: ${e.toString()}");
      return null;
    }
  }

  // Function to upload file and get download URL
  static Future<UploadTask?> uploadprofile(
      {required String currentUserId, required File file}) async {
    try {
      // Check if file exists and is readable
      if (!file.existsSync()) {
        log("Profile file does not exist: ${file.path}");
        return null;
      }
      
      final int timestamp = DateTime.now().millisecondsSinceEpoch;
      Reference storageReference = FirebaseStorage.instanceFor(bucket: bucketId)
          .ref()
          .child('users/$currentUserId/$timestamp.jpg');
      
      log("Uploading profile to: users/$currentUserId/$timestamp.jpg");
      UploadTask uploadTask = storageReference.putFile(file);

      try {
        await uploadTask.then((p0) {
          storageReference.getDownloadURL().then((fileURL) async {
            Map<String, dynamic> updateObject = {
              "Pictures": FieldValue.arrayUnion([
                fileURL,
              ])
            };
            try {
              log("Adding profile URL to Firestore");
              await firebaseFireStoreInstance
                  .collection("Users")
                  .doc(currentUserId)
                  .set(
                    updateObject,
                    SetOptions(merge: true),
                  );
            } catch (err) {
              log("Error updating Firestore with profile: ${err.toString()}");
              return null;
            }
          }).catchError((err) {
            log("Error getting profile download URL: ${err.toString()}");
            return null;
          });
        }).catchError((err) {
          log("Error in profile upload task: ${err.toString()}");
          return null;
        });

        return uploadTask;
      } catch (e) {
        log("Error in profile upload task completion: ${e.toString()}");
        return null;
      }
    } on FirebaseException catch (e) {
      log("Firebase error in profile upload: ${e.message}");
      return null;
    } catch (e) {
      log("General error in profile upload: ${e.toString()}");
      return null;
    }
  }
  static Future<String?> uploadVerification({
    required String userId,
    required File file,
  }) async {
    try {
      if (!file.existsSync()) {
        log('Verification file does not exist: ${file.path}');
        return null;
      }

      final int timestamp = DateTime.now().millisecondsSinceEpoch;
      Reference storageReference = FirebaseStorage.instanceFor(bucket: bucketId)
          .ref()
          .child('verification/$userId/$timestamp.jpg');

      UploadTask uploadTask = storageReference.putFile(file);
      await uploadTask;

      final fileURL = await storageReference.getDownloadURL();
      await firebaseFireStoreInstance.collection('Users').doc(userId).set({
        'verificationImages': FieldValue.arrayUnion([fileURL]),
        'isVerified': true,
      }, SetOptions(merge: true));

      return fileURL;
    } catch (e) {
      log('Error uploading verification image: ${e.toString()}');
      return null;
    }
  }

}
