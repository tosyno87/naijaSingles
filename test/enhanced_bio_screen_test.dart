import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naijasingles/common/bloc/user/user_bloc.dart';
import 'package:naijasingles/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:naijasingles/features/onboarding/data/repositories/onboarding_repository.dart';
import 'package:naijasingles/features/onboarding/screens/enhanced_bio_screen.dart';

class MockOnboardingRepository extends Mock implements OnboardingRepository {}

class MockUserBloc extends Mock implements UserBloc {}

void main() {
  late MockOnboardingRepository mockRepository;
  late MockUserBloc mockUserBloc;

  setUp(() {
    mockRepository = MockOnboardingRepository();
    mockUserBloc = MockUserBloc();
  });

  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      home: BlocProvider<OnboardingBloc>(
        create: (_) => OnboardingBloc(
          repository: mockRepository,
          userBloc: mockUserBloc,
        ),
        child: Scaffold(body: child),
      ),
    );
  }

  group('Enhanced Bio Screen Tests', () {
    testWidgets('Enhanced bio screen renders correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const EnhancedBioScreen()),
      );

      await tester.pumpAndSettle();

      // Verify key elements are present (simplified bio screen)
      expect(find.text('Tell your story'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Bio screen has text field and header',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const EnhancedBioScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tell your story'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Bio text field accepts input', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const EnhancedBioScreen()),
      );
      await tester.pumpAndSettle();

      final bioField = find.byType(TextField);
      expect(bioField, findsOneWidget);

      await tester.enterText(
          bioField, 'This is my test bio with enough characters.');
      await tester.pump();

      expect(find.textContaining('This is my test bio'), findsOneWidget);
    });

    testWidgets('Bio text field is editable', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const EnhancedBioScreen()),
      );
      await tester.pumpAndSettle();

      final bioField = find.byType(TextField);
      await tester.enterText(bioField, 'Test bio content');
      await tester.pump();

      expect(find.text('Test bio content'), findsOneWidget);
    });

    testWidgets('Bio screen renders with scroll view',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const EnhancedBioScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text('Tell your story'), findsOneWidget);
    });
  });
}
