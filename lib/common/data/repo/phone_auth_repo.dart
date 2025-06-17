import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:naijasingles/config/app_config.dart';

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
    if (kDebugMode && phoneNumber == '+12179044453') {
      log("🔥 Using test phone number with Firebase Auth Emulator");
      
      // When using Firebase Auth Emulator, we need to follow the proper flow
      // First, trigger the phone verification to get a real verification ID
      await auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (credential) {
          log("✅ Auto verification completed in emulator");
          verificationCompleted(credential);
        },
        verificationFailed: verificationFailed,
        codeSent: (verificationId, resendToken) {
          log("📩 Test code sent. Verification ID: $verificationId");
          
          // For test phone numbers in the emulator, we know the code is always
          // '123456'. We can create the credential here and complete the
          // verification
          final testCredential = PhoneAuthProvider.credential(
            verificationId: verificationId,
            smsCode: '123456',
          );
          
          // Call the original codeSent callback first
          codeSent(verificationId, resendToken);
          
          // Then automatically complete the verification
          verificationCompleted(testCredential);
        },
        timeout: const Duration(seconds: 60),
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      );
      
      return;
    }
    
    // Normal flow for non-test numbers or production mode
    await auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      timeout: const Duration(seconds: 120),
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      forceResendingToken: null,
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
  
  // Method for development testing with Firebase Auth Emulator
  Future<User?> signInWithTestPhone() async {
    try {
      log("📲 Starting Firebase test phone sign-in using emulator");
      
      // When using Firebase Auth Emulator with test phone numbers:
      // 1. We need to use a specific test phone number format
      // 2. The verification code provided by the emulator is '123456'
      
      // First, sign in directly with the test phone number
      final phoneNumber = '+12179044453'; // This is a test phone number format
      
      // Create a Completer to handle the async verification process
      final completer = Completer<UserCredential>();
      
      // Start the phone verification process
      await auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // This callback is triggered when verification is automatically completed
          // (usually on Android with SMS retrieval)
          try {
            log("✅ Auto verification completed for test phone");
            final userCredential = await auth.signInWithCredential(credential);
            completer.complete(userCredential);
          } catch (e) {
            completer.completeError(e);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          log("❌ Test phone verification failed: ${e.message}");
          completer.completeError(e);
        },
        codeSent: (String verificationId, int? resendToken) async {
          try {
            log("📩 Code sent for test phone. Using verification ID: $verificationId");

            // For Firebase Auth Emulator, the verification code is always '123456'
            final credential = PhoneAuthProvider.credential(
              verificationId: verificationId,
              smsCode: '123456',
            );
            
            // Sign in with the credential
            final userCredential = await auth.signInWithCredential(credential);
            log("✅ Successfully signed in with test phone: ${userCredential.user?.uid}");
            completer.complete(userCredential);
          } catch (e) {
            log("❌ Error signing in with test credential: $e");
            completer.completeError(e);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          log("⏰ Code auto retrieval timeout for test phone");
          // Don't complete the completer here, as it might have been completed already
        },
      );
      
      // Wait for the sign-in process to complete
      final userCredential = await completer.future;
      return userCredential.user;
    } catch (e) {
      log("🔥 Error with test phone auth: $e");
      rethrow;
    }
  }

  // check signIn
  Future<bool> isSignedIn() async {
    var currentUser = auth.currentUser;
    return currentUser != null;
  }

  Future deleteUser(User user) async {
    // user.delete();
    final checkedSnapshot = await firebaseFireStoreInstance
        .collection("Users")
        .doc(user.uid)
        .collection('CheckedUser')
        .get();
    for (final element in checkedSnapshot.docs) {
      await firebaseFireStoreInstance
          .collection("Users")
          .doc(user.uid)
          .collection("CheckedUser")
          .doc(element.id)
          .delete()
          .then((value) => log("success"));
    }
    final likedBySnapshot = await firebaseFireStoreInstance
        .collection("Users")
        .doc(user.uid)
        .collection('LikedBy')
        .get();
    for (final element in likedBySnapshot.docs) {
      await firebaseFireStoreInstance
          .collection("Users")
          .doc(user.uid)
          .collection("LikedBy")
          .doc(element.id)
          .delete()
          .then((value) => log("success"));
    }

    final matchesSnapshot = await firebaseFireStoreInstance
        .collection("Users")
        .doc(user.uid)
        .collection('Matches')
        .get();
    for (final element in matchesSnapshot.docs) {
      await firebaseFireStoreInstance
          .collection("Users")
          .doc(user.uid)
          .collection("Matches")
          .doc(element.id)
          .delete()
          .then((value) => log("success"));
    }

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
      'phoneNumber': user.phoneNumber,
      'Pictures': [] // Initialize empty Pictures array
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
