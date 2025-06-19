import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Events
abstract class GoogleSignInEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class GoogleSignInRequested extends GoogleSignInEvent {}

// States
abstract class GoogleSignInState extends Equatable {
  @override
  List<Object> get props => [];
}

class GoogleSignInInitial extends GoogleSignInState {}

class GoogleSignInLoading extends GoogleSignInState {}

class GoogleSignInSuccess extends GoogleSignInState {
  final User user;

  GoogleSignInSuccess({required this.user});

  @override
  List<Object> get props => [user];
}

class GoogleSignInFailure extends GoogleSignInState {
  final String error;

  GoogleSignInFailure({required this.error});

  @override
  List<Object> get props => [error];
}

// BLoC
class GoogleSignInBloc extends Bloc<GoogleSignInEvent, GoogleSignInState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  GoogleSignInBloc() : super(GoogleSignInInitial()) {
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
  }

  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<GoogleSignInState> emit,
  ) async {
    emit(GoogleSignInLoading());
    try {
      // Trigger the Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in flow
        emit(GoogleSignInFailure(error: "Sign in canceled"));
        return;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Check if this is a new user (first time sign-in)
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
        
        log("Google Sign In successful. User: ${user.uid}, New user: $isNewUser");
        
        // Create or update user document in Firestore
        await _updateUserData(user, isNewUser);
        
        emit(GoogleSignInSuccess(user: user));
      } else {
        emit(GoogleSignInFailure(error: "Failed to sign in with Google"));
      }
    } catch (e) {
      log("Google Sign In error: $e");
      emit(GoogleSignInFailure(error: "Error signing in with Google: ${e.toString()}"));
    }
  }

  Future<void> _updateUserData(User user, bool isNewUser) async {
    try {
      // Get user data from Google account
      final displayName = user.displayName ?? '';
      final email = user.email ?? '';
      final photoURL = user.photoURL;
      
      // Create a map of user data
      final userData = {
        'userId': user.uid,
        'email': email,
        'name': displayName,
        'userName': displayName,
        'isBlocked': false,
        'isPremium': false,
        'lastActive': DateTime.now().toIso8601String(),
      };
      
      // If user has a profile picture from Google, add it
      if (photoURL != null && photoURL.isNotEmpty) {
        userData['profilePicture'] = photoURL;
        userData['photos'] = [photoURL];
      }
      
      // Update or create user document in Firestore
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));
          
      log("User data updated in Firestore");
    } catch (e) {
      log("Error updating user data: $e");
      // Don't throw here, just log the error
    }
  }
}
