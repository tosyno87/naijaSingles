import 'dart:developer';
import '../models/event_model.dart';
import '../models/rsvp_model.dart';
import '../services/events_firestore_service.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';

abstract class EventsRepository {
  Future<List<EventModel>> getEvents({
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  });
  
  Future<List<EventModel>> searchEvents(String query);
  
  Future<List<EventModel>> getEventsByCategory(String category);
  
  Future<List<EventModel>> getEventsNearLocation({
    double? latitude,
    double? longitude,
    double radiusKm = 50.0,
    int limit = 20,
  });
  
  Future<List<EventModel>> getEventsWithDistance({
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
    double? userLatitude,
    double? userLongitude,
  });
  
  Future<EventModel?> getEventById(String eventId);
  
  Future<void> rsvpToEvent({
    required String userId,
    required String eventId,
    required RSVPStatus status,
  });
  
  Future<RSVPModel?> getUserRSVP(String userId, String eventId);
  
  Future<List<RSVPModel>> getUserRSVPs(String userId);
  
  Future<List<EventAttendeeModel>> getEventAttendees(String eventId);
}

class EventsRepositoryImpl implements EventsRepository {
  final EventsFirestoreService _firestoreService;
  final LocationService _locationService;
  
  // Cache management
  final Map<String, List<EventModel>> _eventsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 15);

  EventsRepositoryImpl({
    required EventsFirestoreService firestoreService,
    LocationService? locationService,
  })  : _firestoreService = firestoreService,
        _locationService = locationService ?? LocationService();

  @override
  Future<List<EventModel>> getEvents({
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'events_${page}_$limit';
    
    // Check cache first (unless force refresh)
    if (!forceRefresh && _isCacheValid(cacheKey)) {
      log('Returning cached events for page $page', name: 'EventsRepository');
      return _eventsCache[cacheKey] ?? [];
    }

    try {
      List<EventModel> events = [];
      
      // Try to get from Firestore first (faster)
      if (page == 1) {
        try {
          final cachedEvents = await _firestoreService.fetchEvents(limit: limit);
          if (cachedEvents.isNotEmpty && !forceRefresh) {
            events = cachedEvents;
            log('Loaded ${events.length} events from Firestore cache', name: 'EventsRepository');
            
            // Update cache
            _updateCache(cacheKey, events);
            
            // Fetch fresh data in background
            _fetchAndCacheInBackground(page, limit);
            
            return events;
          }
        } catch (e) {
          log('Failed to load from Firestore cache: $e', name: 'EventsRepository');
        }
      }
      
      // Fetch from Firestore only (user-created events)
      events = await _firestoreService.fetchEvents(limit: limit);
      
      if (events.isNotEmpty) {
        // Update memory cache
        _updateCache(cacheKey, events);
        
        log('Fetched ${events.length} events from Firestore', name: 'EventsRepository');
      }
      
      return events;
    } catch (e) {
      log('Error fetching events: $e', name: 'EventsRepository');
      
      // Fallback to Firestore cache even if expired
      try {
        final fallbackEvents = await _firestoreService.fetchEvents(limit: limit);
        if (fallbackEvents.isNotEmpty) {
          log('Using fallback Firestore cache with ${fallbackEvents.length} events', name: 'EventsRepository');
          return fallbackEvents;
        }
      } catch (fallbackError) {
        log('Fallback cache also failed: $fallbackError', name: 'EventsRepository');
      }
      
      rethrow;
    }
  }

  @override
  Future<List<EventModel>> searchEvents(String query) async {
    if (query.trim().isEmpty) return [];
    
    final cacheKey = 'search_${query.toLowerCase()}';
    
    // Check cache first
    if (_isCacheValid(cacheKey)) {
      return _eventsCache[cacheKey] ?? [];
    }

    try {
      // Search in Firestore first (faster)
      final firestoreResults = await _firestoreService.searchEvents(query);
      
      // Use only Firestore results for user-created events
      final searchResults = firestoreResults;
      
      // Update search cache
      _updateCache(cacheKey, searchResults);
      
      log('Search for "$query" returned ${searchResults.length} results from Firestore', name: 'EventsRepository');
      return searchResults;
    } catch (e) {
      log('Error searching events: $e', name: 'EventsRepository');
      rethrow;
    }
  }

  @override
  Future<List<EventModel>> getEventsByCategory(String category) async {
    final cacheKey = 'category_${category.toLowerCase()}';
    
    // Check cache first
    if (_isCacheValid(cacheKey)) {
      return _eventsCache[cacheKey] ?? [];
    }

    try {
      // Get from Firestore first
      final firestoreEvents = await _firestoreService.getEventsByCategory(category);
      
      // If we have enough cached events, return them and fetch fresh data in background
      if (firestoreEvents.length >= 10) {
        _updateCache(cacheKey, firestoreEvents);
        
        // Fetch fresh data in background
        _fetchCategoryInBackground(category);
        
        return firestoreEvents;
      }
      
      // Use only Firestore results for user-created events
      final categoryEvents = firestoreEvents;
      _updateCache(cacheKey, categoryEvents);
      
      return categoryEvents;
    } catch (e) {
      log('Error fetching events by category: $e', name: 'EventsRepository');
      rethrow;
    }
  }

  @override
  Future<EventModel?> getEventById(String eventId) async {
    try {
      // Try Firestore first
      EventModel? event = await _firestoreService.getEventById(eventId);
      
      if (event != null) {
        return event;
      }
      
      // External API calls removed - only user-generated events supported
      
      if (event != null) {
        // Cache the event
        await _firestoreService.saveEvents([event]);
      }
      
      return event;
    } catch (e) {
      log('Error fetching event by ID: $e', name: 'EventsRepository');
      return null;
    }
  }

  @override
  Future<void> rsvpToEvent({
    required String userId,
    required String eventId,
    required RSVPStatus status,
  }) async {
    try {
      // Check if user already has an RSVP
      final existingRSVP = await _firestoreService.getUserRSVP(userId, eventId);
      
      if (existingRSVP != null) {
        // Update existing RSVP
        await _firestoreService.updateRSVP(
          userId: userId,
          eventId: eventId,
          oldStatus: existingRSVP.status,
          newStatus: status,
        );
      } else {
        // Create new RSVP
        await _firestoreService.rsvpToEvent(
          userId: userId,
          eventId: eventId,
          status: status,
          userProfile: await _getUserProfile(userId),
        );
      }
      
      log('RSVP updated for user $userId to event $eventId: ${status.value}', name: 'EventsRepository');
    } catch (e) {
      log('Error updating RSVP: $e', name: 'EventsRepository');
      rethrow;
    }
  }

  @override
  Future<RSVPModel?> getUserRSVP(String userId, String eventId) async {
    try {
      return await _firestoreService.getUserRSVP(userId, eventId);
    } catch (e) {
      log('Error fetching user RSVP: $e', name: 'EventsRepository');
      return null;
    }
  }

  @override
  Future<List<RSVPModel>> getUserRSVPs(String userId) async {
    try {
      return await _firestoreService.getUserRSVPs(userId);
    } catch (e) {
      log('Error fetching user RSVPs: $e', name: 'EventsRepository');
      return [];
    }
  }

  @override
  Future<List<EventAttendeeModel>> getEventAttendees(String eventId) async {
    try {
      return await _firestoreService.getEventAttendees(eventId);
    } catch (e) {
      log('Error fetching event attendees: $e', name: 'EventsRepository');
      return [];
    }
  }

  // Private helper methods
  bool _isCacheValid(String cacheKey) {
    if (!_eventsCache.containsKey(cacheKey) || !_cacheTimestamps.containsKey(cacheKey)) {
      return false;
    }
    
    final cacheTime = _cacheTimestamps[cacheKey]!;
    final now = DateTime.now();
    
    return now.difference(cacheTime) < _cacheExpiry;
  }

  void _updateCache(String cacheKey, List<EventModel> events) {
    _eventsCache[cacheKey] = events;
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  Future<void> _fetchAndCacheInBackground(int page, int limit) async {
    try {
      // Background refresh removed - only user-generated events supported
    } catch (e) {
      log('Background cache update failed: $e', name: 'EventsRepository');
    }
  }

  Future<void> _fetchCategoryInBackground(String category) async {
    try {
      // Background category refresh removed - only user-generated events supported
    } catch (e) {
      log('Background category cache update failed: $e', name: 'EventsRepository');
    }
  }


  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    // TODO: Implement user profile fetching from your user service
    // This should return basic user info for the attendee list
    return {
      'name': 'Current User', // Replace with actual user name
      'avatar': null, // Replace with actual user avatar
      'age': null, // Replace with actual user age
      'location': null, // Replace with actual user location
    };
  }

  // Cache cleanup method (call periodically)
  void clearExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheExpiry) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _eventsCache.remove(key);
      _cacheTimestamps.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      log('Cleared ${expiredKeys.length} expired cache entries', name: 'EventsRepository');
    }
  }

  // Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cached_queries': _eventsCache.length,
      'cache_size_mb': _calculateCacheSize(),
      'oldest_cache': _getOldestCacheTime(),
      'newest_cache': _getNewestCacheTime(),
    };
  }

  double _calculateCacheSize() {
    // Rough estimation of cache size in MB
    int totalEvents = 0;
    for (final events in _eventsCache.values) {
      totalEvents += events.length;
    }
    return (totalEvents * 2.5) / 1024; // Rough estimate: 2.5KB per event
  }

  DateTime? _getOldestCacheTime() {
    if (_cacheTimestamps.isEmpty) return null;
    return _cacheTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  DateTime? _getNewestCacheTime() {
    if (_cacheTimestamps.isEmpty) return null;
    return _cacheTimestamps.values.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  @override
  Future<List<EventModel>> getEventsNearLocation({
    double? latitude,
    double? longitude,
    double radiusKm = 50.0,
    int limit = 20,
  }) async {
    try {
      // Get user location if not provided
      Position? userLocation;
      if (latitude != null && longitude != null) {
        userLocation = Position(
          latitude: latitude,
          longitude: longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      } else {
        userLocation = await _locationService.getCurrentLocation();
      }

      if (userLocation == null) {
        log('❌ Unable to get user location for nearby events', name: 'EventsRepository');
        return [];
      }

      // Get all events and filter by distance
      final allEvents = await _firestoreService.fetchEvents(limit: 100); // Get more events to filter
      
      // Calculate distances and filter
      final nearbyEvents = <EventModel>[];
      for (final event in allEvents) {
        if (event.location.latitude != null && event.location.longitude != null) {
          final distance = LocationService.calculateDistance(
            userLocation.latitude,
            userLocation.longitude,
            event.location.latitude!,
            event.location.longitude!,
          );
          
          if (distance <= radiusKm) {
            nearbyEvents.add(event.copyWith(distanceFromUser: distance));
          }
        }
      }

      // Sort by distance and limit results
      nearbyEvents.sort((a, b) => (a.distanceFromUser ?? 0).compareTo(b.distanceFromUser ?? 0));
      
      final result = nearbyEvents.take(limit).toList();
      log('📍 Found ${result.length} events within ${radiusKm}km', name: 'EventsRepository');
      
      return result;
    } catch (e) {
      log('❌ Error getting events near location: $e', name: 'EventsRepository');
      return [];
    }
  }

  @override
  Future<List<EventModel>> getEventsWithDistance({
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
    double? userLatitude,
    double? userLongitude,
  }) async {
    try {
      // Get user location
      Position? userLocation;
      if (userLatitude != null && userLongitude != null) {
        userLocation = Position(
          latitude: userLatitude,
          longitude: userLongitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      } else {
        userLocation = await _locationService.getCurrentLocation();
      }

      // Get events normally
      final events = await getEvents(
        page: page,
        limit: limit,
        forceRefresh: forceRefresh,
      );

      // Add distance information if user location is available
      if (userLocation != null) {
        final eventsWithDistance = events.map((event) {
          if (event.location.latitude != null && event.location.longitude != null) {
            final distance = LocationService.calculateDistance(
              userLocation!.latitude,
              userLocation!.longitude,
              event.location.latitude!,
              event.location.longitude!,
            );
            return event.copyWith(distanceFromUser: distance);
          }
          return event;
        }).toList();

        // Sort by distance if user location is available
        eventsWithDistance.sort((a, b) {
          final distanceA = a.distanceFromUser ?? double.infinity;
          final distanceB = b.distanceFromUser ?? double.infinity;
          return distanceA.compareTo(distanceB);
        });

        return eventsWithDistance;
      }

      return events;
    } catch (e) {
      log('❌ Error getting events with distance: $e', name: 'EventsRepository');
      return await getEvents(page: page, limit: limit, forceRefresh: forceRefresh);
    }
  }
}
