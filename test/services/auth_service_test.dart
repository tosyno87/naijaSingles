import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naijasingles/services/auth_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUserCredential extends Mock implements UserCredential {}

class MockPhoneAuthCredential extends Mock implements PhoneAuthCredential {}

void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late AuthService authService;

  setUpAll(() {
    // Register fallback values for any() matchers
    registerFallbackValue(const Duration(seconds: 60));
    registerFallbackValue(MockPhoneAuthCredential());
  });

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    authService = AuthService(firebaseAuth: mockFirebaseAuth);
  });

  group('signInWithEmail', () {
    test('returns UserCredential on success', () async {
      final mockCredential = MockUserCredential();

      when(
        () => mockFirebaseAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => mockCredential);

      final result = await authService.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, equals(mockCredential));
    });

    test('throws FirebaseAuthException on invalid credentials', () async {
      when(
        () => mockFirebaseAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        FirebaseAuthException(
          code: 'wrong-password',
          message: 'The password is invalid',
        ),
      );

      expect(
        () => authService.signInWithEmail(
          email: 'test@example.com',
          password: 'wrongpassword',
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
    });

    test('trims email input', () async {
      final mockCredential = MockUserCredential();

      when(
        () => mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => mockCredential);

      await authService.signInWithEmail(
        email: '  test@example.com  ',
        password: 'password123',
      );

      verify(
        () => mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).called(1);
    });
  });

  group('verifyPhoneNumber', () {
    test('forwards all parameters to Firebase', () async {
      void verificationCompleted(PhoneAuthCredential credential) {}
      void verificationFailed(FirebaseAuthException e) {}
      void codeSent(String verificationId, int? resendToken) {}
      void codeAutoRetrievalTimeout(String verificationId) {}

      when(
        () => mockFirebaseAuth.verifyPhoneNumber(
          phoneNumber: any(named: 'phoneNumber'),
          verificationCompleted: any(named: 'verificationCompleted'),
          verificationFailed: any(named: 'verificationFailed'),
          codeSent: any(named: 'codeSent'),
          codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
          timeout: any(named: 'timeout'),
        ),
      ).thenAnswer((_) async {});

      await authService.verifyPhoneNumber(
        phone: '+12179044453',
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      );

      verify(
        () => mockFirebaseAuth.verifyPhoneNumber(
          phoneNumber: '+12179044453',
          verificationCompleted: verificationCompleted,
          verificationFailed: verificationFailed,
          codeSent: codeSent,
          codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
          timeout: any(named: 'timeout'),
        ),
      ).called(1);
    });
  });

  group('signInWithCredential', () {
    test('creates credential and signs in', () async {
      final mockCredential = MockUserCredential();

      when(() => mockFirebaseAuth.signInWithCredential(any()))
          .thenAnswer((_) async => mockCredential);

      final result = await authService.signInWithCredential(
        verificationId: 'test-verification-id',
        smsCode: '123456',
      );

      expect(result, equals(mockCredential));

      // Verify that signInWithCredential was called with any credential
      verify(() => mockFirebaseAuth.signInWithCredential(any())).called(1);
    });

    test('throws exception when credential is invalid', () async {
      when(() => mockFirebaseAuth.signInWithCredential(any())).thenThrow(
        FirebaseAuthException(
          code: 'invalid-verification-code',
          message: 'The verification code is invalid',
        ),
      );

      expect(
        () => authService.signInWithCredential(
          verificationId: 'test-verification-id',
          smsCode: 'invalid-code',
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
  });
}
