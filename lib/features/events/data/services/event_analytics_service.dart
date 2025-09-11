import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class EventAnalytics {
  final String eventId;
  final int totalViews;
  final int totalRSVPs;
  final int totalShares;
  final int totalClicks;
  final Map<String, int> viewsByDay;
  final Map<String, int> rsvpsByDay;
  final List<String> topLocations;
  final List<String> topAgeGroups;
  final double conversionRate;
  final DateTime lastUpdated;

  const EventAnalytics({
    required this.eventId,
    required this.totalViews,
    required this.totalRSVPs,
    required this.totalShares,
    required this.totalClicks,
    required this.viewsByDay,
    required this.rsvpsByDay,
    required this.topLocations,
    required this.topAgeGroups,
    required this.conversionRate,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'totalViews': totalViews,
      'totalRSVPs': totalRSVPs,
      'totalShares': totalShares,
      'totalClicks': totalClicks,
      'viewsByDay': viewsByDay,
      'rsvpsByDay': rsvpsByDay,
      'topLocations': topLocations,
      'topAgeGroups': topAgeGroups,
      'conversionRate': conversionRate,
      'lastUpdated': lastUpdated,
    };
  }

  factory EventAnalytics.fromJson(Map<String, dynamic> json) {
    return EventAnalytics(
      eventId: json['eventId'] ?? '',
      totalViews: json['totalViews'] ?? 0,
      totalRSVPs: json['totalRSVPs'] ?? 0,
      totalShares: json['totalShares'] ?? 0,
      totalClicks: json['totalClicks'] ?? 0,
      viewsByDay: Map<String, int>.from(json['viewsByDay'] ?? {}),
      rsvpsByDay: Map<String, int>.from(json['rsvpsByDay'] ?? {}),
      topLocations: List<String>.from(json['topLocations'] ?? []),
      topAgeGroups: List<String>.from(json['topAgeGroups'] ?? []),
      conversionRate: (json['conversionRate'] ?? 0.0).toDouble(),
      lastUpdated: (json['lastUpdated'] as Timestamp).toDate(),
    );
  }
}

class EventAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Track event view
  Future<void> trackEventView(String eventId, String userId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      await _firestore.collection('eventAnalytics').doc(eventId).set({
        'eventId': eventId,
        'lastUpdated': FieldValue.serverTimestamp(),
        'totalViews': FieldValue.increment(1),
        'viewsByDay.$today': FieldValue.increment(1),
      }, SetOptions(merge: true));

      // Track user-specific view
      await _firestore
          .collection('eventAnalytics')
          .doc(eventId)
          .collection('userViews')
          .doc(userId)
          .set({
        'userId': userId,
        'viewedAt': FieldValue.serverTimestamp(),
        'date': today,
      }, SetOptions(merge: true));

      log('Event view tracked for event: $eventId, user: $userId', name: 'EventAnalyticsService');
    } catch (e) {
      log('Error tracking event view: $e', name: 'EventAnalyticsService');
    }
  }

  /// Track event RSVP
  Future<void> trackEventRSVP(String eventId, String userId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      await _firestore.collection('eventAnalytics').doc(eventId).set({
        'eventId': eventId,
        'lastUpdated': FieldValue.serverTimestamp(),
        'totalRSVPs': FieldValue.increment(1),
        'rsvpsByDay.$today': FieldValue.increment(1),
      }, SetOptions(merge: true));

      // Track user-specific RSVP
      await _firestore
          .collection('eventAnalytics')
          .doc(eventId)
          .collection('userRSVPs')
          .doc(userId)
          .set({
        'userId': userId,
        'rsvpedAt': FieldValue.serverTimestamp(),
        'date': today,
      }, SetOptions(merge: true));

      log('Event RSVP tracked for event: $eventId, user: $userId', name: 'EventAnalyticsService');
    } catch (e) {
      log('Error tracking event RSVP: $e', name: 'EventAnalyticsService');
    }
  }

  /// Track event share
  Future<void> trackEventShare(String eventId, String userId, String shareMethod) async {
    try {
      await _firestore.collection('eventAnalytics').doc(eventId).set({
        'eventId': eventId,
        'lastUpdated': FieldValue.serverTimestamp(),
        'totalShares': FieldValue.increment(1),
      }, SetOptions(merge: true));

      // Track user-specific share
      await _firestore
          .collection('eventAnalytics')
          .doc(eventId)
          .collection('userShares')
          .doc('${userId}_${DateTime.now().millisecondsSinceEpoch}')
          .set({
        'userId': userId,
        'sharedAt': FieldValue.serverTimestamp(),
        'shareMethod': shareMethod, // 'whatsapp', 'instagram', 'twitter', etc.
      });

      log('Event share tracked for event: $eventId, user: $userId, method: $shareMethod', name: 'EventAnalyticsService');
    } catch (e) {
      log('Error tracking event share: $e', name: 'EventAnalyticsService');
    }
  }

  /// Track event click (e.g., on ticket link)
  Future<void> trackEventClick(String eventId, String userId, String clickType) async {
    try {
      await _firestore.collection('eventAnalytics').doc(eventId).set({
        'eventId': eventId,
        'lastUpdated': FieldValue.serverTimestamp(),
        'totalClicks': FieldValue.increment(1),
      }, SetOptions(merge: true));

      // Track user-specific click
      await _firestore
          .collection('eventAnalytics')
          .doc(eventId)
          .collection('userClicks')
          .doc('${userId}_${DateTime.now().millisecondsSinceEpoch}')
          .set({
        'userId': userId,
        'clickedAt': FieldValue.serverTimestamp(),
        'clickType': clickType, // 'ticket_link', 'location', 'organizer', etc.
      });

      log('Event click tracked for event: $eventId, user: $userId, type: $clickType', name: 'EventAnalyticsService');
    } catch (e) {
      log('Error tracking event click: $e', name: 'EventAnalyticsService');
    }
  }

  /// Get analytics for a specific event
  Future<EventAnalytics?> getEventAnalytics(String eventId) async {
    try {
      final doc = await _firestore.collection('eventAnalytics').doc(eventId).get();
      
      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      
      // Calculate conversion rate
      final totalViews = data['totalViews'] ?? 0;
      final totalRSVPs = data['totalRSVPs'] ?? 0;
      final conversionRate = totalViews > 0 ? (totalRSVPs / totalViews) * 100 : 0.0;

      return EventAnalytics(
        eventId: eventId,
        totalViews: totalViews,
        totalRSVPs: totalRSVPs,
        totalShares: data['totalShares'] ?? 0,
        totalClicks: data['totalClicks'] ?? 0,
        viewsByDay: Map<String, int>.from(data['viewsByDay'] ?? {}),
        rsvpsByDay: Map<String, int>.from(data['rsvpsByDay'] ?? {}),
        topLocations: List<String>.from(data['topLocations'] ?? []),
        topAgeGroups: List<String>.from(data['topAgeGroups'] ?? []),
        conversionRate: conversionRate,
        lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      );
    } catch (e) {
      log('Error getting event analytics: $e', name: 'EventAnalyticsService');
      return null;
    }
  }

  /// Get analytics for all events created by a user
  Future<List<EventAnalytics>> getUserEventAnalytics(String userId) async {
    try {
      // First get all events created by the user
      final eventsQuery = await _firestore
          .collection('events')
          .where('createdByUserId', isEqualTo: userId)
          .get();

      if (eventsQuery.docs.isEmpty) {
        return [];
      }

      final eventIds = eventsQuery.docs.map((doc) => doc.id).toList();
      final analyticsList = <EventAnalytics>[];

      // Get analytics for each event
      for (final eventId in eventIds) {
        final analytics = await getEventAnalytics(eventId);
        if (analytics != null) {
          analyticsList.add(analytics);
        }
      }

      // Sort by total views descending
      analyticsList.sort((a, b) => b.totalViews.compareTo(a.totalViews));

      return analyticsList;
    } catch (e) {
      log('Error getting user event analytics: $e', name: 'EventAnalyticsService');
      return [];
    }
  }

  /// Get trending events based on analytics
  Future<List<String>> getTrendingEventIds({int limit = 10}) async {
    try {
      final query = await _firestore
          .collection('eventAnalytics')
          .orderBy('totalViews', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => doc.id).toList();
    } catch (e) {
      log('Error getting trending event IDs: $e', name: 'EventAnalyticsService');
      return [];
    }
  }

  /// Get analytics summary for dashboard
  Future<Map<String, dynamic>> getAnalyticsSummary(String userId) async {
    try {
      final userAnalytics = await getUserEventAnalytics(userId);
      
      if (userAnalytics.isEmpty) {
        return {
          'totalEvents': 0,
          'totalViews': 0,
          'totalRSVPs': 0,
          'totalShares': 0,
          'averageConversionRate': 0.0,
          'topPerformingEvent': null,
        };
      }

      final totalViews = userAnalytics.fold(0, (sum, analytics) => sum + analytics.totalViews);
      final totalRSVPs = userAnalytics.fold(0, (sum, analytics) => sum + analytics.totalRSVPs);
      final totalShares = userAnalytics.fold(0, (sum, analytics) => sum + analytics.totalShares);
      final averageConversionRate = userAnalytics.fold(0.0, (sum, analytics) => sum + analytics.conversionRate) / userAnalytics.length;
      final topPerformingEvent = userAnalytics.isNotEmpty ? userAnalytics.first : null;

      return {
        'totalEvents': userAnalytics.length,
        'totalViews': totalViews,
        'totalRSVPs': totalRSVPs,
        'totalShares': totalShares,
        'averageConversionRate': averageConversionRate,
        'topPerformingEvent': topPerformingEvent?.toJson(),
      };
    } catch (e) {
      log('Error getting analytics summary: $e', name: 'EventAnalyticsService');
      return {
        'totalEvents': 0,
        'totalViews': 0,
        'totalRSVPs': 0,
        'totalShares': 0,
        'averageConversionRate': 0.0,
        'topPerformingEvent': null,
      };
    }
  }

  /// Update user demographics for better analytics
  Future<void> updateUserDemographics(String eventId, String userId, {
    String? location,
    String? ageGroup,
  }) async {
    try {
      final updates = <String, dynamic>{
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (location != null) {
        updates['userDemographics.$userId.location'] = location;
      }

      if (ageGroup != null) {
        updates['userDemographics.$userId.ageGroup'] = ageGroup;
      }

      await _firestore.collection('eventAnalytics').doc(eventId).update(updates);

      log('User demographics updated for event: $eventId, user: $userId', name: 'EventAnalyticsService');
    } catch (e) {
      log('Error updating user demographics: $e', name: 'EventAnalyticsService');
    }
  }
}
