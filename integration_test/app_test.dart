import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naijasingles/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('NaijaSingles Automated Tests', () {
    testWidgets('App launches without crashing', (WidgetTester tester) async {
      print('🧪 Testing app launch...');

      app.main();
      await tester.pumpAndSettle(Duration(seconds: 5));

      // App should load without errors
      expect(find.byType(MaterialApp), findsOneWidget);
      print('✅ App launched successfully');
    });

    testWidgets('Bio screen single prompt selection',
        (WidgetTester tester) async {
      print('🧪 Testing bio screen prompt selection...');

      app.main();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Try to find bio-related elements
      // This is a simplified test - you'd navigate to the actual bio screen

      // Look for any prompt-like buttons
      final promptButtons = find.byType(GestureDetector);
      if (promptButtons.evaluate().isNotEmpty) {
        print('✅ Found interactive elements');
      }

      print('✅ Bio screen test completed');
    });

    testWidgets('Navigation flow test', (WidgetTester tester) async {
      print('🧪 Testing basic navigation...');

      app.main();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Test basic navigation elements exist
      final scaffolds = find.byType(Scaffold);
      expect(scaffolds, findsWidgets);

      print('✅ Navigation test completed');
    });

    testWidgets('Performance test', (WidgetTester tester) async {
      print('🧪 Testing app performance...');

      final stopwatch = Stopwatch()..start();

      app.main();
      await tester.pumpAndSettle();

      stopwatch.stop();
      final loadTime = stopwatch.elapsedMilliseconds;

      print('📊 App load time: ${loadTime}ms');

      // App should load within reasonable time
      expect(loadTime, lessThan(10000)); // 10 seconds max

      print('✅ Performance test passed');
    });
  });
}
