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
}
