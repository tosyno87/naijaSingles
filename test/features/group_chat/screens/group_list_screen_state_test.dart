import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/common/widgets/state_views/state_views.dart';
import 'package:naijasingles/features/group_chat/screens/group_list_screen.dart';
import '../../../helpers/firebase_widget_setup.dart';

void main() {
  setUpAll(() async {
    await setupFirebaseForWidgetTests();
  });

  testWidgets('GroupListScreen shows AppEmptyView when user has no groups', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: GroupListScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppEmptyView), findsOneWidget);
  });
}
