import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../constants/constants.dart';
import '../utils/app_logger.dart';

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
    // Cancel any existing subscription before starting a new one
    _userSubscription?.cancel();
    _userSubscription = null;
    
    final user = _auth.currentUser;
    if (user != null) {
      try {
        // Listen to the specific document directly using the user's UID as the document ID
        _userSubscription = _userCollection.doc(user.uid).snapshots().listen(
            (documentSnapshot) {
          try {
            if (documentSnapshot.exists) {
              final userData = UserModel.fromDocument(documentSnapshot);
              currentUser = userData;
              notifyListeners();
            } else {
              AppLogger.warning("User document does not exist for UID: ${user.uid}");
              currentUser = null;
              notifyListeners();
            }
          } catch (e) {
            AppLogger.error("Error parsing user document", error: e);
            // Don't set currentUser to null here, keep existing data
          }
        }, onError: (error) {
          // Only log errors if user is still authenticated
          // Permission errors when user is logged out are expected
          if (_auth.currentUser != null) {
            AppLogger.error("Error listening to user details", error: error);
          }
        });
      } catch (e) {
        AppLogger.error("Exception in listenCurrentUserdetails", error: e);
      }
    } else {
      // User is not authenticated - ensure user data is cleared
      currentUser = null;
      AppLogger.debug("No authenticated user found");
    }
  }

  // Listen for authentication state changes
  void listenAuthChanges() {
    authStateSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // User logged in - start listening to user details
        listenCurrentUserdetails();
      } else {
        // User is logged out - cancel any active subscriptions and clear user data
        _userSubscription?.cancel();
        _userSubscription = null;
        currentUser = null;
      }
    });
  }

// you can cancel listen to user if requieed
  void cancelCurrentUserSubscription() {
    _userSubscription?.cancel();
    _userSubscription = null;
    authStateSubscription?.cancel();
    authStateSubscription = null;
    currentUser = null;
  }
}
