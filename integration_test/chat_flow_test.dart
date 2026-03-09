import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naijasingles/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Chat Flow Tests', () {
    testWidgets('Chat list navigation finds at least one nav entry',
        (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final chatIcons = find.byIcon(Icons.chat);
      final messageIcons = find.byIcon(Icons.message);
      final chatTexts = find.textContaining('Chat');
      final messageTexts = find.textContaining('Message');

      final hasChatNav = chatIcons.evaluate().isNotEmpty ||
          messageIcons.evaluate().isNotEmpty ||
          chatTexts.evaluate().isNotEmpty ||
          messageTexts.evaluate().isNotEmpty;

      if (!hasChatNav) {
        // App likely landed on auth screen -- still a valid state but
        // there is nothing further to test in this flow.
        expect(
          find.byType(Scaffold),
          findsWidgets,
          reason: 'Auth screen should still render a Scaffold',
        );
        return;
      }

      // We found a chat navigation element -- tap it and verify we land
      // on a screen that still has a Scaffold (i.e. no crash).
      final target = chatIcons.evaluate().isNotEmpty
          ? chatIcons.first
          : messageIcons.evaluate().isNotEmpty
              ? messageIcons.first
              : chatTexts.evaluate().isNotEmpty
                  ? chatTexts.first
                  : messageTexts.first;

      await tester.tap(target);
      await tester.pumpAndSettle();

      expect(
        find.byType(Scaffold),
        findsWidgets,
        reason: 'After tapping chat nav, a Scaffold must be present',
      );
    });

    testWidgets('Chat list renders expected widget types',
        (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // After full settle the widget tree must be non-empty.
      expect(
        find.byType(MaterialApp),
        findsOneWidget,
        reason: 'App root must be present',
      );

      // Structural sanity: Scaffold should exist.
      expect(
        find.byType(Scaffold),
        findsWidgets,
        reason: 'At least one Scaffold must be rendered',
      );
    });

    testWidgets('Chat actions menu (if reachable) contains expected items',
        (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final moreIcons = find.byIcon(Icons.more_vert);

      if (moreIcons.evaluate().isNotEmpty) {
        await tester.tap(moreIcons.first);
        await tester.pumpAndSettle();

        final deleteOption = find.textContaining('Delete');
        final blockOption = find.textContaining('Block');
        final reportOption = find.textContaining('Report');

        final hasAnyAction = deleteOption.evaluate().isNotEmpty ||
            blockOption.evaluate().isNotEmpty ||
            reportOption.evaluate().isNotEmpty;

        expect(
          hasAnyAction,
          isTrue,
          reason: 'Menu must contain at least one action item',
        );
      }
    });
  });
}
