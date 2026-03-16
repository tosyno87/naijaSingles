import 'dart:developer';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../common/data/repo/phone_auth_repo.dart';
import '../../../../../../common/utils/profile_completion_guard.dart';
import '../../../../../../models/user_model.dart';
import '../../../../../../services/secure_storage_service.dart';

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
            } on Object catch (e) {
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

              // Only consider user registered if profile is sufficiently complete
              if (ProfileCompletionGuard.isUserComplete(usr)) {
                log('✅ User already registered with complete profile: ${usr.name}');
                emit(AlreadyRegistered(user: usr));
              } else {
                // User document exists but profile is incomplete - ensure minimal doc then treat as new registration
                log('⚠️ User document exists but profile is incomplete - treating as new registration');
                try {
                  await phoneAuthRepository.ensureMinimalUserDocument(user);
                  emit(NewRegistration(token: event.token, user: user));
                } on Object catch (e) {
                  log('❌ Failed to ensure minimal user doc: $e');
                  emit(const RegistrationFailed(
                    message: 'Could not set up your account. Please try again.',
                  ),);
                }
              }
            } on Object catch (getUserError) {
              log('❌ Error getting user data: $getUserError');
              log('❌ Error type: ${getUserError.runtimeType}');

              // If userDetails returned true but we can't get user data,
              // there might be a data inconsistency
              // In this case, treat as new registration to allow onboarding
              log('⚠️ User document exists but cannot retrieve data - treating as new registration');
              try {
                await phoneAuthRepository.ensureMinimalUserDocument(user);
                emit(NewRegistration(token: event.token, user: user));
              } on Object catch (e) {
                log('❌ Failed to ensure minimal user doc: $e');
                emit(const RegistrationFailed(
                  message: 'Could not set up your account. Please try again.',
                ),);
              }
            }
          } else {
            log('📝 User not found in database - new registration');
            if (user.displayName != null || user.phoneNumber != null) {
              // Prevent duplicate account: block if this phone is already used by another account
              final phone = user.phoneNumber?.trim();
              if (phone != null && phone.isNotEmpty) {
                try {
                  final existingUserId =
                      await phoneAuthRepository.findUserIdByPhoneNumber(phone);
                  if (existingUserId != null && existingUserId != user.uid) {
                    log('❌ Phone number already registered to another account: $existingUserId');
                    await phoneAuthRepository.signOut();
                    emit(
                      const RegistrationFailed(
                        message:
                            'This phone number is already registered. Please sign in instead.',
                      ),
                    );
                    return;
                  }
                } on FirebaseException catch (e) {
                  if (e.code == 'permission-denied') {
                    // Permission-denied on a collection query means a matching
                    // document exists but is unreadable (e.g. paused/incognito).
                    // Firebase Auth guarantees unique phone-to-UID mapping, so
                    // if this UID has no document, it's safe to proceed.
                    log('⚠️ Phone dedup query denied by rules — proceeding (Firebase Auth is authoritative)');
                  } else {
                    log('❌ Firestore error during phone dedup: ${e.code}');
                    emit(
                      const RegistrationFailed(
                        message: 'Unable to verify phone. Please try again.',
                      ),
                    );
                    return;
                  }
                } on SocketException {
                  log('❌ Network error during phone dedup — blocking registration');
                  emit(
                    const RegistrationFailed(
                      message: 'No internet connection. Please try again.',
                    ),
                  );
                  return;
                } on Object catch (e) {
                  log('❌ Unexpected error during phone dedup: $e');
                  emit(
                    const RegistrationFailed(
                      message: 'Unable to verify phone. Please try again.',
                    ),
                  );
                  return;
                }
              }
              try {
                await phoneAuthRepository.ensureMinimalUserDocument(user);
                emit(NewRegistration(token: event.token, user: user));
              } on Object catch (e) {
                log('❌ Failed to ensure minimal user doc: $e');
                emit(const RegistrationFailed(
                  message: 'Could not set up your account. Please try again.',
                ),);
              }
            } else {
              emit(
                const RegistrationFailed(
                  message: 'Error: No user identifier found',
                ),
              );
            }
          }
        } else {
          log('❌ User has no displayName or phoneNumber');
          emit(
            const RegistrationFailed(
              message: 'Error: No user identifier found',
            ),
          );
        }
      } on SocketException {
        log('❌ Network error during registration check');
        emit(const RegistrationFailed(message: 'No internet'));
      } on Object catch (e) {
        log('❌ Unexpected error in CheckRegistration: $e');
        emit(RegistrationFailed(message: 'Error checking registration: $e'));
      }
    });
  }
  PhoneAuthRepository phoneAuthRepository;
}
