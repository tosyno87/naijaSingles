import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../common/constants/constants.dart';
import '../../../../common/data/repo/phone_auth_repo.dart';

part 'phone_auth_event.dart';
part 'phone_auth_state.dart';

class PhoneAuthBloc extends Bloc<PhoneAuthEvent, PhoneAuthState> {
  PhoneAuthBloc({required this.phoneAuthRepository})
      : super(PhoneAuthInitial()) {
    // When user clicks on send otp labelLarge then this event will be fired
    on<SendOtpToPhoneEvent>(_onSendOtp);
    on<OnPhoneNumberupdateEvent>(_updatenumber);

    // After receiving the otp, When user clicks on verify otp labelLarge then this event will be fired
    on<VerifySentOtpEvent>(_onVerifyOtp);

    // When the firebase sends the code to the user's phone, this event will be fired
    on<OnPhoneOtpSent>(
      (event, emit) =>
          emit(PhoneAuthCodeSentSuccess(verificationId: event.verificationId)),
    );

    // When any error occurs while sending otp to the user's phone, this event will be fired
    on<OnPhoneAuthErrorEvent>(
      (event, emit) => emit(PhoneAuthError(error: event.error)),
    );

    // When the otp verification is successful, this event will be fired
    on<OnPhoneAuthVerificationCompleteEvent>(_loginWithCredential);

    // For development testing with Firebase test phone numbers
    on<UseTestPhoneAuthEvent>(_onUseTestPhoneAuth);
  }
  final PhoneAuthRepository phoneAuthRepository;
  final auth = firebaseAuthInstance;
  FutureOr<void> _updatenumber(
    OnPhoneNumberupdateEvent event,
    Emitter<PhoneAuthState> emit,
  ) async {
    emit(PhoneAuthLoading());
    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: event.verificationId,
        smsCode: event.token.toString(),
      );
      await phoneAuthRepository.updatePhone(
        phoneNumber: event.phoneNumber,
        verificationCompleted: credential,
      );
      final User? user = firebaseAuthInstance.currentUser;

      if (user != null) {
        await firebaseFireStoreInstance
            .collection('users')
            .doc(user.uid)
            .update({'phoneNumber': event.phoneNumber});
        // add(OnPhoneAuthVerificationCompleteEvent(credential: credential));

        emit(PhoneupdateSuccess(verificationId: event.verificationId));
      } else {
        emit(const PhoneAuthError(error: 'User is null'));
      }
    } catch (e) {
      emit(PhoneAuthError(error: e.toString()));
    }
  }

  FutureOr<void> _onSendOtp(
    SendOtpToPhoneEvent event,
    Emitter<PhoneAuthState> emit,
  ) async {
    log('');
    log('🎯🎯🎯 EVENT RECEIVED IN BLOC! 🎯🎯🎯');
    log('Event: SendOtpToPhoneEvent');
    log('Phone: ${event.phoneNumber}');
    log('');

    emit(PhoneAuthLoading());
    try {
      // Normalize phone number: remove spaces, dashes, and parentheses
      // Firebase test phone numbers must match exactly (with country code, no spaces)
      final normalizedPhone = event.phoneNumber
          .replaceAll(' ', '')
          .replaceAll('-', '')
          .replaceAll('(', '')
          .replaceAll(')', '')
          .trim();

      log('');
      log('═══════════════════════════════════════════════════════');
      log('🔥 FIREBASE PHONE AUTH CALLED');
      log('═══════════════════════════════════════════════════════');
      log('Phone Number Received: ${event.phoneNumber}');
      log('Normalized Phone: $normalizedPhone');
      log('');
      log('✅ Make sure this EXACT number is in Firebase Console:');
      log('   "$normalizedPhone"');
      log('');
      log('⚠️  Firebase Console may show formatted numbers like:');
      log('   "+234 800 000 0000" or "+234-800-000-0000"');
      log('   But internally it stores: "$normalizedPhone"');
      log('   Your app MUST send: "$normalizedPhone"');
      log('═══════════════════════════════════════════════════════');
      log('');

      // For iOS, we need to handle the verification differently
      if (Platform.isIOS) {
        // First, get a reCAPTCHA verification ID
        await phoneAuthRepository.verifyPhone(
          phoneNumber: normalizedPhone,
          verificationCompleted: (PhoneAuthCredential credential) async {
            log('✅ Phone verification completed automatically');
            add(OnPhoneAuthVerificationCompleteEvent(credential: credential));
          },
          codeSent: (String verificationId, int? resendToken) {
            log('📨 Verification code sent. Verification ID: $verificationId');
            add(
              OnPhoneOtpSent(
                verificationId: verificationId,
                token: resendToken,
                phoneNumber: normalizedPhone,
              ),
            );
          },
          verificationFailed: (FirebaseAuthException e) {
            log('❌ Phone verification failed: ${e.code} - ${e.message}');
            log('💡 Error code: ${e.code}');
            if (e.code == 'invalid-phone-number') {
              log('⚠️ INVALID PHONE NUMBER FORMAT');
              log('   Expected format: +1234567890 (with + and country code, no spaces)');
              log('   Your number: $normalizedPhone');
              log('   Make sure it matches EXACTLY in Firebase Console test numbers');
            } else if (e.code == 'missing-verification-code') {
              log('⚠️ Missing verification code - test number might not be configured');
            } else if (e.code == 'quota-exceeded') {
              log('⚠️ Quota exceeded - too many requests');
            }
            add(OnPhoneAuthErrorEvent(
                error: '${e.code}: ${e.message ?? e.toString()}',),);
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            log('⏱️ Code auto-retrieval timeout: $verificationId');
          },
        );
      } else {
        // Android flow remains the same
        await phoneAuthRepository.verifyPhone(
          phoneNumber: normalizedPhone,
          verificationCompleted: (PhoneAuthCredential credential) async {
            log('✅ Phone verification completed automatically');
            add(OnPhoneAuthVerificationCompleteEvent(credential: credential));
          },
          codeSent: (String verificationId, int? resendToken) {
            log('📨 Verification code sent. Verification ID: $verificationId');
            add(
              OnPhoneOtpSent(
                verificationId: verificationId,
                token: resendToken,
                phoneNumber: normalizedPhone,
              ),
            );
          },
          verificationFailed: (FirebaseAuthException e) {
            log('❌ Phone verification failed: ${e.code} - ${e.message}');
            add(OnPhoneAuthErrorEvent(
                error: '${e.code}: ${e.message ?? e.toString()}',),);
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            log('⏱️ Code auto-retrieval timeout: $verificationId');
          },
        );
      }
    } catch (e) {
      emit(PhoneAuthError(error: e.toString()));
    }
  }

  FutureOr<void> _onVerifyOtp(
    VerifySentOtpEvent event,
    Emitter<PhoneAuthState> emit,
  ) async {
    try {
      emit(PhoneAuthLoading());
      // After receiving the otp, we will verify the otp and then will create a credential from the otp and verificationId and then will send it to the [OnPhoneAuthVerificationCompleteEvent] event to be handled by the bloc and then will emit the [PhoneAuthVerified] state after successful login
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: event.verificationId,
        smsCode: event.otpCode,
      );
      add(OnPhoneAuthVerificationCompleteEvent(credential: credential));
    } catch (e) {
      emit(PhoneAuthError(error: e.toString()));
    }
  }

  FutureOr<void> _loginWithCredential(
    OnPhoneAuthVerificationCompleteEvent event,
    Emitter<PhoneAuthState> emit,
  ) async {
    // After receiving the credential from the event, we will login with the credential and then will emit the [PhoneAuthVerified] state after successful login
    try {
      final user = await auth.signInWithCredential(event.credential);
      if (user.user != null) {
        emit(PhoneAuthVerified(user: user.user));
      }
    } on FirebaseAuthException catch (e) {
      emit(PhoneAuthError(error: e.code));
    } catch (e) {
      emit(PhoneAuthError(error: e.toString()));
    }
  }

  // Handler for development testing with Firebase test phone numbers
  FutureOr<void> _onUseTestPhoneAuth(
    UseTestPhoneAuthEvent event,
    Emitter<PhoneAuthState> emit,
  ) async {
    try {
      emit(PhoneAuthLoading());
      // Test phone authentication is disabled in production
      emit(
        const PhoneAuthError(
          error: 'Test authentication is not available in production',
        ),
      );
    } catch (e) {
      emit(PhoneAuthError(error: e.toString()));
    }
  }
}
