import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/events_repository.dart';

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
  final EventsRepository _repository;
  
  static const int _eventsPerPage = 20;
  int _currentPage = 1;
  List<EventModel> _allEvents = [];

  EventsBloc({
    required EventsRepository repository,
  })  : _repository = repository,
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

      final events = await _repository.getEvents(
        page: 1,
        limit: _eventsPerPage,
        forceRefresh: event.forceRefresh,
      );

      _allEvents = events;
      _currentPage = 1;
      
      emit(EventsLoaded(
        events: _allEvents,
        hasReachedMax: events.length < _eventsPerPage,
      ));
    } catch (e) {
      log('Error loading events: $e', name: 'EventsBloc');
      emit(EventsError(
        message: _getErrorMessage(e),
        isNetworkError: _isNetworkError(e),
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
      final moreEvents = await _repository.getEvents(
        page: _currentPage + 1,
        limit: _eventsPerPage,
      );

      if (moreEvents.isNotEmpty) {
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
        if (event.filter.category != null) {
          // Get events by category
          filteredEvents = await _repository.getEventsByCategory(event.filter.category!);
        } else {
          // Apply other filters to cached events
          filteredEvents = _applyFilters(_allEvents, event.filter);
        }
        
        // Apply additional filters if needed
        filteredEvents = _applyFilters(filteredEvents, event.filter);
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
      final searchResults = await _repository.searchEvents(event.query);

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

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('EventbriteException')) {
      return 'Failed to load events. Please check your internet connection and try again.';
    } else if (error.toString().contains('FirestoreException')) {
      return 'Failed to save events. Please try again.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  bool _isNetworkError(dynamic error) {
    return error.toString().contains('EventbriteException') ||
           error.toString().contains('SocketException') ||
           error.toString().contains('TimeoutException');
  }
}
