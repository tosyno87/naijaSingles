import 'dart:developer';
import 'dart:io';

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
      log('Google sign-in successful: ${user?.displayName}');
      emit(GoogleLoginSuccess(user: user));
    } on SocketException {
      log('Google sign-in failed: No Internet Connection');
      emit(const GoogleLoginFailed(message: 'No Internet Connection'));
    } catch (e) {
      log('Google sign-in failed: ${e.toString()}');
      final errorMessage = e.toString().contains('Exception:')
          ? e.toString().split('Exception:').last.trim()
          : e.toString();
      emit(GoogleLoginFailed(message: errorMessage));
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
