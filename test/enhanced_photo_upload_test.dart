import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/onboarding/screens/enhanced_photo_upload_screen.dart';
import 'package:naijasingles/features/user/controllers/onboarding_controller.dart';
import 'package:provider/provider.dart';

void main() {
  group('Enhanced Photo Upload Screen Tests', () {
    testWidgets('Enhanced photo upload screen renders correctly',
        (WidgetTester tester) async {
      // Create a test app with the enhanced photo upload screen
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => OnboardingController(),
            child: const Scaffold(
              body: EnhancedPhotoUploadScreen(),
            ),
          ),
        ),
      );

      // Verify the screen renders
      expect(find.text('Add Your Profile Photos'), findsOneWidget);
      expect(find.text('MAIN PHOTO'), findsOneWidget);
      expect(find.text('Quick Photo Guide'), findsOneWidget);

      // Verify photo slots are present - handle multiple text widgets
      expect(find.text('Main Photo'), findsOneWidget);
      expect(find.text('Full Body'), findsOneWidget);
      expect(find.text('Activity'),
          findsAtLeastNWidgets(1),); // At least one Activity text
      expect(find.text('Social'),
          findsAtLeastNWidgets(1),); // At least one Social text
      expect(find.text('Lifestyle'), findsOneWidget);
    });

    testWidgets('Photo guide section is visible and accessible',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => OnboardingController(),
            child: const Scaffold(
              body: EnhancedPhotoUploadScreen(),
            ),
          ),
        ),
      );

      // Verify the photo guide section is present
      expect(find.text('Quick Photo Guide'), findsOneWidget);

      // Verify photo tips are visible in the guide
      expect(find.text('Main Photo: Clear face shot with a genuine smile'),
          findsOneWidget,);
      expect(find.text('Full Body: Show your style in a natural setting'),
          findsOneWidget,);
      expect(
          find.text(
              'Activity: Doing something you love or are passionate about',),
          findsOneWidget,);
    });

    testWidgets('Primary photo slot has special styling',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => OnboardingController(),
            child: const Scaffold(
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
        title: 'Main Photo',
        description: 'A clear, smiling face shot with good lighting',
        isPrimary: true,
      );

      expect(guidance.type, PhotoType.closeUp);
      expect(guidance.title, 'Main Photo');
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
