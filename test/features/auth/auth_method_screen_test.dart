import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/auth/auth_method/auth_method_selection_screen.dart';
import 'package:naijasingles/features/auth/auth_method/sign_in_method_selection_screen.dart';

/// Widget tests ensuring supported auth screens expose only Google + Phone
/// (no Apple, no Email). Prevents regression if legacy options are re-added.
void main() {
  group('Auth method screens — Google + Phone only', () {
    testWidgets('AuthMethodSelectionScreen shows only Google and Phone',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const AuthMethodSelectionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Continue with Phone'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);

      // No legacy options (only Google + Phone are supported)
      expect(find.text('Continue with Apple'), findsNothing);
      expect(find.text('Continue with Email'), findsNothing);
    });

    testWidgets('SignInMethodSelectionScreen shows only Google and Phone',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const SignInMethodSelectionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Continue with Phone'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);

      // No legacy options (only Google + Phone are supported)
      expect(find.text('Continue with Apple'), findsNothing);
      expect(find.text('Continue with Email'), findsNothing);
    });
  });
}
