import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:naijasingles/common/data/repo/googlelogin_repo.dart';
import 'package:naijasingles/features/auth/google_login/google_login_bloc.dart';
import 'package:naijasingles/features/auth/google_login/google_login_events.dart';
import 'package:naijasingles/features/auth/google_login/google_login_states.dart';

class MockGoogleLoginRepository extends Mock implements GoogleLoginRepository {}

void main() {
  late MockGoogleLoginRepository mockRepo;
  late GoogleLoginBloc bloc;

  setUpAll(() {
    registerFallbackValue(MockUser(uid: 'fallback-uid'));
  });

  setUp(() {
    mockRepo = MockGoogleLoginRepository();
  });

  tearDown(() {
    bloc.close();
  });

  group('GoogleLoginBloc', () {
    test('initial state is GoogleLoginInitial', () {
      bloc = GoogleLoginBloc(repository: mockRepo);
      expect(bloc.state, isA<GoogleLoginInitial>());
    });

    blocTest<GoogleLoginBloc, GoogleLoginStates>(
      'emits [GoogleLoginLoading, GoogleLoginSuccess] when sign-in and reconciliation succeed',
      build: () {
        when(() => mockRepo.signInWithGoogle()).thenAnswer(
          (_) async => MockUser(uid: 'uid-1', displayName: 'Test'),
        );
        when(() => mockRepo.ensureUserDocument(any())).thenAnswer((_) async {});
        return GoogleLoginBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const GoogleLoginRequested()),
      expect: () => [
        GoogleLoginLoading(),
        isA<GoogleLoginSuccess>(),
      ],
      verify: (_) {
        verify(() => mockRepo.signInWithGoogle()).called(1);
        verify(() => mockRepo.ensureUserDocument(any())).called(1);
      },
    );

    blocTest<GoogleLoginBloc, GoogleLoginStates>(
      'emits [GoogleLoginLoading, GoogleLoginInitial] when user cancels (signIn returns null)',
      build: () {
        when(() => mockRepo.signInWithGoogle()).thenAnswer((_) async => null);
        return GoogleLoginBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const GoogleLoginRequested()),
      expect: () => [
        GoogleLoginLoading(),
        GoogleLoginInitial(),
      ],
      verify: (_) {
        verify(() => mockRepo.signInWithGoogle()).called(1);
        verifyNever(() => mockRepo.ensureUserDocument(any()));
      },
    );

    blocTest<GoogleLoginBloc, GoogleLoginStates>(
      'emits [GoogleLoginLoading, GoogleLoginFailed] when signIn throws SocketException',
      build: () {
        when(() => mockRepo.signInWithGoogle())
            .thenThrow(SocketException('Network error'));
        return GoogleLoginBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const GoogleLoginRequested()),
      expect: () => [
        GoogleLoginLoading(),
        isA<GoogleLoginFailed>(),
      ],
      verify: (_) {
        verify(() => mockRepo.signInWithGoogle()).called(1);
        verifyNever(() => mockRepo.ensureUserDocument(any()));
      },
    );

    blocTest<GoogleLoginBloc, GoogleLoginStates>(
      'emits [GoogleLoginLoading, GoogleLoginFailed] with recovery message when signIn throws account-exists-with-different-credential',
      build: () {
        when(() => mockRepo.signInWithGoogle()).thenThrow(
          FirebaseAuthException(
            code: 'account-exists-with-different-credential',
            message: 'Email already in use',
          ),
        );
        return GoogleLoginBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const GoogleLoginRequested()),
      expect: () => [
        GoogleLoginLoading(),
        const GoogleLoginFailed(
          message:
              'An account already exists with the same email but different sign-in method.',
        ),
      ],
      verify: (_) {
        verify(() => mockRepo.signInWithGoogle()).called(1);
        verifyNever(() => mockRepo.ensureUserDocument(any()));
      },
    );

    blocTest<GoogleLoginBloc, GoogleLoginStates>(
      'emits [GoogleLoginLoading, GoogleLoginSuccess] when ensureUserDocument is permission-denied',
      build: () {
        when(() => mockRepo.signInWithGoogle()).thenAnswer(
          (_) async => MockUser(uid: 'uid-1', displayName: 'Test'),
        );
        when(() => mockRepo.ensureUserDocument(any())).thenThrow(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
            message: 'The caller does not have permission',
          ),
        );
        return GoogleLoginBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const GoogleLoginRequested()),
      expect: () => [
        GoogleLoginLoading(),
        isA<GoogleLoginSuccess>(),
      ],
      verify: (_) {
        verify(() => mockRepo.signInWithGoogle()).called(1);
        verify(() => mockRepo.ensureUserDocument(any())).called(1);
      },
    );

    blocTest<GoogleLoginBloc, GoogleLoginStates>(
      'emits [GoogleLoginLoading, GoogleLoginFailed] when ensureUserDocument throws after successful sign-in',
      build: () {
        when(() => mockRepo.signInWithGoogle()).thenAnswer(
          (_) async => MockUser(uid: 'uid-1'),
        );
        when(() => mockRepo.ensureUserDocument(any()))
            .thenThrow(Exception('Firestore unavailable'));
        return GoogleLoginBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const GoogleLoginRequested()),
      expect: () => [
        GoogleLoginLoading(),
        const GoogleLoginFailed(
          message: 'Could not complete sign in. Please try again.',
        ),
      ],
      verify: (_) {
        verify(() => mockRepo.signInWithGoogle()).called(1);
        verify(() => mockRepo.ensureUserDocument(any())).called(1);
      },
    );

    blocTest<GoogleLoginBloc, GoogleLoginStates>(
      'GoogleLoginCancelled emits GoogleLoginInitial',
      build: () => GoogleLoginBloc(repository: mockRepo),
      act: (bloc) => bloc.add(GoogleLoginCancelled()),
      expect: () => [GoogleLoginInitial()],
    );
  });
}
