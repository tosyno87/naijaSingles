import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../lib/features/onboarding/screens/enhanced_bio_screen.dart';
import '../lib/features/user/controllers/onboarding_controller.dart';

void main() {
  group('Enhanced Bio Screen Tests', () {
    late OnboardingController controller;

    setUp(() {
      controller = OnboardingController();
    });

    testWidgets('Enhanced bio screen renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<OnboardingController>(
            create: (_) => controller,
            child: const Scaffold(
              body: EnhancedBioScreen(),
            ),
          ),
        ),
      );

      // Verify key elements are present
      expect(find.text('Tell your story'), findsOneWidget);
      expect(find.text('Get started with prompts'), findsOneWidget);
      expect(find.text('Your bio'), findsOneWidget);
      expect(find.text('Tips for a great bio'), findsOneWidget);
    });

    testWidgets('Personality prompts are displayed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<OnboardingController>(
            create: (_) => controller,
            child: const Scaffold(
              body: EnhancedBioScreen(),
            ),
          ),
        ),
      );

      // Verify some personality prompts are present
      expect(find.text("I'm the type of person who..."), findsOneWidget);
      expect(find.text("You'll find me on weekends..."), findsOneWidget);
      expect(find.text("I'm passionate about..."), findsOneWidget);
    });

    testWidgets('Bio text field accepts input', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<OnboardingController>(
            create: (_) => controller,
            child: const Scaffold(
              body: EnhancedBioScreen(),
            ),
          ),
        ),
      );

      // Find the bio text field
      final bioField = find.byType(TextField);
      expect(bioField, findsOneWidget);

      // Enter text
      await tester.enterText(bioField, 'This is my test bio with enough characters to meet the minimum requirement.');
      await tester.pump();

      // Verify character count updates
      expect(find.textContaining('/300'), findsOneWidget);
    });

    testWidgets('Prompt selection works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<OnboardingController>(
            create: (_) => controller,
            child: const Scaffold(
              body: EnhancedBioScreen(),
            ),
          ),
        ),
      );

      // Find and tap a prompt
      final prompt = find.text("I'm passionate about...");
      expect(prompt, findsOneWidget);
      
      await tester.tap(prompt);
      await tester.pump();

      // Verify the prompt appears in the bio field
      final bioField = find.byType(TextField);
      final textField = tester.widget<TextField>(bioField);
      expect(textField.controller?.text, contains("I'm passionate about..."));
    });

    testWidgets('Bio quality indicator shows correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<OnboardingController>(
            create: (_) => controller,
            child: const Scaffold(
              body: EnhancedBioScreen(),
            ),
          ),
        ),
      );

      // Enter a short bio
      final bioField = find.byType(TextField);
      await tester.enterText(bioField, 'Short bio');
      await tester.pump();

      // Should show improvement message
      expect(find.textContaining('Add'), findsWidgets);

      // Enter a longer, better bio
      await tester.enterText(bioField, 
        'I love hiking and exploring new places. Currently passionate about photography and cooking. Looking for someone who shares my love for adventure and good food!');
      await tester.pump();

      // Should show better quality indicator
      expect(find.textContaining('Perfect length'), findsOneWidget);
    });
  });
}
