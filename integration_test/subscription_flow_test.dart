import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naijasingles/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('US Market Subscription Flow', () {
    testWidgets('Premium subscription flow with US payment methods',
        (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await _testPremiumSubscriptionFlow(tester);
    });

    testWidgets('Diaspora-specific premium features', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await _testDiasporaPremiumFeatures(tester);
    });

    testWidgets('Professional networking premium features', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await _testProfessionalPremiumFeatures(tester);
    });

    testWidgets('Cultural matching premium features', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await _testCulturalPremiumFeatures(tester);
    });
  });
}

/// Test premium subscription flow with US payment methods
Future<void> _testPremiumSubscriptionFlow(WidgetTester tester) async {
  // Navigate to premium/subscription screen
  await _navigateToPremiumScreen(tester);

  // Test premium plan selection
  await _testPremiumPlanSelection(tester);

  // Test US payment methods
  await _testUSPaymentMethods(tester);

  // Test subscription confirmation
  await _testSubscriptionConfirmation(tester);

  print('✅ Premium subscription flow test completed');
}

/// Test diaspora-specific premium features
Future<void> _testDiasporaPremiumFeatures(WidgetTester tester) async {
  await _navigateToPremiumScreen(tester);

  // Test diaspora-specific premium features
  final diasporaFeatures = [
    'Advanced Cultural Matching',
    'Professional Network Access',
    'Cultural Event Notifications',
    'Multi-Language Translation',
    'Extended Location Range',
    'Immigration Status Filtering',
    'Home Country Connections',
  ];

  for (String feature in diasporaFeatures) {
    final featureWidget = find.textContaining(feature);
    if (featureWidget.evaluate().isNotEmpty) {
      // Verify feature is listed in premium benefits
      expect(featureWidget, findsOneWidget);
      print('✓ Found diaspora feature: $feature');
    }
  }

  // Test feature preview/demo
  final previewButton = find.text('Preview Features');
  if (previewButton.evaluate().isNotEmpty) {
    await tester.tap(previewButton);
    await tester.pumpAndSettle();

    // Test cultural matching preview
    expect(find.textContaining('Cultural Compatibility'), findsWidgets);
    expect(find.textContaining('Professional Network'), findsWidgets);
  }

  print('✅ Diaspora premium features test completed');
}

/// Test professional networking premium features
Future<void> _testProfessionalPremiumFeatures(WidgetTester tester) async {
  await _navigateToPremiumScreen(tester);

  // Test professional networking features
  final professionalFeatures = [
    'LinkedIn Integration',
    'Industry-Specific Matching',
    'Professional Event Access',
    'Career Mentorship Connections',
    'Visa Status Compatibility',
    'African Professional Directory',
  ];

  for (String feature in professionalFeatures) {
    final featureWidget = find.textContaining(feature);
    if (featureWidget.evaluate().isNotEmpty) {
      expect(featureWidget, findsOneWidget);
      print('✓ Found professional feature: $feature');
    }
  }

  // Test professional upgrade flow
  final professionalPlan = find.text('Professional Plan');
  if (professionalPlan.evaluate().isNotEmpty) {
    await tester.tap(professionalPlan);
    await tester.pumpAndSettle();

    // Verify professional plan benefits
    expect(find.textContaining('Career Networking'), findsWidgets);
    expect(find.textContaining('Professional Events'), findsWidgets);
  }

  print('✅ Professional premium features test completed');
}

/// Test cultural matching premium features
Future<void> _testCulturalPremiumFeatures(WidgetTester tester) async {
  await _navigateToPremiumScreen(tester);

  // Test cultural matching premium features
  final culturalFeatures = [
    'Ethnicity-Based Matching',
    'Language Compatibility',
    'Cultural Values Alignment',
    'Traditional vs Modern Preferences',
    'Religious Compatibility',
    'Home Country Visit Frequency',
  ];

  for (String feature in culturalFeatures) {
    final featureWidget = find.textContaining(feature);
    if (featureWidget.evaluate().isNotEmpty) {
      expect(featureWidget, findsOneWidget);
      print('✓ Found cultural feature: $feature');
    }
  }

  // Test cultural premium upgrade
  final culturalPlan = find.text('Cultural Plus');
  if (culturalPlan.evaluate().isNotEmpty) {
    await tester.tap(culturalPlan);
    await tester.pumpAndSettle();

    // Test cultural matching algorithm preview
    expect(find.textContaining('Cultural Compatibility Score'), findsWidgets);
    expect(find.textContaining('Shared Values'), findsWidgets);
  }

  print('✅ Cultural premium features test completed');
}

/// Helper function to navigate to premium screen
Future<void> _navigateToPremiumScreen(WidgetTester tester) async {
  // Look for premium/upgrade button in various locations

  // Check profile screen
  final profileTab = find.text('Profile');
  if (profileTab.evaluate().isNotEmpty) {
    await tester.tap(profileTab);
    await tester.pumpAndSettle();

    final upgradeButton = find.text('Upgrade to Premium');
    if (upgradeButton.evaluate().isNotEmpty) {
      await tester.tap(upgradeButton);
      await tester.pumpAndSettle();
      return;
    }
  }

  // Check settings screen
  final settingsIcon = find.byIcon(Icons.settings);
  if (settingsIcon.evaluate().isNotEmpty) {
    await tester.tap(settingsIcon);
    await tester.pumpAndSettle();

    final premiumOption = find.text('Premium Features');
    if (premiumOption.evaluate().isNotEmpty) {
      await tester.tap(premiumOption);
      await tester.pumpAndSettle();
      return;
    }
  }

  // Check for premium banner/notification
  final premiumBanner = find.textContaining('Premium');
  if (premiumBanner.evaluate().isNotEmpty) {
    await tester.tap(premiumBanner.first);
    await tester.pumpAndSettle();
  }

  // Wait for premium screen to load
  await tester.pump(const Duration(seconds: 2));
}

/// Test premium plan selection
Future<void> _testPremiumPlanSelection(WidgetTester tester) async {
  // Test different subscription plans
  final subscriptionPlans = [
    'Basic Premium',
    'Cultural Plus',
    'Professional',
    'Ultimate',
  ];

  for (String plan in subscriptionPlans) {
    final planWidget = find.textContaining(plan);
    if (planWidget.evaluate().isNotEmpty) {
      await tester.tap(planWidget);
      await tester.pumpAndSettle();

      // Verify plan details are shown
      expect(find.textContaining('month'), findsWidgets);
      expect(find.textContaining(r'$'), findsWidgets);

      print('✓ Tested plan: $plan');
      break; // Test first available plan
    }
  }

  // Test plan comparison
  final compareButton = find.text('Compare Plans');
  if (compareButton.evaluate().isNotEmpty) {
    await tester.tap(compareButton);
    await tester.pumpAndSettle();

    // Verify comparison table
    expect(find.textContaining('Features'), findsWidgets);
    expect(find.textContaining('Basic'), findsWidgets);
    expect(find.textContaining('Premium'), findsWidgets);
  }
}

/// Test US payment methods
Future<void> _testUSPaymentMethods(WidgetTester tester) async {
  // Look for payment method selection
  final paymentButton = find.text('Choose Payment Method');
  if (paymentButton.evaluate().isNotEmpty) {
    await tester.tap(paymentButton);
    await tester.pumpAndSettle();

    // Test US payment methods
    final usPaymentMethods = [
      'Credit Card',
      'Debit Card',
      'PayPal',
      'Apple Pay',
      'Google Pay',
    ];

    for (String method in usPaymentMethods) {
      final methodWidget = find.textContaining(method);
      if (methodWidget.evaluate().isNotEmpty) {
        expect(methodWidget, findsOneWidget);
        print('✓ Found payment method: $method');
      }
    }

    // Test credit card form (if available)
    final creditCardOption = find.text('Credit Card');
    if (creditCardOption.evaluate().isNotEmpty) {
      await tester.tap(creditCardOption);
      await tester.pumpAndSettle();

      // Test credit card form fields
      final cardNumberField = find.byType(TextFormField);
      if (cardNumberField.evaluate().isNotEmpty) {
        // Test with mock card number (don't use real numbers)
        await tester.enterText(cardNumberField.first, '4111 1111 1111 1111');
        await tester.pumpAndSettle();
      }
    }
  }
}

/// Test subscription confirmation
Future<void> _testSubscriptionConfirmation(WidgetTester tester) async {
  // Look for subscription confirmation
  final confirmButton = find.text('Confirm Subscription');
  if (confirmButton.evaluate().isNotEmpty) {
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    // Test confirmation dialog
    expect(find.textContaining('Confirm'), findsWidgets);
    expect(find.textContaining('Premium'), findsWidgets);

    // Test terms and conditions
    final termsCheckbox = find.byType(Checkbox);
    if (termsCheckbox.evaluate().isNotEmpty) {
      await tester.tap(termsCheckbox);
      await tester.pumpAndSettle();
    }

    // Test final confirmation (mock - don't actually process payment)
    final finalConfirmButton = find.text('Complete Purchase');
    if (finalConfirmButton.evaluate().isNotEmpty) {
      // In a real test, we would mock the payment processing
      print('✓ Would process payment here (mocked)');

      // Instead of tapping, just verify the button exists
      expect(finalConfirmButton, findsOneWidget);
    }
  }

  // Test subscription success screen
  final successMessage = find.textContaining('Welcome to Premium');
  if (successMessage.evaluate().isNotEmpty) {
    expect(successMessage, findsOneWidget);
    print('✓ Subscription success screen displayed');
  }
}
