import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/enhanced_event_model.dart';

class UserEventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _eventsCollection => _firestore.collection('events');
  CollectionReference get _userEventsCollection => _firestore.collection('userEvents');
  CollectionReference get _eventModerationCollection => _firestore.collection('event_moderation');

  /// Create a new user-generated event
  Future<String> createEvent(EventCreationData data) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated to create events');
      }

      // Validate event data
      if (!data.isValid) {
        throw Exception('Invalid event data provided');
      }

      // Upload images to Firebase Storage
      final imageUrls = await _uploadEventImages(data.imageUrls);

      // Create event document reference
      final eventRef = _eventsCollection.doc();
      
      // Update data with uploaded image URLs
      data.imageUrls = imageUrls;
      
      // Create enhanced event model
      final event = data.toEventModel(eventRef.id, currentUser.uid);

      // Save event to Firestore with published status
      await eventRef.set(event.toFirestoreJson());

      // Add to user's events collection
      await _addToUserEvents(currentUser.uid, eventRef.id, 'creator');

      // No moderation needed - events are immediately published
      // await _createModerationRecord(eventRef.id); // REMOVED

      log('Created and published user event: ${eventRef.id}', name: 'UserEventService');
      return eventRef.id;
    } catch (e) {
      log('Error creating event: $e', name: 'UserEventService');
      rethrow;
    }
  }

  /// Update an existing user event
  Future<void> updateEvent(String eventId, EventCreationData data) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated to update events');
      }

      // Get existing event
      final eventDoc = await _eventsCollection.doc(eventId).get();
      if (!eventDoc.exists) {
        throw Exception('Event not found');
      }

      final existingEvent = EnhancedEventModel.fromFirestoreJson(
        eventDoc.data() as Map<String, dynamic>,
        eventDoc.id,
      );

      // Check if user owns the event
      if (existingEvent.createdByUserId != currentUser.uid) {
        throw Exception('User does not have permission to update this event');
      }

      // Check if event can be edited
      if (!existingEvent.canEdit) {
        throw Exception('Event cannot be edited in its current status');
      }

      // Upload new images if any
      final newImageUrls = await _uploadEventImages(data.imageUrls);
      // Replace existing images with new ones (don't append)
      data.imageUrls = newImageUrls;

      // Create updated event
      final updatedEvent = existingEvent.copyWith(
        name: data.name,
        description: data.description,
        startDate: data.startDate,
        endDate: data.endDate,
        location: data.location,
        imageUrls: data.imageUrls,
        isFree: data.isFree,
        ticketPrice: data.ticketPrice,
        category: data.category,
        tags: data.tags,
        maxAttendees: data.maxAttendees,
        metadata: data.metadata,
        updatedAt: DateTime.now(),
        status: EventStatus.underReview, // Reset to review after update
      );

      // Update in Firestore
      await _eventsCollection.doc(eventId).update(updatedEvent.toFirestoreJson());

      // Update moderation record
      await _updateModerationRecord(eventId, 'updated');

      log('Updated user event: $eventId', name: 'UserEventService');
    } catch (e) {
      log('Error updating event: $e', name: 'UserEventService');
      rethrow;
    }
  }

  /// Delete (soft delete) a user event
  Future<void> deleteEvent(String eventId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated to delete events');
      }

      // Get existing event
      final eventDoc = await _eventsCollection.doc(eventId).get();
      if (!eventDoc.exists) {
        throw Exception('Event not found');
      }

      final existingEvent = EnhancedEventModel.fromFirestoreJson(
        eventDoc.data() as Map<String, dynamic>,
        eventDoc.id,
      );

      // Check if user owns the event
      if (existingEvent.createdByUserId != currentUser.uid) {
        throw Exception('User does not have permission to delete this event');
      }

      // Soft delete by updating status
      await _eventsCollection.doc(eventId).update({
        'status': EventStatus.cancelled.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Remove from user's active events
      await _removeFromUserEvents(currentUser.uid, eventId);

      log('Deleted user event: $eventId', name: 'UserEventService');
    } catch (e) {
      log('Error deleting event: $e', name: 'UserEventService');
      rethrow;
    }
  }

  /// Get events created by a specific user
  Future<List<EnhancedEventModel>> getUserEvents(String userId) async {
    try {
      final querySnapshot = await _eventsCollection
          .where('createdByUserId', isEqualTo: userId)
          .where('isUserGenerated', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      // Filter out cancelled/deleted events
      return querySnapshot.docs
          .map((doc) => EnhancedEventModel.fromFirestoreJson(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .where((event) => event.status != EventStatus.cancelled)
          .toList();
    } catch (e) {
      log('Error fetching user events: $e', name: 'UserEventService');
      rethrow;
    }
  }

  /// Get all published user-generated events for the main feed
  Future<List<EnhancedEventModel>> getPublishedEvents({int limit = 20}) async {
    try {
      final querySnapshot = await _eventsCollection
          .where('isUserGenerated', isEqualTo: true)
          .where('status', isEqualTo: 'published')
          .where('endDate', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .orderBy('endDate')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final events = querySnapshot.docs.map((doc) {
        return EnhancedEventModel.fromFirestoreJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).where((event) => event.isVisible && event.status != EventStatus.cancelled).toList();

      log('Fetched ${events.length} published user events', name: 'UserEventService');
      return events;
    } catch (e) {
      log('Error getting published events: $e', name: 'UserEventService');
      return [];
    }
  }

  /// Get events the user is attending
  Future<List<EnhancedEventModel>> getUserAttendingEvents(String userId) async {
    try {
      final userEventsDoc = await _userEventsCollection.doc(userId).get();
      if (!userEventsDoc.exists) {
        return [];
      }

      final userEventsData = userEventsDoc.data() as Map<String, dynamic>;
      final eventIds = (userEventsData['events'] as Map<String, dynamic>?)?.keys.toList() ?? [];

      if (eventIds.isEmpty) {
        return [];
      }

      // Fetch events in batches (Firestore 'in' query limit is 10)
      final events = <EnhancedEventModel>[];
      for (int i = 0; i < eventIds.length; i += 10) {
        final batch = eventIds.skip(i).take(10).toList();
        final querySnapshot = await _eventsCollection
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        events.addAll(
          querySnapshot.docs.map((doc) => EnhancedEventModel.fromFirestoreJson(
            doc.data() as Map<String, dynamic>,
            doc.id,
          )),
        );
      }

      return events;
    } catch (e) {
      log('Error fetching user attending events: $e', name: 'UserEventService');
      rethrow;
    }
  }

  /// Save event as draft
  Future<String> saveEventAsDraft(EventCreationData data) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated to save drafts');
      }

      // Create event document reference
      final eventRef = _eventsCollection.doc();
      
      // Create event model with draft status
      final event = data.toEventModel(eventRef.id, currentUser.uid).copyWith(
        status: EventStatus.draft,
      );

      // Save event to Firestore
      await eventRef.set(event.toFirestoreJson());

      // Add to user's events collection
      await _addToUserEvents(currentUser.uid, eventRef.id, 'creator');

      log('Saved event draft: ${eventRef.id}', name: 'UserEventService');
      return eventRef.id;
    } catch (e) {
      log('Error saving event draft: $e', name: 'UserEventService');
      rethrow;
    }
  }

  /// Publish a draft event
  Future<void> publishDraftEvent(String eventId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated to publish events');
      }

      // Get existing event
      final eventDoc = await _eventsCollection.doc(eventId).get();
      if (!eventDoc.exists) {
        throw Exception('Event not found');
      }

      final existingEvent = EnhancedEventModel.fromFirestoreJson(
        eventDoc.data() as Map<String, dynamic>,
        eventDoc.id,
      );

      // Check if user owns the event
      if (existingEvent.createdByUserId != currentUser.uid) {
        throw Exception('User does not have permission to publish this event');
      }

      // Check if event is in draft status
      if (existingEvent.status != EventStatus.draft) {
        throw Exception('Only draft events can be published');
      }

      // Update status to under review
      await _eventsCollection.doc(eventId).update({
        'status': EventStatus.underReview.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Create moderation record
      await _createModerationRecord(eventId);

      log('Published draft event: $eventId', name: 'UserEventService');
    } catch (e) {
      log('Error publishing draft event: $e', name: 'UserEventService');
      rethrow;
    }
  }

  /// Upload event images to Firebase Storage
  Future<List<String>> _uploadEventImages(List<String> imagePaths) async {
    final uploadedUrls = <String>[];

    for (final imagePath in imagePaths) {
      try {
        // Skip if it's already a URL (existing image)
        if (imagePath.startsWith('http')) {
          uploadedUrls.add(imagePath);
          continue;
        }

        final file = File(imagePath);
        if (!await file.exists()) {
          log('Image file not found: $imagePath', name: 'UserEventService');
          continue;
        }

        // Create unique filename
        final fileName = 'event_images/${DateTime.now().millisecondsSinceEpoch}_${imagePath.split('/').last}';
        final ref = _storage.ref().child(fileName);

        // Upload file
        final uploadTask = ref.putFile(file);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        uploadedUrls.add(downloadUrl);
        log('Uploaded image: $downloadUrl', name: 'UserEventService');
      } catch (e) {
        log('Error uploading image $imagePath: $e', name: 'UserEventService');
        // Continue with other images even if one fails
      }
    }

    return uploadedUrls;
  }

  /// Add event to user's events collection
  Future<void> _addToUserEvents(String userId, String eventId, String role) async {
    await _userEventsCollection.doc(userId).set({
      'events': {
        eventId: {
          'role': role,
          'joinedAt': Timestamp.fromDate(DateTime.now()),
          'status': 'active',
        }
      }
    }, SetOptions(merge: true));
  }

  /// Remove event from user's events collection
  Future<void> _removeFromUserEvents(String userId, String eventId) async {
    await _userEventsCollection.doc(userId).update({
      'events.$eventId': FieldValue.delete(),
    });
  }

  /// Create moderation record for new event
  Future<void> _createModerationRecord(String eventId) async {
    await _eventModerationCollection.doc(eventId).set({
      'status': 'pending',
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'notes': '',
      'reviewedBy': null,
      'reviewedAt': null,
    });
  }

  /// Update moderation record
  Future<void> _updateModerationRecord(String eventId, String action) async {
    await _eventModerationCollection.doc(eventId).update({
      'status': 'pending',
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'notes': 'Event $action by user',
    });
  }

  /// Validate event data
  void _validateEventData(EventCreationData data) {
    if (!data.isValid) {
      throw Exception('Invalid event data');
    }

    // Additional validations
    if (data.startDate!.isBefore(DateTime.now().add(Duration(hours: 1)))) {
      throw Exception('Event must start at least 1 hour from now');
    }

    if (data.endDate!.difference(data.startDate!).inHours > 168) { // 7 days
      throw Exception('Event duration cannot exceed 7 days');
    }

    if (data.maxAttendees < 1 || data.maxAttendees > 10000) {
      throw Exception('Max attendees must be between 1 and 10,000');
    }

    if (!data.isFree && (data.ticketPrice == null || data.ticketPrice! <= 0)) {
      throw Exception('Paid events must have a valid ticket price');
    }
  }
}

// Exception classes
class UserEventException implements Exception {
  final String message;
  UserEventException(this.message);

  @override
  String toString() => 'UserEventException: $message';
}

class EventValidationException extends UserEventException {
  EventValidationException(String message) : super(message);
}

class EventPermissionException extends UserEventException {
  EventPermissionException(String message) : super(message);
}
