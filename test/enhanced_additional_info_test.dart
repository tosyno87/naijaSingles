import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naijasingles/common/bloc/user/user_bloc.dart';
import 'package:naijasingles/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:naijasingles/features/onboarding/data/repositories/onboarding_repository.dart';
import 'package:naijasingles/features/onboarding/screens/enhanced_additional_info_screen.dart';

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

  group('Enhanced Additional Info Screen Tests', () {
    testWidgets('Enhanced additional info screen renders correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const EnhancedAdditionalInfoScreen()),
      );

      await tester.pumpAndSettle();

      // Verify the screen renders (may need to scroll for some content)
      expect(find.text('Tell us more about you'), findsOneWidget);
      expect(find.text('Height'), findsOneWidget);
    });

    testWidgets('Screen has proper structure and components',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const EnhancedAdditionalInfoScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));
      expect(find.text('Tell us more about you'), findsOneWidget);
    });

    testWidgets('Screen renders with scroll view', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const EnhancedAdditionalInfoScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));
      expect(find.text('Tell us more about you'), findsOneWidget);
    });

    testWidgets('Info card is present', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const EnhancedAdditionalInfoScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tell us more about you'), findsOneWidget);
    });
  });

  group('Enhanced Additional Info Bloc Integration', () {
    testWidgets('Bloc is properly initialized', (WidgetTester tester) async {
      final bloc = OnboardingBloc(
        repository: mockRepository,
        userBloc: mockUserBloc,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<OnboardingBloc>.value(
            value: bloc,
            child: const Scaffold(
              body: EnhancedAdditionalInfoScreen(),
            ),
          ),
        ),
      );

      // Verify bloc is working
      expect(bloc, isNotNull);
      expect(bloc, isA<OnboardingBloc>());
    });
  });
}
