import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../../../../common/utils/app_logger.dart';

/// Helper class to store event with its recommendation score
class ScoredEvent {
  final EventModel event;
  final double score;

  ScoredEvent({required this.event, required this.score});
}

class EventSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Advanced search with multiple filters
  Future<List<EventModel>> searchEvents({
    String? query,
    String? category,
    bool? isFree,
    DateTime? startDate,
    DateTime? endDate,
    double? latitude,
    double? longitude,
    double? radiusKm,
    List<String>? tags,
    int limit = 20,
  }) async {
    try {
      Query eventsQuery = _firestore.collection('events');

      // Filter by status (only published events)
      eventsQuery = eventsQuery.where('status', isEqualTo: 'published');

      // Category filter
      if (category != null && category.isNotEmpty) {
        eventsQuery = eventsQuery.where('category', isEqualTo: category);
      }

      // Free/Paid filter
      if (isFree != null) {
        eventsQuery = eventsQuery.where('isFree', isEqualTo: isFree);
      }

      // Date range filter
      if (startDate != null) {
        eventsQuery =
            eventsQuery.where('startDate', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        eventsQuery =
            eventsQuery.where('startDate', isLessThanOrEqualTo: endDate);
      }

      // Order by start date
      eventsQuery = eventsQuery.orderBy('startDate');

      // Limit results
      eventsQuery = eventsQuery.limit(limit);

      final querySnapshot = await eventsQuery.get();
      List<EventModel> events = querySnapshot.docs
          .map((doc) => EventModel.fromFirestoreJson(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Apply text search filter (client-side for better flexibility)
      if (query != null && query.trim().isNotEmpty) {
        events = _filterByTextSearch(events, query.trim().toLowerCase());
      }

      // Apply location filter (client-side for better accuracy)
      if (latitude != null && longitude != null && radiusKm != null) {
        events = _filterByLocation(events, latitude, longitude, radiusKm);
      }

      // Apply tags filter (client-side)
      if (tags != null && tags.isNotEmpty) {
        events = _filterByTags(events, tags);
      }

      return events;
    } catch (e) {
      AppLogger.error('Error searching events', error: e);
      return [];
    }
  }

  /// Get trending events based on RSVP count and recent activity
  Future<List<EventModel>> getTrendingEvents({int limit = 10}) async {
    try {
      final eventsQuery = _firestore
          .collection('events')
          .where('status', isEqualTo: 'published')
          .where('startDate', isGreaterThan: DateTime.now())
          .orderBy('startDate')
          .orderBy('rsvpCount', descending: true)
          .limit(limit);

      final querySnapshot = await eventsQuery.get();
      return querySnapshot.docs
          .map((doc) => EventModel.fromFirestoreJson(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting trending events', error: e);
      return [];
    }
  }

  /// Get events happening this weekend
  Future<List<EventModel>> getWeekendEvents() async {
    final now = DateTime.now();
    final friday = now.add(Duration(days: (5 - now.weekday) % 7));
    final sunday = friday.add(const Duration(days: 2));

    return searchEvents(
      startDate: DateTime(friday.year, friday.month, friday.day),
      endDate: DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59),
      limit: 15,
    );
  }

  /// Get free events
  Future<List<EventModel>> getFreeEvents({int limit = 15}) async {
    return searchEvents(isFree: true, limit: limit);
  }

  /// Get events by category with recommendations
  Future<List<EventModel>> getEventsByCategory(String category,
      {int limit = 20}) async {
    return searchEvents(category: category, limit: limit);
  }

  /// Get recommended events based on user interests
  Future<List<EventModel>> getRecommendedEvents({
    required List<String> userInterests,
    String? userLocation,
    int limit = 15,
  }) async {
    try {
      // Get events that match user interests
      final eventsQuery = _firestore
          .collection('events')
          .where('status', isEqualTo: 'published')
          .where('startDate', isGreaterThan: DateTime.now())
          .orderBy('startDate')
          .limit(limit * 2); // Get more to filter

      final querySnapshot = await eventsQuery.get();
      List<EventModel> events = querySnapshot.docs
          .map((doc) => EventModel.fromFirestoreJson(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Score events based on user interests
      final scoredEvents = _scoreEventsByInterests(events, userInterests);

      // Sort by score and return top results
      scoredEvents.sort((a, b) => b.score.compareTo(a.score));

      return scoredEvents.take(limit).map((e) => e.event).toList();
    } catch (e) {
      AppLogger.error('Error getting recommended events', error: e);
      return [];
    }
  }

  /// Filter events by text search (name, description, tags)
  List<EventModel> _filterByTextSearch(List<EventModel> events, String query) {
    return events.where((event) {
      final searchableText =
          '${event.name} ${event.description} ${event.category}'.toLowerCase();
      return searchableText.contains(query);
    }).toList();
  }

  /// Filter events by location using Haversine formula
  List<EventModel> _filterByLocation(
      List<EventModel> events, double lat, double lng, double radiusKm) {
    return events.where((event) {
      if (event.location.latitude == null || event.location.longitude == null) {
        return false;
      }

      final distance = _calculateDistance(
        lat,
        lng,
        event.location.latitude!,
        event.location.longitude!,
      );

      return distance <= radiusKm;
    }).toList();
  }

  /// Filter events by tags
  List<EventModel> _filterByTags(List<EventModel> events, List<String> tags) {
    return events.where((event) {
      // Check if event has any of the specified tags
      return tags.any(
          (tag) => event.category.toLowerCase().contains(tag.toLowerCase()));
    }).toList();
  }

  /// Score events based on user interests
  List<ScoredEvent> _scoreEventsByInterests(
      List<EventModel> events, List<String> userInterests) {
    List<ScoredEvent> scoredEvents = [];

    for (final event in events) {
      double score = 0.0;

      // Score based on category match
      for (final interest in userInterests) {
        if (event.category.toLowerCase().contains(interest.toLowerCase())) {
          score += 2.0;
        }
        if (event.name.toLowerCase().contains(interest.toLowerCase())) {
          score += 1.5;
        }
        if (event.description.toLowerCase().contains(interest.toLowerCase())) {
          score += 1.0;
        }
      }

      // Boost score for events happening soon
      final daysUntilEvent = event.startDate.difference(DateTime.now()).inDays;
      if (daysUntilEvent <= 7) {
        score += 0.5;
      }

      // Boost score for popular events
      if (event.rsvpCount > 10) {
        score += 0.3;
      }

      scoredEvents.add(ScoredEvent(event: event, score: score));
    }

    return scoredEvents;
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
}
