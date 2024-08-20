import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/data/repo/facebooklogin_repo.dart';
import './facebook_login_events.dart';
import './facebook_login_states.dart';

class FacebookLoginBloc extends Bloc<FacebookLoginEvents, FacebookLoginStates> {
  FacebookLoginBloc() : super(FacebookLoginInitial()) {
    on<FacebookLoginEvents>((event, emit) async {
      try {
        final result = await FaceBookLoginRepositoryImpl().signInWithFacebook();

        emit(FacebookLoginSuccess(user: result));
      } on SocketException {
        emit(const FacebookLoginFailed(message: 'No Internet Connection'));
      } catch (e) {
        emit(FacebookLoginFailed(message: e.toString()));
      }
    });
  }
}
