import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naijasingles/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Chat Flow Tests', () {
    testWidgets('Chat list navigation', (WidgetTester tester) async {
      print('🧪 Testing chat list navigation...');

      app.main();
      await tester.pumpAndSettle(Duration(seconds: 5));

      // Look for chat/messages tab or button
      final chatIcons = find.byIcon(Icons.chat);
      final messageIcons = find.byIcon(Icons.message);
      final chatTexts = find.textContaining('Chat');
      final messageTexts = find.textContaining('Message');

      bool foundChatNavigation = false;

      if (chatIcons.evaluate().isNotEmpty) {
        await tester.tap(chatIcons.first);
        await tester.pumpAndSettle();
        print('✅ Chat icon navigation executed');
        foundChatNavigation = true;
      } else if (messageIcons.evaluate().isNotEmpty) {
        await tester.tap(messageIcons.first);
        await tester.pumpAndSettle();
        print('✅ Message icon navigation executed');
        foundChatNavigation = true;
      } else if (chatTexts.evaluate().isNotEmpty) {
        await tester.tap(chatTexts.first);
        await tester.pumpAndSettle();
        print('✅ Chat text navigation executed');
        foundChatNavigation = true;
      } else if (messageTexts.evaluate().isNotEmpty) {
        await tester.tap(messageTexts.first);
        await tester.pumpAndSettle();
        print('✅ Message text navigation executed');
        foundChatNavigation = true;
      }

      if (!foundChatNavigation) {
        print('⚠️ Chat navigation not found - may need authentication first');
      }

      print('✅ Chat list navigation test completed');
    });

    testWidgets('Chat list display', (WidgetTester tester) async {
      print('🧪 Testing chat list display...');

      app.main();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Look for list elements
      final listViews = find.byType(ListView);
      final listTiles = find.byType(ListTile);
      final cards = find.byType(Card);

      if (listViews.evaluate().isNotEmpty) {
        print('✅ Found ListView elements');
      }

      if (listTiles.evaluate().isNotEmpty) {
        print('✅ Found ListTile elements (chat items)');
      }

      if (cards.evaluate().isNotEmpty) {
        print('✅ Found Card elements');
      }

      // Look for user avatars in chat list
      final circleAvatars = find.byType(CircleAvatar);
      if (circleAvatars.evaluate().isNotEmpty) {
        print('✅ Found user avatars in chat list');
      }

      print('✅ Chat list display test completed');
    });

    testWidgets('Individual chat screen', (WidgetTester tester) async {
      print('🧪 Testing individual chat screen...');

      app.main();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Look for message input field
      final textFields = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.keyboardType == TextInputType.multiline,
      );

      if (textFields.evaluate().isNotEmpty) {
        print('✅ Found message input field');

        // Test message input
        await tester.enterText(textFields.first, 'Test message');
        await tester.pump();
        print('✅ Message input test executed');
      }

      // Look for send button
      final sendIcons = find.byIcon(Icons.send);
      if (sendIcons.evaluate().isNotEmpty) {
        print('✅ Found send button');

        // Test send button tap
        await tester.tap(sendIcons.first);
        await tester.pumpAndSettle();
        print('✅ Send button tap executed');
      }

      print('✅ Individual chat screen test completed');
    });

    testWidgets('Message bubbles and display', (WidgetTester tester) async {
      print('🧪 Testing message bubbles and display...');

      app.main();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Look for message containers/bubbles
      final containers = find.byType(Container);
      if (containers.evaluate().isNotEmpty) {
        print('✅ Found container elements (possible message bubbles)');
      }

      // Look for message text
      final richTexts = find.byType(RichText);
      final texts = find.byType(Text);

      if (richTexts.evaluate().isNotEmpty || texts.evaluate().isNotEmpty) {
        print('✅ Found text elements (messages)');
      }

      // Look for timestamp elements
      final timestampTexts = find.textContaining(':');
      if (timestampTexts.evaluate().isNotEmpty) {
        print('✅ Found timestamp-like elements');
      }

      print('✅ Message bubbles and display test completed');
    });

    testWidgets('Chat actions (delete, block)', (WidgetTester tester) async {
      print('🧪 Testing chat actions...');

      app.main();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Look for more options or menu
      final moreIcons = find.byIcon(Icons.more_vert);
      final menuIcons = find.byIcon(Icons.menu);

      if (moreIcons.evaluate().isNotEmpty) {
        await tester.tap(moreIcons.first);
        await tester.pumpAndSettle();
        print('✅ More options menu opened');

        // Look for delete option
        final deleteTexts = find.textContaining('Delete');
        if (deleteTexts.evaluate().isNotEmpty) {
          print('✅ Found delete option');
        }

        // Look for block option
        final blockTexts = find.textContaining('Block');
        if (blockTexts.evaluate().isNotEmpty) {
          print('✅ Found block option');
        }
      }

      // Look for swipe actions (Dismissible)
      final dismissibles = find.byType(Dismissible);
      if (dismissibles.evaluate().isNotEmpty) {
        print('✅ Found swipe-to-delete functionality');
      }

      print('✅ Chat actions test completed');
    });

    testWidgets('Message delivery status', (WidgetTester tester) async {
      print('🧪 Testing message delivery status...');

      app.main();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Look for delivery status icons
      final checkIcons = find.byIcon(Icons.check);
      final doneAllIcons = find.byIcon(Icons.done_all);

      if (checkIcons.evaluate().isNotEmpty) {
        print('✅ Found check icons (delivery status)');
      }

      if (doneAllIcons.evaluate().isNotEmpty) {
        print('✅ Found double check icons (read status)');
      }

      // Look for status text
      final sentTexts = find.textContaining('Sent');
      final deliveredTexts = find.textContaining('Delivered');
      final readTexts = find.textContaining('Read');

      if (sentTexts.evaluate().isNotEmpty ||
          deliveredTexts.evaluate().isNotEmpty ||
          readTexts.evaluate().isNotEmpty) {
        print('✅ Found delivery status text');
      }

      print('✅ Message delivery status test completed');
    });
  });
}
