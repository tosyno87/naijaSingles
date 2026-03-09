// ignore_for_file: one_member_abstracts

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import '../../constants/constants.dart';

abstract class FaceBookLoginRepository {
  Future<User?> signInWithFacebook();
}

class FaceBookLoginRepositoryImpl implements FaceBookLoginRepository {
  @override
  Future<User?> signInWithFacebook() async {
    final result = await FacebookAuth.instance.login();
    final status = result.status;
    if (status == LoginStatus.success) {
      final accessToken = result.accessToken;

      // Get the token string directly from the accessToken
      final tokenString = accessToken?.tokenString ?? '';
      final user = await _provideFirebaseUser(accessToken: tokenString);
      return user;
    } else if (status == LoginStatus.cancelled ||
        status == LoginStatus.failed) {
      throw Exception(result.message.toString());
    } else {
      throw Exception('Network Error');
    }
  }

  //utility functions

  Future<User?> _provideFirebaseUser({required String accessToken}) async {
    final OAuthCredential oAuthCredential =
        FacebookAuthProvider.credential(accessToken);

    final userCredential =
        await firebaseAuthInstance.signInWithCredential(oAuthCredential);

    final user = userCredential.user;
    return user;
  }
}
