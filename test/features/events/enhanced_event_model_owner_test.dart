import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/events/data/models/enhanced_event_model.dart';

void main() {
  group('EnhancedEventModel owner fallback', () {
    Map<String, dynamic> _baseJson() => {
          'name': 'Legacy Event',
          'description': 'Test',
          'startDate': DateTime(2026, 1, 1).toIso8601String(),
          'endDate': DateTime(2026, 1, 2).toIso8601String(),
          'location': {'city': 'Lagos'},
          'createdAt': DateTime(2026, 1, 1).toIso8601String(),
          'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
        };

    test('uses createdByUserId when present', () {
      final event = EnhancedEventModel.fromFirestoreJson(
        {
          ..._baseJson(),
          'createdByUserId': 'new-owner',
          'creatorId': 'legacy-owner',
        },
        'event-1',
      );

      expect(event.ownerUserId, 'new-owner');
    });

    test('falls back to creatorId for legacy documents', () {
      final event = EnhancedEventModel.fromFirestoreJson(
        {
          ..._baseJson(),
          'creatorId': 'legacy-owner',
        },
        'event-2',
      );

      expect(event.createdByUserId, isNull);
      expect(event.ownerUserId, 'legacy-owner');
    });
  });

  group('EnhancedEventModel.isOwnedBy mirrors Firestore OR-logic', () {
    Map<String, dynamic> _baseJson() => {
          'name': 'Test Event',
          'description': 'Test',
          'startDate': DateTime(2026, 1, 1).toIso8601String(),
          'endDate': DateTime(2026, 1, 2).toIso8601String(),
          'location': {'city': 'Lagos'},
          'createdAt': DateTime(2026, 1, 1).toIso8601String(),
          'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
        };

    test('matches via createdByUserId', () {
      final event = EnhancedEventModel.fromFirestoreJson(
        {..._baseJson(), 'createdByUserId': 'user-a'},
        'event-1',
      );

      expect(event.isOwnedBy('user-a'), isTrue);
      expect(event.isOwnedBy('user-b'), isFalse);
    });

    test('matches via creatorId (legacy)', () {
      final event = EnhancedEventModel.fromFirestoreJson(
        {..._baseJson(), 'creatorId': 'user-a'},
        'event-2',
      );

      expect(event.isOwnedBy('user-a'), isTrue);
      expect(event.isOwnedBy('user-b'), isFalse);
    });

    test('both fields present, different values — matches either', () {
      final event = EnhancedEventModel.fromFirestoreJson(
        {
          ..._baseJson(),
          'createdByUserId': 'user-a',
          'creatorId': 'user-b',
        },
        'event-3',
      );

      expect(event.isOwnedBy('user-a'), isTrue);
      expect(event.isOwnedBy('user-b'), isTrue);
      expect(event.isOwnedBy('user-c'), isFalse);
    });

    test('neither field set — no owner', () {
      final event = EnhancedEventModel.fromFirestoreJson(
        _baseJson(),
        'event-4',
      );

      expect(event.isOwnedBy('any-user'), isFalse);
    });
  });
}
