import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../constants/constants.dart';

class UserProvider extends ChangeNotifier {
  UserProvider() {
    listenCurrentUserdetails();
    listenAuthChanges();
  }
  final FirebaseAuth _auth = firebaseAuthInstance;
  final CollectionReference _userCollection =
      firebaseFireStoreInstance.collection("users");

  UserModel? _currentUser;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  StreamSubscription<User?>? authStateSubscription;

  UserModel? get currentUser => _currentUser;
  set currentUser(UserModel? val) {
    _currentUser = val;
    notifyListeners();
  }

  // for listining all details of user

  Future<void> listenCurrentUserdetails() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        // Listen to the specific document directly using the user's UID as the document ID
        _userSubscription = _userCollection
            .doc(user.uid)
            .snapshots()
            .listen((documentSnapshot) {
          if (documentSnapshot.exists) {
            final userData = UserModel.fromDocument(documentSnapshot);
            currentUser = userData;
            notifyListeners();
          }
        }, onError: (error) {
          print("Error listening to user details: $error");
        });
      } catch (e) {
        print("Exception in listenCurrentUserdetails: $e");
      }
    } else {
      print("No authenticated user found");
    }
  }

  // Listen for authentication state changes
  void listenAuthChanges() {
    authStateSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        listenCurrentUserdetails();
      } else {
        // User is logged out
        // Handle this case as needed
      }
    });
  }

// you can cancel listen to user if requieed
  void cancelCurrentUserSubscription() {
    _userSubscription?.cancel();
    authStateSubscription!.cancel();
  }
}
