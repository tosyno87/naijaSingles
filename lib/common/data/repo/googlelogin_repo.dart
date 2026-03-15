import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../constants/constants.dart';
import '../../utils/app_logger.dart';

abstract class GoogleLoginRepository {
  Future<User?> signInWithGoogle();
  Future<void> ensureUserDocument(User user);
  Future<AuthCredential?> getGoogleReauthCredential();
}

class GoogleLoginRepositoryImpl implements GoogleLoginRepository {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Specify scopes if needed
    scopes: [
      'email',
      'profile',
    ],
  );

  @override
  Future<User?> signInWithGoogle() async {
    try {
      // Begin interactive sign-in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // If user cancels the sign-in flow, return null (no throw)
      if (googleUser == null) {
        return null;
      }

      // Obtain auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential =
          await firebaseAuthInstance.signInWithCredential(credential);

      // Return the user
      return userCredential.user;
    } on Object catch (e) {
      AppLogger.error('Google Sign-In Error', error: e);
      // Handle specific errors if needed
      if (e is FirebaseAuthException) {
        if (e.code == 'account-exists-with-different-credential') {
          throw Exception(
            'An account already exists with the same email address but different sign-in credentials.',
          );
        } else if (e.code == 'invalid-credential') {
          throw Exception(
            'Error occurred while accessing credentials. Try again.',
          );
        }
      }
      // Rethrow the error for the BLoC to handle
      rethrow;
    }
  }

  @override
  Future<void> ensureUserDocument(User user) async {
    final userRef =
        firebaseFireStoreInstance.collection('users').doc(user.uid);
    final doc = await userRef.get();
    if (doc.exists && doc.data() != null && doc.data()!.isNotEmpty) {
      await userRef.update({
        'lastActive': FieldValue.serverTimestamp(),
        'lastSignIn': FieldValue.serverTimestamp(),
        'email': user.email,
        'name': user.displayName ?? '',
        'photoUrl': user.photoURL ?? '',
      });
    } else {
      await userRef.set({
        'email': user.email,
        'name': user.displayName,
        'photoUrl': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
        'signInMethod': 'google',
        'onboardingCompleted': false,
      });
    }
  }

  @override
  Future<AuthCredential?> getGoogleReauthCredential() async {
    try {
      // For re-authentication we only need a fresh credential.
      // Do not sign out first, and do not sign in to Firebase here.
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      return GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
    } on Object catch (e) {
      AppLogger.error('Google re-auth credential error', error: e);
      rethrow;
    }
  }
}
