import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naijasingles/common/data/repo/phone_auth_repo.dart';
import 'package:naijasingles/features/auth/auth_status/bloc/authstatus_bloc.dart';

class MockPhoneAuthRepository extends Mock implements PhoneAuthRepository {}

class MockFirebaseUser extends Mock implements User {}

void main() {
  group('AuthstatusBloc', () {
    late MockPhoneAuthRepository repo;
    late MockFirebaseUser user;

    setUp(() {
      repo = MockPhoneAuthRepository();
      user = MockFirebaseUser();
    });

    blocTest<AuthstatusBloc, AuthstatusState>(
      'emits AuthenticatedState when Firebase has a persisted user session',
      build: () {
        when(() => repo.isSignedIn()).thenAnswer((_) async => true);
        when(() => repo.getCurrentUser()).thenAnswer((_) async => user);
        when(() => user.phoneNumber).thenReturn('+15555550100');
        when(() => user.uid).thenReturn('user-1');
        when(() => user.getIdToken(true)).thenAnswer((_) async => 'token');
        return AuthstatusBloc(phoneAuthRepository: repo);
      },
      act: (bloc) => bloc.add(AuthRequestEvent()),
      expect: () => [
        AuthLoadingState(),
        AuthenticatedState(user: user),
      ],
    );

    blocTest<AuthstatusBloc, AuthstatusState>(
      'emits UnauthenticatedState when Firebase has no persisted user session',
      build: () {
        when(() => repo.isSignedIn()).thenAnswer((_) async => false);
        return AuthstatusBloc(phoneAuthRepository: repo);
      },
      act: (bloc) => bloc.add(AuthRequestEvent()),
      expect: () => [
        AuthLoadingState(),
        UnauthenticatedState(),
      ],
    );
  });
}
