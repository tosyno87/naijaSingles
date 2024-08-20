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
      firebaseFireStoreInstance.collection("Users");

  UserModel? _currentUser;
  StreamSubscription<QuerySnapshot>? _userSubscription;
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
      _userSubscription = _userCollection
          .where("userId", isEqualTo: user.uid)
          .snapshots()
          .listen((event) {
        if (event.docs.isNotEmpty) {
          // log("listen user1 ${event.docs.first.data().toString()}");
          final userData = UserModel.fromDocument(event.docs.first);
          currentUser = userData;
          notifyListeners();
        }
      });
    } else {
      throw Exception('No user found');
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
