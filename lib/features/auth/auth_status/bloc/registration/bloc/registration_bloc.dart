import 'dart:developer';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookup4u2/common/data/repo/phone_auth_repo.dart';

import '../../../../../../models/user_model.dart';

part 'registration_event.dart';
part 'registration_state.dart';

class RegistrationBloc extends Bloc<RegistrationEvents, RegistrationStates> {
  PhoneAuthRepository phoneAuthRepository;
  RegistrationBloc({required this.phoneAuthRepository})
      : super(RegistrationInitial()) {
    on<RegistrationRequest>((event, emit) async {
      emit(RegistrationLoading());
      try {
        User? user = await phoneAuthRepository.getCurrentUser();

        if (user != null) {
          var registeredUser =
              await phoneAuthRepository.registration(userData: event.userdata);

          emit(RegistrationSuccess(user: registeredUser));
        }
      } on SocketException {
        emit(const RegistrationFailed(message: "No internet"));
      }
    });
    on<CheckRegistration>((event, emit) async {
      emit(RegistrationLoading());
      try {
        var user = await phoneAuthRepository.getCurrentUser();

        if (user!.displayName != null || user.phoneNumber != null) {
          var isRegistered = await phoneAuthRepository.userDetails(user.uid);
          log(isRegistered.toString());
          if (isRegistered) {
            var usr = await phoneAuthRepository.getRegisterUser();
            if (usr.name != null) {
              log("coming in already state $usr");
              emit(AlreadyRegistered(user: usr));
            } else {
              log("coming in no data $usr");
              emit(NewRegistration(token: event.token, user: user));
            }
          } else {
            if (user.displayName != null || user.phoneNumber != null) {
              log("from here");
              emit(NewRegistration(token: event.token, user: user));
            } else {
              // ignore: prefer_const_constructors
              emit(RegistrationFailed(message: "Error"));
            }
          }
        }
      } on SocketException {
        emit(const RegistrationFailed(message: "No internet"));
      }
    });
  }
}
