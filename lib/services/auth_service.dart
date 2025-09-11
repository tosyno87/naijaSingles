import 'package:firebase_auth/firebase_auth.dart';

import '../common/constants/constants.dart';

/// Utility class that centralizes authentication calls to Firebase.
class AuthService {
  /// FirebaseAuth instance used for all operations. Can be overridden for testing.
  AuthService({FirebaseAuth? firebaseAuth})
      : _auth = firebaseAuth ?? firebaseAuthInstance;

  final FirebaseAuth _auth;

  /// Sign in a user using their email and password.
  ///
  /// Throws a [FirebaseAuthException] if sign in fails.
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Start phone number verification for [phone].
  /// The provided callbacks are forwarded to [FirebaseAuth.verifyPhoneNumber].
  Future<void> verifyPhoneNumber({
    required String phone,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    Duration timeout = const Duration(seconds: 60),
    int? forceResendingToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      timeout: timeout,
      forceResendingToken: forceResendingToken,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  /// Sign in using the verification ID and SMS code sent to the user.
  ///
  /// Returns the resulting [UserCredential] on success.
  Future<UserCredential> signInWithCredential({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }
}
