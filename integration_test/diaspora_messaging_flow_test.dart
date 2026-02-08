import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naijasingles/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('African Diaspora Messaging Flow', () {
    testWidgets('Cross-cultural messaging between African ethnicities',
        (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await _testCrossCulturalMessaging(tester);
    });

    testWidgets('Multi-language messaging support', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await _testMultiLanguageMessaging(tester);
    });

    testWidgets('Cultural context in conversations', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await _testCulturalContextMessaging(tester);
    });

    testWidgets('Professional networking conversations', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await _testProfessionalNetworkingChat(tester);
    });
  });
}

/// Test cross-cultural messaging between different African ethnicities
Future<void> _testCrossCulturalMessaging(WidgetTester tester) async {
  // Navigate to messages screen
  await _navigateToMessagesScreen(tester);

  // Look for existing conversations or create new match
  final conversationList = find.byType(ListTile);

  if (conversationList.evaluate().isNotEmpty) {
    // Tap on first conversation
    await tester.tap(conversationList.first);
    await tester.pumpAndSettle();

    // Test sending culturally aware messages
    await _testCulturalGreetings(tester);
    await _testCulturalTopics(tester);
  } else {
    // Create a test match first
    await _createTestMatch(tester);
  }

  print('✅ Cross-cultural messaging test completed');
}

/// Test multi-language messaging support
Future<void> _testMultiLanguageMessaging(WidgetTester tester) async {
  await _navigateToMessagesScreen(tester);

  // Enter chat conversation
  final chatTile = find.byType(ListTile).first;
  if (chatTile.evaluate().isNotEmpty) {
    await tester.tap(chatTile);
    await tester.pumpAndSettle();

    // Test English message
    await _sendMessage(tester, 'Hello! How are you doing?');

    // Test Yoruba greeting (if supported)
    await _sendMessage(tester, 'Bawo ni? (How are you in Yoruba)');

    // Test Igbo greeting (if supported)
    await _sendMessage(tester, 'Kedu? (How are you in Igbo)');

    // Test French greeting (for Francophone Africans)
    await _sendMessage(tester, 'Bonjour! Comment allez-vous?');

    // Test language translation feature (if available)
    final translateButton = find.byIcon(Icons.translate);
    if (translateButton.evaluate().isNotEmpty) {
      await tester.tap(translateButton);
      await tester.pumpAndSettle();
    }
  }

  print('✅ Multi-language messaging test completed');
}

/// Test cultural context in conversations
Future<void> _testCulturalContextMessaging(WidgetTester tester) async {
  await _navigateToMessagesScreen(tester);

  final chatTile = find.byType(ListTile).first;
  if (chatTile.evaluate().isNotEmpty) {
    await tester.tap(chatTile);
    await tester.pumpAndSettle();

    // Test cultural conversation starters
    final culturalTopics = [
      'What part of Nigeria are you from?',
      'Do you visit home often?',
      'What do you miss most about Africa?',
      'Are you involved in the African community here?',
      'What traditional foods do you cook?',
      'Do you speak your native language at home?',
    ];

    for (String topic in culturalTopics.take(3)) {
      await _sendMessage(tester, topic);
      await tester.pump(const Duration(milliseconds: 500));
    }

    // Test cultural emoji/reactions (if available)
    final emojiButton = find.byIcon(Icons.emoji_emotions);
    if (emojiButton.evaluate().isNotEmpty) {
      await tester.tap(emojiButton);
      await tester.pumpAndSettle();

      // Look for African flag emojis or cultural symbols
      final nigerianFlag = find.text('🇳🇬');
      if (nigerianFlag.evaluate().isNotEmpty) {
        await tester.tap(nigerianFlag);
        await tester.pumpAndSettle();
      }
    }
  }

  print('✅ Cultural context messaging test completed');
}

/// Test professional networking conversations
Future<void> _testProfessionalNetworkingChat(WidgetTester tester) async {
  await _navigateToMessagesScreen(tester);

  final chatTile = find.byType(ListTile).first;
  if (chatTile.evaluate().isNotEmpty) {
    await tester.tap(chatTile);
    await tester.pumpAndSettle();

    // Test professional conversation topics
    final professionalTopics = [
      'What field do you work in?',
      'How long have you been in the US?',
      'Are you part of any African professional organizations?',
      'What\'s your experience with visa sponsorship?',
      'Do you mentor other African professionals?',
    ];

    for (String topic in professionalTopics.take(2)) {
      await _sendMessage(tester, topic);
      await tester.pump(const Duration(milliseconds: 500));
    }

    // Test professional networking features
    final networkingButton = find.text('Professional Info');
    if (networkingButton.evaluate().isNotEmpty) {
      await tester.tap(networkingButton);
      await tester.pumpAndSettle();

      // Verify professional information is displayed
      expect(find.textContaining('LinkedIn'), findsWidgets);
      expect(find.textContaining('Industry'), findsWidgets);
    }

    // Test sharing professional events
    final shareEventButton = find.text('Share Event');
    if (shareEventButton.evaluate().isNotEmpty) {
      await tester.tap(shareEventButton);
      await tester.pumpAndSettle();

      // Look for African professional events
      expect(find.textContaining('African Professional'), findsWidgets);
    }
  }

  print('✅ Professional networking chat test completed');
}

/// Helper function to navigate to messages screen
Future<void> _navigateToMessagesScreen(WidgetTester tester) async {
  // Look for messages tab in bottom navigation
  final messagesTab = find.text('Messages');
  if (messagesTab.evaluate().isNotEmpty) {
    await tester.tap(messagesTab);
    await tester.pumpAndSettle();
  }

  // Alternative: look for chat icon
  final chatIcon = find.byIcon(Icons.chat);
  if (chatIcon.evaluate().isNotEmpty) {
    await tester.tap(chatIcon);
    await tester.pumpAndSettle();
  }

  // Wait for messages screen to load
  await tester.pump(const Duration(seconds: 2));
}

/// Helper function to send a message
Future<void> _sendMessage(WidgetTester tester, String message) async {
  // Find message input field
  final messageField = find.byType(TextField);
  if (messageField.evaluate().isNotEmpty) {
    await tester.enterText(messageField.last, message);
    await tester.pumpAndSettle();

    // Find and tap send button
    final sendButton = find.byIcon(Icons.send);
    if (sendButton.evaluate().isNotEmpty) {
      await tester.tap(sendButton);
      await tester.pumpAndSettle();
    }
  }
}

/// Helper function to test cultural greetings
Future<void> _testCulturalGreetings(WidgetTester tester) async {
  final greetings = [
    'Sannu! (Hello in Hausa)',
    'Ndewo! (Hello in Igbo)',
    'Bawo! (Hello in Yoruba)',
    'Habari! (Hello in Swahili)',
    'Selam! (Hello in Amharic)',
  ];

  for (String greeting in greetings.take(2)) {
    await _sendMessage(tester, greeting);
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// Helper function to test cultural conversation topics
Future<void> _testCulturalTopics(WidgetTester tester) async {
  final topics = [
    'What\'s your favorite African dish to cook?',
    'Do you celebrate traditional holidays?',
    'What do you think about raising kids with African values in America?',
    'Have you been to any African cultural events recently?',
  ];

  for (String topic in topics.take(2)) {
    await _sendMessage(tester, topic);
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// Helper function to create a test match (mock)
Future<void> _createTestMatch(WidgetTester tester) async {
  // This would typically involve going through the matching flow
  // For integration testing, we might need to mock this
  print('Creating test match for messaging flow...');

  // Navigate back to home to create a match
  final homeTab = find.text('Home');
  if (homeTab.evaluate().isNotEmpty) {
    await tester.tap(homeTab);
    await tester.pumpAndSettle();

    // Simulate a swipe right to create a match
    final swipeCard = find.byType(Card).first;
    if (swipeCard.evaluate().isNotEmpty) {
      await tester.drag(swipeCard, const Offset(300, 0));
      await tester.pumpAndSettle();
    }
  }
}
