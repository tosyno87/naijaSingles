import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/settings/discovery_preferences_screen.dart';

import '../../helpers/firebase_widget_setup.dart';

void main() {
  setUpAll(() async {
    await setupFirebaseForWidgetTests();
  });

  testWidgets('DiscoveryPreferencesScreen shows title and main sections',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DiscoveryPreferencesScreen()),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Discovery Preferences'), findsOneWidget);
    expect(find.text('Show me'), findsOneWidget);
    expect(find.text('Maximum distance'), findsOneWidget);
    expect(find.text('Age range'), findsOneWidget);
  });
}
