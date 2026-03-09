import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:naijasingles/services/super_like_service.dart';

void main() {
  group('SuperLikeService constants', () {
    test('freeSuperLikesPerDay is 1', () {
      expect(SuperLikeService.freeSuperLikesPerDay, 1);
    });

    test('premiumSuperLikesPerDay is 5', () {
      expect(SuperLikeService.premiumSuperLikesPerDay, 5);
    });

    test('superLikeCooldown is 24 hours', () {
      expect(
        SuperLikeService.superLikeCooldown,
        const Duration(hours: 24),
      );
    });

    test('superLikeHighlightDuration is 3 days', () {
      expect(
        SuperLikeService.superLikeHighlightDuration,
        const Duration(days: 3),
      );
    });

    test('premium limit is strictly greater than free limit', () {
      expect(
        SuperLikeService.premiumSuperLikesPerDay,
        greaterThan(SuperLikeService.freeSuperLikesPerDay),
      );
    });
  });

  group('SuperLikeResult', () {
    test('success factory sets isSuccess to true', () {
      final result = SuperLikeResult.success(
        superLikeId: 'sl_123',
      );

      expect(result.isSuccess, isTrue);
      expect(result.superLikeId, 'sl_123');
      expect(result.isInstantMatch, isFalse);
      expect(result.matchId, isNull);
      expect(result.error, isNull);
    });

    test('success factory with instant match', () {
      final result = SuperLikeResult.success(
        superLikeId: 'sl_456',
        isInstantMatch: true,
        matchId: 'match_789',
      );

      expect(result.isSuccess, isTrue);
      expect(result.superLikeId, 'sl_456');
      expect(result.isInstantMatch, isTrue);
      expect(result.matchId, 'match_789');
    });

    test('failed factory sets isSuccess to false with error message', () {
      final result = SuperLikeResult.failed('Daily limit reached');

      expect(result.isSuccess, isFalse);
      expect(result.error, 'Daily limit reached');
      expect(result.superLikeId, isNull);
      expect(result.isInstantMatch, isFalse);
    });

    test('toString includes key fields', () {
      final result = SuperLikeResult.failed('some error');
      final str = result.toString();

      expect(str, contains('success: false'));
      expect(str, contains('some error'));
    });
  });

  group('SuperLikeResponse', () {
    test('success factory defaults to no match', () {
      final response = SuperLikeResponse.success();

      expect(response.isSuccess, isTrue);
      expect(response.isMatch, isFalse);
      expect(response.matchId, isNull);
      expect(response.error, isNull);
    });

    test('success factory with match', () {
      final response = SuperLikeResponse.success(
        isMatch: true,
        matchId: 'match_abc',
      );

      expect(response.isSuccess, isTrue);
      expect(response.isMatch, isTrue);
      expect(response.matchId, 'match_abc');
    });

    test('failed factory sets isSuccess to false', () {
      final response = SuperLikeResponse.failed('Not found');

      expect(response.isSuccess, isFalse);
      expect(response.error, 'Not found');
      expect(response.isMatch, isFalse);
    });

    test('toString includes key fields', () {
      final response = SuperLikeResponse.success(isMatch: true);
      final str = response.toString();

      expect(str, contains('success: true'));
      expect(str, contains('match: true'));
    });
  });

  group('SuperLikeEligibility', () {
    test('canSend true with remaining count', () {
      final eligibility = SuperLikeEligibility(
        canSend: true,
        remainingCount: 3,
        nextResetTime: DateTime(2026, 3, 5),
      );

      expect(eligibility.canSend, isTrue);
      expect(eligibility.remainingCount, 3);
      expect(eligibility.reason, isNull);
    });

    test('canSend false includes reason', () {
      final eligibility = SuperLikeEligibility(
        canSend: false,
        reason: 'Daily super like limit reached (1/1)',
        remainingCount: 0,
        nextResetTime: DateTime(2026, 3, 5),
      );

      expect(eligibility.canSend, isFalse);
      expect(eligibility.reason, contains('Daily super like limit'));
      expect(eligibility.remainingCount, 0);
    });

    test('timeUntilReset returns duration until nextResetTime', () {
      final futureReset = DateTime.now().add(const Duration(hours: 12));
      final eligibility = SuperLikeEligibility(
        canSend: true,
        remainingCount: 1,
        nextResetTime: futureReset,
      );

      expect(eligibility.timeUntilReset.inHours, closeTo(12, 1));
    });

    test('toString includes key fields', () {
      final eligibility = SuperLikeEligibility(
        canSend: true,
        remainingCount: 2,
        nextResetTime: DateTime(2026, 3, 5),
      );
      final str = eligibility.toString();

      expect(str, contains('canSend: true'));
      expect(str, contains('remaining: 2'));
    });
  });

  group('SuperLikeStats', () {
    test('constructor sets all fields', () {
      final stats = SuperLikeStats(
        sentCount: 10,
        receivedCount: 5,
        dailyUsedCount: 2,
        dailyLimit: 5,
        responseRate: 0.8,
        matchRate: 0.4,
        isPremium: true,
        nextResetTime: DateTime(2026, 3, 5),
      );

      expect(stats.sentCount, 10);
      expect(stats.receivedCount, 5);
      expect(stats.dailyUsedCount, 2);
      expect(stats.dailyLimit, 5);
      expect(stats.responseRate, 0.8);
      expect(stats.matchRate, 0.4);
      expect(stats.isPremium, isTrue);
    });

    test('remainingToday calculates correctly', () {
      final stats = SuperLikeStats(
        sentCount: 0,
        receivedCount: 0,
        dailyUsedCount: 3,
        dailyLimit: 5,
        responseRate: 0,
        matchRate: 0,
        isPremium: true,
        nextResetTime: DateTime(2026, 3, 5),
      );

      expect(stats.remainingToday, 2);
    });

    test('remainingToday clamps to zero when usage exceeds limit', () {
      final stats = SuperLikeStats(
        sentCount: 0,
        receivedCount: 0,
        dailyUsedCount: 7,
        dailyLimit: 5,
        responseRate: 0,
        matchRate: 0,
        isPremium: true,
        nextResetTime: DateTime(2026, 3, 5),
      );

      expect(stats.remainingToday, 0);
    });

    test('canSendMore is true when remaining > 0', () {
      final stats = SuperLikeStats(
        sentCount: 0,
        receivedCount: 0,
        dailyUsedCount: 0,
        dailyLimit: 1,
        responseRate: 0,
        matchRate: 0,
        isPremium: false,
        nextResetTime: DateTime(2026, 3, 5),
      );

      expect(stats.canSendMore, isTrue);
    });

    test('canSendMore is false when limit reached', () {
      final stats = SuperLikeStats(
        sentCount: 0,
        receivedCount: 0,
        dailyUsedCount: 1,
        dailyLimit: 1,
        responseRate: 0,
        matchRate: 0,
        isPremium: false,
        nextResetTime: DateTime(2026, 3, 5),
      );

      expect(stats.canSendMore, isFalse);
    });

    group('empty factory', () {
      test('creates stats with zero counts', () {
        final stats = SuperLikeStats.empty();

        expect(stats.sentCount, 0);
        expect(stats.receivedCount, 0);
        expect(stats.dailyUsedCount, 0);
        expect(stats.responseRate, 0);
        expect(stats.matchRate, 0);
        expect(stats.isPremium, isFalse);
      });

      test('uses free daily limit', () {
        final stats = SuperLikeStats.empty();

        expect(
          stats.dailyLimit,
          SuperLikeService.freeSuperLikesPerDay,
        );
      });

      test('remainingToday equals full free limit', () {
        final stats = SuperLikeStats.empty();

        expect(
          stats.remainingToday,
          SuperLikeService.freeSuperLikesPerDay,
        );
        expect(stats.canSendMore, isTrue);
      });
    });

    test('toString includes formatted stats', () {
      final stats = SuperLikeStats(
        sentCount: 3,
        receivedCount: 2,
        dailyUsedCount: 1,
        dailyLimit: 5,
        responseRate: 0.5,
        matchRate: 0.25,
        isPremium: true,
        nextResetTime: DateTime(2026, 3, 5),
      );
      final str = stats.toString();

      expect(str, contains('Sent: 3'));
      expect(str, contains('Received: 2'));
      expect(str, contains('Daily Used: 1/5'));
      expect(str, contains('50.0%'));
      expect(str, contains('25.0%'));
      expect(str, contains('Premium: true'));
    });
  });

  group('SuperLike model', () {
    test('constructor sets all required fields', () {
      final now = DateTime.now();
      final highlight = now.add(const Duration(days: 3));
      final superLike = SuperLike(
        id: 'sl_1',
        fromUserId: 'user_a',
        toUserId: 'user_b',
        fromUserName: 'Alice',
        fromUserImageUrl: 'https://example.com/alice.jpg',
        toUserName: 'Bob',
        timestamp: now,
        isActive: true,
        responded: false,
        highlightUntil: highlight,
      );

      expect(superLike.id, 'sl_1');
      expect(superLike.fromUserId, 'user_a');
      expect(superLike.toUserId, 'user_b');
      expect(superLike.fromUserName, 'Alice');
      expect(superLike.fromUserImageUrl, 'https://example.com/alice.jpg');
      expect(superLike.toUserName, 'Bob');
      expect(superLike.timestamp, now);
      expect(superLike.isActive, isTrue);
      expect(superLike.responded, isFalse);
      expect(superLike.responseType, isNull);
      expect(superLike.respondedAt, isNull);
      expect(superLike.highlightUntil, highlight);
    });

    test('isHighlighted returns true when highlightUntil is in the future', () {
      final superLike = SuperLike(
        id: 'sl_1',
        fromUserId: 'a',
        toUserId: 'b',
        fromUserName: 'A',
        fromUserImageUrl: '',
        toUserName: 'B',
        timestamp: DateTime.now(),
        isActive: true,
        responded: false,
        highlightUntil: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(superLike.isHighlighted, isTrue);
    });

    test('isHighlighted returns false when highlightUntil is in the past', () {
      final superLike = SuperLike(
        id: 'sl_1',
        fromUserId: 'a',
        toUserId: 'b',
        fromUserName: 'A',
        fromUserImageUrl: '',
        toUserName: 'B',
        timestamp: DateTime.now(),
        isActive: true,
        responded: false,
        highlightUntil: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(superLike.isHighlighted, isFalse);
    });

    test('isHighlighted returns false when highlightUntil is null', () {
      final superLike = SuperLike(
        id: 'sl_1',
        fromUserId: 'a',
        toUserId: 'b',
        fromUserName: 'A',
        fromUserImageUrl: '',
        toUserName: 'B',
        timestamp: DateTime.now(),
        isActive: true,
        responded: false,
      );

      expect(superLike.isHighlighted, isFalse);
    });

    test('wasLikedBack returns true when responseType is "like"', () {
      final superLike = SuperLike(
        id: 'sl_1',
        fromUserId: 'a',
        toUserId: 'b',
        fromUserName: 'A',
        fromUserImageUrl: '',
        toUserName: 'B',
        timestamp: DateTime.now(),
        isActive: true,
        responded: true,
        responseType: 'like',
      );

      expect(superLike.wasLikedBack, isTrue);
      expect(superLike.wasPassed, isFalse);
    });

    test('wasPassed returns true when responseType is "pass"', () {
      final superLike = SuperLike(
        id: 'sl_1',
        fromUserId: 'a',
        toUserId: 'b',
        fromUserName: 'A',
        fromUserImageUrl: '',
        toUserName: 'B',
        timestamp: DateTime.now(),
        isActive: true,
        responded: true,
        responseType: 'pass',
      );

      expect(superLike.wasPassed, isTrue);
      expect(superLike.wasLikedBack, isFalse);
    });

    test('fromDocument parses Firestore document correctly', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final now = DateTime.now();
      final highlightUntil = now.add(const Duration(days: 3));

      await fakeFirestore.collection('superLikes').doc('sl_test').set({
        'fromUserId': 'user_a',
        'toUserId': 'user_b',
        'fromUserName': 'Alice',
        'fromUserImageUrl': 'https://example.com/photo.jpg',
        'toUserName': 'Bob',
        'timestamp': Timestamp.fromDate(now),
        'isActive': true,
        'responded': true,
        'responseType': 'like',
        'respondedAt': Timestamp.fromDate(now),
        'highlightUntil': Timestamp.fromDate(highlightUntil),
      });

      final doc =
          await fakeFirestore.collection('superLikes').doc('sl_test').get();
      final superLike = SuperLike.fromDocument(doc);

      expect(superLike.id, 'sl_test');
      expect(superLike.fromUserId, 'user_a');
      expect(superLike.toUserId, 'user_b');
      expect(superLike.fromUserName, 'Alice');
      expect(superLike.fromUserImageUrl, 'https://example.com/photo.jpg');
      expect(superLike.toUserName, 'Bob');
      expect(superLike.isActive, isTrue);
      expect(superLike.responded, isTrue);
      expect(superLike.responseType, 'like');
      expect(superLike.wasLikedBack, isTrue);
    });

    test('fromDocument handles missing optional fields gracefully', () async {
      final fakeFirestore = FakeFirebaseFirestore();

      await fakeFirestore.collection('superLikes').doc('sl_sparse').set({
        'fromUserId': 'user_x',
        'toUserId': 'user_y',
      });

      final doc =
          await fakeFirestore.collection('superLikes').doc('sl_sparse').get();
      final superLike = SuperLike.fromDocument(doc);

      expect(superLike.id, 'sl_sparse');
      expect(superLike.fromUserId, 'user_x');
      expect(superLike.toUserId, 'user_y');
      expect(superLike.fromUserName, '');
      expect(superLike.fromUserImageUrl, '');
      expect(superLike.toUserName, '');
      expect(superLike.isActive, isFalse);
      expect(superLike.responded, isFalse);
      expect(superLike.responseType, isNull);
      expect(superLike.respondedAt, isNull);
      expect(superLike.highlightUntil, isNull);
    });

    test('toString includes user names and status', () {
      final superLike = SuperLike(
        id: 'sl_1',
        fromUserId: 'a',
        toUserId: 'b',
        fromUserName: 'Alice',
        fromUserImageUrl: '',
        toUserName: 'Bob',
        timestamp: DateTime.now(),
        isActive: true,
        responded: true,
      );
      final str = superLike.toString();

      expect(str, contains('Alice'));
      expect(str, contains('Bob'));
      expect(str, contains('responded: true'));
      expect(str, contains('active: true'));
    });
  });
}
