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
  CollectionReference get _userEventsCollection =>
      _firestore.collection('userEvents');
  CollectionReference get _eventModerationCollection =>
      _firestore.collection('event_moderation');

  bool _isOwnedByCurrentUser(EnhancedEventModel event, String userId) =>
      event.ownerUserId == userId;

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

      log(
        'Created and published user event: ${eventRef.id}',
        name: 'UserEventService',
      );
      return eventRef.id;
    } on Object catch (e) {
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
      if (!_isOwnedByCurrentUser(existingEvent, currentUser.uid)) {
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
      await _eventsCollection
          .doc(eventId)
          .update(updatedEvent.toFirestoreJson());

      // Update moderation record
      await _updateModerationRecord(eventId, 'updated');

      log('Updated user event: $eventId', name: 'UserEventService');
    } on Object catch (e) {
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
      if (!_isOwnedByCurrentUser(existingEvent, currentUser.uid)) {
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
    } on Object catch (e) {
      log('Error deleting event: $e', name: 'UserEventService');
      rethrow;
    }
  }

  /// Get events created by a specific user
  Future<List<EnhancedEventModel>> getUserEvents(String userId) async {
    try {
      final createdByQuerySnapshot = await _eventsCollection
          .where('createdByUserId', isEqualTo: userId)
          .where('isUserGenerated', isEqualTo: true)
          .get();

      final creatorQuerySnapshot = await _eventsCollection
          .where('creatorId', isEqualTo: userId)
          .where('isUserGenerated', isEqualTo: true)
          .get();

      final eventById = <String, EnhancedEventModel>{};
      for (final doc in [
        ...createdByQuerySnapshot.docs,
        ...creatorQuerySnapshot.docs
      ]) {
        final event = EnhancedEventModel.fromFirestoreJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        if (event.status != EventStatus.cancelled) {
          eventById[doc.id] = event;
        }
      }

      final events = eventById.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return events;
    } on Object catch (e) {
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

      final events = querySnapshot.docs
          .map(
            (doc) => EnhancedEventModel.fromFirestoreJson(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .where(
            (event) => event.isVisible && event.status != EventStatus.cancelled,
          )
          .toList();

      log(
        'Fetched ${events.length} published user events',
        name: 'UserEventService',
      );
      return events;
    } on Object catch (e) {
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
      final eventIds =
          (userEventsData['events'] as Map<String, dynamic>?)?.keys.toList() ??
              [];

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
          querySnapshot.docs.map(
            (doc) => EnhancedEventModel.fromFirestoreJson(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          ),
        );
      }

      return events;
    } on Object catch (e) {
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
    } on Object catch (e) {
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
      if (!_isOwnedByCurrentUser(existingEvent, currentUser.uid)) {
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
    } on Object catch (e) {
      log('Error publishing draft event: $e', name: 'UserEventService');
      rethrow;
    }
  }

  /// Upload event images to Firebase Storage
  Future<List<String>> _uploadEventImages(List<String> imagePaths) async {
    log(
      '🖼️ _uploadEventImages called with ${imagePaths.length} image(s)',
      name: 'UserEventService',
    );

    final uploadedUrls = <String>[];

    if (imagePaths.isEmpty) {
      log('⚠️ No images to upload', name: 'UserEventService');
      return uploadedUrls;
    }

    for (int i = 0; i < imagePaths.length; i++) {
      final imagePath = imagePaths[i];
      log(
        '🖼️ Processing image ${i + 1}/${imagePaths.length}: $imagePath',
        name: 'UserEventService',
      );

      try {
        // Skip if it's already a URL (existing image)
        if (imagePath.startsWith('http')) {
          log(
            '✅ Image ${i + 1} is already a URL, skipping upload',
            name: 'UserEventService',
          );
          uploadedUrls.add(imagePath);
          continue;
        }

        final file = File(imagePath);
        if (!await file.exists()) {
          log('❌ Image file not found: $imagePath', name: 'UserEventService');
          continue;
        }

        log(
          '📤 Uploading image ${i + 1} to Firebase Storage...',
          name: 'UserEventService',
        );
        log(
          '📦 Storage instance: ${_storage.app.name}',
          name: 'UserEventService',
        );
        log(
          '📦 Storage bucket: ${_storage.app.options.storageBucket}',
          name: 'UserEventService',
        );

        // Verify user is authenticated
        final currentUser = _auth.currentUser;
        if (currentUser == null) {
          log(
            '❌ User is not authenticated - cannot upload',
            name: 'UserEventService',
          );
          throw Exception('User must be authenticated to upload images');
        }
        log(
          '✅ User authenticated: ${currentUser.uid}',
          name: 'UserEventService',
        );

        // Use owner-scoped path to enforce least-privilege storage rules.
        final fileName =
            'event_images/${currentUser.uid}/${DateTime.now().millisecondsSinceEpoch}_${imagePath.split('/').last}';
        log('📝 Target file path: $fileName', name: 'UserEventService');
        final ref = _storage.ref().child(fileName);

        // Upload file
        log(
          '📤 Starting upload task for image ${i + 1}...',
          name: 'UserEventService',
        );
        log(
          '📤 File size: ${await file.length()} bytes',
          name: 'UserEventService',
        );

        // Read file as bytes - sometimes putFile fails on iOS Simulator
        final fileBytes = await file.readAsBytes();
        log(
          '📤 File bytes read: ${fileBytes.length} bytes',
          name: 'UserEventService',
        );

        // Try using putData instead of putFile (more reliable on iOS Simulator)
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          cacheControl: 'public, max-age=31536000',
        );

        log('📤 Uploading with putData...', name: 'UserEventService');
        log('📤 Reference path: ${ref.fullPath}', name: 'UserEventService');
        log('📤 Reference bucket: ${ref.bucket}', name: 'UserEventService');

        final uploadTask = ref.putData(fileBytes, metadata);

        // Monitor upload progress
        uploadTask.snapshotEvents.listen(
          (snapshot) {
            if (snapshot.totalBytes > 0) {
              final progress =
                  (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
              log(
                '📊 Upload progress for image ${i + 1}: ${progress.toStringAsFixed(1)}%',
                name: 'UserEventService',
              );
            } else {
              log(
                '📊 Upload progress: ${snapshot.bytesTransferred} bytes transferred (total unknown)',
                name: 'UserEventService',
              );
            }
          },
          onError: (error) {
            log(
              '❌ Upload progress error for image ${i + 1}: $error',
              name: 'UserEventService',
            );
          },
        );

        log('⏳ Waiting for upload to complete...', name: 'UserEventService');
        final snapshot = await uploadTask.whenComplete(() {
          log(
            '✅ Upload task completed for image ${i + 1}',
            name: 'UserEventService',
          );
        }).catchError((error) {
          log(
            '❌ Upload task failed for image ${i + 1}: $error',
            name: 'UserEventService',
          );
          throw error;
        });
        log(
          '✅ Upload completed, getting download URL...',
          name: 'UserEventService',
        );

        final downloadUrl = await snapshot.ref.getDownloadURL();

        uploadedUrls.add(downloadUrl);
        log(
          '✅ Successfully uploaded image ${i + 1}: $downloadUrl',
          name: 'UserEventService',
        );
      } on Object catch (e, stackTrace) {
        log(
          '❌ Error uploading image ${i + 1} ($imagePath)',
          name: 'UserEventService',
        );
        log('❌ Error type: ${e.runtimeType}', name: 'UserEventService');
        log('❌ Error toString: ${e.toString()}', name: 'UserEventService');

        // Handle FirebaseException specifically
        if (e is FirebaseException) {
          log(
            '❌ FirebaseException - Code: ${e.code}, Message: ${e.message}',
            name: 'UserEventService',
          );
          log('❌ Plugin: ${e.plugin}', name: 'UserEventService');

          if (e.code == 'permission-denied') {
            log(
              '❌ PERMISSION DENIED - Storage rules may be blocking upload',
              name: 'UserEventService',
            );
          } else if (e.code == 'unknown') {
            log(
              '❌ UNKNOWN ERROR - This could indicate:',
              name: 'UserEventService',
            );
            log(
              '   - Storage bucket not configured correctly',
              name: 'UserEventService',
            );
            log('   - Network connectivity issue', name: 'UserEventService');
            log(
              '   - Firebase Storage not initialized properly',
              name: 'UserEventService',
            );
            log(
              '   - Storage rules still propagating (wait a few minutes)',
              name: 'UserEventService',
            );
          } else if (e.code == 'unauthorized') {
            log(
              '❌ UNAUTHORIZED - User may not be authenticated',
              name: 'UserEventService',
            );
          }
        } else {
          log('❌ Non-Firebase exception: $e', name: 'UserEventService');
        }

        log('❌ Stack trace: $stackTrace', name: 'UserEventService');
        // Continue with other images even if one fails
      }
    }

    log(
      '✅ _uploadEventImages completed: ${uploadedUrls.length}/${imagePaths.length} images uploaded',
      name: 'UserEventService',
    );
    return uploadedUrls;
  }

  /// Add event to user's events collection
  Future<void> _addToUserEvents(
    String userId,
    String eventId,
    String role,
  ) async {
    await _userEventsCollection.doc(userId).set(
      {
        'events': {
          eventId: {
            'role': role,
            'joinedAt': Timestamp.fromDate(DateTime.now()),
            'status': 'active',
          },
        },
      },
      SetOptions(merge: true),
    );
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
}

// Exception classes
class UserEventException implements Exception {
  UserEventException(this.message);
  final String message;

  @override
  String toString() => 'UserEventException: $message';
}

class EventValidationException extends UserEventException {
  EventValidationException(super.message);
}

class EventPermissionException extends UserEventException {
  EventPermissionException(super.message);
}
