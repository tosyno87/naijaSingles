import 'dart:developer';
import 'package:dio/dio.dart';
import '../models/event_model.dart';

class MeetupService {
  static const String _baseUrl = 'https://api.meetup.com';
  // You'll get this from: https://secure.meetup.com/meetup_api/key/
  static const String _apiKey = 'YOUR_MEETUP_API_KEY_HERE';
  
  final Dio _dio;

  MeetupService() : _dio = Dio() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    
    // Add interceptor for logging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => log(obj.toString(), name: 'MeetupAPI'),
    ));
  }

  /// Fetch Afrocentric events from Meetup
  Future<List<EventModel>> fetchAfrocentricEvents({
    int page = 1,
    int limit = 20,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = _buildAfrocentricSearchParams(
        page: page,
        limit: limit,
        location: location,
        startDate: startDate,
        endDate: endDate,
      );

      log('🔍 Fetching Meetup events with params: $queryParams', name: 'MeetupService');
      
      // Meetup API endpoint for finding events
      final response = await _dio.get('/find/events', queryParameters: queryParams);
      
      if (response.statusCode == 200) {
        final data = response.data;
        final events = (data as List<dynamic>?)
            ?.map((eventJson) => _convertMeetupToEventModel(eventJson))
            .where((event) => event != null)
            .cast<EventModel>()
            .toList() ?? [];
        
        log('✅ Fetched ${events.length} Afrocentric events from Meetup', name: 'MeetupService');
        return events;
      } else {
        throw MeetupException('Failed to fetch events: ${response.statusCode}');
      }
    } catch (e) {
      log('❌ Error fetching events from Meetup: $e', name: 'MeetupService');
      
      if (e is DioException) {
        log('🔄 API not configured, returning empty list', name: 'MeetupService');
        return [];
      }
      
      throw MeetupException('Failed to fetch events: $e');
    }
  }

  /// Convert Meetup API response to EventModel
  EventModel? _convertMeetupToEventModel(Map<String, dynamic> meetupEvent) {
    try {
      final venue = meetupEvent['venue'] as Map<String, dynamic>?;
      final group = meetupEvent['group'] as Map<String, dynamic>?;
      final fee = meetupEvent['fee'] as Map<String, dynamic>?;
      
      return EventModel(
        id: 'meetup_${meetupEvent['id']}',
        externalId: meetupEvent['id']?.toString() ?? '',
        name: meetupEvent['name'] as String? ?? 'Untitled Event',
        description: meetupEvent['description'] as String? ?? 'No description available',
        startDate: DateTime.fromMillisecondsSinceEpoch(
          (meetupEvent['time'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
        ),
        endDate: DateTime.fromMillisecondsSinceEpoch(
          ((meetupEvent['time'] as int?) ?? DateTime.now().millisecondsSinceEpoch) + 
          ((meetupEvent['duration'] as int?) ?? 3600000), // Default 1 hour if no duration
        ),
        imageUrl: _extractImageUrl(meetupEvent),
        location: _extractLocation(venue),
        ticketUrl: meetupEvent['link'] as String? ?? '',
        isFree: (fee?['amount'] as num?)?.toDouble() == 0.0 || fee == null,
        category: _mapMeetupCategory(group?['category']?['name'] as String?),
        attendeeCount: (meetupEvent['yes_rsvp_count'] as int?) ?? 0,
        rsvpCount: (meetupEvent['rsvp_limit'] as int?) ?? 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (meetupEvent['created'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
        ),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          (meetupEvent['updated'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
        ),
        status: EventStatus.published,
        isPublic: true,
        createdByUserId: 'meetup_import', // For imported events
      );
    } catch (e) {
      log('⚠️ Error converting Meetup event: $e', name: 'MeetupService');
      return null;
    }
  }

  /// Extract image URL from Meetup event
  String _extractImageUrl(Map<String, dynamic> meetupEvent) {
    // Try different image sources
    if (meetupEvent['featured_photo'] != null) {
      final featuredPhoto = meetupEvent['featured_photo'] as Map<String, dynamic>?;
      return featuredPhoto?['photo_link'] ?? '';
    }
    
    if (meetupEvent['photo_url'] != null) {
      return meetupEvent['photo_url'] as String? ?? '';
    }
    
    // Fallback to group photo
    final group = meetupEvent['group'] as Map<String, dynamic>?;
    if (group != null && group['group_photo'] != null) {
      final groupPhoto = group['group_photo'] as Map<String, dynamic>?;
      return groupPhoto?['photo_link'] ?? '';
    }
    
    // Default fallback image
    return 'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=800';
  }

  /// Extract location from Meetup venue
  EventLocation _extractLocation(Map<String, dynamic>? venue) {
    if (venue == null) {
      return const EventLocation(
        name: 'TBD',
        address: 'Location to be determined',
        city: 'TBD',
        state: 'TBD',
        country: 'TBD',
        latitude: 0.0,
        longitude: 0.0,
      );
    }

    final address1 = venue['address_1'] as String? ?? '';
    final address2 = venue['address_2'] as String? ?? '';
    final fullAddress = '$address1 $address2'.trim();

    return EventLocation(
      name: venue['name'] as String? ?? 'Venue TBD',
      address: fullAddress.isEmpty ? 'Address TBD' : fullAddress,
      city: venue['city'] as String? ?? '',
      state: venue['state'] as String? ?? '',
      country: (venue['country'] as String?)?.toUpperCase() ?? '',
      latitude: (venue['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (venue['lon'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Map Meetup categories to our app categories
  String _mapMeetupCategory(String? meetupCategory) {
    if (meetupCategory == null) return 'Community';
    
    final category = meetupCategory.toLowerCase();
    
    if (category.contains('music') || category.contains('arts')) {
      return 'Music';
    } else if (category.contains('food') || category.contains('dining')) {
      return 'Food & Drink';
    } else if (category.contains('business') || category.contains('career')) {
      return 'Business';
    } else if (category.contains('tech') || category.contains('technology')) {
      return 'Technology';
    } else if (category.contains('social') || category.contains('cultural')) {
      return 'Community';
    } else {
      return 'Community';
    }
  }

  /// Build search parameters for Afrocentric events
  Map<String, String> _buildAfrocentricSearchParams({
    int page = 1,
    int limit = 20,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final params = <String, String>{
      'key': _apiKey,
      'sign': 'true',
      'photo-host': 'public',
      'page': limit.toString(),
      'offset': ((page - 1) * limit).toString(),
    };

    // Afrocentric search terms
    params['text'] = 'african OR afrobeats OR afrocentric OR "black culture" OR "african diaspora" OR nigerian OR ghanaian OR kenyan OR "african music" OR "african food"';

    // Location filtering
    if (location != null && location.isNotEmpty) {
      params['location'] = location;
    } else {
      // Default to major cities with African diaspora communities
      params['location'] = 'New York, NY';
    }

    // Date filtering
    if (startDate != null) {
      params['time'] = '${startDate.millisecondsSinceEpoch},${endDate?.millisecondsSinceEpoch ?? (startDate.add(const Duration(days: 365)).millisecondsSinceEpoch)}';
    }

    return params;
  }



  /// Search events by query
  Future<List<EventModel>> searchEvents({
    required String query,
    String? category,
    String? location,
  }) async {
    try {
      final queryParams = <String, String>{
        'key': _apiKey,
        'sign': 'true',
        'photo-host': 'public',
        'page': '20',
        'text': query,
      };

      if (location != null && location.isNotEmpty) {
        queryParams['location'] = location;
      } else {
        queryParams['location'] = 'New York, NY';
      }

      log('🔍 Searching Meetup events with query: $query', name: 'MeetupService');
      
      final response = await _dio.get('/find/events', queryParameters: queryParams);
      
      if (response.statusCode == 200) {
        final data = response.data;
        final events = (data as List<dynamic>?)
            ?.map((eventJson) => _convertMeetupToEventModel(eventJson))
            .where((event) => event != null)
            .cast<EventModel>()
            .toList() ?? [];
        
        log('✅ Found ${events.length} events for query: $query', name: 'MeetupService');
        return events;
      } else {
        throw MeetupException('Failed to search events: ${response.statusCode}');
      }
    } catch (e) {
      log('❌ Error searching events: $e', name: 'MeetupService');
      return [];
    }
  }

  /// Fetch event by ID
  Future<EventModel?> fetchEventById(String eventId) async {
    try {
      // Extract Meetup ID from our event ID format
      final meetupId = eventId.replaceFirst('meetup_', '');
      
      final response = await _dio.get(
        '/events/$meetupId',
        queryParameters: {
          'key': _apiKey,
          'sign': 'true',
          'photo-host': 'public',
        },
      );
      
      if (response.statusCode == 200) {
        return _convertMeetupToEventModel(response.data);
      }
      return null;
    } catch (e) {
      log('❌ Error fetching event by ID: $e', name: 'MeetupService');
      return null;
    }
  }

  /// Get events by category
  Future<List<EventModel>> getEventsByCategory(String category) async {
    // Map our categories to Meetup search terms
    final searchQuery = _getCategorySearchQuery(category);
    return searchEvents(query: searchQuery, category: category);
  }

  /// Map category to search query
  String _getCategorySearchQuery(String category) {
    switch (category.toLowerCase()) {
      case 'music':
        return 'african music afrobeats concert';
      case 'food & drink':
      case 'food':
        return 'african food nigerian ghanaian cuisine';
      case 'business':
        return 'african business entrepreneur networking';
      case 'technology':
      case 'tech':
        return 'african tech developer programming';
      case 'arts':
        return 'african art culture exhibition';
      case 'community':
      default:
        return 'african community cultural meetup';
    }
  }

  /// Handle Dio errors and return user-friendly messages
  String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        switch (statusCode) {
          case 401:
            return 'Invalid API key. Please check your Meetup API configuration.';
          case 403:
            return 'Access forbidden. Your API key may not have the required permissions.';
          case 404:
            return 'Events not found. Try adjusting your search criteria.';
          case 429:
            return 'Too many requests. Please wait a moment and try again.';
          default:
            return 'Server error (${statusCode ?? 'unknown'}). Please try again later.';
        }
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.unknown:
      default:
        return 'Network error. Please check your connection and try again.';
    }
  }
}

class MeetupException implements Exception {
  final String message;
  
  const MeetupException(this.message);
  
  @override
  String toString() => 'MeetupException: $message';
}
