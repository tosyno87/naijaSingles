import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naijasingles/common/data/repo/phone_auth_repo.dart';
import 'package:naijasingles/features/auth/auth_status/bloc/registration/bloc/registration_bloc.dart';
import 'package:naijasingles/models/user_model.dart';

class MockPhoneAuthRepository extends Mock implements PhoneAuthRepository {}

class MockFirebaseUser extends Mock implements User {}

void main() {
  group('RegistrationBloc', () {
    late MockPhoneAuthRepository repo;
    late RegistrationBloc bloc;

    setUp(() {
      repo = MockPhoneAuthRepository();
      bloc = RegistrationBloc(phoneAuthRepository: repo);
    });

    final userModel = UserModel(id: '1', name: 'test', userGender: 'Male');
    final firebaseUser = MockFirebaseUser();

    blocTest<RegistrationBloc, RegistrationStates>(
      'emits [Loading, Success] on RegistrationRequest',
      build: () {
        when(() => repo.getCurrentUser()).thenAnswer((_) async => firebaseUser);
        when(() => repo.registration(userData: any(named: 'userData')))
            .thenAnswer((_) async => userModel);
        return bloc;
      },
      act: (bloc) => bloc.add(const RegistrationRequest(userdata: {})),
      expect: () => [
        RegistrationLoading(),
        RegistrationSuccess(user: userModel),
      ],
    );

    blocTest<RegistrationBloc, RegistrationStates>(
      'emits [Loading, AlreadyRegistered] when user already registered',
      build: () {
        when(() => firebaseUser.uid).thenReturn('test-user-id');
        when(() => repo.getCurrentUser()).thenAnswer((_) async => firebaseUser);
        when(() => firebaseUser.displayName).thenReturn('name');
        when(() => repo.userDetails(any())).thenAnswer((_) async => true);
        when(() => repo.getRegisterUser()).thenAnswer((_) async => userModel);
        return bloc;
      },
      act: (bloc) => bloc.add(const CheckRegistration(token: 't')),
      expect: () => [
        RegistrationLoading(),
        AlreadyRegistered(user: userModel),
      ],
    );

    blocTest<RegistrationBloc, RegistrationStates>(
      'emits [Loading, NewRegistration] when no data found (signup)',
      build: () {
        when(() => firebaseUser.uid).thenReturn('test-user-id');
        when(() => repo.getCurrentUser()).thenAnswer((_) async => firebaseUser);
        when(() => firebaseUser.displayName).thenReturn('name');
        when(() => repo.userDetails(any())).thenAnswer((_) async => false);
        when(() => repo.ensureMinimalUserDocument(firebaseUser))
            .thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) => bloc.add(const CheckRegistration(token: 't', isLogin: false)),
      expect: () => [
        RegistrationLoading(),
        NewRegistration(token: 't', user: firebaseUser),
      ],
    );

    blocTest<RegistrationBloc, RegistrationStates>(
      'emits [Loading, NotRegistered] when isLogin and user not registered; does not call ensureMinimalUserDocument; calls signOut',
      build: () {
        when(() => firebaseUser.uid).thenReturn('test-user-id');
        when(() => firebaseUser.displayName).thenReturn('name');
        when(() => firebaseUser.phoneNumber).thenReturn('+2348012345678');
        when(() => repo.getCurrentUser()).thenAnswer((_) async => firebaseUser);
        when(() => repo.userDetails(any())).thenAnswer((_) async => false);
        when(() => repo.findUserIdByPhoneNumber(any())).thenAnswer((_) async => null);
        when(() => repo.signOut()).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) => bloc.add(const CheckRegistration(token: 't', isLogin: true)),
      expect: () => [
        RegistrationLoading(),
        const NotRegistered(),
      ],
      verify: (_) {
        verify(() => repo.signOut()).called(1);
        verifyNever(() => repo.ensureMinimalUserDocument(firebaseUser));
      },
    );

    blocTest<RegistrationBloc, RegistrationStates>(
      'emits [Loading, RegistrationFailed] and does not emit NewRegistration when phone already used by another account',
      build: () {
        when(() => firebaseUser.uid).thenReturn('current-uid');
        when(() => firebaseUser.phoneNumber).thenReturn('+12179044453');
        when(() => firebaseUser.displayName).thenReturn('name');
        when(() => repo.getCurrentUser()).thenAnswer((_) async => firebaseUser);
        when(() => repo.userDetails(any())).thenAnswer((_) async => false);
        when(() => repo.findUserIdByPhoneNumber(any()))
            .thenAnswer((_) async => 'other-uid');
        when(() => repo.signOut()).thenAnswer((_) async => {});
        return bloc;
      },
      act: (bloc) => bloc.add(const CheckRegistration(token: 't')),
      expect: () => [
        RegistrationLoading(),
        const RegistrationFailed(
          message:
              'This phone number is already registered. Please sign in instead.',
        ),
      ],
    );

    blocTest<RegistrationBloc, RegistrationStates>(
      'calls signOut when phone already used by another account',
      build: () {
        when(() => firebaseUser.uid).thenReturn('current-uid');
        when(() => firebaseUser.phoneNumber).thenReturn('+12179044453');
        when(() => firebaseUser.displayName).thenReturn('name');
        when(() => repo.getCurrentUser()).thenAnswer((_) async => firebaseUser);
        when(() => repo.userDetails(any())).thenAnswer((_) async => false);
        when(() => repo.findUserIdByPhoneNumber(any()))
            .thenAnswer((_) async => 'other-uid');
        when(() => repo.signOut()).thenAnswer((_) async => {});
        return bloc;
      },
      act: (bloc) => bloc.add(const CheckRegistration(token: 't')),
      verify: (_) {
        verify(() => repo.signOut()).called(1);
      },
    );

    blocTest<RegistrationBloc, RegistrationStates>(
      'fails closed: emits RegistrationFailed when findUserIdByPhoneNumber throws',
      build: () {
        when(() => firebaseUser.uid).thenReturn('current-uid');
        when(() => firebaseUser.phoneNumber).thenReturn('+12179044453');
        when(() => firebaseUser.displayName).thenReturn('name');
        when(() => repo.getCurrentUser()).thenAnswer((_) async => firebaseUser);
        when(() => repo.userDetails(any())).thenAnswer((_) async => false);
        when(() => repo.findUserIdByPhoneNumber(any()))
            .thenThrow(Exception('Firestore unavailable'));
        return bloc;
      },
      act: (bloc) => bloc.add(const CheckRegistration(token: 't')),
      expect: () => [
        RegistrationLoading(),
        const RegistrationFailed(
          message: 'Unable to verify phone. Please try again.',
        ),
      ],
    );
  });
}
