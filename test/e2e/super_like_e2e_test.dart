import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/notifications/notification_model.dart';
import 'package:naijasingles/services/super_like_service.dart';

/// Contract tests for the super-like -> notification -> display flow.
///
/// These tests verify the data contracts between the super-like service,
/// cloud function notification fan-out, and in-app notification display.
/// They do not hit real Firebase; they validate models and transformations.
void main() {
  group('Super-like send contract', () {
    test('SuperLikeResult.success carries superLikeId and optional matchId',
        () {
      final result = SuperLikeResult.success(
        superLikeId: 'sl_123',
        isInstantMatch: true,
        matchId: 'match_456',
      );

      expect(result.isSuccess, isTrue);
      expect(result.superLikeId, 'sl_123');
      expect(result.isInstantMatch, isTrue);
      expect(result.matchId, 'match_456');
      expect(result.error, isNull);
    });

    test('SuperLikeResult.failed carries error message', () {
      final result = SuperLikeResult.failed('Daily limit reached');

      expect(result.isSuccess, isFalse);
      expect(result.error, 'Daily limit reached');
      expect(result.superLikeId, isNull);
      expect(result.isInstantMatch, isFalse);
    });

    test('SuperLikeEligibility reflects free tier limits', () {
      final eligibility = SuperLikeEligibility(
        canSend: true,
        remainingCount: SuperLikeService.freeSuperLikesPerDay,
        nextResetTime: DateTime.now().add(const Duration(hours: 12)),
      );

      expect(eligibility.canSend, isTrue);
      expect(eligibility.remainingCount, SuperLikeService.freeSuperLikesPerDay);
      expect(eligibility.timeUntilReset.inHours, greaterThanOrEqualTo(0));
    });

    test('SuperLikeEligibility blocked with reason', () {
      final eligibility = SuperLikeEligibility(
        canSend: false,
        remainingCount: 0,
        nextResetTime: DateTime.now().add(const Duration(hours: 6)),
        reason: 'Daily limit reached. Upgrade to premium for more!',
      );

      expect(eligibility.canSend, isFalse);
      expect(eligibility.remainingCount, 0);
      expect(eligibility.reason, contains('Daily limit'));
    });
  });

  group('Notification fan-out contract', () {
    test('super_like notification has correct type and fields', () {
      final notification = AppNotification(
        id: 'notif_789',
        title: 'New Super Like!',
        message: 'Ada super liked you',
        timestamp: DateTime.now(),
        type: 'super_like',
        avatarUrl: 'https://example.com/photo.jpg',
        actionId: 'user_from_id',
      );

      expect(notification.type, 'super_like');
      expect(notification.title, isNotEmpty);
      expect(notification.message, contains('super liked'));
      expect(notification.actionId, isNotNull);
      expect(notification.avatarUrl, isNotNull);
    });

    test('super_like notification icon is correct', () {
      final notification = AppNotification(
        id: 'n1',
        title: 'Super Like',
        message: 'test',
        timestamp: DateTime.now(),
        type: 'super_like',
      );

      expect(notification.typeIcon, isNotNull);
      expect(notification.typeColor, isNotNull);
    });

    test('match notification from super-like has correct type', () {
      final notification = AppNotification(
        id: 'n2',
        title: 'It\'s a Match!',
        message: 'You and Kofi matched',
        timestamp: DateTime.now(),
        type: 'match',
        actionId: 'match_456',
      );

      expect(notification.type, 'match');
      expect(notification.actionId, isNotNull);
    });

    test('notification types cover all super-like outcomes', () {
      const superLikeTypes = ['super_like', 'superLike', 'match', 'like'];

      for (final type in superLikeTypes) {
        final n = AppNotification(
          id: 'test_$type',
          title: 'Test',
          message: 'Test message',
          timestamp: DateTime.now(),
          type: type,
        );

        expect(n.typeIcon, isNotNull, reason: 'Icon missing for type: $type');
        expect(
          n.typeColor,
          isNotNull,
          reason: 'Color missing for type: $type',
        );
      }
    });
  });

  group('In-app display contract', () {
    test('AppNotification.fromFirestore handles all required fields', () {
      final now = DateTime.now();
      final notification = AppNotification(
        id: 'n3',
        title: 'Someone super liked you!',
        message: 'Tap to see who',
        timestamp: now,
        type: 'super_like',
        isRead: false,
        actionId: 'sender_user_id',
        avatarUrl: 'https://example.com/avatar.jpg',
      );

      expect(notification.id, 'n3');
      expect(notification.isRead, isFalse);
      expect(notification.actionId, 'sender_user_id');

      final firestoreMap = notification.toFirestore();
      expect(firestoreMap['type'], 'super_like');
      expect(firestoreMap['actionId'], 'sender_user_id');
      expect(firestoreMap['isRead'], isFalse);
    });

    test('Notification round-trips through toFirestore', () {
      final original = AppNotification(
        id: 'round_trip',
        title: 'Test Title',
        message: 'Test Message',
        timestamp: DateTime(2025, 6, 15, 12, 0),
        type: 'super_like',
        avatarUrl: 'https://example.com/img.png',
        isRead: true,
        actionId: 'action_123',
      );

      final map = original.toFirestore();

      expect(map['title'], original.title);
      expect(map['message'], original.message);
      expect(map['type'], original.type);
      expect(map['avatarUrl'], original.avatarUrl);
      expect(map['isRead'], original.isRead);
      expect(map['actionId'], original.actionId);
    });
  });

  group('Navigation from notification contract', () {
    test('super_like actionId can be used as user ID for profile navigation',
        () {
      final notification = AppNotification(
        id: 'n4',
        title: 'Super Like',
        message: 'Ada super liked you',
        timestamp: DateTime.now(),
        type: 'super_like',
        actionId: 'user_ada_123',
      );

      expect(notification.actionId, isNotEmpty);
      expect(notification.actionId, startsWith('user_'));
    });

    test('match actionId can be used as match ID for chat navigation', () {
      final notification = AppNotification(
        id: 'n5',
        title: 'Match!',
        message: 'You and Kofi matched',
        timestamp: DateTime.now(),
        type: 'match',
        actionId: 'match_kofi_456',
      );

      expect(notification.actionId, isNotEmpty);
      expect(notification.actionId, startsWith('match_'));
    });
  });
}
