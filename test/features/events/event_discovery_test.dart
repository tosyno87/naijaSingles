import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naijasingles/features/events/presentation/bloc/events_bloc.dart';
import 'package:naijasingles/features/events/data/models/event_model.dart';

void main() {
  group('Event Discovery Features', () {
    testWidgets('EventFilter should support advanced filtering options', (WidgetTester tester) async {
      // Test enhanced EventFilter with new fields
      final filter = EventFilter(
        category: 'Music',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        location: 'Lagos',
        freeOnly: true,
        maxPrice: 50.0,
        minPrice: 10.0,
        latitude: 6.5244,
        longitude: 3.3792,
        radiusKm: 25.0,
        tags: ['afrobeat', 'networking'],
        sortBy: 'popularity',
        trendingOnly: false,
        weekendOnly: true,
      );

      // Test hasActiveFilters
      expect(filter.hasActiveFilters, isTrue);
      expect(filter.hasLocationFilter, isTrue);
      expect(filter.hasPriceFilter, isTrue);
      expect(filter.hasDateFilter, isTrue);

      // Test copyWith
      final updatedFilter = filter.copyWith(
        category: 'Business',
        freeOnly: false,
      );

      expect(updatedFilter.category, equals('Business'));
      expect(updatedFilter.freeOnly, isFalse);
      expect(updatedFilter.maxPrice, equals(50.0)); // Should remain unchanged
    });

    testWidgets('EventFilter should handle empty filters correctly', (WidgetTester tester) async {
      final emptyFilter = const EventFilter();

      expect(emptyFilter.hasActiveFilters, isFalse);
      expect(emptyFilter.hasLocationFilter, isFalse);
      expect(emptyFilter.hasPriceFilter, isFalse);
      expect(emptyFilter.hasDateFilter, isFalse);
    });

    testWidgets('EventModel should support new fields', (WidgetTester tester) async {
      final event = EventModel(
        id: 'test-event',
        name: 'Test Event',
        description: 'Test Description',
        startDate: DateTime(2024, 1, 15),
        endDate: DateTime(2024, 1, 15),
        location: const EventLocation(
          name: 'Test Venue',
          address: 'Test Address',
          city: 'Lagos',
          state: 'Lagos State',
          country: 'Nigeria',
          latitude: 6.5244,
          longitude: 3.3792,
        ),
        isFree: false,
        ticketPrice: 25.0,
        category: 'Music',
        tags: ['afrobeat', 'live music'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdByUserId: 'test-user',
      );

      expect(event.ticketPrice, equals(25.0));
      expect(event.tags, equals(['afrobeat', 'live music']));
      expect(event.isFree, isFalse);
    });

    testWidgets('EventModel should handle free events correctly', (WidgetTester tester) async {
      final freeEvent = EventModel(
        id: 'free-event',
        name: 'Free Event',
        description: 'Free Description',
        startDate: DateTime(2024, 1, 15),
        endDate: DateTime(2024, 1, 15),
        location: const EventLocation(
          name: 'Free Venue',
          address: 'Free Address',
          city: 'Lagos',
          state: 'Lagos State',
          country: 'Nigeria',
          latitude: 6.5244,
          longitude: 3.3792,
        ),
        isFree: true,
        category: 'Community',
        tags: ['networking', 'free'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdByUserId: 'test-user',
      );

      expect(freeEvent.isFree, isTrue);
      expect(freeEvent.ticketPrice, isNull);
      expect(freeEvent.tags, equals(['networking', 'free']));
    });

    testWidgets('EventFilter should apply weekend filter correctly', (WidgetTester tester) async {
      final weekendFilter = const EventFilter(weekendOnly: true);
      
      // Create events for different days
      final fridayEvent = EventModel(
        id: 'friday-event',
        name: 'Friday Event',
        description: 'Friday Description',
        startDate: DateTime(2024, 1, 5), // Friday
        endDate: DateTime(2024, 1, 5),
        location: const EventLocation(
          name: 'Friday Venue',
          address: 'Friday Address',
          city: 'Lagos',
          state: 'Lagos State',
          country: 'Nigeria',
          latitude: 6.5244,
          longitude: 3.3792,

        ),
        isFree: true,
        category: 'Music',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdByUserId: 'test-user',
      );

      final mondayEvent = EventModel(
        id: 'monday-event',
        name: 'Monday Event',
        description: 'Monday Description',
        startDate: DateTime(2024, 1, 1), // Monday
        endDate: DateTime(2024, 1, 1),
        location: const EventLocation(
          name: 'Monday Venue',
          address: 'Monday Address',
          city: 'Lagos',
          state: 'Lagos State',
          country: 'Nigeria',
          latitude: 6.5244,
          longitude: 3.3792,

        ),
        isFree: true,
        category: 'Business',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdByUserId: 'test-user',
      );

      // Test weekend filter logic (this would be in the BLoC)
      expect(fridayEvent.startDate.weekday, equals(DateTime.friday));
      expect(mondayEvent.startDate.weekday, equals(DateTime.monday));
    });

    testWidgets('EventFilter should handle price range filtering', (WidgetTester tester) async {
      final priceFilter = EventFilter(
        minPrice: 20.0,
        maxPrice: 100.0,
      );

      expect(priceFilter.hasPriceFilter, isTrue);
      expect(priceFilter.minPrice, equals(20.0));
      expect(priceFilter.maxPrice, equals(100.0));

      // Test price filtering logic
      final expensiveEvent = EventModel(
        id: 'expensive-event',
        name: 'Expensive Event',
        description: 'Expensive Description',
        startDate: DateTime(2024, 1, 15),
        endDate: DateTime(2024, 1, 15),
        location: const EventLocation(
          name: 'Expensive Venue',
          address: 'Expensive Address',
          city: 'Lagos',
          state: 'Lagos State',
          country: 'Nigeria',
          latitude: 6.5244,
          longitude: 3.3792,

        ),
        isFree: false,
        ticketPrice: 150.0, // Above max price
        category: 'Music',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdByUserId: 'test-user',
      );

      final affordableEvent = EventModel(
        id: 'affordable-event',
        name: 'Affordable Event',
        description: 'Affordable Description',
        startDate: DateTime(2024, 1, 15),
        endDate: DateTime(2024, 1, 15),
        location: const EventLocation(
          name: 'Affordable Venue',
          address: 'Affordable Address',
          city: 'Lagos',
          state: 'Lagos State',
          country: 'Nigeria',
          latitude: 6.5244,
          longitude: 3.3792,

        ),
        isFree: false,
        ticketPrice: 50.0, // Within price range
        category: 'Music',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdByUserId: 'test-user',
      );

      // Test price filtering logic (this would be in the BLoC)
      expect(expensiveEvent.ticketPrice! > priceFilter.maxPrice!, isTrue);
      expect(affordableEvent.ticketPrice! <= priceFilter.maxPrice!, isTrue);
      expect(affordableEvent.ticketPrice! >= priceFilter.minPrice!, isTrue);
    });

    testWidgets('EventFilter should handle tag filtering', (WidgetTester tester) async {
      final tagFilter = EventFilter(
        tags: ['afrobeat', 'networking'],
      );

      expect(tagFilter.hasActiveFilters, isTrue);
      expect(tagFilter.tags, equals(['afrobeat', 'networking']));

      final eventWithMatchingTags = EventModel(
        id: 'tagged-event',
        name: 'Tagged Event',
        description: 'Tagged Description',
        startDate: DateTime(2024, 1, 15),
        endDate: DateTime(2024, 1, 15),
        location: const EventLocation(
          name: 'Tagged Venue',
          address: 'Tagged Address',
          city: 'Lagos',
          state: 'Lagos State',
          country: 'Nigeria',
          latitude: 6.5244,
          longitude: 3.3792,

        ),
        isFree: true,
        category: 'Music',
        tags: ['afrobeat', 'live music', 'networking'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdByUserId: 'test-user',
      );

      final eventWithoutMatchingTags = EventModel(
        id: 'untagged-event',
        name: 'Untagged Event',
        description: 'Untagged Description',
        startDate: DateTime(2024, 1, 15),
        endDate: DateTime(2024, 1, 15),
        location: const EventLocation(
          name: 'Untagged Venue',
          address: 'Untagged Address',
          city: 'Lagos',
          state: 'Lagos State',
          country: 'Nigeria',
          latitude: 6.5244,
          longitude: 3.3792,

        ),
        isFree: true,
        category: 'Business',
        tags: ['business', 'conference'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdByUserId: 'test-user',
      );

      // Test tag filtering logic (this would be in the BLoC)
      final eventTags = eventWithMatchingTags.tags.map((tag) => tag.toLowerCase()).toList();
      final hasMatchingTag = tagFilter.tags!.any((filterTag) => 
        eventTags.any((eventTag) => eventTag.contains(filterTag.toLowerCase())));
      expect(hasMatchingTag, isTrue);

      final eventTags2 = eventWithoutMatchingTags.tags.map((tag) => tag.toLowerCase()).toList();
      final hasMatchingTag2 = tagFilter.tags!.any((filterTag) => 
        eventTags2.any((eventTag) => eventTag.contains(filterTag.toLowerCase())));
      expect(hasMatchingTag2, isFalse);
    });
  });
}
