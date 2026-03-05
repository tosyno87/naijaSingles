import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/match/data/services/match_service.dart';
import 'package:naijasingles/features/match/models/match_model.dart';

/// FirebaseAuth's Pigeon API registers platform channel listeners on
/// construction. These mock handlers prevent PlatformException during tests
/// where no real Firebase backend is available.
///
/// The Pigeon codegen expects non-null String return values for listener
/// registration, so we return a wrapped list with a dummy string.
void _setupFirebaseAuthPigeonMocks() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const codec = StandardMessageCodec();

  final channels = [
    'dev.flutter.pigeon.firebase_auth_platform_interface.FirebaseAuthHostApi.registerIdTokenListener',
    'dev.flutter.pigeon.firebase_auth_platform_interface.FirebaseAuthHostApi.registerAuthStateListener',
  ];

  for (final channel in channels) {
    messenger.setMockMessageHandler(channel, (ByteData? message) async {
      return codec.encodeMessage(<Object?>['mock_listener_id']);
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
  _setupFirebaseAuthPigeonMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  // ===========================================================================
  // MatchService – no authenticated user
  // All methods that depend on currentUserId should fail gracefully when
  // FirebaseAuth has no signed-in user.
  // ===========================================================================
  group('MatchService – no auth user', () {
    late MatchService service;

    setUp(() {
      service = MatchService();
    });

    test('handleLike returns null when currentUserId is null', () async {
      final result = await service.handleLike('toUser123');
      expect(result, isNull);
    });

    test('handleLike returns null for empty toUserId', () async {
      final result = await service.handleLike('');
      expect(result, isNull);
    });

    test('createMatch returns null when currentUserId is null', () async {
      final result = await service.createMatch(otherUserId: 'otherUser');
      expect(result, isNull);
    });

    test('getMatchBetweenUsers returns null when currentUserId is null',
        () async {
      final result = await service.getMatchBetweenUsers('otherUser');
      expect(result, isNull);
    });

    test('getUserMatches returns empty list when currentUserId is null',
        () async {
      final result = await service.getUserMatches();
      expect(result, isEmpty);
      expect(result, isA<List<MatchModel>>());
    });

    test('getUserMatchesLegacy returns empty list when currentUserId is null',
        () async {
      final result = await service.getUserMatchesLegacy();
      expect(result, isEmpty);
      expect(result, isA<List<Map<String, dynamic>>>());
    });

    test('hasUserLiked returns false when currentUserId is null', () async {
      final result = await service.hasUserLiked('otherUser');
      expect(result, isFalse);
    });

    test('getUsersWhoLikedMe returns empty list when currentUserId is null',
        () async {
      final result = await service.getUsersWhoLikedMe();
      expect(result, isEmpty);
      expect(result, isA<List<String>>());
    });

    test('getMatchesStream emits empty list when currentUserId is null',
        () async {
      final stream = service.getMatchesStream();
      final result = await stream.first;
      expect(result, isEmpty);
    });
  });

  // ===========================================================================
  // MatchService – return type contracts
  // Verify the correct types are returned from every public method, ensuring
  // the API surface is stable even without authentication.
  // ===========================================================================
  group('MatchService – return type contracts', () {
    late MatchService service;

    setUp(() {
      service = MatchService();
    });

    test('handleLike returns Future<String?>', () {
      final future = service.handleLike('user123');
      expect(future, isA<Future<String?>>());
    });

    test('createMatch returns Future<String?>', () {
      final future = service.createMatch(otherUserId: 'user123');
      expect(future, isA<Future<String?>>());
    });

    test('getUserMatches returns Future that resolves to List<MatchModel>',
        () async {
      final result = await service.getUserMatches();
      expect(result, isA<List<MatchModel>>());
    });

    test(
        'getUserMatchesLegacy returns Future that resolves to List<Map<String, dynamic>>',
        () async {
      final result = await service.getUserMatchesLegacy();
      expect(result, isA<List<Map<String, dynamic>>>());
    });

    test('hasUserLiked returns Future<bool>', () {
      final future = service.hasUserLiked('user123');
      expect(future, isA<Future<bool>>());
    });

    test('getUsersWhoLikedMe returns Future that resolves to List<String>',
        () async {
      final result = await service.getUsersWhoLikedMe();
      expect(result, isA<List<String>>());
    });

    test('getMatchesStream returns a Stream', () {
      final stream = service.getMatchesStream();
      expect(stream, isA<Stream<List<MatchModel>>>());
    });

    test('getMatchBetweenUsers returns Future<String?>', () {
      final future = service.getMatchBetweenUsers('user123');
      expect(future, isA<Future<String?>>());
    });

    test('getMatchById returns Future<MatchModel?>', () {
      final future = service.getMatchById('match123');
      expect(future, isA<Future<MatchModel?>>());
    });

    test('updateMatchStatus returns Future<bool>', () {
      final future = service.updateMatchStatus('match123', 'unmatched');
      expect(future, isA<Future<bool>>());
    });

    test('deleteMatch returns Future<bool>', () {
      final future = service.deleteMatch('match123');
      expect(future, isA<Future<bool>>());
    });
  });

  // ===========================================================================
  // MatchService – idempotent null-auth guards
  // Repeated calls to guarded methods should return the same safe defaults
  // without accumulating side effects.
  // ===========================================================================
  group('MatchService – idempotent null-auth guards', () {
    late MatchService service;

    setUp(() {
      service = MatchService();
    });

    test('calling handleLike twice returns null both times', () async {
      final first = await service.handleLike('user1');
      final second = await service.handleLike('user2');

      expect(first, isNull);
      expect(second, isNull);
    });

    test('calling getUserMatches twice returns empty both times', () async {
      final first = await service.getUserMatches();
      final second = await service.getUserMatches();

      expect(first, isEmpty);
      expect(second, isEmpty);
    });

    test('calling hasUserLiked with different IDs returns false each time',
        () async {
      final a = await service.hasUserLiked('userX');
      final b = await service.hasUserLiked('userY');

      expect(a, isFalse);
      expect(b, isFalse);
    });

    test('calling getUsersWhoLikedMe twice returns empty both times', () async {
      final first = await service.getUsersWhoLikedMe();
      final second = await service.getUsersWhoLikedMe();

      expect(first, isEmpty);
      expect(second, isEmpty);
    });

    test('calling createMatch twice returns null both times', () async {
      final first = await service.createMatch(otherUserId: 'user1');
      final second = await service.createMatch(otherUserId: 'user2');

      expect(first, isNull);
      expect(second, isNull);
    });
  });

  // ===========================================================================
  // MatchService – currentUserId property
  // Without a signed-in user, currentUserId should be null.
  // ===========================================================================
  group('MatchService – currentUserId', () {
    test('is null when no user is signed in', () {
      final service = MatchService();
      expect(service.currentUserId, isNull);
    });
  });
}
