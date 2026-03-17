import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:naijasingles/common/bloc/theme/theme_bloc.dart';
import 'package:naijasingles/common/constants/constants.dart';
import 'package:naijasingles/common/data/repo/phone_auth_repo.dart';
import 'package:naijasingles/features/auth/auth_status/bloc/authstatus_bloc.dart';
import 'package:naijasingles/features/auth/auth_status/bloc/registration/bloc/registration_bloc.dart';
import 'package:naijasingles/features/auth/phone/bloc/phone_auth_bloc.dart';
import 'package:naijasingles/features/auth/phone/ui/screens/otp_page.dart';
import 'package:naijasingles/common/bloc/user/user_bloc.dart';

class MockPhoneAuthRepository extends Mock implements PhoneAuthRepository {}

class MockUserBloc extends Mock implements UserBloc {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  late MockPhoneAuthRepository mockRepo;
  late AuthstatusBloc authstatusBloc;
  late MockUserBloc mockUserBloc;
  late MockNavigatorObserver mockNavigatorObserver;

  setUp(() {
    firebaseAuthInstance = MockFirebaseAuth();
    mockRepo = MockPhoneAuthRepository();
    when(() => mockRepo.signOut()).thenAnswer((_) async {});
    authstatusBloc = AuthstatusBloc(phoneAuthRepository: mockRepo);
    mockUserBloc = MockUserBloc();
    mockNavigatorObserver = MockNavigatorObserver();
    when(() => mockUserBloc.state).thenReturn(UserInitial());
    when(
      () => mockUserBloc.stream,
    ).thenAnswer((_) => const Stream<UserState>.empty());
  });

  testWidgets(
      'OtpPage supports login flow where RegistrationBloc reaches NotRegistered',
      (WidgetTester tester) async {
    final registrationBloc = RegistrationBloc(phoneAuthRepository: mockRepo);
    final mockUser = MockUser(
      uid: 'test-user-id',
      displayName: 'Test User',
      phoneNumber: '+2348012345678',
    );
    when(() => mockRepo.getCurrentUser()).thenAnswer((_) async => mockUser);
    when(() => mockRepo.userDetails(any())).thenAnswer((_) async => false);
    when(
      () => mockRepo.findUserIdByPhoneNumber(any()),
    ).thenAnswer((_) async => null);

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [mockNavigatorObserver],
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MultiBlocProvider(
                        providers: [
                          BlocProvider<ThemeBloc>(create: (_) => ThemeBloc()),
                          BlocProvider<AuthstatusBloc>.value(
                            value: authstatusBloc,
                          ),
                          BlocProvider<UserBloc>.value(value: mockUserBloc),
                        ],
                        child: OtpPage(
                          phoneNumber: '+2348012345678',
                          verificationId: 'vid',
                          isLogin: true,
                          registrationBlocOverride: registrationBloc,
                          phoneAuthBlocOverride:
                              PhoneAuthBloc(phoneAuthRepository: mockRepo),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Open OTP'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open OTP'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(OtpPage), findsOneWidget);

    // Drive the listener through the real RegistrationBloc flow.
    registrationBloc.add(const CheckRegistration(token: '', isLogin: true));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (registrationBloc.state is NotRegistered) {
        break;
      }
    }

    expect(registrationBloc.state, const NotRegistered());
  });
}
