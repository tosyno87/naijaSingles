import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/match/data/services/likes_service.dart';
import 'package:naijasingles/features/match/models/match_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  // ===========================================================================
  // MatchModel – constructor
  // ===========================================================================
  group('MatchModel – constructor', () {
    test('stores all required and optional fields', () {
      final now = DateTime(2024, 1, 15, 12, 0);
      final model = MatchModel(
        id: 'match1',
        users: ['userA', 'userB'],
        matchedAt: now,
        matchStatus: 'matched',
        chatThreadId: 'chat1',
      );

      expect(model.id, 'match1');
      expect(model.users, ['userA', 'userB']);
      expect(model.matchedAt, now);
      expect(model.matchStatus, 'matched');
      expect(model.chatThreadId, 'chat1');
    });

    test('chatThreadId defaults to null when omitted', () {
      final model = MatchModel(
        id: 'match1',
        users: ['userA'],
        matchedAt: DateTime(2024),
        matchStatus: 'matched',
      );

      expect(model.chatThreadId, isNull);
    });

    test('accepts an empty users list without error', () {
      final model = MatchModel(
        id: 'match1',
        users: [],
        matchedAt: DateTime(2024),
        matchStatus: 'matched',
      );

      expect(model.users, isEmpty);
    });
  });

  // ===========================================================================
  // MatchModel – toMap()
  // ===========================================================================
  group('MatchModel – toMap()', () {
    test('includes users, matchedAt, and matchStatus keys', () {
      final model = MatchModel(
        id: 'match1',
        users: ['userA', 'userB'],
        matchedAt: DateTime.now(),
        matchStatus: 'matched',
        chatThreadId: 'chat1',
      );

      final map = model.toMap();

      expect(map, containsPair('users', ['userA', 'userB']));
      expect(map, containsPair('matchStatus', 'matched'));
      expect(map, containsPair('chatThreadId', 'chat1'));
      expect(map, contains('matchedAt'));
    });

    test('omits chatThreadId key when value is null', () {
      final model = MatchModel(
        id: 'match1',
        users: ['userA', 'userB'],
        matchedAt: DateTime.now(),
        matchStatus: 'matched',
      );

      final map = model.toMap();

      expect(map.containsKey('chatThreadId'), isFalse);
      expect(map.keys, containsAll(['users', 'matchedAt', 'matchStatus']));
    });

    test('does not include the model id field in the map', () {
      final model = MatchModel(
        id: 'match1',
        users: ['userA'],
        matchedAt: DateTime.now(),
        matchStatus: 'matched',
      );

      expect(model.toMap().containsKey('id'), isFalse);
    });

    test('matchedAt value is a FieldValue server timestamp', () {
      final model = MatchModel(
        id: 'match1',
        users: ['userA'],
        matchedAt: DateTime.now(),
        matchStatus: 'matched',
      );

      expect(model.toMap()['matchedAt'], isA<FieldValue>());
    });

    test('preserves users list ordering', () {
      final model = MatchModel(
        id: 'match1',
        users: ['z_user', 'a_user', 'm_user'],
        matchedAt: DateTime.now(),
        matchStatus: 'matched',
      );

      expect(model.toMap()['users'], ['z_user', 'a_user', 'm_user']);
    });

    test('map has exactly 3 keys when chatThreadId is null', () {
      final model = MatchModel(
        id: 'match1',
        users: ['userA'],
        matchedAt: DateTime.now(),
        matchStatus: 'matched',
      );

      expect(model.toMap().length, 3);
    });

    test('map has exactly 4 keys when chatThreadId is present', () {
      final model = MatchModel(
        id: 'match1',
        users: ['userA'],
        matchedAt: DateTime.now(),
        matchStatus: 'matched',
        chatThreadId: 'thread1',
      );

      expect(model.toMap().length, 4);
    });
  });

  // ===========================================================================
  // MatchModel – copyWith()
  // ===========================================================================
  group('MatchModel – copyWith()', () {
    late MatchModel original;

    setUp(() {
      original = MatchModel(
        id: 'match1',
        users: ['userA', 'userB'],
        matchedAt: DateTime(2024, 1, 15),
        matchStatus: 'matched',
        chatThreadId: 'chat1',
      );
    });

    test('replaces only the specified fields', () {
      final updated = original.copyWith(
        matchStatus: 'unmatched',
        chatThreadId: 'chat2',
      );

      expect(updated.id, 'match1');
      expect(updated.users, ['userA', 'userB']);
      expect(updated.matchedAt, DateTime(2024, 1, 15));
      expect(updated.matchStatus, 'unmatched');
      expect(updated.chatThreadId, 'chat2');
    });

    test('with no arguments returns an equivalent model', () {
      final copy = original.copyWith();
      expect(copy, equals(original));
    });

    test('can replace id', () {
      expect(original.copyWith(id: 'new_id').id, 'new_id');
    });

    test('can replace users list', () {
      final updated = original.copyWith(users: ['u1', 'u2', 'u3']);
      expect(updated.users, ['u1', 'u2', 'u3']);
    });

    test('can replace matchedAt', () {
      final newDate = DateTime(2025, 6, 1);
      final updated = original.copyWith(matchedAt: newDate);
      expect(updated.matchedAt, newDate);
    });

    test('copy is independent — mutating copy users does not affect original',
        () {
      final updated = original.copyWith(users: ['x', 'y']);
      updated.users.add('z');

      expect(original.users, ['userA', 'userB']);
      expect(updated.users, ['x', 'y', 'z']);
    });
  });

  // ===========================================================================
  // MatchModel – == operator & hashCode
  // ===========================================================================
  group('MatchModel – equality', () {
    test('equal when id, users, status, and chatThreadId match', () {
      final a = MatchModel(
        id: 'match1',
        users: ['userA', 'userB'],
        matchedAt: DateTime(2024, 1, 15),
        matchStatus: 'matched',
      );
      final b = MatchModel(
        id: 'match1',
        users: ['userA', 'userB'],
        matchedAt: DateTime(2025, 6, 1),
        matchStatus: 'matched',
      );

      expect(a, equals(b));
    });

    test('equal regardless of user list order', () {
      final a = MatchModel(
        id: 'match1',
        users: ['userA', 'userB'],
        matchedAt: DateTime.now(),
        matchStatus: 'matched',
      );
      final b = MatchModel(
        id: 'match1',
        users: ['userB', 'userA'],
        matchedAt: DateTime.now(),
        matchStatus: 'matched',
      );

      expect(a, equals(b));
    });

    test('not equal when ids differ', () {
      final a = MatchModel(
        id: 'match1',
        users: ['userA', 'userB'],
        matchedAt: DateTime.now(),
        matchStatus: 'matched',
      );
      final b = MatchModel(
        id: 'match2',
        users: ['userA', 'userB'],
        matchedAt: DateTime.now(),
        matchStatus: 'matched',
      );

      expect(a, isNot(equals(b)));
    });

    test('not equal when matchStatus differs', () {
      final a = MatchModel(
        id: 'match1',
        users: ['userA', 'userB'],
        matchedAt: DateTime.now(),
        matchStatus: 'matched',
      );
      final b = MatchModel(
        id: 'match1',
        users: ['userA', 'userB'],
        matchedAt: DateTime.now(),
        matchStatus: 'unmatched',
      );

      expect(a, isNot(equals(b)));
    });

    test('not equal when users differ', () {
      final a = MatchModel(
        id: 'match1',
        users: ['userA', 'userB'],
        matchedAt: DateTime.now(),
        matchStatus: 'matched',
      );
      final b = MatchModel(
        id: 'match1',
        users: ['userA', 'userC'],
        matchedAt: DateTime.now(),
        matchStatus: 'matched',
      );

      expect(a, isNot(equals(b)));
    });

    test('not equal when chatThreadId differs', () {
      final a = MatchModel(
        id: 'match1',
        users: ['userA', 'userB'],
        matchedAt: DateTime.now(),
        matchStatus: 'matched',
        chatThreadId: 'chat1',
      );
      final b = MatchModel(
        id: 'match1',
        users: ['userA', 'userB'],
        matchedAt: DateTime.now(),
        matchStatus: 'matched',
        chatThreadId: 'chat2',
      );

      expect(a, isNot(equals(b)));
    });

    test('not equal when one chatThreadId is null and the other is not', () {
      final a = MatchModel(
        id: 'match1',
        users: ['userA', 'userB'],
        matchedAt: DateTime.now(),
        matchStatus: 'matched',
        chatThreadId: 'chat1',
      );
      final b = MatchModel(
        id: 'match1',
        users: ['userA', 'userB'],
        matchedAt: DateTime.now(),
        matchStatus: 'matched',
      );

      expect(a, isNot(equals(b)));
    });

    test('not equal when user count differs', () {
      final a = MatchModel(
        id: 'match1',
        users: ['userA', 'userB'],
        matchedAt: DateTime.now(),
        matchStatus: 'matched',
      );
      final b = MatchModel(
        id: 'match1',
        users: ['userA'],
        matchedAt: DateTime.now(),
        matchStatus: 'matched',
      );

      expect(a, isNot(equals(b)));
    });

    test('identical instance is equal to itself', () {
      final model = MatchModel(
        id: 'match1',
        users: ['userA'],
        matchedAt: DateTime.now(),
        matchStatus: 'matched',
      );

      expect(model == model, isTrue);
    });

    test('is not equal to a non-MatchModel object', () {
      final model = MatchModel(
        id: 'match1',
        users: ['userA'],
        matchedAt: DateTime.now(),
        matchStatus: 'matched',
      );

      // ignore: unrelated_type_equality_checks
      expect(model == 'not a match model', isFalse);
    });

    test('hashCode is stable across multiple calls', () {
      final model = MatchModel(
        id: 'match1',
        users: ['userA', 'userB'],
        matchedAt: DateTime(2024),
        matchStatus: 'matched',
        chatThreadId: 'chat1',
      );

      expect(model.hashCode, model.hashCode);
    });

    test('hashCode uses list identity — different list instances may differ',
        () {
      final users = ['userA', 'userB'];
      final a = MatchModel(
        id: 'match1',
        users: users,
        matchedAt: DateTime(2024),
        matchStatus: 'matched',
      );
      final b = MatchModel(
        id: 'match1',
        users: users,
        matchedAt: DateTime(2025),
        matchStatus: 'matched',
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  // ===========================================================================
  // MatchModel – fromDocument()
  // ===========================================================================
  group('MatchModel – fromDocument()', () {
    test('parses a full Firestore document with all fields', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      await fakeFirestore.collection('matches').doc('m1').set({
        'users': ['userA', 'userB'],
        'matchedAt': Timestamp.fromDate(DateTime(2024, 1, 15)),
        'matchStatus': 'matched',
        'chatThreadId': 'chat1',
      });

      final doc = await fakeFirestore.collection('matches').doc('m1').get();
      final model = MatchModel.fromDocument(doc);

      expect(model.id, 'm1');
      expect(model.users, ['userA', 'userB']);
      expect(model.matchedAt, DateTime(2024, 1, 15));
      expect(model.matchStatus, 'matched');
      expect(model.chatThreadId, 'chat1');
    });

    test('falls back to timestamp field when matchedAt is absent', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      await fakeFirestore.collection('matches').doc('m2').set({
        'users': ['userA', 'userB'],
        'timestamp': Timestamp.fromDate(DateTime(2024, 6, 1)),
        'matchStatus': 'active',
      });

      final doc = await fakeFirestore.collection('matches').doc('m2').get();
      final model = MatchModel.fromDocument(doc);

      expect(model.matchedAt, DateTime(2024, 6, 1));
    });

    test('defaults matchStatus to "matched" when missing', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      await fakeFirestore.collection('matches').doc('m3').set({
        'users': ['userA', 'userB'],
      });

      final doc = await fakeFirestore.collection('matches').doc('m3').get();
      final model = MatchModel.fromDocument(doc);

      expect(model.matchStatus, 'matched');
    });

    test('handles missing users list gracefully', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      await fakeFirestore.collection('matches').doc('m4').set({
        'matchStatus': 'matched',
      });

      final doc = await fakeFirestore.collection('matches').doc('m4').get();
      final model = MatchModel.fromDocument(doc);

      expect(model.users, isEmpty);
    });

    test('chatThreadId is null when absent from document', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      await fakeFirestore.collection('matches').doc('m5').set({
        'users': ['userA', 'userB'],
        'matchStatus': 'matched',
      });

      final doc = await fakeFirestore.collection('matches').doc('m5').get();
      final model = MatchModel.fromDocument(doc);

      expect(model.chatThreadId, isNull);
    });

    test('uses the Firestore document ID as the model id', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      await fakeFirestore.collection('matches').doc('custom_doc_id').set({
        'users': ['u1'],
        'matchStatus': 'matched',
      });

      final doc =
          await fakeFirestore.collection('matches').doc('custom_doc_id').get();
      final model = MatchModel.fromDocument(doc);

      expect(model.id, 'custom_doc_id');
    });

    test('preserves user list ordering from Firestore', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      await fakeFirestore.collection('matches').doc('m6').set({
        'users': ['z_user', 'a_user', 'm_user'],
        'matchStatus': 'matched',
      });

      final doc = await fakeFirestore.collection('matches').doc('m6').get();
      final model = MatchModel.fromDocument(doc);

      expect(model.users, ['z_user', 'a_user', 'm_user']);
    });

    test(
        'uses DateTime.now fallback when both matchedAt and timestamp are null',
        () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final before = DateTime.now();

      await fakeFirestore.collection('matches').doc('m7').set({
        'users': ['userA'],
        'matchStatus': 'matched',
      });

      final doc = await fakeFirestore.collection('matches').doc('m7').get();
      final model = MatchModel.fromDocument(doc);
      final after = DateTime.now();

      expect(
          model.matchedAt.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue);
      expect(model.matchedAt.isBefore(after.add(const Duration(seconds: 1))),
          isTrue);
    });
  });

  // ===========================================================================
  // MatchModel – toString()
  // ===========================================================================
  group('MatchModel – toString()', () {
    test('contains all field values', () {
      final model = MatchModel(
        id: 'match1',
        users: ['userA', 'userB'],
        matchedAt: DateTime(2024, 1, 15),
        matchStatus: 'matched',
        chatThreadId: 'chat1',
      );

      final str = model.toString();

      expect(str, contains('match1'));
      expect(str, contains('userA'));
      expect(str, contains('userB'));
      expect(str, contains('matched'));
      expect(str, contains('chat1'));
    });

    test('includes null chatThreadId representation', () {
      final model = MatchModel(
        id: 'match1',
        users: ['userA'],
        matchedAt: DateTime(2024),
        matchStatus: 'matched',
      );

      expect(model.toString(), contains('null'));
    });
  });

  // ===========================================================================
  // MutualLikeCheckResult
  // ===========================================================================
  group('MutualLikeCheckResult', () {
    test('stores isMutualLike and isExistingMatch flags', () {
      const result = MutualLikeCheckResult(
        isMutualLike: true,
        isExistingMatch: false,
      );

      expect(result.isMutualLike, isTrue);
      expect(result.isExistingMatch, isFalse);
      expect(result.matchId, isNull);
    });

    test('stores optional matchId', () {
      const result = MutualLikeCheckResult(
        isMutualLike: false,
        isExistingMatch: true,
        matchId: 'match123',
      );

      expect(result.isMutualLike, isFalse);
      expect(result.isExistingMatch, isTrue);
      expect(result.matchId, 'match123');
    });

    test('const-constructed identical instances share identity', () {
      const a = MutualLikeCheckResult(
        isMutualLike: false,
        isExistingMatch: false,
      );
      const b = MutualLikeCheckResult(
        isMutualLike: false,
        isExistingMatch: false,
      );

      expect(identical(a, b), isTrue);
    });

    test('matchId defaults to null', () {
      const result = MutualLikeCheckResult(
        isMutualLike: true,
        isExistingMatch: true,
      );

      expect(result.matchId, isNull);
    });

    test('both flags can be true simultaneously', () {
      const result = MutualLikeCheckResult(
        isMutualLike: true,
        isExistingMatch: true,
        matchId: 'abc',
      );

      expect(result.isMutualLike, isTrue);
      expect(result.isExistingMatch, isTrue);
      expect(result.matchId, 'abc');
    });
  });

  // ===========================================================================
  // LikesService – static cache operations
  // ===========================================================================
  group('LikesService – cache operations', () {
    late LikesService service;

    setUp(() {
      service = LikesService();
      service.clearCache();
    });

    tearDown(() {
      service.clearCache();
    });

    test('getCacheStats returns a map with expected keys', () {
      final stats = service.getCacheStats();

      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('likeCheckCacheSize'), isTrue);
      expect(stats.containsKey('oldestCacheEntry'), isTrue);
    });

    test('getCacheStats reports zero size after clearCache', () {
      final stats = service.getCacheStats();

      expect(stats['likeCheckCacheSize'], 0);
    });

    test('getCacheStats reports "None" for oldestCacheEntry when empty', () {
      final stats = service.getCacheStats();

      expect(stats['oldestCacheEntry'], 'None');
    });

    test('clearCache is idempotent — calling twice does not throw', () {
      service.clearCache();
      service.clearCache();

      final stats = service.getCacheStats();

      expect(stats['likeCheckCacheSize'], 0);
      expect(stats['oldestCacheEntry'], 'None');
    });

    test('cache is shared across LikesService instances (static maps)', () {
      final serviceA = LikesService();
      final serviceB = LikesService();

      serviceA.clearCache();

      final statsA = serviceA.getCacheStats();
      final statsB = serviceB.getCacheStats();

      expect(statsA['likeCheckCacheSize'], statsB['likeCheckCacheSize']);
    });

    test('likeCheckCacheSize is always an int', () {
      expect(service.getCacheStats()['likeCheckCacheSize'], isA<int>());
    });

    test('oldestCacheEntry is always a String', () {
      expect(service.getCacheStats()['oldestCacheEntry'], isA<String>());
    });

    test('clearCache on a fresh service has no side effects', () {
      final freshService = LikesService();
      freshService.clearCache();

      final stats = freshService.getCacheStats();
      expect(stats['likeCheckCacheSize'], 0);
      expect(stats['oldestCacheEntry'], 'None');
    });
  });

  // ===========================================================================
  // LikesService – input validation (early returns before Firestore)
  // ===========================================================================
  group('LikesService – input validation', () {
    late LikesService service;

    setUp(() {
      service = LikesService();
      service.clearCache();
    });

    tearDown(() {
      service.clearCache();
    });

    test('handleLike with empty fromUserId returns null', () async {
      final result = await service.handleLike('', 'user2');
      expect(result, isNull);
    });

    test('handleLike with empty toUserId returns null', () async {
      final result = await service.handleLike('user1', '');
      expect(result, isNull);
    });

    test('handleLike with both IDs empty returns null', () async {
      final result = await service.handleLike('', '');
      expect(result, isNull);
    });

    test('empty-string validation does not populate the cache', () async {
      await service.handleLike('', 'user2');
      await service.handleLike('user1', '');
      await service.handleLike('', '');

      final stats = service.getCacheStats();
      expect(stats['likeCheckCacheSize'], 0);
    });

    test('sequential empty-ID calls all return null independently', () async {
      final r1 = await service.handleLike('', 'user2');
      final r2 = await service.handleLike('user1', '');
      final r3 = await service.handleLike('', '');

      expect(r1, isNull);
      expect(r2, isNull);
      expect(r3, isNull);
    });
  });
}
