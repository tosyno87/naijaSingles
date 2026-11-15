import '../../events/data/models/event_model.dart';

const String kHoustonLaunchCity = 'houston';

class HoustonEventsSelection {
  const HoustonEventsSelection({
    required this.events,
  });

  final List<EventModel> events;
}

String eventLocationHaystack(EventModel event) => [
      event.location.city,
      event.location.state,
      event.location.country,
      event.location.name,
      event.location.address,
    ].whereType<String>().join(' ').toLowerCase();

bool eventMentionsHouston(EventModel event) =>
    eventLocationHaystack(event).contains(kHoustonLaunchCity);

/// Houston home only lists Houston events. Other cities stay on See all —
/// never under "This weekend in Houston".
HoustonEventsSelection selectHoustonWeekendEvents(
  List<EventModel> results, {
  int limit = 6,
}) {
  final List<EventModel> houston = results.where(eventMentionsHouston).toList();
  return HoustonEventsSelection(
    events: houston.take(limit).toList(),
  );
}

/// Real place text only. Do not append Houston to a non-Houston city.
String eventPlaceLabel(EventModel event) {
  final String? city = event.location.city;
  if (city != null && city.trim().isNotEmpty) {
    return city.trim();
  }
  return event.location.shortAddress;
}

int eventGoingCount(EventModel event) {
  if (event.attendeeCount > 0) return event.attendeeCount;
  return event.rsvpCount;
}
