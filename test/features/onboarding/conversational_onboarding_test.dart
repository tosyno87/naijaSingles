import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naijasingles/common/bloc/user/user_bloc.dart';
import 'package:naijasingles/common/routes/route_name.dart';
import 'package:naijasingles/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:naijasingles/features/onboarding/bloc/onboarding_data.dart';
import 'package:naijasingles/features/onboarding/conversational/conversational_onboarding_flow.dart';
import 'package:naijasingles/features/onboarding/data/onboarding_draft_mapper.dart';
import 'package:naijasingles/features/onboarding/data/repositories/onboarding_repository.dart';

class MockOnboardingRepository extends Mock implements OnboardingRepository {}

class MockUserBloc extends Mock implements UserBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OnboardingBloc bloc;

  setUp(() {
    bloc = OnboardingBloc(
      repository: MockOnboardingRepository(),
      userBloc: MockUserBloc(),
    );
  });

  tearDown(() async {
    await bloc.close();
  });

  testWidgets('consent skip opens the form fallback route', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/': (_) => BlocProvider.value(
                value: bloc,
                child: const ConversationalOnboardingFlow(),
              ),
          RouteName.onboardingForms: (_) =>
              const Scaffold(body: Text('form-fallback')),
        },
      ),
    );

    expect(find.text('Tell us who you are'), findsOneWidget);
    await tester.tap(find.text('Fill it in myself'));
    await tester.pumpAndSettle();
    expect(find.text('form-fallback'), findsOneWidget);
  });

  test('mapper prefills adult fields and drops under-18 dates', () {
    const mapper = OnboardingDraftMapper();
    final drafted = mapper.apply(
      current: OnboardingData(),
      fields: {
        'fullName': 'Adaeze',
        'gender': 'Female',
        'dateOfBirth': '2015-01-01',
        'bio': 'Houston community',
        'lookingFor': 'Friendship',
        'languages': ['English', 'Igbo'],
      },
    );

    expect(drafted.fullName, 'Adaeze');
    expect(drafted.gender, 'Female');
    expect(drafted.dateOfBirth, isNull);
    expect(drafted.bio, 'Houston community');
    expect(drafted.lookingFor, 'Friendship');
    expect(drafted.languages, ['English', 'Igbo']);
  });

  test('draft applied event updates OnboardingBloc data', () async {
    final next = OnboardingData(fullName: 'Kofi', gender: 'Male');
    final future = expectLater(
      bloc.stream,
      emits(
        isA<OnboardingLoaded>().having(
          (s) => s.data.fullName,
          'fullName',
          'Kofi',
        ),
      ),
    );
    bloc.add(OnboardingDraftApplied(next));
    await future;
  });
}
