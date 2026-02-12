import 'dart:developer';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../common/data/repo/phone_auth_repo.dart';
import '../../../../../../services/secure_storage_service.dart';

import '../../../../../../models/user_model.dart';

part 'registration_event.dart';
part 'registration_state.dart';

class RegistrationBloc extends Bloc<RegistrationEvents, RegistrationStates> {
  RegistrationBloc({required this.phoneAuthRepository})
      : super(RegistrationInitial()) {
    on<RegistrationRequest>((event, emit) async {
      emit(RegistrationLoading());
      try {
        final User? user = await phoneAuthRepository.getCurrentUser();

        if (user != null) {
          final registeredUser =
              await phoneAuthRepository.registration(userData: event.userdata);

          emit(RegistrationSuccess(user: registeredUser));
        }
      } on SocketException {
        emit(const RegistrationFailed(message: 'No internet'));
      }
    });
    on<CheckRegistration>((event, emit) async {
      emit(RegistrationLoading());
      try {
        final user = await phoneAuthRepository.getCurrentUser();

        if (user!.displayName != null || user.phoneNumber != null) {
          // Store authentication token securely
          if (event.token.isNotEmpty) {
            try {
              final secureStorage = SecureStorageService();
              await secureStorage.storeAuthToken(event.token);
              await secureStorage.storeUserId(user.uid);
              log('✅ Token stored securely after phone verification');
            } catch (e) {
              log('⚠️ Error storing token securely: $e');
              // Continue even if secure storage fails
            }
          }

          log('🔍 Checking registration for user: ${user.uid}');
          final isRegistered = await phoneAuthRepository.userDetails(user.uid);
          log('📋 Registration check result: $isRegistered');

          if (isRegistered) {
            try {
              final usr = await phoneAuthRepository.getRegisterUser();
              log('👤 Retrieved user data: ${usr.name ?? "no name"}');

              // Only consider user registered if they have a name (completed onboarding)
              if (usr.name != null && usr.name!.isNotEmpty) {
                log('✅ User already registered with complete profile: ${usr.name}');
                emit(AlreadyRegistered(user: usr));
              } else {
                // User document exists but profile incomplete (no name) - treat as new registration
                // This ensures users complete onboarding even if document exists
                log('⚠️ User document exists but has no name - treating as new registration');
                log('⚠️ Redirecting to onboarding to complete profile');
                emit(NewRegistration(token: event.token, user: user));
              }
            } catch (getUserError) {
              log('❌ Error getting user data: $getUserError');
              log('❌ Error type: ${getUserError.runtimeType}');

              // If userDetails returned true but we can't get user data,
              // there might be a data inconsistency
              // In this case, treat as new registration to allow onboarding
              log('⚠️ User document exists but cannot retrieve data - treating as new registration');
              emit(NewRegistration(token: event.token, user: user));
            }
          } else {
            log('📝 User not found in database - new registration');
            if (user.displayName != null || user.phoneNumber != null) {
              // Prevent duplicate account: block if this phone is already used by another account
              final phone = user.phoneNumber?.trim();
              if (phone != null && phone.isNotEmpty) {
                final existingUserId = await phoneAuthRepository
                    .findUserIdByPhoneNumber(phone);
                if (existingUserId != null && existingUserId != user.uid) {
                  log('❌ Phone number already registered to another account: $existingUserId');
                  await phoneAuthRepository.signOut();
                  emit(const RegistrationFailed(
                    message:
                        'This phone number is already registered. Please sign in instead.',
                  ));
                  return;
                }
              }
              emit(NewRegistration(token: event.token, user: user));
            } else {
              emit(const RegistrationFailed(
                  message: 'Error: No user identifier found'));
            }
          }
        } else {
          log('❌ User has no displayName or phoneNumber');
          emit(const RegistrationFailed(
              message: 'Error: No user identifier found'));
        }
      } on SocketException {
        log('❌ Network error during registration check');
        emit(const RegistrationFailed(message: 'No internet'));
      } catch (e) {
        log('❌ Unexpected error in CheckRegistration: $e');
        emit(RegistrationFailed(message: 'Error checking registration: $e'));
      }
    });
  }
  PhoneAuthRepository phoneAuthRepository;
}
