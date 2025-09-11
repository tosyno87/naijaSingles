import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naijasingles/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Matching Flow Tests', () {
    testWidgets('Swipe card functionality', (WidgetTester tester) async {
      print('🧪 Testing swipe card functionality...');

      app.main();
      await tester.pumpAndSettle(Duration(seconds: 5));

      // Look for swipeable cards
      final gestureDetectors = find.byType(GestureDetector);
      final dismissibles = find.byType(Dismissible);
      
      if (gestureDetectors.evaluate().isNotEmpty) {
        print('✅ Found interactive gesture elements');
        
        // Test swipe gesture
        if (gestureDetectors.evaluate().isNotEmpty) {
          await tester.drag(gestureDetectors.first, Offset(-300, 0));
          await tester.pumpAndSettle();
          print('✅ Left swipe gesture executed');
          
          await tester.drag(gestureDetectors.first, Offset(300, 0));
          await tester.pumpAndSettle();
          print('✅ Right swipe gesture executed');
        }
      }

      if (dismissibles.evaluate().isNotEmpty) {
        print('✅ Found dismissible cards');
      }

      print('✅ Swipe card functionality test completed');
    });

    testWidgets('Like and dislike buttons', (WidgetTester tester) async {
      print('🧪 Testing like and dislike buttons...');

      app.main();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Look for like/dislike buttons (typically with heart/X icons)
      final heartIcons = find.byIcon(Icons.favorite);
      final closeIcons = find.byIcon(Icons.close);
      final thumbUpIcons = find.byIcon(Icons.thumb_up);
      final thumbDownIcons = find.byIcon(Icons.thumb_down);

      bool foundLikeButton = false;
      bool foundDislikeButton = false;

      if (heartIcons.evaluate().isNotEmpty || thumbUpIcons.evaluate().isNotEmpty) {
        print('✅ Found like button');
        foundLikeButton = true;
      }

      if (closeIcons.evaluate().isNotEmpty || thumbDownIcons.evaluate().isNotEmpty) {
        print('✅ Found dislike button');
        foundDislikeButton = true;
      }

      // Test button interactions
      if (foundLikeButton && heartIcons.evaluate().isNotEmpty) {
        await tester.tap(heartIcons.first);
        await tester.pumpAndSettle();
        print('✅ Like button tap executed');
      }

      if (foundDislikeButton && closeIcons.evaluate().isNotEmpty) {
        await tester.tap(closeIcons.first);
        await tester.pumpAndSettle();
        print('✅ Dislike button tap executed');
      }

      print('✅ Like and dislike buttons test completed');
    });

    testWidgets('Match notification', (WidgetTester tester) async {
      print('🧪 Testing match notification...');

      app.main();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Look for match-related UI elements
      final matchTexts = find.textContaining('Match');
      final congratsTexts = find.textContaining('Congrat');
      
      if (matchTexts.evaluate().isNotEmpty || congratsTexts.evaluate().isNotEmpty) {
        print('✅ Found match-related text elements');
      }

      // Look for match dialog or popup
      final dialogs = find.byType(Dialog);
      final alertDialogs = find.byType(AlertDialog);
      
      if (dialogs.evaluate().isNotEmpty || alertDialogs.evaluate().isNotEmpty) {
        print('✅ Found dialog elements (possible match popup)');
      }

      print('✅ Match notification test completed');
    });

    testWidgets('User profile view', (WidgetTester tester) async {
      print('🧪 Testing user profile view...');

      app.main();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Look for profile images
      final images = find.byType(Image);
      final circleAvatars = find.byType(CircleAvatar);
      
      if (images.evaluate().isNotEmpty) {
        print('✅ Found image elements');
      }

      if (circleAvatars.evaluate().isNotEmpty) {
        print('✅ Found avatar elements');
      }

      // Look for user information
      final listTiles = find.byType(ListTile);
      final cards = find.byType(Card);
      
      if (listTiles.evaluate().isNotEmpty || cards.evaluate().isNotEmpty) {
        print('✅ Found structured information elements');
      }

      // Test profile interaction (tap to view details)
      if (images.evaluate().isNotEmpty) {
        await tester.tap(images.first);
        await tester.pumpAndSettle();
        print('✅ Profile image tap executed');
      }

      print('✅ User profile view test completed');
    });

    testWidgets('Filter and preferences', (WidgetTester tester) async {
      print('🧪 Testing filter and preferences...');

      app.main();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Look for filter/settings icons
      final filterIcons = find.byIcon(Icons.filter_list);
      final settingsIcons = find.byIcon(Icons.settings);
      final tuneIcons = find.byIcon(Icons.tune);

      if (filterIcons.evaluate().isNotEmpty || 
          settingsIcons.evaluate().isNotEmpty || 
          tuneIcons.evaluate().isNotEmpty) {
        print('✅ Found filter/settings elements');
        
        // Test filter interaction
        if (filterIcons.evaluate().isNotEmpty) {
          await tester.tap(filterIcons.first);
          await tester.pumpAndSettle();
          print('✅ Filter button tap executed');
        }
      }

      // Look for sliders (age range, distance)
      final sliders = find.byType(Slider);
      final rangeSliders = find.byType(RangeSlider);
      
      if (sliders.evaluate().isNotEmpty || rangeSliders.evaluate().isNotEmpty) {
        print('✅ Found slider elements for preferences');
      }

      print('✅ Filter and preferences test completed');
    });
  });
}
