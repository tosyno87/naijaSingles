import 'dart:async';
import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/rsvp_model.dart';
import '../../data/services/events_firestore_service.dart';

// RSVP Events
abstract class RSVPEvent extends Equatable {
  const RSVPEvent();

  @override
  List<Object?> get props => [];
}

class RSVPToEventEvent extends RSVPEvent {

  const RSVPToEventEvent({
    required this.eventId,
    required this.status,
    this.notes,
  });
  final String eventId;
  final RSVPStatus status;
  final String? notes;

  @override
  List<Object?> get props => [eventId, status, notes];
}

class LoadUserRSVPsEvent extends RSVPEvent {

  const LoadUserRSVPsEvent(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

class LoadEventRSVPStatusEvent extends RSVPEvent {

  const LoadEventRSVPStatusEvent({
    required this.userId,
    required this.eventId,
  });
  final String userId;
  final String eventId;

  @override
  List<Object?> get props => [userId, eventId];
}

class LoadEventAttendeesEvent extends RSVPEvent {

  const LoadEventAttendeesEvent({
    required this.eventId,
    this.statusFilter,
  });
  final String eventId;
  final RSVPStatus? statusFilter;

  @override
  List<Object?> get props => [eventId, statusFilter];
}

// RSVP States
abstract class RSVPState extends Equatable {
  const RSVPState();

  @override
  List<Object?> get props => [];
}

class RSVPInitial extends RSVPState {}

class RSVPLoading extends RSVPState {}

class RSVPSuccess extends RSVPState {

  const RSVPSuccess({
    required this.eventId,
    required this.status,
    required this.message,
  });
  final String eventId;
  final RSVPStatus status;
  final String message;

  @override
  List<Object?> get props => [eventId, status, message];
}

class RSVPError extends RSVPState {

  const RSVPError({
    required this.message,
    this.eventId,
  });
  final String message;
  final String? eventId;

  @override
  List<Object?> get props => [message, eventId];
}

class UserRSVPsLoaded extends RSVPState {

  const UserRSVPsLoaded({
    required this.rsvps,
    required this.userId,
  });
  final List<RSVPModel> rsvps;
  final String userId;

  @override
  List<Object?> get props => [rsvps, userId];
}

class EventRSVPStatusLoaded extends RSVPState {

  const EventRSVPStatusLoaded({
    required this.eventId,
    required this.status,
    this.rsvpModel,
  });
  final String eventId;
  final RSVPStatus status;
  final RSVPModel? rsvpModel;

  @override
  List<Object?> get props => [eventId, status, rsvpModel];
}

class EventAttendeesLoaded extends RSVPState {

  const EventAttendeesLoaded({
    required this.eventId,
    required this.attendees,
    required this.statusCounts,
  });
  final String eventId;
  final List<EventAttendeeModel> attendees;
  final Map<RSVPStatus, int> statusCounts;

  @override
  List<Object?> get props => [eventId, attendees, statusCounts];
}

// RSVP BLoC
class RSVPBloc extends Bloc<RSVPEvent, RSVPState> {

  RSVPBloc({
    required EventsFirestoreService firestoreService,
    required String currentUserId,
  })  : _firestoreService = firestoreService,
        _currentUserId = currentUserId,
        super(RSVPInitial()) {
    on<RSVPToEventEvent>(_onRSVPToEvent);
    on<LoadUserRSVPsEvent>(_onLoadUserRSVPs);
    on<LoadEventRSVPStatusEvent>(_onLoadEventRSVPStatus);
    on<LoadEventAttendeesEvent>(_onLoadEventAttendees);
  }
  final EventsFirestoreService _firestoreService;
  final String _currentUserId;

  // Cache for RSVP statuses to avoid repeated queries
  final Map<String, RSVPModel> _rsvpCache = {};

  Future<void> _onRSVPToEvent(
      RSVPToEventEvent event, Emitter<RSVPState> emit,) async {
    emit(RSVPLoading());

    try {
      // Check if user already has an RSVP for this event
      final existingRSVP =
          await _firestoreService.getUserRSVP(_currentUserId, event.eventId);

      if (existingRSVP != null) {
        // Update existing RSVP
        await _firestoreService.updateRSVP(
          userId: _currentUserId,
          eventId: event.eventId,
          oldStatus: existingRSVP.status,
          newStatus: event.status,
        );

        log('Updated RSVP for event ${event.eventId}: ${existingRSVP.status.value} -> ${event.status.value}',
            name: 'RSVPBloc',);
      } else {
        // Create new RSVP
        await _firestoreService.rsvpToEvent(
          userId: _currentUserId,
          eventId: event.eventId,
          status: event.status,
          userProfile: await _getUserProfile(),
          notes: event.notes,
        );

        log('Created new RSVP for event ${event.eventId} with status ${event.status.value}',
            name: 'RSVPBloc',);
      }

      // Update cache
      final newRSVP = RSVPModel(
        id: '${_currentUserId}_${event.eventId}',
        userId: _currentUserId,
        eventId: event.eventId,
        status: event.status,
        rsvpDate: DateTime.now(),
        notes: event.notes,
      );
      _rsvpCache[event.eventId] = newRSVP;

      emit(RSVPSuccess(
        eventId: event.eventId,
        status: event.status,
        message: _getSuccessMessage(event.status),
      ),);
    } catch (e) {
      log('Error processing RSVP: $e', name: 'RSVPBloc');
      emit(RSVPError(
        message: 'Failed to update RSVP. Please try again.',
        eventId: event.eventId,
      ),);
    }
  }

  Future<void> _onLoadUserRSVPs(
      LoadUserRSVPsEvent event, Emitter<RSVPState> emit,) async {
    emit(RSVPLoading());

    try {
      final rsvps = await _firestoreService.getUserRSVPs(event.userId);

      // Update cache
      for (final rsvp in rsvps) {
        _rsvpCache[rsvp.eventId] = rsvp;
      }

      emit(UserRSVPsLoaded(
        rsvps: rsvps,
        userId: event.userId,
      ),);

      log('Loaded ${rsvps.length} RSVPs for user ${event.userId}',
          name: 'RSVPBloc',);
    } catch (e) {
      log('Error loading user RSVPs: $e', name: 'RSVPBloc');
      emit(const RSVPError(
          message: 'Failed to load your RSVPs. Please try again.',),);
    }
  }

  Future<void> _onLoadEventRSVPStatus(
      LoadEventRSVPStatusEvent event, Emitter<RSVPState> emit,) async {
    try {
      // Check cache first
      if (_rsvpCache.containsKey(event.eventId)) {
        final cachedRSVP = _rsvpCache[event.eventId]!;
        emit(EventRSVPStatusLoaded(
          eventId: event.eventId,
          status: cachedRSVP.status,
          rsvpModel: cachedRSVP,
        ),);
        return;
      }

      // Load from Firestore
      final rsvp =
          await _firestoreService.getUserRSVP(event.userId, event.eventId);

      if (rsvp != null) {
        _rsvpCache[event.eventId] = rsvp;
        emit(EventRSVPStatusLoaded(
          eventId: event.eventId,
          status: rsvp.status,
          rsvpModel: rsvp,
        ),);
      } else {
        emit(const EventRSVPStatusLoaded(
          eventId: '',
          status: RSVPStatus.none,
        ),);
      }
    } catch (e) {
      log('Error loading RSVP status: $e', name: 'RSVPBloc');
      // Don't emit error for RSVP status loading - just assume no RSVP
      emit(EventRSVPStatusLoaded(
        eventId: event.eventId,
        status: RSVPStatus.none,
      ),);
    }
  }

  Future<void> _onLoadEventAttendees(
      LoadEventAttendeesEvent event, Emitter<RSVPState> emit,) async {
    emit(RSVPLoading());

    try {
      final attendees = await _firestoreService.getEventAttendees(
        event.eventId,
        status: event.statusFilter,
      );

      // Calculate status counts
      final statusCounts = <RSVPStatus, int>{};
      for (final status in RSVPStatus.values) {
        statusCounts[status] =
            attendees.where((a) => a.status == status).length;
      }

      emit(EventAttendeesLoaded(
        eventId: event.eventId,
        attendees: attendees,
        statusCounts: statusCounts,
      ),);

      log('Loaded ${attendees.length} attendees for event ${event.eventId}',
          name: 'RSVPBloc',);
    } catch (e) {
      log('Error loading event attendees: $e', name: 'RSVPBloc');
      emit(const RSVPError(
          message: 'Failed to load event attendees. Please try again.',),);
    }
  }

  Future<Map<String, dynamic>?> _getUserProfile() async {
    // TODO: Implement user profile fetching from your user service
    // This should return basic user info for the attendee list
    return {
      'name': 'Current User', // Replace with actual user name
      'avatar': null, // Replace with actual user avatar
      'age': null, // Replace with actual user age
      'location': null, // Replace with actual user location
    };
  }

  String _getSuccessMessage(RSVPStatus status) {
    switch (status) {
      case RSVPStatus.going:
        return "Great! You're going to this event. We'll send you reminders.";
      case RSVPStatus.interested:
        return "Thanks for showing interest! We'll keep you updated.";
      case RSVPStatus.notGoing:
        return 'Thanks for letting us know. Maybe next time!';
      case RSVPStatus.none:
        return 'RSVP removed successfully.';
    }
  }

  // Helper method to get RSVP status for an event (used by UI)
  RSVPStatus getRSVPStatus(String eventId) => _rsvpCache[eventId]?.status ?? RSVPStatus.none;

  // Helper method to check if user is going to an event
  bool isUserGoing(String eventId) => getRSVPStatus(eventId) == RSVPStatus.going;

  // Helper method to get all events user is going to
  List<String> getGoingEventIds() => _rsvpCache.entries
        .where((entry) => entry.value.status == RSVPStatus.going)
        .map((entry) => entry.key)
        .toList();

  // Clear cache (useful for logout)
  void clearCache() {
    _rsvpCache.clear();
  }
}
