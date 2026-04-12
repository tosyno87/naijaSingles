import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/settings/widgets/notification_settings_panel.dart';
import 'package:naijasingles/services/settings_service.dart';

void main() {
  group('NotificationSettingsPanel', () {
    testWidgets('when Enable All is off, channel rows have no onChanged',
        (tester) async {
      final draft = NotificationSettings.defaultSettings().copyWith(
        enableAllNotifications: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationSettingsPanel(
              draft: draft,
              onDraftChanged: (_) {},
              isSaving: false,
              bottomInset: 0,
              onQuietHoursStart: () {},
              onQuietHoursEnd: () {},
            ),
          ),
        ),
      );

      final tiles = tester
          .widgetList<SwitchListTile>(
            find.byType(SwitchListTile),
          )
          .toList();

      // 0: Enable All, 1: Mute, 2–4: Matches/Messages/Likes, 5–6: Sound/Vibration,
      // 7: Quiet hours
      expect(tiles.length, greaterThanOrEqualTo(8));
      expect(tiles[2].onChanged, isNull, reason: 'New Matches');
      expect(tiles[3].onChanged, isNull, reason: 'New Messages');
      expect(tiles[4].onChanged, isNull, reason: 'New Likes');
      expect(tiles[5].onChanged, isNotNull, reason: 'Sound stays editable');
      expect(tiles[6].onChanged, isNotNull, reason: 'Vibration stays editable');
    });

    testWidgets('when Enable All is on, channel rows are interactive',
        (tester) async {
      final draft = NotificationSettings.defaultSettings();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationSettingsPanel(
              draft: draft,
              onDraftChanged: (_) {},
              isSaving: false,
              bottomInset: 0,
              onQuietHoursStart: () {},
              onQuietHoursEnd: () {},
            ),
          ),
        ),
      );

      final tiles = tester
          .widgetList<SwitchListTile>(
            find.byType(SwitchListTile),
          )
          .toList();

      expect(tiles[2].onChanged, isNotNull);
      expect(tiles[3].onChanged, isNotNull);
      expect(tiles[4].onChanged, isNotNull);
    });
  });
}
