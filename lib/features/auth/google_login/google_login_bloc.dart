import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/data/repo/googlelogin_repo.dart';
import './google_login_events.dart';
import './google_login_states.dart';

class GoogleLoginBloc extends Bloc<GoogleLoginEvents, GoogleLoginStates> {
  GoogleLoginBloc({GoogleLoginRepository? repository})
      : _repository = repository ?? GoogleLoginRepositoryImpl(),
        super(GoogleLoginInitial()) {
    on<GoogleLoginRequested>(_onGoogleLoginRequested);
    on<GoogleLoginCancelled>(_onGoogleLoginCancelled);
  }
  final GoogleLoginRepository _repository;

  Future<void> _onGoogleLoginRequested(
    GoogleLoginRequested event,
    Emitter<GoogleLoginStates> emit,
  ) async {
    log('GoogleLoginRequested()');
    emit(GoogleLoginLoading());
    log('Transition to GoogleLoginLoading()');

    try {
      log('Attempting to sign in with Google...');
      final user = await _repository.signInWithGoogle();
      if (user == null) {
        log('Google sign-in canceled by user');
        emit(GoogleLoginInitial());
        return;
      }
      log('Google sign-in successful: ${user.displayName}');
      try {
        await _repository.ensureUserDocument(user);
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          // Do not block authenticated users from entering the app when
          // profile reconciliation is denied by rules or transient auth races.
          log(
            'Google profile reconciliation denied by Firestore rules; '
            'continuing with authenticated session',
          );
        } else {
          rethrow;
        }
      }
      emit(GoogleLoginSuccess(user: user));
    } on SocketException {
      log('Google sign-in failed: No Internet Connection');
      emit(const GoogleLoginFailed(message: 'No Internet Connection'));
    } on FirebaseAuthException catch (e) {
      log('Google sign-in failed: ${e.code} ${e.message}');
      final message = e.code == 'account-exists-with-different-credential'
          ? 'An account already exists with the same email but different sign-in method.'
          : (e.message ?? 'Sign in failed. Please try again.');
      emit(GoogleLoginFailed(message: message));
    } on Object catch (e) {
      final msg = e.toString();
      if (msg.contains('canceled by user') || msg.contains('was canceled')) {
        log('Google sign-in canceled by user');
        emit(GoogleLoginInitial());
        return;
      }
      log('Google sign-in failed: $msg');
      // User-friendly message for credential/reconciliation/network errors
      emit(
        const GoogleLoginFailed(
          message: 'Could not complete sign in. Please try again.',
        ),
      );
    }
  }

  void _onGoogleLoginCancelled(
    GoogleLoginCancelled event,
    Emitter<GoogleLoginStates> emit,
  ) {
    log('GoogleLoginCancelled()');
    emit(GoogleLoginInitial());
  }
}
