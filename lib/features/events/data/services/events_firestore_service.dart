import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../models/rsvp_model.dart';

class EventsFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _eventsCollection => _firestore.collection('events');
  CollectionReference get _userRSVPsCollection =>
      _firestore.collection('user_rsvps');
  CollectionReference get _eventAttendeesCollection =>
      _firestore.collection('event_attendees');

  /// Save events to Firestore (batch operation for efficiency)
  Future<void> saveEvents(List<EventModel> events) async {
    try {
      final batch = _firestore.batch();

      for (final event in events) {
        // Use event.id instead of eventbriteId for user-generated events
        final docRef = _eventsCollection.doc(event.id);
        batch.set(docRef, event.toFirestoreJson(), SetOptions(merge: true));
      }

      await batch.commit();
      log(
        'Saved ${events.length} events to Firestore',
        name: 'EventsFirestoreService',
      );
    } catch (e) {
      log(
        'Error saving events to Firestore: $e',
        name: 'EventsFirestoreService',
      );
      throw FirestoreException('Failed to save events: $e');
    }
  }

  /// Fetch events from Firestore with pagination
  Future<List<EventModel>> fetchEvents({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    DateTime? startDate,
    String? category,
  }) async {
    try {
      Query query = _eventsCollection
          .where(
            'startDate',
            isGreaterThanOrEqualTo: startDate ?? DateTime.now(),
          )
          .orderBy('startDate')
          .limit(limit);

      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();

      final events = querySnapshot.docs
          .map(
            (doc) => EventModel.fromFirestoreJson(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();

      log(
        'Fetched ${events.length} events from Firestore',
        name: 'EventsFirestoreService',
      );
      return events;
    } catch (e) {
      log(
        'Error fetching events from Firestore: $e',
        name: 'EventsFirestoreService',
      );
      throw FirestoreException('Failed to fetch events: $e');
    }
  }

  /// Get a specific event by ID
  Future<EventModel?> getEventById(String eventId) async {
    try {
      final doc = await _eventsCollection.doc(eventId).get();

      if (doc.exists) {
        return EventModel.fromFirestoreJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      log('Error fetching event $eventId: $e', name: 'EventsFirestoreService');
      return null;
    }
  }

  /// RSVP to an event
  Future<void> rsvpToEvent({
    required String userId,
    required String eventId,
    required RSVPStatus status,
    Map<String, dynamic>? userProfile,
    String? notes,
  }) async {
    try {
      final batch = _firestore.batch();

      // Create RSVP model
      final rsvp = RSVPModel(
        id: '${userId}_$eventId',
        userId: userId,
        eventId: eventId,
        status: status,
        rsvpDate: DateTime.now(),
        userProfile: userProfile,
        notes: notes,
      );

      // Save to user_rsvps collection
      final userRSVPRef =
          _userRSVPsCollection.doc(userId).collection('events').doc(eventId);
      batch.set(userRSVPRef, rsvp.toFirestoreJson());

      // Save to event_attendees collection
      final attendeeRef = _eventAttendeesCollection
          .doc(eventId)
          .collection('attendees')
          .doc(userId);
      batch.set(attendeeRef, rsvp.toFirestoreJson());

      // Update event RSVP count
      final eventRef = _eventsCollection.doc(eventId);
      if (status == RSVPStatus.going) {
        batch.update(eventRef, {
          'rsvpCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      log(
        'RSVP saved for user $userId to event $eventId with status ${status.value}',
        name: 'EventsFirestoreService',
      );
    } catch (e) {
      log('Error saving RSVP: $e', name: 'EventsFirestoreService');
      throw FirestoreException('Failed to save RSVP: $e');
    }
  }

  /// Update existing RSVP
  Future<void> updateRSVP({
    required String userId,
    required String eventId,
    required RSVPStatus oldStatus,
    required RSVPStatus newStatus,
  }) async {
    try {
      final batch = _firestore.batch();

      // Update user RSVP
      final userRSVPRef =
          _userRSVPsCollection.doc(userId).collection('events').doc(eventId);
      batch.update(userRSVPRef, {
        'status': newStatus.value,
        'rsvpDate': FieldValue.serverTimestamp(),
      });

      // Update attendee record
      final attendeeRef = _eventAttendeesCollection
          .doc(eventId)
          .collection('attendees')
          .doc(userId);
      batch.update(attendeeRef, {
        'status': newStatus.value,
        'rsvpDate': FieldValue.serverTimestamp(),
      });

      // Update event RSVP count
      final eventRef = _eventsCollection.doc(eventId);
      int countChange = 0;

      if (oldStatus == RSVPStatus.going && newStatus != RSVPStatus.going) {
        countChange = -1; // Decrement if changing from going to something else
      } else if (oldStatus != RSVPStatus.going &&
          newStatus == RSVPStatus.going) {
        countChange = 1; // Increment if changing to going
      }

      if (countChange != 0) {
        batch.update(eventRef, {
          'rsvpCount': FieldValue.increment(countChange),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      log(
        'RSVP updated for user $userId to event $eventId: ${oldStatus.value} -> ${newStatus.value}',
        name: 'EventsFirestoreService',
      );
    } catch (e) {
      log('Error updating RSVP: $e', name: 'EventsFirestoreService');
      throw FirestoreException('Failed to update RSVP: $e');
    }
  }

  /// Get user's RSVP status for a specific event
  Future<RSVPModel?> getUserRSVP(String userId, String eventId) async {
    try {
      final doc = await _userRSVPsCollection
          .doc(userId)
          .collection('events')
          .doc(eventId)
          .get();

      if (doc.exists) {
        return RSVPModel.fromFirestoreJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      log('Error fetching user RSVP: $e', name: 'EventsFirestoreService');
      return null;
    }
  }

  /// Get all user's RSVPs
  Future<List<RSVPModel>> getUserRSVPs(String userId) async {
    try {
      final querySnapshot = await _userRSVPsCollection
          .doc(userId)
          .collection('events')
          .orderBy('rsvpDate', descending: true)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => RSVPModel.fromFirestoreJson(
              doc.data(),
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      log('Error fetching user RSVPs: $e', name: 'EventsFirestoreService');
      throw FirestoreException('Failed to fetch user RSVPs: $e');
    }
  }

  /// Get event attendees
  Future<List<EventAttendeeModel>> getEventAttendees(
    String eventId, {
    RSVPStatus? status,
  }) async {
    try {
      Query query = _eventAttendeesCollection
          .doc(eventId)
          .collection('attendees')
          .orderBy('rsvpDate', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.value);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map(
            (doc) => EventAttendeeModel.fromFirestoreJson(
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      log('Error fetching event attendees: $e', name: 'EventsFirestoreService');
      throw FirestoreException('Failed to fetch event attendees: $e');
    }
  }

  /// Search events in Firestore
  Future<List<EventModel>> searchEvents(String query) async {
    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation - consider using Algolia or similar for production
      final querySnapshot = await _eventsCollection
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => EventModel.fromFirestoreJson(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      log('Error searching events: $e', name: 'EventsFirestoreService');
      throw FirestoreException('Failed to search events: $e');
    }
  }

  /// Get events by category
  Future<List<EventModel>> getEventsByCategory(
    String category, {
    int limit = 20,
  }) async {
    try {
      final querySnapshot = await _eventsCollection
          .where('category', isEqualTo: category)
          .where('startDate', isGreaterThanOrEqualTo: DateTime.now())
          .orderBy('startDate')
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => EventModel.fromFirestoreJson(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      log(
        'Error fetching events by category: $e',
        name: 'EventsFirestoreService',
      );
      throw FirestoreException('Failed to fetch events by category: $e');
    }
  }

  /// Delete old events (cleanup job)
  Future<void> deleteOldEvents({int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      final querySnapshot = await _eventsCollection
          .where('endDate', isLessThan: cutoffDate)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      log(
        'Deleted ${querySnapshot.docs.length} old events',
        name: 'EventsFirestoreService',
      );
    } catch (e) {
      log('Error deleting old events: $e', name: 'EventsFirestoreService');
    }
  }
}

class FirestoreException implements Exception {
  const FirestoreException(this.message);
  final String message;

  @override
  String toString() => 'FirestoreException: $message';
}
