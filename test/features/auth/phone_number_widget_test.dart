import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/common/constants/constants.dart';
import 'package:naijasingles/common/widgets/afropeep_primary_button.dart';
import 'package:naijasingles/features/auth/phone/ui/screens/phone_number.dart';

void main() {
  setUp(() {
    firebaseAuthInstance = MockFirebaseAuth();
  });

  group('PhoneNumber widget validation', () {
    testWidgets('Continue button is disabled for invalid (too short) number',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PhoneNumber(updatePhoneNumber: false),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);
      await tester.enterText(textFields.first, '123');
      await tester.pump(const Duration(milliseconds: 100));

      final continueButton = find.ancestor(
        of: find.text('Continue'),
        matching: find.byType(AfropeepPrimaryButton),
      );
      expect(continueButton, findsOneWidget);
      final buttonWidget = tester.widget<AfropeepPrimaryButton>(continueButton);
      expect(buttonWidget.onPressed, isNull);
    });

    testWidgets('Continue button is enabled for valid US number',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PhoneNumber(updatePhoneNumber: false),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, '2125551234');
      await tester.pump(const Duration(milliseconds: 100));

      final continueButton = find.ancestor(
        of: find.text('Continue'),
        matching: find.byType(AfropeepPrimaryButton),
      );
      expect(continueButton, findsOneWidget);
      final buttonWidget = tester.widget<AfropeepPrimaryButton>(continueButton);
      expect(buttonWidget.onPressed, isNotNull);
    });
  });
}
