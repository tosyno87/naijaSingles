import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/auth/welcome/welcome_screen.dart';

void main() {
  group('WelcomeScreen', () {
    testWidgets('shows Create Account and Log in when not authenticated',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);
    });

    testWidgets('Create Account opens auth-method picker (phone and Google)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Continue with phone'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Already have an account? '), findsOneWidget);
    });
  });
}
