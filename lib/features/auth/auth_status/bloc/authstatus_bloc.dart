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

      // Check if user is signed in
      try {
        var issingedin = await phoneAuthRepository.isSignedIn();
        log("Is signed in check: $issingedin");

        if (issingedin) {
          var user = auth.currentUser;
          if (user != null) {
            log("User signed in successfully: ${user.uid}");
            log("Phone number: ${user.phoneNumber ?? 'No phone number'}");
            log("Email: ${user.email ?? 'No email'}");

            // Verify token can be retrieved
            try {
              final token = await user.getIdToken(true);
              log("Token retrieved successfully: ${token != null}");
              emit(AuthenticatedState(user: user));
            } catch (tokenError) {
              log("Error retrieving token: $tokenError");
              // Sign out and treat as unauthenticated if token retrieval fails
              await phoneAuthRepository.signOut();
              emit(UnauthenticatedState());
            }
          } else {
            log("Current user is null despite isSignedIn returning true");
            emit(UnauthenticatedState());
          }
        } else {
          log("User is not signed in");
          emit(UnauthenticatedState());
        }
      } catch (authError) {
        log("Error checking authentication status: $authError");
        emit(AuthFailed(message: "Authentication check failed: $authError"));
      }
    } catch (e) {
      log("Unexpected error in _isLoggedin: $e");
      emit(AuthFailed(message: e.toString()));
    }
  }
}
