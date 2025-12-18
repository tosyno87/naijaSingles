import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../constants/constants.dart';
import '../../utils/app_logger.dart';

abstract class GoogleLoginRepository {
  Future<User?> signInWithGoogle();
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

      // If user cancels the sign-in flow, return null
      if (googleUser == null) {
        throw Exception('Google sign in was canceled by user');
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
    } catch (e) {
      AppLogger.error('Google Sign-In Error', error: e);
      // Handle specific errors if needed
      if (e is FirebaseAuthException) {
        if (e.code == 'account-exists-with-different-credential') {
          throw 'An account already exists with the same email address but different sign-in credentials.';
        } else if (e.code == 'invalid-credential') {
          throw 'Error occurred while accessing credentials. Try again.';
        }
      }
      // Rethrow the error for the BLoC to handle
      rethrow;
    }
  }
}
