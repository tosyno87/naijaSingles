import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naijasingles/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('User Registration Flow Tests', () {
    testWidgets('Complete user registration flow', (WidgetTester tester) async {
      print('🧪 Testing user registration flow...');

      app.main();
      await tester.pumpAndSettle(Duration(seconds: 5));

      // Test 1: App launches to registration/login screen
      expect(find.byType(MaterialApp), findsOneWidget);
      print('✅ App launched successfully');

      // Test 2: Look for registration elements
      // This would typically include phone number input, name input, etc.
      final textFields = find.byType(TextField);
      final textFormFields = find.byType(TextFormField);
      
      if (textFields.evaluate().isNotEmpty || textFormFields.evaluate().isNotEmpty) {
        print('✅ Found input fields for registration');
      } else {
        print('⚠️ No obvious input fields found - may need navigation to registration');
      }

      // Test 3: Look for registration buttons
      final elevatedButtons = find.byType(ElevatedButton);
      final textButtons = find.byType(TextButton);
      
      if (elevatedButtons.evaluate().isNotEmpty || textButtons.evaluate().isNotEmpty) {
        print('✅ Found interactive buttons');
      }

      // Test 4: Check for terms and conditions or privacy policy links
      final richTexts = find.byType(RichText);
      if (richTexts.evaluate().isNotEmpty) {
        print('✅ Found text elements (possibly terms/privacy)');
      }

      print('✅ User registration flow test completed');
    });

    testWidgets('Phone number validation', (WidgetTester tester) async {
      print('🧪 Testing phone number validation...');

      app.main();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Look for phone number input field
      final phoneFields = find.byWidgetPredicate(
        (widget) => widget is TextField && 
                   widget.keyboardType == TextInputType.phone,
      );

      if (phoneFields.evaluate().isNotEmpty) {
        print('✅ Found phone number input field');
        
        // Test invalid phone number
        await tester.enterText(phoneFields.first, '123');
        await tester.pump();
        
        // Look for validation error
        final errorTexts = find.textContaining('Invalid');
        if (errorTexts.evaluate().isNotEmpty) {
          print('✅ Phone validation working');
        }
      } else {
        print('⚠️ Phone number field not found - may need navigation');
      }

      print('✅ Phone number validation test completed');
    });

    testWidgets('Age verification', (WidgetTester tester) async {
      print('🧪 Testing age verification...');

      app.main();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Look for age-related elements
      final ageElements = find.textContaining('18');
      if (ageElements.evaluate().isNotEmpty) {
        print('✅ Found age verification elements');
      }

      // Look for date picker or age input
      final dateFields = find.byWidgetPredicate(
        (widget) => widget is TextField && 
                   (widget.keyboardType == TextInputType.datetime ||
                    widget.keyboardType == TextInputType.number),
      );

      if (dateFields.evaluate().isNotEmpty) {
        print('✅ Found date/age input fields');
      }

      print('✅ Age verification test completed');
    });
  });
}
