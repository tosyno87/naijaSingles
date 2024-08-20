// ignore: depend_on_referenced_packages
import 'dart:async';
import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../common/constants/constants.dart';
import '../../../../common/data/repo/phone_auth_repo.dart';

part 'authstatus_event.dart';
part 'authstatus_state.dart';

class AuthstatusBloc extends Bloc<AuthstatusEvent, AuthstatusState> {
  final PhoneAuthRepository phoneAuthRepository;
  final auth = firebaseAuthInstance;
  AuthstatusBloc({required this.phoneAuthRepository})
      : super(AuthIntialState()) {
    //when user already logged in
    on<AuthRequestEvent>(_isLoggedin);
    //when user logout
    on<LogoutEvent>(_logout);
  }

//for logout
  Future<void> _logout(LogoutEvent event, Emitter<AuthstatusState> emit) async {
    try {
      emit(AuthLoadingState());
      await phoneAuthRepository.signOut();
      log("user singout sucessfully");
      emit(UnauthenticatedState());
    } catch (e) {
      emit(AuthFailed(message: e.toString()));
    }
  }

//for login status of user
  FutureOr<void> _isLoggedin(
      AuthRequestEvent event, Emitter<AuthstatusState> emit) async {
    try {
      emit(AuthLoadingState());
      var issingedin = await phoneAuthRepository.isSignedIn();
      if (issingedin) {
        var user = auth.currentUser;
        if (user != null) {
          log("user singin sucessfully");
          log(auth.currentUser!.phoneNumber.toString());

          emit(AuthenticatedState(user: user));
        } else {
          emit(UnauthenticatedState());
        }
      } else {
        emit(const AuthFailed(message: "Login failed"));
      }
    } catch (e) {
      emit(AuthFailed(message: e.toString()));
    }
  }
}
