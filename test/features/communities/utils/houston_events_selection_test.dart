import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/communities/utils/houston_events_selection.dart';
import 'package:naijasingles/features/events/data/models/event_model.dart';

EventModel _event({
  required String id,
  required String name,
  String? city,
  String? namePlace,
}) {
  final DateTime now = DateTime(2026, 5, 24);
  return EventModel(
    id: id,
    name: name,
    description: 'd',
    startDate: now,
    endDate: now.add(const Duration(hours: 4)),
    location: EventLocation(
      city: city,
      name: namePlace,
    ),
    isFree: true,
    category: 'Culture',
    createdAt: now,
    updatedAt: now,
    createdByUserId: 'host',
    attendeeCount: 12,
  );
}

void main() {
  group('selectHoustonWeekendEvents', () {
    test('keeps only Houston events and hides other cities', () {
      final HoustonEventsSelection selected = selectHoustonWeekendEvents(
        <EventModel>[
          _event(id: 'lagos', name: 'Lagos Night', city: 'Lagos'),
          _event(id: 'hou', name: 'Afrobeats', city: 'Houston'),
        ],
      );
      expect(selected.events.single.id, 'hou');
    });

    test('returns empty when nothing matches Houston', () {
      final HoustonEventsSelection selected = selectHoustonWeekendEvents(
        <EventModel>[
          _event(id: 'lagos', name: 'Lagos Night', city: 'Lagos'),
        ],
      );
      expect(selected.events, isEmpty);
    });
  });

  test('eventGoingCount prefers attendeeCount', () {
    final EventModel event = _event(id: '1', name: 'E', city: 'Houston');
    expect(eventGoingCount(event), 12);
  });

  test('eventPlaceLabel uses the real city and never appends Houston', () {
    expect(
      eventPlaceLabel(_event(id: 'lagos', name: 'Lagos Night', city: 'Lagos')),
      'Lagos',
    );
    expect(
      eventPlaceLabel(_event(id: 'hou', name: 'Afrobeats', city: 'Houston')),
      'Houston',
    );
    expect(
      eventPlaceLabel(
        _event(
          id: 'named',
          name: 'Named',
          namePlace: 'EaDo Houston',
        ),
      ),
      'EaDo Houston',
    );
  });
}
