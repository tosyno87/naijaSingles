import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naijasingles/common/constants/constants.dart';
import 'package:naijasingles/common/data/repo/phone_auth_repo.dart';
import 'package:naijasingles/features/auth/phone/bloc/phone_auth_bloc.dart';

class MockPhoneAuthRepository extends Mock implements PhoneAuthRepository {}

void main() {
  late MockPhoneAuthRepository mockRepo;
  late PhoneAuthBloc bloc;

  setUp(() {
    firebaseAuthInstance = MockFirebaseAuth();
    mockRepo = MockPhoneAuthRepository();
    bloc = PhoneAuthBloc(phoneAuthRepository: mockRepo);
  });

  tearDown(() {
    bloc.close();
  });

  // ---------------------------------------------------------------------------
  // State classes
  // ---------------------------------------------------------------------------
  group('PhoneAuthState', () {
    test('PhoneAuthInitial supports value equality', () {
      expect(PhoneAuthInitial(), equals(PhoneAuthInitial()));
    });

    test('PhoneAuthLoading supports value equality', () {
      expect(PhoneAuthLoading(), equals(PhoneAuthLoading()));
    });

    test('PhoneAuthError exposes error message', () {
      const state = PhoneAuthError(error: 'something went wrong');
      expect(state.error, 'something went wrong');
    });

    test('PhoneAuthError instances with same message are equal', () {
      expect(
        const PhoneAuthError(error: 'err'),
        equals(const PhoneAuthError(error: 'err')),
      );
    });

    test('PhoneAuthError instances with different messages are not equal', () {
      expect(
        const PhoneAuthError(error: 'a'),
        isNot(equals(const PhoneAuthError(error: 'b'))),
      );
    });

    test('PhoneAuthCodeSentSuccess exposes verificationId', () {
      const state = PhoneAuthCodeSentSuccess(verificationId: 'vid-123');
      expect(state.verificationId, 'vid-123');
    });

    test('PhoneAuthCodeSentSuccess supports value equality', () {
      expect(
        const PhoneAuthCodeSentSuccess(verificationId: 'vid'),
        equals(const PhoneAuthCodeSentSuccess(verificationId: 'vid')),
      );
    });

    test('PhoneupdateSuccess exposes verificationId and supports equality', () {
      const state = PhoneupdateSuccess(verificationId: 'vid-456');
      expect(state.verificationId, 'vid-456');
      expect(
        state,
        equals(const PhoneupdateSuccess(verificationId: 'vid-456')),
      );
    });

    test('PhoneAuthVerified holds a non-null user reference', () {
      final mockUser = MockUser(uid: 'test-uid-123');
      final state = PhoneAuthVerified(user: mockUser);
      expect(state.user, isNotNull);
      expect(state.user!.uid, 'test-uid-123');
    });

    test('PhoneAuthVerified accepts null user', () {
      final state = PhoneAuthVerified(user: null);
      expect(state.user, isNull);
    });

    test('PhoneAuthCodeSentSuccess with different ids are not equal', () {
      expect(
        const PhoneAuthCodeSentSuccess(verificationId: 'a'),
        isNot(equals(const PhoneAuthCodeSentSuccess(verificationId: 'b'))),
      );
    });

    test('PhoneupdateSuccess with different ids are not equal', () {
      expect(
        const PhoneupdateSuccess(verificationId: 'a'),
        isNot(equals(const PhoneupdateSuccess(verificationId: 'b'))),
      );
    });

    test('different state subtypes are not equal', () {
      expect(PhoneAuthInitial(), isNot(equals(PhoneAuthLoading())));
      expect(
        PhoneAuthLoading(),
        isNot(equals(const PhoneAuthError(error: 'err'))),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Event classes
  // ---------------------------------------------------------------------------
  group('PhoneAuthEvent', () {
    test('SendOtpToPhoneEvent props include phoneNumber', () {
      const event = SendOtpToPhoneEvent(phoneNumber: '+1234567890');
      expect(event.props, ['+1234567890']);
    });

    test('SendOtpToPhoneEvent supports equality', () {
      expect(
        const SendOtpToPhoneEvent(phoneNumber: '+1'),
        equals(const SendOtpToPhoneEvent(phoneNumber: '+1')),
      );
    });

    test('VerifySentOtpEvent props include otpCode and verificationId', () {
      const event =
          VerifySentOtpEvent(otpCode: '123456', verificationId: 'vid');
      expect(event.props, ['123456', 'vid']);
    });

    test('VerifySentOtpEvent supports equality', () {
      expect(
        const VerifySentOtpEvent(otpCode: '123456', verificationId: 'vid'),
        equals(
          const VerifySentOtpEvent(otpCode: '123456', verificationId: 'vid'),
        ),
      );
    });

    test('OnPhoneOtpSent props include verificationId and stringified token',
        () {
      const event = OnPhoneOtpSent(
        verificationId: 'vid',
        token: 42,
        phoneNumber: '+1',
      );
      expect(event.props, ['vid', '42']);
    });

    test('OnPhoneAuthErrorEvent props include error', () {
      const event = OnPhoneAuthErrorEvent(error: 'timeout');
      expect(event.props, ['timeout']);
    });

    test('OnPhoneAuthErrorEvent supports equality', () {
      expect(
        const OnPhoneAuthErrorEvent(error: 'err'),
        equals(const OnPhoneAuthErrorEvent(error: 'err')),
      );
    });

    test('UseTestPhoneAuthEvent has empty props', () {
      expect(UseTestPhoneAuthEvent().props, isEmpty);
    });

    test('SendOtpToPhoneEvent with different numbers are not equal', () {
      expect(
        const SendOtpToPhoneEvent(phoneNumber: '+1111111111'),
        isNot(equals(const SendOtpToPhoneEvent(phoneNumber: '+2222222222'))),
      );
    });

    test('VerifySentOtpEvent with different codes are not equal', () {
      expect(
        const VerifySentOtpEvent(otpCode: '111111', verificationId: 'vid'),
        isNot(equals(
          const VerifySentOtpEvent(otpCode: '999999', verificationId: 'vid'),
        )),
      );
    });

    test('VerifySentOtpEvent with different verificationIds are not equal', () {
      expect(
        const VerifySentOtpEvent(otpCode: '123456', verificationId: 'a'),
        isNot(equals(
          const VerifySentOtpEvent(otpCode: '123456', verificationId: 'b'),
        )),
      );
    });

    test('OnPhoneNumberupdateEvent stores properties correctly', () {
      const event = OnPhoneNumberupdateEvent(
        verificationId: 'vid-789',
        token: '654321',
        phoneNumber: '+2348012345678',
      );
      expect(event.verificationId, 'vid-789');
      expect(event.token, '654321');
      expect(event.phoneNumber, '+2348012345678');
    });

    test('OnPhoneOtpSent with null token stringifies to "null" in props', () {
      const event = OnPhoneOtpSent(
        verificationId: 'vid',
        token: null,
        phoneNumber: '+1',
      );
      expect(event.props, ['vid', 'null']);
    });
  });

  // ---------------------------------------------------------------------------
  // Bloc event → state transitions
  // ---------------------------------------------------------------------------
  group('PhoneAuthBloc', () {
    test('initial state is PhoneAuthInitial', () {
      expect(bloc.state, isA<PhoneAuthInitial>());
    });

    blocTest<PhoneAuthBloc, PhoneAuthState>(
      'emits [PhoneAuthCodeSentSuccess] when OnPhoneOtpSent is added',
      setUp: () => firebaseAuthInstance = MockFirebaseAuth(),
      build: () => PhoneAuthBloc(phoneAuthRepository: mockRepo),
      act: (bloc) => bloc.add(
        const OnPhoneOtpSent(
          verificationId: 'vid-test',
          token: 123,
          phoneNumber: '+1234567890',
        ),
      ),
      expect: () => [
        const PhoneAuthCodeSentSuccess(verificationId: 'vid-test'),
      ],
    );

    blocTest<PhoneAuthBloc, PhoneAuthState>(
      'emits [PhoneAuthError] when OnPhoneAuthErrorEvent is added',
      setUp: () => firebaseAuthInstance = MockFirebaseAuth(),
      build: () => PhoneAuthBloc(phoneAuthRepository: mockRepo),
      act: (bloc) =>
          bloc.add(const OnPhoneAuthErrorEvent(error: 'network-error')),
      expect: () => [
        const PhoneAuthError(error: 'network-error'),
      ],
    );

    blocTest<PhoneAuthBloc, PhoneAuthState>(
      'emits [PhoneAuthLoading, PhoneAuthError] when UseTestPhoneAuthEvent is added',
      setUp: () => firebaseAuthInstance = MockFirebaseAuth(),
      build: () => PhoneAuthBloc(phoneAuthRepository: mockRepo),
      act: (bloc) => bloc.add(UseTestPhoneAuthEvent()),
      expect: () => [
        PhoneAuthLoading(),
        const PhoneAuthError(
          error: 'Test authentication is not available in production',
        ),
      ],
    );

    blocTest<PhoneAuthBloc, PhoneAuthState>(
      'emits correct states when multiple error events arrive in sequence',
      setUp: () => firebaseAuthInstance = MockFirebaseAuth(),
      build: () => PhoneAuthBloc(phoneAuthRepository: mockRepo),
      act: (bloc) {
        bloc
          ..add(const OnPhoneAuthErrorEvent(error: 'first-error'))
          ..add(const OnPhoneAuthErrorEvent(error: 'second-error'));
      },
      expect: () => [
        const PhoneAuthError(error: 'first-error'),
        const PhoneAuthError(error: 'second-error'),
      ],
    );

    blocTest<PhoneAuthBloc, PhoneAuthState>(
      'emits [PhoneAuthCodeSentSuccess, PhoneAuthError] for OtpSent then Error',
      setUp: () => firebaseAuthInstance = MockFirebaseAuth(),
      build: () => PhoneAuthBloc(phoneAuthRepository: mockRepo),
      act: (bloc) {
        bloc
          ..add(const OnPhoneOtpSent(
            verificationId: 'vid',
            token: 1,
            phoneNumber: '+1',
          ))
          ..add(const OnPhoneAuthErrorEvent(error: 'timeout'));
      },
      expect: () => [
        const PhoneAuthCodeSentSuccess(verificationId: 'vid'),
        const PhoneAuthError(error: 'timeout'),
      ],
    );

    blocTest<PhoneAuthBloc, PhoneAuthState>(
      'emits nothing when no events are added',
      setUp: () => firebaseAuthInstance = MockFirebaseAuth(),
      build: () => PhoneAuthBloc(phoneAuthRepository: mockRepo),
      expect: () => <PhoneAuthState>[],
    );

    blocTest<PhoneAuthBloc, PhoneAuthState>(
      'OnPhoneOtpSent with null token still emits PhoneAuthCodeSentSuccess',
      setUp: () => firebaseAuthInstance = MockFirebaseAuth(),
      build: () => PhoneAuthBloc(phoneAuthRepository: mockRepo),
      act: (bloc) => bloc.add(
        const OnPhoneOtpSent(
          verificationId: 'vid-null-token',
          token: null,
          phoneNumber: '+2348000000000',
        ),
      ),
      expect: () => [
        const PhoneAuthCodeSentSuccess(verificationId: 'vid-null-token'),
      ],
    );

    blocTest<PhoneAuthBloc, PhoneAuthState>(
      'consecutive OnPhoneOtpSent events emit latest verificationId',
      setUp: () => firebaseAuthInstance = MockFirebaseAuth(),
      build: () => PhoneAuthBloc(phoneAuthRepository: mockRepo),
      act: (bloc) {
        bloc
          ..add(const OnPhoneOtpSent(
            verificationId: 'vid-first',
            token: 1,
            phoneNumber: '+1',
          ))
          ..add(const OnPhoneOtpSent(
            verificationId: 'vid-second',
            token: 2,
            phoneNumber: '+1',
          ));
      },
      expect: () => [
        const PhoneAuthCodeSentSuccess(verificationId: 'vid-first'),
        const PhoneAuthCodeSentSuccess(verificationId: 'vid-second'),
      ],
    );

    blocTest<PhoneAuthBloc, PhoneAuthState>(
      'UseTestPhoneAuthEvent error message is deterministic',
      setUp: () => firebaseAuthInstance = MockFirebaseAuth(),
      build: () => PhoneAuthBloc(phoneAuthRepository: mockRepo),
      act: (bloc) => bloc.add(UseTestPhoneAuthEvent()),
      verify: (bloc) {
        final lastState = bloc.state;
        expect(lastState, isA<PhoneAuthError>());
        expect(
          (lastState as PhoneAuthError).error,
          contains('not available in production'),
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // State props verification
  // ---------------------------------------------------------------------------
  group('PhoneAuthState props', () {
    test('PhoneAuthInitial props list is empty', () {
      expect(PhoneAuthInitial().props, <Object>[]);
    });

    test('PhoneAuthLoading props list is empty', () {
      expect(PhoneAuthLoading().props, <Object>[]);
    });

    test('PhoneAuthError props list contains exactly the error string', () {
      const state = PhoneAuthError(error: 'auth/invalid-phone');
      expect(state.props, hasLength(1));
      expect(state.props.first, 'auth/invalid-phone');
    });

    test('PhoneAuthCodeSentSuccess props list contains the verificationId', () {
      const state = PhoneAuthCodeSentSuccess(verificationId: 'abc-xyz');
      expect(state.props, hasLength(1));
      expect(state.props.first, 'abc-xyz');
    });

    test('PhoneupdateSuccess props list contains the verificationId', () {
      const state = PhoneupdateSuccess(verificationId: 'up-vid');
      expect(state.props, hasLength(1));
      expect(state.props.first, 'up-vid');
    });
  });

  // ---------------------------------------------------------------------------
  // Additional event equality edge cases
  // ---------------------------------------------------------------------------
  group('PhoneAuthEvent equality edge cases', () {
    test('OnPhoneOtpSent instances with same values are equal', () {
      expect(
        const OnPhoneOtpSent(
          verificationId: 'vid',
          token: 10,
          phoneNumber: '+1',
        ),
        equals(const OnPhoneOtpSent(
          verificationId: 'vid',
          token: 10,
          phoneNumber: '+1',
        )),
      );
    });

    test('OnPhoneOtpSent instances with different tokens are not equal', () {
      expect(
        const OnPhoneOtpSent(
          verificationId: 'vid',
          token: 1,
          phoneNumber: '+1',
        ),
        isNot(equals(const OnPhoneOtpSent(
          verificationId: 'vid',
          token: 2,
          phoneNumber: '+1',
        ))),
      );
    });

    test('UseTestPhoneAuthEvent instances are always equal', () {
      expect(UseTestPhoneAuthEvent(), equals(UseTestPhoneAuthEvent()));
    });

    test('OnPhoneNumberupdateEvent uses default Equatable props (empty)', () {
      const event = OnPhoneNumberupdateEvent(
        verificationId: 'vid',
        token: '123',
        phoneNumber: '+1',
      );
      expect(event.props, <Object>[]);
    });
  });
}
