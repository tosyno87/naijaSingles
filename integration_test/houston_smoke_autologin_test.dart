import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naijasingles/main.dart' as app;

/// Device smoke for Houston Discover after ENABLE_AUTO_LOGIN.
///
/// Run:
/// flutter test integration_test/houston_smoke_autologin_test.dart \
///   -d <device> \
///   --dart-define=ENV=production \
///   --dart-define=ENABLE_AUTO_LOGIN=true \
///   --dart-define=TEST_EMAIL=... \
///   --dart-define=TEST_PASSWORD=... \
///   --dart-define=PRESERVE_DEBUG_SESSION_FOR_E2E=true
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Houston smoke: Discover then Connect and Messages', (
    WidgetTester tester,
  ) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 8));

    // Discover home copy (Houston-first).
    expect(find.textContaining('Houston'), findsWidgets);
    expect(find.text('Discover'), findsWidgets);

    // Switch to Connect (Explore / swipe deck).
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.text('Connect'), findsWidgets);

    // Switch to Messages.
    await tester.tap(find.text('Messages'));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.text('Messages'), findsWidgets);

    // Back to Discover.
    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.textContaining('Houston'), findsWidgets);
  });
}
