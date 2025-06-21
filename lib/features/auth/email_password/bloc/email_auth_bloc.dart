import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Events
abstract class EmailAuthEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class EmailSignUpRequested extends EmailAuthEvent {
  final String email;
  final String password;

  EmailSignUpRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class EmailSignInRequested extends EmailAuthEvent {
  final String email;
  final String password;

  EmailSignInRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class EmailPasswordResetRequested extends EmailAuthEvent {
  final String email;

  EmailPasswordResetRequested({required this.email});

  @override
  List<Object> get props => [email];
}

// States
abstract class EmailAuthState extends Equatable {
  @override
  List<Object> get props => [];
}

class EmailAuthInitial extends EmailAuthState {}

class EmailAuthLoading extends EmailAuthState {}

class EmailAuthSuccess extends EmailAuthState {
  final User user;

  EmailAuthSuccess({required this.user});

  @override
  List<Object> get props => [user];
}

class EmailPasswordResetSent extends EmailAuthState {}

class EmailAuthError extends EmailAuthState {
  final String error;

  EmailAuthError({required this.error});

  @override
  List<Object> get props => [error];
}

// BLoC
class EmailAuthBloc extends Bloc<EmailAuthEvent, EmailAuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  EmailAuthBloc() : super(EmailAuthInitial()) {
    on<EmailSignUpRequested>(_onEmailSignUpRequested);
    on<EmailSignInRequested>(_onEmailSignInRequested);
    on<EmailPasswordResetRequested>(_onEmailPasswordResetRequested);
  }

  Future<void> _onEmailSignUpRequested(
    EmailSignUpRequested event,
    Emitter<EmailAuthState> emit,
  ) async {
    emit(EmailAuthLoading());
    try {
      log("Creating new account with email: ${event.email}");
      
      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      
      final user = userCredential.user;
      
      if (user != null) {
        log("Successfully created account for: ${user.uid}");
        
        // Create user document in Firestore
        await _createUserDocument(user);
        
        emit(EmailAuthSuccess(user: user));
      } else {
        emit(EmailAuthError(error: "Failed to create account"));
      }
    } on FirebaseAuthException catch (e) {
      log("Firebase Auth Error: ${e.code} - ${e.message}");
      String errorMessage;
      
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already registered. Please log in instead.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'weak-password':
          errorMessage = 'The password is too weak. Please use a stronger password.';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred during sign up.';
      }
      
      emit(EmailAuthError(error: errorMessage));
    } catch (e) {
      log("Error during sign up: $e");
      emit(EmailAuthError(error: "An unexpected error occurred. Please try again."));
    }
  }

  Future<void> _onEmailSignInRequested(
    EmailSignInRequested event,
    Emitter<EmailAuthState> emit,
  ) async {
    emit(EmailAuthLoading());
    try {
      log("Signing in with email: ${event.email}");
      
      // Sign in with email and password
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      
      final user = userCredential.user;
      
      if (user != null) {
        log("Successfully signed in: ${user.uid}");
        
        // Update last login timestamp
        await _updateLastLogin(user);
        
        emit(EmailAuthSuccess(user: user));
      } else {
        emit(EmailAuthError(error: "Failed to sign in"));
      }
    } on FirebaseAuthException catch (e) {
      log("Firebase Auth Error: ${e.code} - ${e.message}");
      String errorMessage;
      
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred during sign in.';
      }
      
      emit(EmailAuthError(error: errorMessage));
    } catch (e) {
      log("Error during sign in: $e");
      emit(EmailAuthError(error: "An unexpected error occurred. Please try again."));
    }
  }

  Future<void> _onEmailPasswordResetRequested(
    EmailPasswordResetRequested event,
    Emitter<EmailAuthState> emit,
  ) async {
    emit(EmailAuthLoading());
    try {
      log("Sending password reset email to: ${event.email}");
      
      await _auth.sendPasswordResetEmail(email: event.email);
      
      log("Password reset email sent successfully");
      emit(EmailPasswordResetSent());
    } on FirebaseAuthException catch (e) {
      log("Firebase Auth Error: ${e.code} - ${e.message}");
      String errorMessage;
      
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred while sending the password reset email.';
      }
      
      emit(EmailAuthError(error: errorMessage));
    } catch (e) {
      log("Error sending password reset: $e");
      emit(EmailAuthError(error: "An unexpected error occurred. Please try again."));
    }
  }

  Future<void> _createUserDocument(User user) async {
    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      
      await userRef.set({
        'id': user.uid,
        'email': user.email,
        'name': user.displayName ?? '',
        'photoUrl': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
        'signInMethod': 'email',
        'onboardingCompleted': false,
      });
      
      log("Created user document for: ${user.uid}");
    } catch (e) {
      log("Error creating user document: $e");
      // We don't want to fail the sign-up if this fails
      // Just log the error
    }
  }

  Future<void> _updateLastLogin(User user) async {
    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      
      await userRef.update({
        'lastActive': FieldValue.serverTimestamp(),
        'lastSignIn': FieldValue.serverTimestamp(),
      });
      
      log("Updated last login for: ${user.uid}");
    } catch (e) {
      log("Error updating last login: $e");
      // We don't want to fail the sign-in if this fails
      // Just log the error
    }
  }
}
