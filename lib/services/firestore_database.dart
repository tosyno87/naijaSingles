import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hookup4u2/config/app_config.dart';

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
      UploadTask uploadTask = storageReference.putFile(file);
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
              log("object");
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
            rethrow;
          }
        });
      }).catchError((err) {
        return null;
      });
      return uploadTask;
    } on FirebaseException catch (e) {
      log("err in upload file ${e.message}");
      return null;
    }
  }

  // Function to upload file and get download URL

  static Future<UploadTask?> uploadprofile(
      {required String currentUserId, required file}) async {
    try {
      final int timestamp = DateTime.now().millisecondsSinceEpoch;
      Reference storageReference = FirebaseStorage.instanceFor(bucket: bucketId)
          .ref()
          .child('users/$currentUserId/$timestamp.jpg');
      UploadTask uploadTask = storageReference.putFile(file);

      await uploadTask.then((p0) {
        storageReference.getDownloadURL().then((fileURL) async {
          Map<String, dynamic> updateObject = {
            "Pictures": FieldValue.arrayUnion([
              fileURL,
            ])
          };
          try {
            log("object");
            await firebaseFireStoreInstance
                .collection("Users")
                .doc(currentUserId)
                .set(
                  updateObject,
                  SetOptions(merge: true),
                );
          } catch (err) {
            return null;
          }
        }).catchError((err) {
          return null;
        });
      });

      return uploadTask;
    } on FirebaseException {
      log("task is null");
      return null;
    }
  }
}
