import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/event_model.dart';
import '../../data/repositories/events_repository.dart';

// Events Events
abstract class EventsEvent extends Equatable {
  const EventsEvent();

  @override
  List<Object?> get props => [];
}

class LoadEventsEvent extends EventsEvent {
  const LoadEventsEvent({this.forceRefresh = false});
  final bool forceRefresh;

  @override
  List<Object?> get props => [forceRefresh];
}

class RefreshEventsEvent extends EventsEvent {}

class LoadMoreEventsEvent extends EventsEvent {}

class FilterEventsEvent extends EventsEvent {
  const FilterEventsEvent(this.filter);
  final EventFilter filter;

  @override
  List<Object?> get props => [filter];
}

class SearchEventsEvent extends EventsEvent {
  const SearchEventsEvent(this.query);
  final String query;

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
  const EventsLoaded({
    required this.events,
    this.hasReachedMax = false,
    this.currentFilter,
    this.searchQuery,
    this.isLoadingMore = false,
  });
  final List<EventModel> events;
  final bool hasReachedMax;
  final EventFilter? currentFilter;
  final String? searchQuery;
  final bool isLoadingMore;

  EventsLoaded copyWith({
    List<EventModel>? events,
    bool? hasReachedMax,
    EventFilter? currentFilter,
    String? searchQuery,
    bool? isLoadingMore,
  }) =>
      EventsLoaded(
        events: events ?? this.events,
        hasReachedMax: hasReachedMax ?? this.hasReachedMax,
        currentFilter: currentFilter ?? this.currentFilter,
        searchQuery: searchQuery ?? this.searchQuery,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );

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
  const EventsError({
    required this.message,
    this.isNetworkError = false,
  });
  final String message;
  final bool isNetworkError;

  @override
  List<Object?> get props => [message, isNetworkError];
}

class EventsSearching extends EventsState {
  const EventsSearching(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}

// Event Filter Model
class EventFilter extends Equatable {
  const EventFilter({
    this.category,
    this.startDate,
    this.endDate,
    this.location,
    this.freeOnly = false,
    this.paidOnly,
    this.maxPrice,
    this.minPrice,
    this.latitude,
    this.longitude,
    this.radiusKm,
    this.tags,
    this.sortBy,
    this.trendingOnly = false,
    this.weekendOnly = false,
  });
  final String? category;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? location;
  final bool freeOnly;
  final bool? paidOnly;
  final double? maxPrice;
  final double? minPrice;
  final double? latitude;
  final double? longitude;
  final double? radiusKm;
  final List<String>? tags;
  final String? sortBy; // 'date', 'popularity', 'distance', 'price'
  final bool trendingOnly;
  final bool weekendOnly;

  EventFilter copyWith({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    bool? freeOnly,
    bool? paidOnly,
    double? maxPrice,
    double? minPrice,
    double? latitude,
    double? longitude,
    double? radiusKm,
    List<String>? tags,
    String? sortBy,
    bool? trendingOnly,
    bool? weekendOnly,
  }) =>
      EventFilter(
        category: category ?? this.category,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        location: location ?? this.location,
        freeOnly: freeOnly ?? this.freeOnly,
        paidOnly: paidOnly ?? this.paidOnly,
        maxPrice: maxPrice ?? this.maxPrice,
        minPrice: minPrice ?? this.minPrice,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        radiusKm: radiusKm ?? this.radiusKm,
        tags: tags ?? this.tags,
        sortBy: sortBy ?? this.sortBy,
        trendingOnly: trendingOnly ?? this.trendingOnly,
        weekendOnly: weekendOnly ?? this.weekendOnly,
      );

  bool get hasActiveFilters =>
      category != null ||
      startDate != null ||
      endDate != null ||
      location != null ||
      freeOnly ||
      maxPrice != null ||
      minPrice != null ||
      latitude != null ||
      longitude != null ||
      radiusKm != null ||
      (tags != null && tags!.isNotEmpty) ||
      sortBy != null ||
      trendingOnly ||
      weekendOnly;

  bool get hasLocationFilter =>
      latitude != null && longitude != null && radiusKm != null;
  bool get hasPriceFilter => maxPrice != null || minPrice != null;
  bool get hasDateFilter => startDate != null || endDate != null;

  @override
  List<Object?> get props => [
        category,
        startDate,
        endDate,
        location,
        freeOnly,
        paidOnly,
        maxPrice,
        minPrice,
        latitude,
        longitude,
        radiusKm,
        tags,
        sortBy,
        trendingOnly,
        weekendOnly,
      ];
}

// Events BLoC
class EventsBloc extends Bloc<EventsEvent, EventsState> {
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
  final EventsRepository _repository;

  static const int _eventsPerPage = 20;
  int _currentPage = 1;
  List<EventModel> _allEvents = [];

  Future<void> _onLoadEvents(
    LoadEventsEvent event,
    Emitter<EventsState> emit,
  ) async {
    try {
      if (state is! EventsLoaded || event.forceRefresh) {
        emit(EventsLoading());
      }

      // Use location-based loading to get events with distance information
      final events = await _repository.getEventsWithDistance(
        forceRefresh: event.forceRefresh,
      );

      _allEvents = events;
      _currentPage = 1;

      emit(
        EventsLoaded(
          events: _allEvents,
          hasReachedMax: events.length < _eventsPerPage,
        ),
      );
    } catch (e) {
      log('Error loading events: $e', name: 'EventsBloc');
      emit(
        EventsError(
          message: _getErrorMessage(e),
          isNetworkError: _isNetworkError(e),
        ),
      );
    }
  }

  Future<void> _onRefreshEvents(
    RefreshEventsEvent event,
    Emitter<EventsState> emit,
  ) async {
    add(const LoadEventsEvent(forceRefresh: true));
  }

  Future<void> _onLoadMoreEvents(
    LoadMoreEventsEvent event,
    Emitter<EventsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EventsLoaded ||
        currentState.hasReachedMax ||
        currentState.isLoadingMore) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final moreEvents = await _repository.getEvents(
        page: _currentPage + 1,
      );

      if (moreEvents.isNotEmpty) {
        _allEvents.addAll(moreEvents);
        _currentPage++;

        emit(
          EventsLoaded(
            events: List.from(_allEvents),
            hasReachedMax: moreEvents.length < _eventsPerPage,
            currentFilter: currentState.currentFilter,
            searchQuery: currentState.searchQuery,
          ),
        );
      } else {
        emit(
          currentState.copyWith(
            hasReachedMax: true,
            isLoadingMore: false,
          ),
        );
      }
    } catch (e) {
      log('Error loading more events: $e', name: 'EventsBloc');
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onFilterEvents(
    FilterEventsEvent event,
    Emitter<EventsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EventsLoaded) return;

    emit(EventsLoading());

    try {
      List<EventModel> filteredEvents;

      if (event.filter.hasActiveFilters) {
        if (event.filter.category != null) {
          // Get events by category
          filteredEvents =
              await _repository.getEventsByCategory(event.filter.category!);
        } else {
          // Apply other filters to cached events
          filteredEvents = _applyFilters(_allEvents, event.filter);
        }

        // Apply additional filters if needed
        filteredEvents = _applyFilters(filteredEvents, event.filter);
      } else {
        filteredEvents = _allEvents;
      }

      emit(
        EventsLoaded(
          events: filteredEvents,
          hasReachedMax: true,
          currentFilter: event.filter,
        ),
      );
    } catch (e) {
      log('Error filtering events: $e', name: 'EventsBloc');
      emit(EventsError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onSearchEvents(
    SearchEventsEvent event,
    Emitter<EventsState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      add(ClearSearchEvent());
      return;
    }

    emit(EventsSearching(event.query));

    try {
      final searchResults = await _repository.searchEvents(event.query);

      emit(
        EventsLoaded(
          events: searchResults,
          hasReachedMax: true,
          searchQuery: event.query,
        ),
      );
    } catch (e) {
      log('Error searching events: $e', name: 'EventsBloc');
      emit(EventsError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onClearSearch(
    ClearSearchEvent event,
    Emitter<EventsState> emit,
  ) async {
    emit(
      EventsLoaded(
        events: _allEvents,
        hasReachedMax: _allEvents.length < _eventsPerPage,
      ),
    );
  }

  List<EventModel> _applyFilters(List<EventModel> events, EventFilter filter) {
    var filteredEvents = events.where((event) {
      // Category filter
      if (filter.category != null &&
          !event.category
              .toLowerCase()
              .contains(filter.category!.toLowerCase())) {
        return false;
      }

      // Free/Paid filter
      if (filter.freeOnly && !event.isFree) {
        return false;
      }

      if (filter.paidOnly ?? false && event.isFree) {
        return false;
      }

      // Date range filters
      if (filter.startDate != null &&
          event.startDate.isBefore(filter.startDate!)) {
        return false;
      }

      if (filter.endDate != null && event.startDate.isAfter(filter.endDate!)) {
        return false;
      }

      // Location text filter
      if (filter.location != null &&
          !event.location.displayAddress
              .toLowerCase()
              .contains(filter.location!.toLowerCase())) {
        return false;
      }

      // Price filters
      if (filter.minPrice != null &&
          (event.ticketPrice ?? 0) < filter.minPrice!) {
        return false;
      }

      if (filter.maxPrice != null &&
          (event.ticketPrice ?? 0) > filter.maxPrice!) {
        return false;
      }

      // Tags filter
      if (filter.tags != null && filter.tags!.isNotEmpty) {
        final eventTags = event.tags.map((tag) => tag.toLowerCase()).toList();
        final hasMatchingTag = filter.tags!.any(
          (filterTag) => eventTags
              .any((eventTag) => eventTag.contains(filterTag.toLowerCase())),
        );
        if (!hasMatchingTag) return false;
      }

      // Weekend filter
      if (filter.weekendOnly) {
        final weekday = event.startDate.weekday;
        if (weekday != DateTime.friday &&
            weekday != DateTime.saturday &&
            weekday != DateTime.sunday) {
          return false;
        }
      }

      return true;
    }).toList();

    // Apply location-based filtering (radius)
    if (filter.hasLocationFilter) {
      filteredEvents = _filterByLocation(
        filteredEvents,
        filter.latitude!,
        filter.longitude!,
        filter.radiusKm!,
      );
    }

    // Apply sorting
    if (filter.sortBy != null) {
      filteredEvents = _sortEvents(filteredEvents, filter.sortBy!);
    }

    return filteredEvents;
  }

  List<EventModel> _filterByLocation(
    List<EventModel> events,
    double latitude,
    double longitude,
    double radiusKm,
  ) =>
      events.where((event) {
        // Skip events without location data
        if (event.location.latitude == null ||
            event.location.longitude == null) {
          return false;
        }

        // Calculate distance between user location and event location
        final distance = _calculateDistance(
          latitude,
          longitude,
          event.location.latitude!,
          event.location.longitude!,
        );
        return distance <= radiusKm;
      }).toList();

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) => degrees * (math.pi / 180);

  List<EventModel> _sortEvents(List<EventModel> events, String sortBy) {
    switch (sortBy) {
      case 'date':
        events.sort((a, b) => a.startDate.compareTo(b.startDate));
        break;
      case 'popularity':
        events.sort((a, b) => b.rsvpCount.compareTo(a.rsvpCount));
        break;
      case 'price':
        events
            .sort((a, b) => (a.ticketPrice ?? 0).compareTo(b.ticketPrice ?? 0));
        break;
      case 'distance':
        // Distance sorting would require user location, handled separately
        break;
    }
    return events;
  }

  String _getErrorMessage(error) {
    if (error.toString().contains('FirestoreException')) {
      return 'Failed to save events. Please try again.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  bool _isNetworkError(error) =>
      error.toString().contains('SocketException') ||
      error.toString().contains('TimeoutException');
}
