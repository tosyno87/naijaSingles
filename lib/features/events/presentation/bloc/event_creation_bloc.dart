import 'dart:async';
import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/enhanced_event_model.dart';
import '../../data/services/user_event_service.dart';

// Events
abstract class EventCreationEvent extends Equatable {
  const EventCreationEvent();

  @override
  List<Object?> get props => [];
}

class CreateEventEvent extends EventCreationEvent {
  final EventCreationData eventData;

  const CreateEventEvent(this.eventData);

  @override
  List<Object?> get props => [eventData];
}

class UpdateEventEvent extends EventCreationEvent {
  final String eventId;
  final EventCreationData eventData;

  const UpdateEventEvent(this.eventId, this.eventData);

  @override
  List<Object?> get props => [eventId, eventData];
}

class SaveEventAsDraftEvent extends EventCreationEvent {
  final EventCreationData eventData;

  const SaveEventAsDraftEvent(this.eventData);

  @override
  List<Object?> get props => [eventData];
}

class PublishDraftEventEvent extends EventCreationEvent {
  final String eventId;

  const PublishDraftEventEvent(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

class DeleteEventEvent extends EventCreationEvent {
  final String eventId;

  const DeleteEventEvent(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

class LoadUserEventsEvent extends EventCreationEvent {
  final String userId;

  const LoadUserEventsEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class ValidateEventDataEvent extends EventCreationEvent {
  final EventCreationData eventData;

  const ValidateEventDataEvent(this.eventData);

  @override
  List<Object?> get props => [eventData];
}

// States
abstract class EventCreationState extends Equatable {
  const EventCreationState();

  @override
  List<Object?> get props => [];
}

class EventCreationInitial extends EventCreationState {}

class EventCreationLoading extends EventCreationState {}

class EventCreationSuccess extends EventCreationState {
  final String eventId;
  final String message;

  const EventCreationSuccess(this.eventId, this.message);

  @override
  List<Object?> get props => [eventId, message];
}

class EventCreationError extends EventCreationState {
  final String message;
  final String? errorCode;

  const EventCreationError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}

class EventValidationState extends EventCreationState {
  final bool isValid;
  final List<String> errors;

  const EventValidationState(this.isValid, this.errors);

  @override
  List<Object?> get props => [isValid, errors];
}

class UserEventsLoaded extends EventCreationState {
  final List<EnhancedEventModel> events;
  final List<EnhancedEventModel> drafts;

  const UserEventsLoaded(this.events, this.drafts);

  @override
  List<Object?> get props => [events, drafts];
}

class UserEventsLoading extends EventCreationState {}

class UserEventsError extends EventCreationState {
  final String message;

  const UserEventsError(this.message);

  @override
  List<Object?> get props => [message];
}

class EventDraftSaved extends EventCreationState {
  final String eventId;

  const EventDraftSaved(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

class EventPublished extends EventCreationState {
  final String eventId;

  const EventPublished(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

class EventDeleted extends EventCreationState {
  final String eventId;

  const EventDeleted(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

// BLoC
class EventCreationBloc extends Bloc<EventCreationEvent, EventCreationState> {
  final UserEventService _userEventService;

  EventCreationBloc({
    required UserEventService userEventService,
  })  : _userEventService = userEventService,
        super(EventCreationInitial()) {
    on<CreateEventEvent>(_onCreateEvent);
    on<UpdateEventEvent>(_onUpdateEvent);
    on<SaveEventAsDraftEvent>(_onSaveEventAsDraft);
    on<PublishDraftEventEvent>(_onPublishDraftEvent);
    on<DeleteEventEvent>(_onDeleteEvent);
    on<LoadUserEventsEvent>(_onLoadUserEvents);
    on<ValidateEventDataEvent>(_onValidateEventData);
  }

  Future<void> _onCreateEvent(
    CreateEventEvent event,
    Emitter<EventCreationState> emit,
  ) async {
    emit(EventCreationLoading());

    try {
      // Validate event data first
      final validationErrors = _validateEventData(event.eventData);
      if (validationErrors.isNotEmpty) {
        emit(EventCreationError(
          'Please fix the following errors:\n${validationErrors.join('\n')}',
          errorCode: 'VALIDATION_ERROR',
        ));
        return;
      }

      final eventId = await _userEventService.createEvent(event.eventData);

      emit(EventCreationSuccess(
        eventId,
        'Event created and published successfully! It\'s now live and visible to other users.',
      ));

      log('Event created successfully: $eventId', name: 'EventCreationBloc');
    } catch (e) {
      log('Error creating event: $e', name: 'EventCreationBloc');
      emit(EventCreationError(
        _getErrorMessage(e),
        errorCode: _getErrorCode(e),
      ));
    }
  }

  Future<void> _onUpdateEvent(
    UpdateEventEvent event,
    Emitter<EventCreationState> emit,
  ) async {
    emit(EventCreationLoading());

    try {
      // Validate event data first
      final validationErrors = _validateEventData(event.eventData);
      if (validationErrors.isNotEmpty) {
        emit(EventCreationError(
          'Please fix the following errors:\n${validationErrors.join('\n')}',
          errorCode: 'VALIDATION_ERROR',
        ));
        return;
      }

      await _userEventService.updateEvent(event.eventId, event.eventData);

      emit(EventCreationSuccess(
        event.eventId,
        'Event updated successfully! It will be reviewed before changes are published.',
      ));

      log('Event updated successfully: ${event.eventId}',
          name: 'EventCreationBloc');
    } catch (e) {
      log('Error updating event: $e', name: 'EventCreationBloc');
      emit(EventCreationError(
        _getErrorMessage(e),
        errorCode: _getErrorCode(e),
      ));
    }
  }

  Future<void> _onSaveEventAsDraft(
    SaveEventAsDraftEvent event,
    Emitter<EventCreationState> emit,
  ) async {
    emit(EventCreationLoading());

    try {
      final eventId = await _userEventService.saveEventAsDraft(event.eventData);

      emit(EventDraftSaved(eventId));

      log('Event draft saved: $eventId', name: 'EventCreationBloc');
    } catch (e) {
      log('Error saving event draft: $e', name: 'EventCreationBloc');
      emit(EventCreationError(
        _getErrorMessage(e),
        errorCode: _getErrorCode(e),
      ));
    }
  }

  Future<void> _onPublishDraftEvent(
    PublishDraftEventEvent event,
    Emitter<EventCreationState> emit,
  ) async {
    emit(EventCreationLoading());

    try {
      await _userEventService.publishDraftEvent(event.eventId);

      emit(EventPublished(event.eventId));

      log('Draft event published: ${event.eventId}', name: 'EventCreationBloc');
    } catch (e) {
      log('Error publishing draft event: $e', name: 'EventCreationBloc');
      emit(EventCreationError(
        _getErrorMessage(e),
        errorCode: _getErrorCode(e),
      ));
    }
  }

  Future<void> _onDeleteEvent(
    DeleteEventEvent event,
    Emitter<EventCreationState> emit,
  ) async {
    emit(EventCreationLoading());

    try {
      await _userEventService.deleteEvent(event.eventId);

      emit(EventDeleted(event.eventId));

      log('Event deleted: ${event.eventId}', name: 'EventCreationBloc');
    } catch (e) {
      log('Error deleting event: $e', name: 'EventCreationBloc');
      emit(EventCreationError(
        _getErrorMessage(e),
        errorCode: _getErrorCode(e),
      ));
    }
  }

  Future<void> _onLoadUserEvents(
    LoadUserEventsEvent event,
    Emitter<EventCreationState> emit,
  ) async {
    emit(UserEventsLoading());

    try {
      final events = await _userEventService.getUserEvents(event.userId);

      // Separate published events from drafts
      final publishedEvents = events
          .where((e) =>
              e.status == EventStatus.published ||
              e.status == EventStatus.underReview ||
              e.status == EventStatus.completed)
          .toList();

      final drafts =
          events.where((e) => e.status == EventStatus.draft).toList();

      emit(UserEventsLoaded(publishedEvents, drafts));

      log('Loaded ${events.length} user events', name: 'EventCreationBloc');
    } catch (e) {
      log('Error loading user events: $e', name: 'EventCreationBloc');
      emit(UserEventsError(_getErrorMessage(e)));
    }
  }

  Future<void> _onValidateEventData(
    ValidateEventDataEvent event,
    Emitter<EventCreationState> emit,
  ) async {
    final errors = _validateEventData(event.eventData);
    emit(EventValidationState(errors.isEmpty, errors));
  }

  List<String> _validateEventData(EventCreationData data) {
    final errors = <String>[];

    // Basic validation
    if (data.name.trim().isEmpty) {
      errors.add('Event name is required');
    } else if (data.name.trim().length < 3) {
      errors.add('Event name must be at least 3 characters');
    } else if (data.name.trim().length > 100) {
      errors.add('Event name must be less than 100 characters');
    }

    if (data.description.trim().isEmpty) {
      errors.add('Event description is required');
    } else if (data.description.trim().length < 10) {
      errors.add('Event description must be at least 10 characters');
    } else if (data.description.trim().length > 2000) {
      errors.add('Event description must be less than 2000 characters');
    }

    // Date validation
    if (data.startDate == null) {
      errors.add('Start date is required');
    } else if (data.startDate!
        .isBefore(DateTime.now().add(Duration(hours: 1)))) {
      errors.add('Event must start at least 1 hour from now');
    }

    if (data.endDate == null) {
      errors.add('End date is required');
    } else if (data.startDate != null &&
        data.endDate!.isBefore(data.startDate!)) {
      errors.add('End date must be after start date');
    } else if (data.startDate != null &&
        data.endDate!.difference(data.startDate!).inHours > 168) {
      errors.add('Event duration cannot exceed 7 days');
    }

    // Location validation
    if (data.location == null) {
      errors.add('Event location is required');
    } else {
      if (data.location!.name == null || data.location!.name!.trim().isEmpty) {
        errors.add('Location name is required');
      }
      if (data.location!.city == null || data.location!.city!.trim().isEmpty) {
        errors.add('City is required');
      }
    }

    // Capacity validation
    if (data.maxAttendees < 1) {
      errors.add('Maximum attendees must be at least 1');
    } else if (data.maxAttendees > 10000) {
      errors.add('Maximum attendees cannot exceed 10,000');
    }

    // Pricing validation
    if (!data.isFree) {
      if (data.ticketPrice == null || data.ticketPrice! <= 0) {
        errors.add('Ticket price must be greater than 0 for paid events');
      } else if (data.ticketPrice! > 1000000) {
        errors.add('Ticket price cannot exceed ₦1,000,000');
      }
    }

    // Category validation
    if (data.category.trim().isEmpty) {
      errors.add('Event category is required');
    }

    // Tags validation
    if (data.tags.length > 10) {
      errors.add('Maximum 10 tags allowed');
    }

    for (final tag in data.tags) {
      if (tag.trim().length > 30) {
        errors.add('Tags must be less than 30 characters');
        break;
      }
    }

    return errors;
  }

  String _getErrorMessage(dynamic error) {
    if (error is UserEventException) {
      return error.message;
    }

    final errorString = error.toString();

    // Common Firebase errors
    if (errorString.contains('permission-denied')) {
      return 'You do not have permission to perform this action';
    } else if (errorString.contains('network-request-failed')) {
      return 'Network error. Please check your connection and try again';
    } else if (errorString.contains('quota-exceeded')) {
      return 'Storage quota exceeded. Please try again later';
    } else if (errorString.contains('unauthenticated')) {
      return 'Please sign in to create events';
    }

    return 'An unexpected error occurred. Please try again';
  }

  String? _getErrorCode(dynamic error) {
    if (error is EventValidationException) {
      return 'VALIDATION_ERROR';
    } else if (error is EventPermissionException) {
      return 'PERMISSION_ERROR';
    }

    final errorString = error.toString();

    if (errorString.contains('permission-denied')) {
      return 'PERMISSION_DENIED';
    } else if (errorString.contains('network-request-failed')) {
      return 'NETWORK_ERROR';
    } else if (errorString.contains('unauthenticated')) {
      return 'AUTH_ERROR';
    }

    return null;
  }
}
