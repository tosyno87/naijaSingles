// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hookup4u2/config/app_config.dart';

import '../../../models/user_model.dart';
import '../../constants/constants.dart';

class PhoneAuthRepository {
  FirebaseAuth auth = firebaseAuthInstance;

  Future<void> verifyPhone({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      timeout: const Duration(seconds: 0),
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  Future<void> updatePhone({
    required String phoneNumber,
    required PhoneAuthCredential verificationCompleted,
  }) async {
    User? user = firebaseAuthInstance.currentUser;

    if (user != null) {
      try {
        await user.updatePhoneNumber(verificationCompleted);
      } catch (e) {
        rethrow;
      }
    }
  }

  // sign out
  Future<void> signOut() async {
    await auth.signOut();
  }

  // check signIn
  Future<bool> isSignedIn() async {
    var currentUser = auth.currentUser;
    return currentUser != null;
  }

  Future deleteUser(User user) async {
    // user.delete();
    await firebaseFireStoreInstance
        .collection("Users")
        .doc(user.uid)
        .collection('CheckedUser')
        .get()
        .then((value) {
      value.docs.forEach((element) async {
        await firebaseFireStoreInstance
            .collection("Users")
            .doc(user.uid)
            .collection("CheckedUser")
            .doc(element.id)
            .delete()
            .then((value) => log("success"));
      });
    });
    await firebaseFireStoreInstance
        .collection("Users")
        .doc(user.uid)
        .collection('LikedBy')
        .get()
        .then((value) {
      value.docs.forEach((element) async {
        await firebaseFireStoreInstance
            .collection("Users")
            .doc(user.uid)
            .collection("LikedBy")
            .doc(element.id)
            .delete()
            .then((value) => log("success"));
      });
    });

    await firebaseFireStoreInstance
        .collection("Users")
        .doc(user.uid)
        .collection('Matches')
        .get()
        .then((value) {
      value.docs.forEach((element) async {
        await firebaseFireStoreInstance
            .collection("Users")
            .doc(user.uid)
            .collection("Matches")
            .doc(element.id)
            .delete()
            .then((value) => log("success"));
      });
    });

    await firebaseFireStoreInstance.collection("Users").doc(user.uid).delete();
    // Delete user details from Firebase Storage
    await deleteUserStorageCollection(user.uid);
  }

  // get current user
  Future<User?> getCurrentUser() async {
    return auth.currentUser;
  }

  Future<String?> getToken() async {
    return auth.currentUser?.getIdToken();
  }

  Future<UserModel> registration(
      {required Map<String, dynamic> userData}) async {
    User? user = auth.currentUser;

    userData.addAll({
      'userId': user!.uid,
      "isBlocked": false,
      'isPremium': false,
      'phoneNumber': user.phoneNumber
    });

    await firebaseFireStoreInstance
        .collection("Users")
        .doc(user.uid)
        .set(userData, SetOptions(merge: true));
    var result = await firebaseFireStoreInstance
        .collection('Users')
        .where('userId', isEqualTo: user.uid)
        .get();
    return UserModel.fromDocument(result.docs.first);
  }

  Future<bool> userDetails(String userId) async {
    var querySnapshot = await firebaseFireStoreInstance
        .collection('Users')
        .where('userId', isEqualTo: userId)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      var docSnapshot = querySnapshot.docs.first;
      if (docSnapshot.data().containsKey('location')) {
        log(docSnapshot.data().toString());
        return true;
      } else {
        // log(querySnapshot.docs.first.data().toString());
        log(userId.toString());
        log('Location field not found');
      }
    } else {
      log(userId.toString());
      log('Document not found');
    }
    return false;
  }

  Future<UserModel> getRegisterUser() async {
    UserModel? registeredUser;
    User? fbuser = auth.currentUser;
    try {
      var result = await firebaseFireStoreInstance
          .collection('Users')
          .where('userId', isEqualTo: fbuser!.uid)
          .get();

      // log(result.docs.first.data().toString());
      registeredUser = UserModel.fromDocument(result.docs.first);

      return registeredUser;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteUserStorageCollection(String userId) async {
    try {
      // Initialize Firebase Storage
      FirebaseStorage storage = FirebaseStorage.instanceFor(bucket: bucketId);

      // Get a reference to the user's collection
      Reference userCollectionRef = storage.ref().child('users/$userId');

      // List all the files in the user's collection
      ListResult listResult = await userCollectionRef.listAll();

      // Delete each file in the user's collection
      for (Reference item in listResult.items) {
        await item.delete();
      }

      // Delete the user's collection folder
      await userCollectionRef.delete();
    } catch (error) {
      // Handle any errors gracefully
      log('Error deleting user collection: $error');
      // Display a user-friendly message or perform any necessary actions
    }
  }
}
