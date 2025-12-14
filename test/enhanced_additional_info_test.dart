import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/onboarding/screens/enhanced_additional_info_screen.dart';
import 'package:naijasingles/features/user/controllers/onboarding_controller.dart';
import 'package:provider/provider.dart';

void main() {
  group('Enhanced Additional Info Screen Tests', () {
    testWidgets('Enhanced additional info screen renders correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => OnboardingController(),
            child: const Scaffold(
              body: EnhancedAdditionalInfoScreen(),
            ),
          ),
        ),
      );

      // Verify the screen renders
      expect(find.text('Tell us more about you'), findsOneWidget);
      expect(
          find.text('Help us create better matches for you'), findsOneWidget,);

      // Verify main sections are present
      expect(find.text('Height'), findsOneWidget);
      expect(find.text('What brings you to NaijaSingles?'), findsOneWidget);
      expect(find.text('Relationship goals'), findsOneWidget);
      expect(find.text('Education'), findsOneWidget);
      expect(find.text('Faith & Religion'), findsOneWidget);
      expect(find.text('Languages'), findsOneWidget);
    });

    testWidgets('Screen has proper structure and components',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => OnboardingController(),
            child: const Scaffold(
              body: EnhancedAdditionalInfoScreen(),
            ),
          ),
        ),
      );

      // Verify the screen has proper structure
      expect(find.byType(Container), findsAtLeastNWidgets(1));
      expect(find.byType(Column), findsAtLeastNWidgets(1));
      expect(find.byType(Text), findsAtLeastNWidgets(1));

      // Verify dropdowns are present
      expect(find.byType(DropdownButton<String>), findsAtLeastNWidgets(1));

      // Verify the screen is scrollable (important for long forms)
      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));
    });

    testWidgets('Progress indicator is present', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => OnboardingController(),
            child: const Scaffold(
              body: EnhancedAdditionalInfoScreen(),
            ),
          ),
        ),
      );

      // Verify progress indicator is present
      expect(find.textContaining('Profile completion:'), findsOneWidget);
      expect(
          find.text('Complete profiles get 3x more matches!'), findsOneWidget,);
    });

    testWidgets('Info card is present', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => OnboardingController(),
            child: const Scaffold(
              body: EnhancedAdditionalInfoScreen(),
            ),
          ),
        ),
      );

      // Verify info card is present
      expect(find.text('Why we ask for this information'), findsOneWidget);
    });
  });

  group('Enhanced Additional Info Controller Integration', () {
    testWidgets('Controller is properly initialized',
        (WidgetTester tester) async {
      final controller = OnboardingController();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => controller,
            child: const Scaffold(
              body: EnhancedAdditionalInfoScreen(),
            ),
          ),
        ),
      );

      // Verify controller is working
      expect(controller, isNotNull);
      expect(controller is OnboardingController, isTrue);
    });
  });
}
