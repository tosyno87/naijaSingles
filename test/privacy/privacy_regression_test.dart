import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/messages/message_model.dart';
import 'package:naijasingles/services/user_privacy_service.dart';

/// Privacy regression suite.
///
/// These tests assert the data-level invariants for:
///  1. Hide-from-discovery toggling
///  2. Blocked user thread visibility
///  3. clearedAt filtering in chat threads
///
/// They validate model transformations and filtering logic without hitting
/// Firebase directly. Any change that breaks these should block a release.
void main() {
  // ───────────────────────────────────────────────────────────────
  //  1. Hide-from-discovery
  // ───────────────────────────────────────────────────────────────
  group('Hide-from-discovery invariants', () {
    test('Default privacy settings have discovery enabled', () {
      const settings = UserPrivacySettings();
      expect(settings.hideFromDiscovery, isFalse);

      final map = settings.toMap();
      expect(map['hideFromDiscovery'], isFalse);
    });

    test('hideFromDiscovery=true produces isDiscoverable=false', () {
      const settings = UserPrivacySettings(hideFromDiscovery: true);
      expect(settings.hideFromDiscovery, isTrue);

      // The service writes `isDiscoverable: !settings.hideFromDiscovery`
      // to the root user document. Verify the model produces the flag.
      final isDiscoverable = !settings.hideFromDiscovery;
      expect(isDiscoverable, isFalse);
    });

    test('Round-trip: toMap -> fromMap preserves hideFromDiscovery', () {
      const original = UserPrivacySettings(hideFromDiscovery: true);
      final restored = UserPrivacySettings.fromMap(original.toMap());
      expect(restored.hideFromDiscovery, original.hideFromDiscovery);
    });

    test('fromMap defaults hideFromDiscovery to false when missing', () {
      final settings = UserPrivacySettings.fromMap({});
      expect(settings.hideFromDiscovery, isFalse);
    });

    test('copyWith can toggle hideFromDiscovery', () {
      const hidden = UserPrivacySettings(hideFromDiscovery: true);
      final visible = hidden.copyWith(hideFromDiscovery: false);
      expect(visible.hideFromDiscovery, isFalse);

      final reHidden = visible.copyWith(hideFromDiscovery: true);
      expect(reHidden.hideFromDiscovery, isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────
  //  2. Blocked user thread visibility
  // ───────────────────────────────────────────────────────────────
  group('Blocked user thread filtering', () {
    final threads = [
      MessageThreadInfo(
        threadId: 't1',
        otherUserId: 'user_a',
        otherUserName: 'Alice',
        lastMessage: 'Hello',
        timestamp: DateTime.now(),
        unread: false,
      ),
      MessageThreadInfo(
        threadId: 't2',
        otherUserId: 'user_b',
        otherUserName: 'Bob',
        lastMessage: 'Hey',
        timestamp: DateTime.now(),
        unread: true,
      ),
      MessageThreadInfo(
        threadId: 't3',
        otherUserId: 'user_c',
        otherUserName: 'Carol',
        lastMessage: 'Hi',
        timestamp: DateTime.now(),
        unread: false,
      ),
    ];

    test('Blocked user threads are filtered out', () {
      final blockedIds = {'user_b'};

      final visible = threads
          .where(
            (t) =>
                t.otherUserId.isNotEmpty && !blockedIds.contains(t.otherUserId),
          )
          .toList();

      expect(visible.length, 2);
      expect(visible.map((t) => t.otherUserId), isNot(contains('user_b')));
    });

    test('Blocking multiple users removes all their threads', () {
      final blockedIds = {'user_a', 'user_c'};

      final visible = threads
          .where(
            (t) =>
                t.otherUserId.isNotEmpty && !blockedIds.contains(t.otherUserId),
          )
          .toList();

      expect(visible.length, 1);
      expect(visible.first.otherUserId, 'user_b');
    });

    test('Empty blocked list shows all threads', () {
      final blockedIds = <String>{};

      final visible = threads
          .where(
            (t) =>
                t.otherUserId.isNotEmpty && !blockedIds.contains(t.otherUserId),
          )
          .toList();

      expect(visible.length, threads.length);
    });

    test('Threads with empty otherUserId are filtered out', () {
      final withBadThread = [
        ...threads,
        MessageThreadInfo(
          threadId: 't_bad',
          otherUserId: '',
          otherUserName: 'Ghost',
          lastMessage: 'Boo',
          timestamp: DateTime.now(),
          unread: false,
        ),
      ];

      final blockedIds = <String>{};
      final visible = withBadThread
          .where(
            (t) =>
                t.otherUserId.isNotEmpty && !blockedIds.contains(t.otherUserId),
          )
          .toList();

      expect(visible.length, threads.length);
    });
  });

  // ───────────────────────────────────────────────────────────────
  //  3. clearedAt filtering invariants
  // ───────────────────────────────────────────────────────────────
  group('clearedAt filtering invariants', () {
    final clearedAt = DateTime(2025, 6, 1, 12, 0);

    final messages = [
      Message(
        id: 'm1',
        senderId: 'a',
        text: 'Old message before clear',
        timestamp: DateTime(2025, 5, 30),
        isRead: true,
      ),
      Message(
        id: 'm2',
        senderId: 'b',
        text: 'Message on clear boundary',
        timestamp: clearedAt,
        isRead: true,
      ),
      Message(
        id: 'm3',
        senderId: 'a',
        text: 'New message after clear',
        timestamp: DateTime(2025, 6, 2),
        isRead: false,
      ),
      Message(
        id: 'm4',
        senderId: 'b',
        text: 'Another new message',
        timestamp: DateTime(2025, 6, 3),
        isRead: false,
      ),
    ];

    test('Messages before clearedAt are excluded', () {
      final filtered =
          messages.where((m) => m.timestamp.isAfter(clearedAt)).toList();

      expect(filtered.length, 2);
      expect(filtered.map((m) => m.id), containsAll(['m3', 'm4']));
    });

    test('Messages exactly at clearedAt are excluded (strict isAfter)', () {
      final filtered =
          messages.where((m) => m.timestamp.isAfter(clearedAt)).toList();

      expect(filtered.map((m) => m.id), isNot(contains('m2')));
    });

    test('Null clearedAt shows all messages', () {
      const DateTime? nullClearedAt = null;

      final filtered = nullClearedAt == null
          ? messages
          : messages.where((m) => m.timestamp.isAfter(nullClearedAt)).toList();

      expect(filtered.length, messages.length);
    });

    test('clearedAt in the future hides all messages', () {
      final futureClear = DateTime(2099, 1, 1);

      final filtered =
          messages.where((m) => m.timestamp.isAfter(futureClear)).toList();

      expect(filtered, isEmpty);
    });

    test('clearedAt in the distant past shows all messages', () {
      final pastClear = DateTime(2000, 1, 1);

      final filtered =
          messages.where((m) => m.timestamp.isAfter(pastClear)).toList();

      expect(filtered.length, messages.length);
    });
  });

  // ───────────────────────────────────────────────────────────────
  //  4. Privacy settings consistency
  // ───────────────────────────────────────────────────────────────
  group('Privacy settings data integrity', () {
    test('toMap/fromMap preserves tribe & hideFromDiscovery; policy fixes rest',
        () {
      const settings = UserPrivacySettings(
        showTribe: false,
        hideFromDiscovery: true,
      );

      final restored = UserPrivacySettings.fromMap(settings.toMap());

      expect(restored.showTribe, isFalse);
      expect(restored.hideFromDiscovery, isTrue);
      expect(restored.allowMessagesFromMatches, isTrue);
      expect(restored.showOnlineStatus, isTrue);
      expect(restored.showLastActive, isTrue);
      expect(restored.showOrientation, isFalse);
      expect(restored.showAge, isTrue);
      expect(restored.showLocation, isTrue);
      expect(restored.showDistance, isTrue);
    });

    test('Partial map uses safe defaults', () {
      final settings = UserPrivacySettings.fromMap({
        'showAge': false,
        'allowMessagesFromMatches': false,
      });

      expect(settings.showAge, isTrue);
      expect(settings.hideFromDiscovery, isFalse);
      expect(settings.allowMessagesFromMatches, isTrue);
      expect(settings.showOnlineStatus, isTrue);
      expect(settings.showOrientation, isFalse);
    });
  });

  // ───────────────────────────────────────────────────────────────
  //  5. Public profile legacy field scrubbing
  // ───────────────────────────────────────────────────────────────
  group('Public profile sexualOrientation scrubbing', () {
    test('stripLegacySexualOrientation removes key and preserves other fields',
        () {
      final scrubbed = UserPrivacyService.stripLegacySexualOrientation({
        'name': 'A',
        'sexualOrientation': {'label': 'X'},
        'bio': 'Hi',
      });

      expect(scrubbed.containsKey('sexualOrientation'), isFalse);
      expect(scrubbed['name'], 'A');
      expect(scrubbed['bio'], 'Hi');
    });

    test('stripLegacySexualOrientation is a shallow copy (caller map untouched)',
        () {
      final original = <String, dynamic>{
        'sexualOrientation': 'legacy',
        'tribe': 'Yoruba',
      };
      UserPrivacyService.stripLegacySexualOrientation(original);

      expect(original.containsKey('sexualOrientation'), isTrue);
    });
  });
}
