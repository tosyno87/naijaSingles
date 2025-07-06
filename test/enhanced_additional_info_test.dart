import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:naijasingles/features/onboarding/screens/enhanced_additional_info_screen.dart';
import 'package:naijasingles/features/user/controllers/onboarding_controller.dart';

void main() {
  group('Enhanced Additional Info Screen Tests', () {
    testWidgets('Enhanced additional info screen renders correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => OnboardingController(),
            child: Scaffold(
              body: EnhancedAdditionalInfoScreen(),
            ),
          ),
        ),
      );

      // Verify the screen renders
      expect(find.text('Tell us more about you'), findsOneWidget);
      expect(
          find.text('Help us create better matches for you'), findsOneWidget);

      // Verify main sections are present
      expect(find.text('Height'), findsOneWidget);
      expect(find.text('What brings you to NaijaSingles?'), findsOneWidget);
      expect(find.text('Relationship goals'), findsOneWidget);
      expect(find.text('Education'), findsOneWidget);
      expect(find.text('Faith & Religion'), findsOneWidget);
      expect(find.text('Languages'), findsOneWidget);
    });

    testWidgets('Progress indicator shows completion status',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => OnboardingController(),
            child: Scaffold(
              body: EnhancedAdditionalInfoScreen(),
            ),
          ),
        ),
      );

      // Verify progress indicator is present
      expect(find.text('Profile completion: 1 of 6 sections'), findsOneWidget);
      expect(
          find.text('Complete profiles get 3x more matches!'), findsOneWidget);
    });

    testWidgets('Info card explains importance of information',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => OnboardingController(),
            child: Scaffold(
              body: EnhancedAdditionalInfoScreen(),
            ),
          ),
        ),
      );

      // Verify info card is present
      expect(find.text('Why we ask for this information'), findsOneWidget);
      expect(find.text('These details help us find better matches'),
          findsOneWidget);
    });

    testWidgets('Looking for options include Nigerian context',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => OnboardingController(),
            child: Scaffold(
              body: EnhancedAdditionalInfoScreen(),
            ),
          ),
        ),
      );

      // Verify enhanced looking for options
      expect(find.text('Serious relationship'), findsOneWidget);
      expect(find.text('Dating & getting to know someone'), findsOneWidget);
      expect(find.text('Casual dating'), findsOneWidget);
      expect(find.text('New friends & connections'), findsOneWidget);
    });

    testWidgets('Relationship intent options are culturally relevant',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => OnboardingController(),
            child: Scaffold(
              body: EnhancedAdditionalInfoScreen(),
            ),
          ),
        ),
      );

      // Verify enhanced relationship intent options
      expect(find.text('Looking for marriage'), findsOneWidget);
      expect(find.text('Long-term relationship'), findsOneWidget);
      expect(find.text('Dating to see where it goes'), findsOneWidget);
    });

    testWidgets('Nigerian languages are included', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => OnboardingController(),
            child: Scaffold(
              body: EnhancedAdditionalInfoScreen(),
            ),
          ),
        ),
      );

      // Verify Nigerian languages are present
      expect(find.text('Hausa'), findsOneWidget);
      expect(find.text('Yoruba'), findsOneWidget);
      expect(find.text('Igbo'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('Religion options include Nigerian context',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => OnboardingController(),
            child: Scaffold(
              body: EnhancedAdditionalInfoScreen(),
            ),
          ),
        ),
      );

      // Verify religion options
      expect(find.text('Christianity'), findsOneWidget);
      expect(find.text('Islam'), findsOneWidget);
      expect(find.text('Traditional African Religion'), findsOneWidget);
    });

    testWidgets('Lifestyle preferences are included',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => OnboardingController(),
            child: Scaffold(
              body: EnhancedAdditionalInfoScreen(),
            ),
          ),
        ),
      );

      // Verify lifestyle sections
      expect(find.text('Lifestyle'), findsOneWidget);
      expect(find.text('Drinking'), findsOneWidget);
      expect(find.text('Smoking'), findsOneWidget);
    });
  });

  group('Enhanced Additional Info Controller Integration', () {
    testWidgets('Controller methods are called when options are selected',
        (WidgetTester tester) async {
      final controller = OnboardingController();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: controller,
            child: Scaffold(
              body: EnhancedAdditionalInfoScreen(),
            ),
          ),
        ),
      );

      // Test looking for selection
      await tester.tap(find.text('Serious relationship'));
      await tester.pumpAndSettle();

      expect(controller.lookingFor, 'Serious');
    });

    testWidgets('Language selection works correctly',
        (WidgetTester tester) async {
      final controller = OnboardingController();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: controller,
            child: Scaffold(
              body: EnhancedAdditionalInfoScreen(),
            ),
          ),
        ),
      );

      // Test language selection
      await tester.tap(find.text('Yoruba'));
      await tester.pumpAndSettle();

      expect(controller.spokenLanguages, contains('Yoruba'));
    });
  });

  group('Enhanced Additional Info Validation', () {
    test('Completion count calculates correctly', () {
      // This would test the completion counting logic
      // Implementation depends on how the completion counting is structured
    });

    test('Required fields are properly identified', () {
      // This would test which fields are considered required
      // Implementation depends on validation logic
    });
  });
}
