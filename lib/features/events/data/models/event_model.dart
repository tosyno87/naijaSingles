import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../../../common/utils/app_logger.dart';

enum EventStatus {
  draft,
  published,
  cancelled,
  completed,
  underReview,
}

class EventModel extends Equatable {
  // Distance in kilometers from user's location

  const EventModel({
    required this.id,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.isFree,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    required this.createdByUserId,
    this.externalId, // Made optional
    this.imageUrl,
    this.ticketUrl,
    this.ticketPrice,
    this.tags = const [],
    this.attendeeCount = 0,
    this.rsvpCount = 0,
    this.status = EventStatus.published,
    this.isPublic = true,
    this.distanceFromUser,
  });

  factory EventModel.fromFirestoreJson(
    Map<String, dynamic> json,
    String docId,
  ) {
    try {
      // Handle both imageUrl (singular) and imageUrls (plural) for backward compatibility
      String? imageUrl;

      // Debug logging
      AppLogger.debug('🔍 EventModel.fromFirestoreJson - Event ID: $docId');
      AppLogger.debug(
          '🔍 EventModel.fromFirestoreJson - json keys: ${json.keys.toList()}');
      AppLogger.debug(
          '🔍 EventModel.fromFirestoreJson - imageUrl: ${json['imageUrl']}');
      AppLogger.debug(
          '🔍 EventModel.fromFirestoreJson - imageUrls: ${json['imageUrls']}');
      AppLogger.debug(
          '🔍 EventModel.fromFirestoreJson - imageUrls type: ${json['imageUrls']?.runtimeType}');

      if (json['imageUrl'] != null &&
          json['imageUrl'].toString().trim().isNotEmpty) {
        imageUrl = json['imageUrl'].toString();
        AppLogger.debug('✅ EventModel: Using imageUrl (singular): $imageUrl');
      } else if (json['imageUrls'] != null && json['imageUrls'] is List) {
        final imageUrlsList = json['imageUrls'] as List;
        // Filter out empty strings and get first valid URL
        final validUrls = imageUrlsList
            .map((e) => e?.toString() ?? '')
            .where((url) => url.trim().isNotEmpty)
            .toList();

        if (validUrls.isNotEmpty) {
          imageUrl = validUrls.first;
          AppLogger.debug('✅ EventModel: Using imageUrls[0]: $imageUrl');
        } else {
          AppLogger.debug(
              '❌ EventModel: imageUrls list is empty or contains only empty strings');
        }
      } else {
        AppLogger.debug('❌ EventModel: No valid imageUrl or imageUrls found');
      }

      return EventModel(
        id: docId,
        externalId: json['externalId'] ?? '',
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        startDate: _parseDateTime(json['startDate']),
        endDate: _parseDateTime(json['endDate']),
        imageUrl: imageUrl,
        location: EventLocation.fromJson(json['location'] ?? {}),
        ticketUrl: json['ticketUrl'],
        isFree: json['isFree'] ?? false,
        ticketPrice: json['ticketPrice']?.toDouble(),
        category: json['category'] ?? 'General',
        tags: List<String>.from(json['tags'] ?? []),
        attendeeCount: json['attendeeCount'] ?? 0,
        rsvpCount: json['rsvpCount'] ?? 0,
        createdAt: _parseDateTime(json['createdAt']),
        updatedAt: _parseDateTime(json['updatedAt']),
        status: _parseEventStatus(json['status']),
        isPublic: json['isPublic'] ?? true,
        createdByUserId: json['createdByUserId'] ?? 'unknown',
        distanceFromUser: json['distanceFromUser']?.toDouble(),
      );
    } catch (e, stackTrace) {
      AppLogger.error('❌ Error parsing EventModel from Firestore',
          error: e, stackTrace: stackTrace);
      AppLogger.debug('📄 Raw data: $json');
      rethrow;
    }
  }
  final String id;
  final String? externalId; // Optional for external event sources
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String? imageUrl;
  final EventLocation location;
  final String? ticketUrl;
  final bool isFree;
  final double? ticketPrice; // For paid user events
  final String category;
  final List<String> tags; // User-defined tags
  final int attendeeCount;
  final int rsvpCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final EventStatus status;
  final bool isPublic;
  final String createdByUserId;
  final double? distanceFromUser;

  // Helper method to safely parse EventStatus from Firestore
  static EventStatus _parseEventStatus(statusValue) {
    AppLogger.debug(
      '🔄 Parsing EventStatus from: $statusValue (type: ${statusValue.runtimeType})',
    );

    if (statusValue == null) return EventStatus.published;

    // Handle string values (enum name)
    if (statusValue is String) {
      switch (statusValue.toLowerCase()) {
        case 'draft':
          return EventStatus.draft;
        case 'published':
          return EventStatus.published;
        case 'cancelled':
          return EventStatus.cancelled;
        case 'completed':
          return EventStatus.completed;
        case 'underreview':
        case 'under_review':
          return EventStatus.underReview;
        default:
          AppLogger.warning(
            '⚠️ Unknown EventStatus string: $statusValue, defaulting to published',
          );
          return EventStatus.published;
      }
    }

    // Handle integer values (enum index) - for backward compatibility
    if (statusValue is int) {
      if (statusValue >= 0 && statusValue < EventStatus.values.length) {
        return EventStatus.values[statusValue];
      }
    }

    AppLogger.warning(
      '⚠️ Could not parse EventStatus: $statusValue, defaulting to published',
    );
    return EventStatus.published;
  }

  // Helper method to safely parse DateTime from Firestore
  static DateTime _parseDateTime(dateValue) {
    if (dateValue == null) return DateTime.now();

    // Handle Timestamp objects (Firestore native)
    if (dateValue is Timestamp) {
      try {
        return dateValue.toDate();
      } catch (e) {
        return DateTime.now();
      }
    }

    // Handle DateTime objects
    if (dateValue is DateTime) {
      return dateValue;
    }

    // Handle milliseconds since epoch (int)
    if (dateValue is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    }

    // Handle string representations
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    }

    // Handle objects with millisecondsSinceEpoch property
    if (dateValue is Map && dateValue.containsKey('millisecondsSinceEpoch')) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(
          dateValue['millisecondsSinceEpoch'],
        );
      } catch (e) {
        return DateTime.now();
      }
    }

    return DateTime.now();
  }

  Map<String, dynamic> toFirestoreJson() => {
        'externalId': externalId,
        'name': name,
        'description': description,
        'startDate': startDate,
        'endDate': endDate,
        'imageUrl': imageUrl,
        'location': location.toJson(),
        'ticketUrl': ticketUrl,
        'isFree': isFree,
        'ticketPrice': ticketPrice,
        'category': category,
        'tags': tags,
        'attendeeCount': attendeeCount,
        'rsvpCount': rsvpCount,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'status': status.toString().split('.').last,
        'isPublic': isPublic,
        'createdByUserId': createdByUserId,
      };

  EventModel copyWith({
    String? id,
    String? externalId,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? imageUrl,
    EventLocation? location,
    String? ticketUrl,
    bool? isFree,
    double? ticketPrice,
    String? category,
    List<String>? tags,
    int? attendeeCount,
    int? rsvpCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    EventStatus? status,
    bool? isPublic,
    String? createdByUserId,
    double? distanceFromUser,
  }) =>
      EventModel(
        id: id ?? this.id,
        externalId: externalId ?? this.externalId,
        name: name ?? this.name,
        description: description ?? this.description,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        imageUrl: imageUrl ?? this.imageUrl,
        location: location ?? this.location,
        ticketUrl: ticketUrl ?? this.ticketUrl,
        isFree: isFree ?? this.isFree,
        ticketPrice: ticketPrice ?? this.ticketPrice,
        category: category ?? this.category,
        tags: tags ?? this.tags,
        attendeeCount: attendeeCount ?? this.attendeeCount,
        rsvpCount: rsvpCount ?? this.rsvpCount,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        status: status ?? this.status,
        isPublic: isPublic ?? this.isPublic,
        createdByUserId: createdByUserId ?? this.createdByUserId,
        distanceFromUser: distanceFromUser ?? this.distanceFromUser,
      );

  @override
  List<Object?> get props => [
        id,
        externalId,
        name,
        description,
        startDate,
        endDate,
        imageUrl,
        location,
        ticketUrl,
        isFree,
        ticketPrice,
        category,
        tags,
        attendeeCount,
        rsvpCount,
        createdAt,
        updatedAt,
        status,
        isPublic,
        createdByUserId,
        distanceFromUser,
      ];
}

class EventLocation extends Equatable {
  const EventLocation({
    this.name,
    this.address,
    this.city,
    this.state,
    this.country,
    this.latitude,
    this.longitude,
  });

  factory EventLocation.fromJson(Map<String, dynamic> json) {
    try {
      AppLogger.debug('🌍 Parsing EventLocation from: $json');

      return EventLocation(
        name: json['name'],
        // Handle both nested (Eventbrite) and flat (Firestore) address formats
        address: json['address'] is String
            ? json['address']
            : json['address']?['localized_address_display'],
        city: json['city'] ?? json['address']?['city'],
        state: json['state'] ?? json['address']?['region'],
        country: json['country'] ?? json['address']?['country'],
        latitude: json['latitude']?.toDouble(),
        longitude: json['longitude']?.toDouble(),
      );
    } catch (e, stackTrace) {
      AppLogger.error('❌ Error parsing EventLocation',
          error: e, stackTrace: stackTrace);
      AppLogger.debug('📄 Raw location data: $json');
      rethrow;
    }
  }
  final String? name;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'city': city,
        'state': state,
        'country': country,
        'latitude': latitude,
        'longitude': longitude,
      };

  String get displayAddress {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    return parts.join(', ');
  }

  @override
  List<Object?> get props =>
      [name, address, city, state, country, latitude, longitude];
}
