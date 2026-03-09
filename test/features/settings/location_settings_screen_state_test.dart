import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/common/widgets/state_views/state_views.dart';
import 'package:naijasingles/features/settings/location_settings_screen.dart';
import '../../helpers/firebase_widget_setup.dart';

void main() {
  setUpAll(() async {
    await setupFirebaseForWidgetTests();
  });

  testWidgets('LocationSettingsScreen shows AppErrorView for no auth', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: LocationSettingsScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppErrorView), findsOneWidget);
  });
}
