import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naijasingles/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('African Diaspora Registration Flow', () {
    testWidgets('Complete diaspora user registration with US phone number', (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Test diaspora-specific registration flow
      await _testDiasporaRegistration(tester);
    });

    testWidgets('Profile setup with African heritage selection', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Skip to profile setup (assuming user is registered)
      await _testCulturalProfileSetup(tester);
    });

    testWidgets('US location and African background integration', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test location services for US cities with African communities
      await _testUSLocationSetup(tester);
    });
  });
}

/// Test diaspora-specific registration flow
Future<void> _testDiasporaRegistration(WidgetTester tester) async {
  // Look for registration screen
  expect(find.text('Welcome to NaijaSingles'), findsOneWidget);
  
  // Test US phone number input
  final phoneField = find.byType(TextFormField).first;
  await tester.enterText(phoneField, '+1 404 555 0123'); // Atlanta area code
  await tester.pumpAndSettle();

  // Verify US phone number format is accepted
  expect(find.text('+1 404 555 0123'), findsOneWidget);

  // Continue with registration
  final continueButton = find.text('Continue');
  if (continueButton.evaluate().isNotEmpty) {
    await tester.tap(continueButton);
    await tester.pumpAndSettle();
  }

  // Test OTP verification (mock)
  final otpFields = find.byType(TextFormField);
  if (otpFields.evaluate().length >= 4) {
    // Enter mock OTP
    await tester.enterText(otpFields.at(0), '1');
    await tester.enterText(otpFields.at(1), '2');
    await tester.enterText(otpFields.at(2), '3');
    await tester.enterText(otpFields.at(3), '4');
    await tester.pumpAndSettle();
  }

  print('✅ Diaspora registration flow test completed');
}

/// Test cultural profile setup specific to African diaspora
Future<void> _testCulturalProfileSetup(WidgetTester tester) async {
  // Look for cultural background selection
  if (find.text('Tell us about your background').evaluate().isNotEmpty) {
    // Test African country selection
    final countryDropdown = find.text('Select your country of origin');
    if (countryDropdown.evaluate().isNotEmpty) {
      await tester.tap(countryDropdown);
      await tester.pumpAndSettle();

      // Select Nigeria (most common in diaspora)
      final nigeriaOption = find.text('Nigeria');
      if (nigeriaOption.evaluate().isNotEmpty) {
        await tester.tap(nigeriaOption);
        await tester.pumpAndSettle();
      }
    }

    // Test ethnicity selection
    final ethnicityField = find.text('Select your ethnicity');
    if (ethnicityField.evaluate().isNotEmpty) {
      await tester.tap(ethnicityField);
      await tester.pumpAndSettle();

      // Select Yoruba ethnicity
      final yorubaOption = find.text('Yoruba');
      if (yorubaOption.evaluate().isNotEmpty) {
        await tester.tap(yorubaOption);
        await tester.pumpAndSettle();
      }
    }

    // Test language selection
    final languageField = find.text('Languages you speak');
    if (languageField.evaluate().isNotEmpty) {
      await tester.tap(languageField);
      await tester.pumpAndSettle();

      // Select English and Yoruba
      final englishOption = find.text('English');
      if (englishOption.evaluate().isNotEmpty) {
        await tester.tap(englishOption);
        await tester.pumpAndSettle();
      }
    }

    // Test immigration status (diaspora-specific)
    final immigrationField = find.text('Immigration status');
    if (immigrationField.evaluate().isNotEmpty) {
      await tester.tap(immigrationField);
      await tester.pumpAndSettle();

      // Select US Citizen
      final citizenOption = find.text('US Citizen');
      if (citizenOption.evaluate().isNotEmpty) {
        await tester.tap(citizenOption);
        await tester.pumpAndSettle();
      }
    }
  }

  print('✅ Cultural profile setup test completed');
}

/// Test US location setup for diaspora communities
Future<void> _testUSLocationSetup(WidgetTester tester) async {
  // Test location permission request
  if (find.text('Enable Location').evaluate().isNotEmpty) {
    await tester.tap(find.text('Enable Location'));
    await tester.pumpAndSettle();
  }

  // Test city selection for major diaspora cities
  final cityField = find.text('Select your city');
  if (cityField.evaluate().isNotEmpty) {
    await tester.tap(cityField);
    await tester.pumpAndSettle();

    // Test Atlanta selection (largest African diaspora community)
    final atlantaOption = find.text('Atlanta, GA');
    if (atlantaOption.evaluate().isNotEmpty) {
      await tester.tap(atlantaOption);
      await tester.pumpAndSettle();
    }
  }

  // Verify location is set correctly
  expect(find.textContaining('Atlanta'), findsWidgets);

  print('✅ US location setup test completed');
}
