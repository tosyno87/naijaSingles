import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/common/widgets/state_views/state_views.dart';
import 'package:naijasingles/features/group_chat/screens/group_chat_screen.dart';
import '../../../helpers/firebase_widget_setup.dart';

void main() {
  setUpAll(() async {
    await setupFirebaseForWidgetTests();
  });

  testWidgets('GroupChatScreen renders shared state view contract', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: GroupChatScreen(groupId: 'group-1')),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final sharedStateViews = find.byWidgetPredicate(
      (w) => w is AppLoadingView || w is AppEmptyView || w is AppErrorView,
    );
    expect(sharedStateViews, findsWidgets);
  });
}
