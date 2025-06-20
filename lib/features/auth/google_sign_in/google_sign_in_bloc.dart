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
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Explicitly specify scopes (optional)
    scopes: ['email', 'profile'],
    // For iOS, specify the client ID explicitly
    clientId: '888697307756-c0gm1rhh6f0dd7fh8f3geqbn12ctmmho.apps.googleusercontent.com',
  );

  GoogleSignInBloc() : super(GoogleSignInInitial()) {
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
  }

  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<GoogleSignInState> emit,
  ) async {
    emit(GoogleSignInLoading());
    try {
      log("Starting Google Sign In process...");
      
      // Check if user is already signed in with Google
      final currentUser = _googleSignIn.currentUser;
      if (currentUser != null) {
        log("User already signed in with Google. Signing out first...");
        await _googleSignIn.signOut();
      }
      
      // Trigger the Google Sign In flow
      log("Triggering Google Sign In UI...");
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      log("Google Sign In result: ${googleUser != null ? 'Success' : 'Canceled/Failed'}");
      
      if (googleUser == null) {
        // User canceled the sign-in flow
        log("Google Sign In was canceled by user");
        emit(GoogleSignInFailure(error: "Sign in canceled"));
        return;
      }

      log("Getting Google authentication details...");
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      log("Got auth tokens - Access token length: ${googleAuth.accessToken?.length ?? 0}, ID token length: ${googleAuth.idToken?.length ?? 0}");

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      log("Signing in to Firebase with Google credential...");
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
        log("Failed to sign in with Google - user is null");
        emit(GoogleSignInFailure(error: "Failed to sign in with Google"));
      }
    } catch (e) {
      log("Google Sign In error: $e");
      emit(GoogleSignInFailure(error: "Error signing in with Google: ${e.toString()}"));
    }
  }

  Future<void> _updateUserData(User user, bool isNewUser) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      
      if (isNewUser) {
        // Create a new user document
        await userRef.set({
          'id': user.uid,
          'email': user.email,
          'name': user.displayName,
          'photoUrl': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
          'signInMethod': 'google',
          'onboardingCompleted': false,
        });
        log("Created new user document for: ${user.uid}");
      } else {
        // Update existing user document
        await userRef.update({
          'lastActive': FieldValue.serverTimestamp(),
          'lastSignIn': FieldValue.serverTimestamp(),
          'email': user.email,
          'name': user.displayName ?? '',
          'photoUrl': user.photoURL ?? '',
        });
        log("Updated existing user document for: ${user.uid}");
      }
    } catch (e) {
      log("Error updating user data: $e");
      // We don't want to fail the sign-in if this fails
      // Just log the error
    }
  }
}
