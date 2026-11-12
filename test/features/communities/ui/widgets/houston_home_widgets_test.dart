import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/communities/ui/widgets/explore_groups_link.dart';
import 'package:naijasingles/features/communities/ui/widgets/houston_home_hero.dart';
import 'package:naijasingles/features/communities/ui/widgets/houston_weekend_event_row.dart';
import 'package:naijasingles/features/communities/ui/widgets/soft_connect_module.dart';
import 'package:naijasingles/features/events/data/models/event_model.dart';

EventModel _weekendEvent() {
  final DateTime start = DateTime(2026, 5, 24, 19);
  return EventModel(
    id: 'e1',
    name: 'Afrobeats & Amapiano',
    description: 'd',
    startDate: start,
    endDate: start.add(const Duration(hours: 4)),
    location: const EventLocation(
      city: 'Midtown Houston',
      name: 'Midtown Houston',
    ),
    isFree: true,
    category: 'Music',
    createdAt: start,
    updatedAt: start,
    createdByUserId: 'host',
    attendeeCount: 127,
  );
}

void main() {
  testWidgets('HoustonHomeHero shows honest locals label by default copy',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HoustonHomeHero(
            localsLabel: HoustonHomeHero.honestLocalsLabel,
            showVerifiedMark: false,
            onSeeThisWeekend: () {},
            onProfileTap: () {},
          ),
        ),
      ),
    );

    expect(find.textContaining('New in Houston?'), findsOneWidget);
    expect(find.text('This weekend in Houston'), findsOneWidget);
    expect(find.text('See this weekend'), findsOneWidget);
    expect(find.text(HoustonHomeHero.honestLocalsLabel), findsOneWidget);
    expect(find.text(HoustonHomeHero.verifiedLocalsLabel), findsNothing);
  });

  testWidgets('HoustonHomeHero can show Verified locals after upgrade',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HoustonHomeHero(
            localsLabel: HoustonHomeHero.verifiedLocalsLabel,
            showVerifiedMark: true,
            onSeeThisWeekend: () {},
            onProfileTap: () {},
          ),
        ),
      ),
    );

    expect(find.text(HoustonHomeHero.verifiedLocalsLabel), findsOneWidget);
    expect(find.byIcon(Icons.verified), findsOneWidget);
  });

  testWidgets('HoustonWeekendEventRow shows title, place, going; omits host',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HoustonWeekendEventRow(
            event: _weekendEvent(),
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Afrobeats & Amapiano'), findsOneWidget);
    expect(find.text('Midtown Houston'), findsOneWidget);
    expect(find.text('127 going'), findsOneWidget);
    expect(find.textContaining('Host:'), findsNothing);
  });

  testWidgets('HoustonWeekendEventRow shows the real city, not a fake Houston',
      (WidgetTester tester) async {
    final DateTime start = DateTime(2026, 5, 24, 19);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HoustonWeekendEventRow(
            event: EventModel(
              id: 'lagos',
              name: 'Lagos Night',
              description: 'd',
              startDate: start,
              endDate: start.add(const Duration(hours: 4)),
              location: const EventLocation(city: 'Lagos'),
              isFree: true,
              category: 'Music',
              createdAt: start,
              updatedAt: start,
              createdByUserId: 'host',
            ),
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Lagos'), findsOneWidget);
    expect(find.text('Lagos Houston'), findsNothing);
  });

  testWidgets('HoustonWeekendEventRow shows host when provided',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HoustonWeekendEventRow(
            event: _weekendEvent(),
            hostName: 'AfroPeep',
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Host: AfroPeep'), findsOneWidget);
  });

  testWidgets('ExploreGroupsLink and SoftConnectModule expose Figma copy',
      (WidgetTester tester) async {
    var groupsTapped = false;
    var connectTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ExploreGroupsLink(onTap: () => groupsTapped = true),
              SoftConnectModule(onTap: () => connectTapped = true),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Community rooms opening this week'), findsOneWidget);
    expect(find.text('Explore groups'), findsOneWidget);
    expect(find.text('Connect after the event'), findsOneWidget);
    expect(find.text('Keep the conversation going.'), findsOneWidget);

    await tester.tap(find.text('Explore groups'));
    await tester.tap(find.text('Connect after the event'));
    expect(groupsTapped, isTrue);
    expect(connectTapped, isTrue);
  });
}
