import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/event_model.dart';
import '../../data/services/eventbrite_service.dart';
import '../../data/services/events_firestore_service.dart';

// Events Events
abstract class EventsEvent extends Equatable {
  const EventsEvent();

  @override
  List<Object?> get props => [];
}

class LoadEventsEvent extends EventsEvent {
  final bool forceRefresh;
  
  const LoadEventsEvent({this.forceRefresh = false});
  
  @override
  List<Object?> get props => [forceRefresh];
}

class RefreshEventsEvent extends EventsEvent {}

class LoadMoreEventsEvent extends EventsEvent {}

class FilterEventsEvent extends EventsEvent {
  final EventFilter filter;
  
  const FilterEventsEvent(this.filter);
  
  @override
  List<Object?> get props => [filter];
}

class SearchEventsEvent extends EventsEvent {
  final String query;
  
  const SearchEventsEvent(this.query);
  
  @override
  List<Object?> get props => [query];
}

class ClearSearchEvent extends EventsEvent {}

// Events States
abstract class EventsState extends Equatable {
  const EventsState();

  @override
  List<Object?> get props => [];
}

class EventsInitial extends EventsState {}

class EventsLoading extends EventsState {}

class EventsLoaded extends EventsState {
  final List<EventModel> events;
  final bool hasReachedMax;
  final EventFilter? currentFilter;
  final String? searchQuery;
  final bool isLoadingMore;

  const EventsLoaded({
    required this.events,
    this.hasReachedMax = false,
    this.currentFilter,
    this.searchQuery,
    this.isLoadingMore = false,
  });

  EventsLoaded copyWith({
    List<EventModel>? events,
    bool? hasReachedMax,
    EventFilter? currentFilter,
    String? searchQuery,
    bool? isLoadingMore,
  }) {
    return EventsLoaded(
      events: events ?? this.events,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentFilter: currentFilter ?? this.currentFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
        events,
        hasReachedMax,
        currentFilter,
        searchQuery,
        isLoadingMore,
      ];
}

class EventsError extends EventsState {
  final String message;
  final bool isNetworkError;

  const EventsError({
    required this.message,
    this.isNetworkError = false,
  });

  @override
  List<Object?> get props => [message, isNetworkError];
}

class EventsSearching extends EventsState {
  final String query;
  
  const EventsSearching(this.query);
  
  @override
  List<Object?> get props => [query];
}

// Event Filter Model
class EventFilter extends Equatable {
  final String? category;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? location;
  final bool freeOnly;

  const EventFilter({
    this.category,
    this.startDate,
    this.endDate,
    this.location,
    this.freeOnly = false,
  });

  EventFilter copyWith({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    bool? freeOnly,
  }) {
    return EventFilter(
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      freeOnly: freeOnly ?? this.freeOnly,
    );
  }

  bool get hasActiveFilters =>
      category != null ||
      startDate != null ||
      endDate != null ||
      location != null ||
      freeOnly;

  @override
  List<Object?> get props => [category, startDate, endDate, location, freeOnly];
}

// Events BLoC
class EventsBloc extends Bloc<EventsEvent, EventsState> {
  final EventbriteService _eventbriteService;
  final EventsFirestoreService _firestoreService;
  
  static const int _eventsPerPage = 20;
  int _currentPage = 1;
  List<EventModel> _allEvents = [];

  EventsBloc({
    required EventbriteService eventbriteService,
    required EventsFirestoreService firestoreService,
  })  : _eventbriteService = eventbriteService,
        _firestoreService = firestoreService,
        super(EventsInitial()) {
    
    on<LoadEventsEvent>(_onLoadEvents);
    on<RefreshEventsEvent>(_onRefreshEvents);
    on<LoadMoreEventsEvent>(_onLoadMoreEvents);
    on<FilterEventsEvent>(_onFilterEvents);
    on<SearchEventsEvent>(_onSearchEvents);
    on<ClearSearchEvent>(_onClearSearch);
  }

  Future<void> _onLoadEvents(LoadEventsEvent event, Emitter<EventsState> emit) async {
    try {
      if (state is! EventsLoaded || event.forceRefresh) {
        emit(EventsLoading());
      }

      // First, try to load from Firestore (cached events)
      List<EventModel> firestoreEvents = [];
      try {
        firestoreEvents = await _firestoreService.fetchEvents(limit: _eventsPerPage);
        log('Loaded ${firestoreEvents.length} events from Firestore cache', name: 'EventsBloc');
      } catch (e) {
        log('Failed to load from Firestore: $e', name: 'EventsBloc');
      }

      // If we have cached events and not forcing refresh, use them
      if (firestoreEvents.isNotEmpty && !event.forceRefresh) {
        _allEvents = firestoreEvents;
        _currentPage = 1;
        emit(EventsLoaded(
          events: _allEvents,
          hasReachedMax: firestoreEvents.length < _eventsPerPage,
        ));
        
        // Fetch fresh events in background and update cache
        _fetchAndCacheEventsInBackground();
        return;
      }

      // Fetch fresh events from Eventbrite
      final freshEvents = await _eventbriteService.fetchAfrocentricEvents(
        page: 1,
        limit: _eventsPerPage,
      );

      if (freshEvents.isNotEmpty) {
        // Cache events in Firestore
        await _firestoreService.saveEvents(freshEvents);
        
        _allEvents = freshEvents;
        _currentPage = 1;
        
        emit(EventsLoaded(
          events: _allEvents,
          hasReachedMax: freshEvents.length < _eventsPerPage,
        ));
      } else if (firestoreEvents.isNotEmpty) {
        // Fallback to cached events if API fails
        _allEvents = firestoreEvents;
        emit(EventsLoaded(
          events: _allEvents,
          hasReachedMax: true,
        ));
      } else {
        emit(const EventsError(
          message: 'No events found. Please check your internet connection and try again.',
          isNetworkError: true,
        ));
      }
    } catch (e) {
      log('Error loading events: $e', name: 'EventsBloc');
      
      // Try to load cached events as fallback
      try {
        final cachedEvents = await _firestoreService.fetchEvents(limit: _eventsPerPage);
        if (cachedEvents.isNotEmpty) {
          _allEvents = cachedEvents;
          emit(EventsLoaded(
            events: _allEvents,
            hasReachedMax: true,
          ));
          return;
        }
      } catch (cacheError) {
        log('Failed to load cached events: $cacheError', name: 'EventsBloc');
      }
      
      emit(EventsError(
        message: _getErrorMessage(e),
        isNetworkError: e is EventbriteException,
      ));
    }
  }

  Future<void> _onRefreshEvents(RefreshEventsEvent event, Emitter<EventsState> emit) async {
    add(const LoadEventsEvent(forceRefresh: true));
  }

  Future<void> _onLoadMoreEvents(LoadMoreEventsEvent event, Emitter<EventsState> emit) async {
    final currentState = state;
    if (currentState is! EventsLoaded || currentState.hasReachedMax || currentState.isLoadingMore) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final moreEvents = await _eventbriteService.fetchAfrocentricEvents(
        page: _currentPage + 1,
        limit: _eventsPerPage,
      );

      if (moreEvents.isNotEmpty) {
        // Cache new events
        await _firestoreService.saveEvents(moreEvents);
        
        _allEvents.addAll(moreEvents);
        _currentPage++;
        
        emit(EventsLoaded(
          events: List.from(_allEvents),
          hasReachedMax: moreEvents.length < _eventsPerPage,
          currentFilter: currentState.currentFilter,
          searchQuery: currentState.searchQuery,
        ));
      } else {
        emit(currentState.copyWith(
          hasReachedMax: true,
          isLoadingMore: false,
        ));
      }
    } catch (e) {
      log('Error loading more events: $e', name: 'EventsBloc');
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onFilterEvents(FilterEventsEvent event, Emitter<EventsState> emit) async {
    final currentState = state;
    if (currentState is! EventsLoaded) return;

    emit(EventsLoading());

    try {
      List<EventModel> filteredEvents;
      
      if (event.filter.hasActiveFilters) {
        // Apply filters to cached events first
        filteredEvents = _applyFilters(_allEvents, event.filter);
        
        // If we need more events or specific filtering, fetch from API
        if (filteredEvents.length < 10 && event.filter.category != null) {
          final apiEvents = await _eventbriteService.searchEvents(
            query: _getCategorySearchQuery(event.filter.category!),
            limit: _eventsPerPage,
            location: event.filter.location,
            category: event.filter.category,
          );
          
          if (apiEvents.isNotEmpty) {
            await _firestoreService.saveEvents(apiEvents);
            filteredEvents = _applyFilters(apiEvents, event.filter);
          }
        }
      } else {
        filteredEvents = _allEvents;
      }

      emit(EventsLoaded(
        events: filteredEvents,
        hasReachedMax: true,
        currentFilter: event.filter,
      ));
    } catch (e) {
      log('Error filtering events: $e', name: 'EventsBloc');
      emit(EventsError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onSearchEvents(SearchEventsEvent event, Emitter<EventsState> emit) async {
    if (event.query.trim().isEmpty) {
      add(ClearSearchEvent());
      return;
    }

    emit(EventsSearching(event.query));

    try {
      // Search in cached events first
      final cachedResults = _allEvents
          .where((event) =>
              event.name.toLowerCase().contains(event.query.toLowerCase()) ||
              event.description.toLowerCase().contains(event.query.toLowerCase()) ||
              event.category.toLowerCase().contains(event.query.toLowerCase()))
          .toList();

      // Search via API for more comprehensive results
      final apiResults = await _eventbriteService.searchEvents(
        query: event.query,
        limit: _eventsPerPage,
      );

      // Combine and deduplicate results
      final allResults = <String, EventModel>{};
      
      for (final event in cachedResults) {
        allResults[event.eventbriteId] = event;
      }
      
      for (final event in apiResults) {
        allResults[event.eventbriteId] = event;
      }

      final searchResults = allResults.values.toList();
      
      // Cache new events from API
      if (apiResults.isNotEmpty) {
        await _firestoreService.saveEvents(apiResults);
      }

      emit(EventsLoaded(
        events: searchResults,
        hasReachedMax: true,
        searchQuery: event.query,
      ));
    } catch (e) {
      log('Error searching events: $e', name: 'EventsBloc');
      emit(EventsError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onClearSearch(ClearSearchEvent event, Emitter<EventsState> emit) async {
    emit(EventsLoaded(
      events: _allEvents,
      hasReachedMax: _allEvents.length < _eventsPerPage,
    ));
  }

  List<EventModel> _applyFilters(List<EventModel> events, EventFilter filter) {
    return events.where((event) {
      if (filter.category != null && 
          !event.category.toLowerCase().contains(filter.category!.toLowerCase())) {
        return false;
      }
      
      if (filter.freeOnly && !event.isFree) {
        return false;
      }
      
      if (filter.startDate != null && event.startDate.isBefore(filter.startDate!)) {
        return false;
      }
      
      if (filter.endDate != null && event.startDate.isAfter(filter.endDate!)) {
        return false;
      }
      
      if (filter.location != null && 
          !event.location.displayAddress.toLowerCase().contains(filter.location!.toLowerCase())) {
        return false;
      }
      
      return true;
    }).toList();
  }

  String _getCategorySearchQuery(String category) {
    switch (category.toLowerCase()) {
      case 'music':
        return 'afrobeats OR african music OR live music';
      case 'business':
        return 'african business OR networking OR entrepreneurship';
      case 'community':
        return 'african community OR cultural event OR meetup';
      case 'food':
        return 'african food OR nigerian food OR ghanaian food';
      case 'arts':
        return 'african art OR cultural art OR exhibition';
      default:
        return 'african OR afrocentric';
    }
  }

  Future<void> _fetchAndCacheEventsInBackground() async {
    try {
      final freshEvents = await _eventbriteService.fetchAfrocentricEvents(
        page: 1,
        limit: _eventsPerPage,
      );
      
      if (freshEvents.isNotEmpty) {
        await _firestoreService.saveEvents(freshEvents);
        log('Background cache updated with ${freshEvents.length} events', name: 'EventsBloc');
      }
    } catch (e) {
      log('Background cache update failed: $e', name: 'EventsBloc');
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is EventbriteException) {
      return error.message;
    } else if (error is FirestoreException) {
      return error.message;
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }
}
