import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naijasingles/firebase_options.dart';
import 'package:naijasingles/main.dart' as app;

/// Real-device launch routing harness for auth/onboarding.
///
/// Run one scenario at a time with:
/// flutter test integration_test/launch_routing_harness_test.dart \
///   --dart-define=PRESERVE_DEBUG_SESSION_FOR_E2E=true \
///   --dart-define=LAUNCH_STATE=fresh
///
/// Supported launch states:
/// - fresh
/// - stale
/// - incomplete
/// - complete
///
/// For incomplete/complete, provide credentials:
/// --dart-define=E2E_INCOMPLETE_EMAIL=... --dart-define=E2E_INCOMPLETE_PASSWORD=...
/// --dart-define=E2E_COMPLETE_EMAIL=... --dart-define=E2E_COMPLETE_PASSWORD=...
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const launchState = String.fromEnvironment(
    'LAUNCH_STATE',
    defaultValue: 'fresh',
  );

  const completeEmail = String.fromEnvironment('E2E_COMPLETE_EMAIL');
  const completePassword = String.fromEnvironment('E2E_COMPLETE_PASSWORD');
  const incompleteEmail = String.fromEnvironment('E2E_INCOMPLETE_EMAIL');
  const incompletePassword = String.fromEnvironment('E2E_INCOMPLETE_PASSWORD');

  group('Launch Routing Harness', () {
    testWidgets('launch state: $launchState', (WidgetTester tester) async {
      if (Firebase.apps.isEmpty) {
        try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        } on FirebaseException catch (e) {
          if (e.code != 'duplicate-app') {
            rethrow;
          }
        }
      }

      final auth = FirebaseAuth.instance;
      await auth.signOut();

      if (launchState == 'stale') {
        try {
          await auth.signInAnonymously();
        } on Object catch (e) {
          fail(
            'LAUNCH_STATE=stale requires anonymous auth enabled for this project. '
            'Error: $e',
          );
        }
      } else if (launchState == 'complete') {
        if (completeEmail.isEmpty || completePassword.isEmpty) {
          fail(
            'Missing E2E_COMPLETE_EMAIL/E2E_COMPLETE_PASSWORD '
            'for LAUNCH_STATE=complete.',
          );
        }
        await auth.signInWithEmailAndPassword(
          email: completeEmail,
          password: completePassword,
        );
      } else if (launchState == 'incomplete') {
        if (incompleteEmail.isEmpty || incompletePassword.isEmpty) {
          fail(
            'Missing E2E_INCOMPLETE_EMAIL/E2E_INCOMPLETE_PASSWORD '
            'for LAUNCH_STATE=incomplete.',
          );
        }
        await auth.signInWithEmailAndPassword(
          email: incompleteEmail,
          password: incompletePassword,
        );
      } else if (launchState != 'fresh') {
        fail(
          'Unsupported LAUNCH_STATE="$launchState". '
          'Use fresh|stale|incomplete|complete.',
        );
      }

      await app.main();
      await _pumpUntilSettled(tester, const Duration(seconds: 12));

      switch (launchState) {
        case 'fresh':
        case 'stale':
          expect(find.text('Create Account'), findsOneWidget);
          expect(find.text('Log in'), findsOneWidget);
          break;
        case 'incomplete':
          expect(find.text('Create Account'), findsNothing);
          expect(find.text('Log in'), findsNothing);
          expect(find.text('Next'), findsOneWidget);
          expect(_findAnyOnboardingHeader(), findsOneWidget);
          break;
        case 'complete':
          expect(find.text('Create Account'), findsNothing);
          expect(_findAnyMainTabLabel(), findsOneWidget);
          break;
      }
    });
  });
}

Finder _findAnyOnboardingHeader() => find.byWidgetPredicate((widget) {
      if (widget is! Text) return false;
      const candidates = <String>{
        'Basic Info',
        'Profile Photo',
        'Your Location',
        'Country & Identity',
        'Tell Your Story',
        'Your Interests',
        'Dating Preferences',
        'Additional Info',
      };
      return candidates.contains(widget.data);
    });

Finder _findAnyMainTabLabel() => find.byWidgetPredicate((widget) {
      if (widget is! Text) return false;
      const candidates = <String>{
        'Connect',
        'Discover',
        'Messages',
        'Profile',
      };
      return candidates.contains(widget.data);
    });

Future<void> _pumpUntilSettled(
  WidgetTester tester,
  Duration maxDuration,
) async {
  final end = DateTime.now().add(maxDuration);
  do {
    await tester.pump(const Duration(milliseconds: 250));
    if (!tester.binding.hasScheduledFrame) {
      await tester.pumpAndSettle(const Duration(milliseconds: 250));
      return;
    }
  } while (DateTime.now().isBefore(end));
}
