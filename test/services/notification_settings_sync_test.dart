import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/services/settings_service.dart';

void main() {
  late FakeFirebaseFirestore fake;

  setUp(() {
    fake = FakeFirebaseFirestore();
    SettingsService.firestoreForTesting = fake;
  });

  tearDown(() {
    SettingsService.firestoreForTesting = null;
  });

  test(
    'updateNotificationSettings mirrors notificationPreferences from notificationSettings',
    () async {
      const userId = 'user_sync_1';
      final settings = NotificationSettings.defaultSettings().copyWith(
        matchNotifications: false,
        messageNotifications: true,
        likeNotifications: false,
        enableAllNotifications: true,
        muteAllNotifications: true,
      );

      await fake.collection('users').doc(userId).set({'displayName': 'Test'});

      final ok =
          await SettingsService.updateNotificationSettings(userId, settings);
      expect(ok, isTrue);

      final ns =
          await fake.collection('notificationSettings').doc(userId).get();
      expect(ns.exists, isTrue);
      final nsData = ns.data()!;
      expect(nsData['matchNotifications'], false);
      expect(nsData['muteAllNotifications'], true);
      expect(nsData['superLikeNotifications'], false);

      final userDoc = await fake.collection('users').doc(userId).get();
      final prefs =
          userDoc.data()!['notificationPreferences'] as Map<String, dynamic>;

      expect(
        prefs,
        settings.normalizedForPersist().toNotificationPreferencesMap(),
      );
    },
  );

  test(
    'getNotificationSettings backfills master keys on notificationSettings and user doc',
    () async {
      const userId = 'user_backfill_1';
      await fake.collection('notificationSettings').doc(userId).set({
        'matchNotifications': true,
        'messageNotifications': false,
        'likeNotifications': true,
        'superLikeNotifications': true,
        'soundEnabled': true,
        'vibrationEnabled': true,
        'quietHoursStart': '22:00',
        'quietHoursEnd': '08:00',
        'quietHoursEnabled': false,
      });
      await fake.collection('users').doc(userId).set({'name': 'Legacy'});

      final loaded = await SettingsService.getNotificationSettings(userId);
      expect(loaded.enableAllNotifications, true);
      expect(loaded.muteAllNotifications, false);

      final ns =
          await fake.collection('notificationSettings').doc(userId).get();
      expect(ns.data()!.containsKey('enableAllNotifications'), isTrue);
      expect(ns.data()!.containsKey('muteAllNotifications'), isTrue);

      final userDoc = await fake.collection('users').doc(userId).get();
      final prefs =
          userDoc.data()!['notificationPreferences'] as Map<String, dynamic>;
      expect(prefs['enableAllNotifications'], true);
      expect(prefs['muteAllNotifications'], false);
    },
  );

  test(
    'getNotificationSettings backfills user.notificationPreferences when settings doc is complete',
    () async {
      const userId = 'user_backfill_2';
      await fake
          .collection('notificationSettings')
          .doc(userId)
          .set(NotificationSettings.defaultSettings().toMap());
      await fake.collection('users').doc(userId).set({
        'notificationPreferences': {
          'matchNotifications': false,
        },
      });

      await SettingsService.getNotificationSettings(userId);

      final userDoc = await fake.collection('users').doc(userId).get();
      final prefs =
          userDoc.data()!['notificationPreferences'] as Map<String, dynamic>;
      expect(prefs.containsKey('enableAllNotifications'), isTrue);
      expect(prefs.containsKey('muteAllNotifications'), isTrue);
      // Mirrored from notificationSettings (canonical), not the partial user map.
      expect(prefs['matchNotifications'], true);
    },
  );
}
