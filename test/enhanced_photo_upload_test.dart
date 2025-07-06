import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:naijasingles/features/onboarding/screens/enhanced_photo_upload_screen.dart';
import 'package:naijasingles/features/user/controllers/onboarding_controller.dart';

void main() {
  group('Enhanced Photo Upload Screen Tests', () {
    testWidgets('Enhanced photo upload screen renders correctly',
        (WidgetTester tester) async {
      // Create a test app with the enhanced photo upload screen
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => OnboardingController(),
            child: Scaffold(
              body: EnhancedPhotoUploadScreen(),
            ),
          ),
        ),
      );

      // Verify the screen renders
      expect(find.text('Add Your Profile Photos'), findsOneWidget);
      expect(find.text('MAIN PHOTO'), findsOneWidget);
      expect(find.text('Photo Tips'), findsOneWidget);

      // Verify photo slots are present
      expect(find.text('Main Photo'), findsOneWidget);
      expect(find.text('Full Body'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Social'), findsOneWidget);
      expect(find.text('Lifestyle'), findsOneWidget);
    });

    testWidgets('Photo tips dialog opens when tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => OnboardingController(),
            child: Scaffold(
              body: EnhancedPhotoUploadScreen(),
            ),
          ),
        ),
      );

      // Tap the photo tips button
      await tester.tap(find.text('Photo Tips'));
      await tester.pumpAndSettle();

      // Verify the dialog opens
      expect(find.text('Photo Tips for Dating Success'), findsOneWidget);
      expect(find.text('Essential Tips'), findsOneWidget);
      expect(find.text('Nigerian Dating Context'), findsOneWidget);
      expect(find.text('What to Avoid'), findsOneWidget);
    });

    testWidgets('Primary photo slot has special styling',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => OnboardingController(),
            child: Scaffold(
              body: EnhancedPhotoUploadScreen(),
            ),
          ),
        ),
      );

      // Verify primary photo slot exists with special styling
      expect(find.text('MAIN PHOTO'), findsOneWidget);
      expect(find.text('Main Photo'), findsOneWidget);

      // Verify required indicator
      expect(find.text('REQUIRED'), findsOneWidget);
    });
  });

  group('Photo Type Guidance Tests', () {
    test('Photo type guidance provides correct information', () {
      const guidance = PhotoTypeGuidance(
        type: PhotoType.closeUp,
        title: "Main Photo",
        description: "A clear, smiling face shot with good lighting",
        isPrimary: true,
      );

      expect(guidance.type, PhotoType.closeUp);
      expect(guidance.title, "Main Photo");
      expect(guidance.isPrimary, true);
    });

    test('All photo types are defined', () {
      expect(PhotoType.values.length, 5);
      expect(PhotoType.values, contains(PhotoType.closeUp));
      expect(PhotoType.values, contains(PhotoType.fullBody));
      expect(PhotoType.values, contains(PhotoType.activity));
      expect(PhotoType.values, contains(PhotoType.social));
      expect(PhotoType.values, contains(PhotoType.lifestyle));
    });
  });
}
