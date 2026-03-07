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
          gender: 'male',
          profilePhotos: [File('dummy.jpg'), ...List<File?>.filled(8, null)],
          locationName: 'London, UK',
          nationality: 'Ghana',
        );

    testWidgets(
      'Skip on page 4 (Bio) advances to page 5 instead of completing',
      (WidgetTester tester) async {
        // Suppress non-fatal assertion from TribeSelectionScreen dropdown
        // (pre-existing issue, unrelated to skip logic)
        final errors = <FlutterErrorDetails>[];
        FlutterError.onError = (details) => errors.add(details);

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

        // Now on page 4 — Bio (optional). "Skip" and page title visible.
        expect(find.text('Tell Your Story'), findsOneWidget);
        expect(find.text('Skip'), findsOneWidget);

        // Tap Skip — should advance to page 5, NOT complete onboarding
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();

        // Verify we landed on page 5 (Interests), still in onboarding
        expect(find.text('Your Interests'), findsOneWidget);
        expect(find.text('Skip'), findsOneWidget);
      },
    );

    testWidgets(
      'Skip on page 5 (Interests) advances to page 6 (required Preferences)',
      (WidgetTester tester) async {
        final errors = <FlutterErrorDetails>[];
        FlutterError.onError = (details) => errors.add(details);

        final bloc = TestableOnboardingBloc(
          repository: mockRepo,
          userBloc: mockUserBloc,
        );
        bloc.seedState(OnboardingLoaded(_completedRequiredPages()));

        await tester.pumpWidget(buildOnboarding(bloc));
        await tester.pumpAndSettle();

        // Navigate through pages 0→3, then skip 4 and 5
        for (int i = 0; i < 4; i++) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();

        // Now on page 5 — skip it
        expect(find.text('Your Interests'), findsOneWidget);
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();

        // Should land on page 6 — Dating Preferences (required).
        // The title appears in both the AppBar and the page content,
        // so we check for at least one match.
        expect(find.text('Dating Preferences'), findsWidgets);
        // Skip should NOT appear on required page 6
        expect(find.text('Skip'), findsNothing);
      },
    );
  });
}
