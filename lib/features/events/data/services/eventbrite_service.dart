import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import '../models/event_model.dart';

class EventbriteService {
  static const String _baseUrl = 'https://www.eventbriteapi.com/v3';
  static const String _apiKey = 'YOUR_EVENTBRITE_API_KEY'; // TODO: Add to environment variables
  
  final Dio _dio;

  EventbriteService() : _dio = Dio() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    
    // Add interceptor for logging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => log(obj.toString(), name: 'EventbriteAPI'),
    ));
  }

  /// Fetch Afrocentric events from Eventbrite
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

      final response = await _dio.get('/events/search/', queryParameters: queryParams);
      
      if (response.statusCode == 200) {
        final data = response.data;
        final events = (data['events'] as List<dynamic>?)
            ?.map((eventJson) => EventModel.fromEventbriteJson(eventJson))
            .toList() ?? [];
        
        log('Fetched ${events.length} Afrocentric events from Eventbrite', name: 'EventbriteService');
        return events;
      } else {
        throw EventbriteException('Failed to fetch events: ${response.statusCode}');
      }
    } on DioException catch (e) {
      log('Dio error fetching events: ${e.message}', name: 'EventbriteService');
      throw EventbriteException(_handleDioError(e));
    } catch (e) {
      log('Unexpected error fetching events: $e', name: 'EventbriteService');
      throw EventbriteException('Unexpected error occurred: $e');
    }
  }

  /// Fetch specific event details by ID
  Future<EventModel?> fetchEventById(String eventId) async {
    try {
      final response = await _dio.get('/events/$eventId/');
      
      if (response.statusCode == 200) {
        return EventModel.fromEventbriteJson(response.data);
      } else {
        log('Event not found: $eventId', name: 'EventbriteService');
        return null;
      }
    } on DioException catch (e) {
      log('Error fetching event $eventId: ${e.message}', name: 'EventbriteService');
      return null;
    }
  }

  /// Search events by custom query
  Future<List<EventModel>> searchEvents({
    required String query,
    int page = 1,
    int limit = 20,
    String? location,
    String? category,
  }) async {
    try {
      final queryParams = {
        'q': query,
        'page': page.toString(),
        'expand': 'venue,category',
        'sort_by': 'date',
      };

      if (location != null && location.isNotEmpty) {
        queryParams['location.address'] = location;
      }

      if (category != null && category.isNotEmpty) {
        queryParams['categories'] = category;
      }

      final response = await _dio.get('/events/search/', queryParameters: queryParams);
      
      if (response.statusCode == 200) {
        final data = response.data;
        final events = (data['events'] as List<dynamic>?)
            ?.map((eventJson) => EventModel.fromEventbriteJson(eventJson))
            .toList() ?? [];
        
        return events;
      } else {
        throw EventbriteException('Failed to search events: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw EventbriteException(_handleDioError(e));
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
      // Afrocentric keywords and categories
      'q': 'african OR afrobeats OR afrocentric OR "black culture" OR "african diaspora" OR "african music" OR "african art" OR "african food" OR "nigerian" OR "ghanaian" OR "kenyan"',
      'categories': '103,110,113,105,108', // Music, Business, Community, Food & Drink, Arts
      'page': page.toString(),
      'expand': 'venue,category,logo',
      'sort_by': 'date',
      'include_all_series_instances': 'true',
    };

    // Location filtering (prioritize African cities and diaspora locations)
    if (location != null && location.isNotEmpty) {
      params['location.address'] = location;
    } else {
      // Default to major African cities and diaspora locations
      params['location.address'] = 'Lagos,Nigeria OR Accra,Ghana OR Nairobi,Kenya OR London,UK OR New York,USA OR Toronto,Canada';
    }

    // Date filtering
    if (startDate != null) {
      params['start_date.range_start'] = startDate.toIso8601String();
    } else {
      // Default to events from today onwards
      params['start_date.range_start'] = DateTime.now().toIso8601String();
    }

    if (endDate != null) {
      params['start_date.range_end'] = endDate.toIso8601String();
    }

    return params;
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
            return 'Authentication failed. Please check API credentials.';
          case 403:
            return 'Access forbidden. API key may be invalid.';
          case 404:
            return 'Events not found.';
          case 429:
            return 'Too many requests. Please try again later.';
          case 500:
            return 'Server error. Please try again later.';
          default:
            return 'Failed to fetch events. Status code: $statusCode';
        }
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.unknown:
        return 'Network error. Please check your internet connection.';
      default:
        return 'An unexpected error occurred.';
    }
  }
}

class EventbriteException implements Exception {
  final String message;
  
  const EventbriteException(this.message);
  
  @override
  String toString() => 'EventbriteException: $message';
}

/// Event categories for filtering
class EventCategories {
  static const Map<String, String> categories = {
    'music': '103',
    'business': '110',
    'community': '113',
    'food_drink': '105',
    'arts': '108',
    'fashion': '106',
    'film_media': '104',
    'health': '107',
    'hobbies': '119',
    'performing_arts': '109',
    'religion': '111',
    'science_tech': '102',
    'sports_fitness': '108',
    'travel': '112',
  };

  static String? getCategoryId(String categoryName) {
    return categories[categoryName.toLowerCase()];
  }

  static List<String> get allCategoryIds => categories.values.toList();
}
