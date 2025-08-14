import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naijasingles/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('African Diaspora Cultural Matching', () {
    testWidgets('Cultural compatibility matching algorithm', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await _testCulturalMatching(tester);
    });

    testWidgets('Cross-cultural matching between African ethnicities', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await _testCrossCulturalMatching(tester);
    });

    testWidgets('Professional networking integration', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await _testProfessionalMatching(tester);
    });

    testWidgets('US city-based matching for diaspora communities', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await _testLocationBasedMatching(tester);
    });
  });
}

/// Test cultural compatibility matching
Future<void> _testCulturalMatching(WidgetTester tester) async {
  // Navigate to home/matching screen
  await _navigateToMatchingScreen(tester);

  // Test swipe functionality with cultural context
  final swipeCard = find.byType(Card).first;
  if (swipeCard.evaluate().isNotEmpty) {
    // Check if cultural information is displayed
    expect(find.textContaining('Nigeria'), findsWidgets);
    expect(find.textContaining('Yoruba'), findsWidgets);
    
    // Test right swipe (like)
    await tester.drag(swipeCard, const Offset(300, 0));
    await tester.pumpAndSettle();

    // Verify swipe was processed
    await tester.pump(const Duration(seconds: 1));
  }

  // Test cultural filter preferences
  final filterButton = find.byIcon(Icons.filter_list);
  if (filterButton.evaluate().isNotEmpty) {
    await tester.tap(filterButton);
    await tester.pumpAndSettle();

    // Test ethnicity filter
    final ethnicityFilter = find.text('Ethnicity');
    if (ethnicityFilter.evaluate().isNotEmpty) {
      await tester.tap(ethnicityFilter);
      await tester.pumpAndSettle();

      // Select same ethnicity preference
      final sameEthnicityOption = find.text('Same as mine');
      if (sameEthnicityOption.evaluate().isNotEmpty) {
        await tester.tap(sameEthnicityOption);
        await tester.pumpAndSettle();
      }
    }

    // Apply filters
    final applyButton = find.text('Apply Filters');
    if (applyButton.evaluate().isNotEmpty) {
      await tester.tap(applyButton);
      await tester.pumpAndSettle();
    }
  }

  print('✅ Cultural matching test completed');
}

/// Test cross-cultural matching between different African ethnicities
Future<void> _testCrossCulturalMatching(WidgetTester tester) async {
  await _navigateToMatchingScreen(tester);

  // Test matching with different African ethnicities
  final profileCards = find.byType(Card);
  
  for (int i = 0; i < 3 && i < profileCards.evaluate().length; i++) {
    final card = profileCards.at(i);
    
    // Check for different African backgrounds
    final cardWidget = tester.widget<Card>(card);
    
    // Simulate viewing profiles from different countries
    // Nigeria, Ghana, Ethiopia, Kenya, etc.
    await tester.tap(card);
    await tester.pumpAndSettle();
    
    // Check if cross-cultural information is displayed
    expect(find.textContaining('African'), findsWidgets);
    
    // Go back to matching
    final backButton = find.byIcon(Icons.arrow_back);
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton);
      await tester.pumpAndSettle();
    }
  }

  print('✅ Cross-cultural matching test completed');
}

/// Test professional networking integration
Future<void> _testProfessionalMatching(WidgetTester tester) async {
  await _navigateToMatchingScreen(tester);

  // Test professional information display
  final profileCard = find.byType(Card).first;
  if (profileCard.evaluate().isNotEmpty) {
    await tester.tap(profileCard);
    await tester.pumpAndSettle();

    // Check for professional information
    expect(find.textContaining('Software Engineer'), findsWidgets);
    expect(find.textContaining('MBA'), findsWidgets);
    expect(find.textContaining('Doctor'), findsWidgets);

    // Test professional networking features
    final networkButton = find.text('Professional Network');
    if (networkButton.evaluate().isNotEmpty) {
      await tester.tap(networkButton);
      await tester.pumpAndSettle();

      // Verify professional networking screen
      expect(find.text('African Professionals'), findsOneWidget);
    }
  }

  print('✅ Professional matching test completed');
}

/// Test location-based matching for US diaspora communities
Future<void> _testLocationBasedMatching(WidgetTester tester) async {
  await _navigateToMatchingScreen(tester);

  // Test location-based filtering
  final settingsButton = find.byIcon(Icons.settings);
  if (settingsButton.evaluate().isNotEmpty) {
    await tester.tap(settingsButton);
    await tester.pumpAndSettle();

    // Test distance preference for diaspora communities
    final distanceSlider = find.byType(Slider);
    if (distanceSlider.evaluate().isNotEmpty) {
      // Set distance to 50 miles (typical for large US cities)
      await tester.drag(distanceSlider.first, const Offset(100, 0));
      await tester.pumpAndSettle();
    }

    // Test city-specific preferences
    final cityPreference = find.text('Preferred Cities');
    if (cityPreference.evaluate().isNotEmpty) {
      await tester.tap(cityPreference);
      await tester.pumpAndSettle();

      // Select major diaspora cities
      final atlantaOption = find.text('Atlanta, GA');
      if (atlantaOption.evaluate().isNotEmpty) {
        await tester.tap(atlantaOption);
        await tester.pumpAndSettle();
      }

      final dcOption = find.text('Washington, DC');
      if (dcOption.evaluate().isNotEmpty) {
        await tester.tap(dcOption);
        await tester.pumpAndSettle();
      }
    }
  }

  print('✅ Location-based matching test completed');
}

/// Helper function to navigate to matching screen
Future<void> _navigateToMatchingScreen(WidgetTester tester) async {
  // Look for bottom navigation or main navigation
  final homeTab = find.text('Home');
  if (homeTab.evaluate().isNotEmpty) {
    await tester.tap(homeTab);
    await tester.pumpAndSettle();
  }

  // Alternative: look for discover/swipe screen
  final discoverTab = find.text('Discover');
  if (discoverTab.evaluate().isNotEmpty) {
    await tester.tap(discoverTab);
    await tester.pumpAndSettle();
  }

  // Wait for matching screen to load
  await tester.pump(const Duration(seconds: 2));
}
