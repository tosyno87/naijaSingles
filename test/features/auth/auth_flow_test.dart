import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naijasingles/common/bloc/user/user_bloc.dart';
import 'package:naijasingles/common/utils/profile_completion_guard.dart';
import 'package:naijasingles/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:naijasingles/features/onboarding/bloc/onboarding_data.dart';
import 'package:naijasingles/features/onboarding/data/repositories/onboarding_repository.dart';
import 'package:naijasingles/features/onboarding/onboarding_main.dart';
import 'package:naijasingles/models/user_model.dart';

class MockOnboardingRepository extends Mock implements OnboardingRepository {}

class MockUserBloc extends Mock implements UserBloc {}

/// Bloc subclass that exposes [emit] so we can seed state in widget tests.
class TestableOnboardingBloc extends OnboardingBloc {
  TestableOnboardingBloc({
    required super.repository,
    required super.userBloc,
  });

  // ignore: invalid_use_of_visible_for_testing_member
  void seedState(OnboardingState state) => emit(state);
}

void main() {
  // ---------------------------------------------------------------
  // 1. New user auth → should route to onboarding
  // ---------------------------------------------------------------
  group('Post-auth routing decision — new user → onboarding', () {
    test('empty Firestore doc → incomplete', () {
      expect(ProfileCompletionGuard.isDocumentComplete({}), isFalse);
    });

    test('doc with only name → incomplete (missing gender/photo)', () {
      expect(
        ProfileCompletionGuard.isDocumentComplete({'name': 'Ada'}),
        isFalse,
      );
    });

    test('doc with onboardingCompleted: false → incomplete', () {
      expect(
        ProfileCompletionGuard.isDocumentComplete({
          'name': 'Ada',
          'gender': 'female',
          'onboardingCompleted': false,
        }),
        isFalse,
      );
    });

    test('UserModel with empty name → incomplete', () {
      expect(
        ProfileCompletionGuard.isUserComplete(UserModel(id: '1', name: '')),
        isFalse,
      );
    });
  });

  // ---------------------------------------------------------------
  // 2. Returning completed user auth → should route to main nav
  // ---------------------------------------------------------------
  group('Post-auth routing decision — returning user → main nav', () {
    test('doc with onboardingCompleted: true → complete', () {
      expect(
        ProfileCompletionGuard.isDocumentComplete({
          'name': 'Kofi',
          'onboardingCompleted': true,
        }),
        isTrue,
      );
    });

    test('doc with isProfileComplete: true → complete', () {
      expect(
        ProfileCompletionGuard.isDocumentComplete({
          'isProfileComplete': true,
        }),
        isTrue,
      );
    });

    test('doc with name + gender + photo (no flags) → complete', () {
      expect(
        ProfileCompletionGuard.isDocumentComplete({
          'name': 'Kofi',
          'userGender': 'male',
          'photos': ['https://example.com/photo.jpg'],
        }),
        isTrue,
      );
    });

    test('UserModel with name + gender → complete', () {
      expect(
        ProfileCompletionGuard.isUserComplete(
          UserModel(id: '1', name: 'Amara', userGender: 'female'),
        ),
        isTrue,
      );
    });
  });

  // ---------------------------------------------------------------
  // 3. Skip on optional pages cannot bypass required preferences
  // ---------------------------------------------------------------
  group('Onboarding skip logic', () {
    late MockOnboardingRepository mockRepo;
    late MockUserBloc mockUserBloc;
    late void Function(FlutterErrorDetails)? originalOnError;

    setUp(() {
      mockRepo = MockOnboardingRepository();
      mockUserBloc = MockUserBloc();
      originalOnError = FlutterError.onError;
    });

    tearDown(() {
      FlutterError.onError = originalOnError;
    });

    Widget buildOnboarding(TestableOnboardingBloc bloc) {
      return MaterialApp(
        home: BlocProvider<OnboardingBloc>.value(
          value: bloc,
          child: const OnboardingMain(),
        ),
      );
    }

    OnboardingData _completedRequiredPages() => OnboardingData(
          fullName: 'Test User',
          dateOfBirth: DateTime(1995, 5, 15),
          gender: 'Male',
          profilePhotos: [File('dummy.jpg'), ...List<File?>.filled(8, null)],
          locationName: 'London, UK',
          nationality: 'Ghana',
        );

    testWidgets(
      'Page 4 (Bio) has no skip and requires minimum bio length to proceed',
      (WidgetTester tester) async {
        final bloc = TestableOnboardingBloc(
          repository: mockRepo,
          userBloc: mockUserBloc,
        );
        bloc.seedState(OnboardingLoaded(_completedRequiredPages()));

        await tester.pumpWidget(buildOnboarding(bloc));
        await tester.pumpAndSettle();

        // Navigate to page 4 (Bio) — tap Next 4 times through pages 0→3
        for (int i = 0; i < 4; i++) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
        }

        // Now on page 4 — Bio is required.
        expect(find.text('Tell Your Story'), findsOneWidget);
        expect(find.text('Skip'), findsNothing);

        // Cannot proceed without minimum bio length.
        expect(
            tester
                .widget<ElevatedButton>(find.byType(ElevatedButton))
                .onPressed,
            isNull);

        await tester.enterText(
          find.byType(TextField),
          'This is a valid onboarding bio with enough characters.',
        );
        await tester.pumpAndSettle();

        // Next becomes available and advances to interests.
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        expect(find.text('Your Interests'), findsOneWidget);
        expect(find.text('Skip'), findsNothing);
      },
    );

    testWidgets(
      'Page 5 (Interests) has no skip and requires minimum interest selection',
      (WidgetTester tester) async {
        final bloc = TestableOnboardingBloc(
          repository: mockRepo,
          userBloc: mockUserBloc,
        );
        final seededData = _completedRequiredPages().copyWith(
          bio: 'This is a valid onboarding bio with enough characters.',
        );
        bloc.seedState(OnboardingLoaded(seededData));

        await tester.pumpWidget(buildOnboarding(bloc));
        await tester.pumpAndSettle();

        // Navigate through pages 0→4 with valid bio.
        for (int i = 0; i < 4; i++) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        // Now on page 5 — no skip and Next disabled until enough interests selected.
        expect(find.text('Your Interests'), findsOneWidget);
        expect(find.text('Skip'), findsNothing);
        expect(
            tester
                .widget<ElevatedButton>(find.byType(ElevatedButton))
                .onPressed,
            isNull);

        await tester.tap(find.text('Photography'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Drawing'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Painting'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        // Should land on page 6 — Dating Preferences (required).
        expect(find.text('Dating Preferences'), findsWidgets);
        expect(find.text('Skip'), findsNothing);
      },
    );

    testWidgets('Page 6 (Preferences) requires interestedIn selection',
        (WidgetTester tester) async {
      final bloc = TestableOnboardingBloc(
        repository: mockRepo,
        userBloc: mockUserBloc,
      );
      final seededData = _completedRequiredPages().copyWith(
        bio: 'This is a valid onboarding bio with enough characters.',
        interests: const ['Photography', 'Drawing', 'Painting'],
      );
      bloc.seedState(OnboardingLoaded(seededData));

      await tester.pumpWidget(buildOnboarding(bloc));
      await tester.pumpAndSettle();

      // Navigate to page 6.
      for (int i = 0; i < 6; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Dating Preferences'), findsWidgets);
      expect(
          tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
          isNull);

      bloc.add(const OnboardingInterestedInUpdated('everyone'));
      await tester.pumpAndSettle();

      expect(
          tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
          isNotNull);
    });

    testWidgets('Page 7 requires lookingFor and relationshipIntent',
        (WidgetTester tester) async {
      final bloc = TestableOnboardingBloc(
        repository: mockRepo,
        userBloc: mockUserBloc,
      );
      final seededData = _completedRequiredPages().copyWith(
        bio: 'This is a valid onboarding bio with enough characters.',
        interests: const ['Photography', 'Drawing', 'Painting'],
        interestedIn: 'everyone',
      );
      bloc.seedState(OnboardingLoaded(seededData));

      await tester.pumpWidget(buildOnboarding(bloc));
      await tester.pumpAndSettle();

      // Navigate to page 7.
      for (int i = 0; i < 7; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Tell us more about you'), findsOneWidget);
      expect(
          tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
          isNull);

      bloc.add(const OnboardingLookingForUpdated('Dating'));
      await tester.pumpAndSettle();
      expect(
          tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
          isNull);

      bloc.add(const OnboardingRelationshipIntentUpdated('Serious'));
      await tester.pumpAndSettle();
      expect(
          tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
          isNotNull);
    });
  });
}
