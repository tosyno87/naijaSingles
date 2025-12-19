import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'event_model.dart' as event_model;

enum EventType { userGenerated, external, promoted }

enum EventStatus { draft, published, cancelled, completed, underReview }

class EnhancedEventModel extends Equatable {
  // Extensible data

  const EnhancedEventModel({
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
    this.externalId,
    this.imageUrls = const [],
    this.ticketUrl,
    this.ticketPrice,
    this.tags = const [],
    this.attendeeCount = 0,
    this.rsvpCount = 0,
    this.maxAttendees = 100,
    this.createdByUserId,
    this.isUserGenerated = false,
    this.eventType = EventType.userGenerated,
    this.status = EventStatus.published,
    this.isPromoted = false,
    this.promotionExpiry,
    this.metadata = const {},
  });

  // Factory for user-generated events
  factory EnhancedEventModel.userGenerated({
    required String id,
    required String name,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required EventLocation location,
    required String createdByUserId,
    List<String> imageUrls = const [],
    bool isFree = true,
    double? ticketPrice,
    String category = 'General',
    List<String> tags = const [],
    int maxAttendees = 100,
    EventStatus status =
        EventStatus.published, // Changed from underReview to published
    Map<String, dynamic> metadata = const {},
  }) {
    final now = DateTime.now();
    return EnhancedEventModel(
      id: id,
      name: name,
      description: description,
      startDate: startDate,
      endDate: endDate,
      imageUrls: imageUrls,
      location: location,
      isFree: isFree,
      ticketPrice: ticketPrice,
      category: category,
      tags: tags,
      maxAttendees: maxAttendees,
      createdAt: now,
      updatedAt: now,
      createdByUserId: createdByUserId,
      isUserGenerated: true,
      status: status,
      metadata: metadata,
    );
  }

  // Factory from existing EventModel (for backward compatibility)
  factory EnhancedEventModel.fromEventModel(eventModel) => EnhancedEventModel(
        id: eventModel.id,
        externalId: eventModel.externalId,
        name: eventModel.name,
        description: eventModel.description,
        startDate: eventModel.startDate,
        endDate: eventModel.endDate,
        imageUrls: eventModel.imageUrl != null ? [eventModel.imageUrl!] : [],
        location: eventModel.location,
        ticketUrl: eventModel.ticketUrl,
        isFree: eventModel.isFree,
        category: eventModel.category,
        attendeeCount: eventModel.attendeeCount,
        rsvpCount: eventModel.rsvpCount,
        createdAt: eventModel.createdAt,
        updatedAt: eventModel.updatedAt,
      );

  factory EnhancedEventModel.fromFirestoreJson(
    Map<String, dynamic> json,
    String docId,
  ) =>
      EnhancedEventModel(
        id: docId,
        externalId: json['externalId'],
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        startDate: (json['startDate'] as Timestamp).toDate(),
        endDate: (json['endDate'] as Timestamp).toDate(),
        imageUrls: (json['imageUrls'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .where((url) => url.isNotEmpty)
                .toList() ??
            [],
        location: EventLocation.fromJson(json['location'] ?? {}),
        ticketUrl: json['ticketUrl'],
        isFree: json['isFree'] ?? true,
        ticketPrice: json['ticketPrice']?.toDouble(),
        category: json['category'] ?? 'General',
        tags: List<String>.from(json['tags'] ?? []),
        attendeeCount: json['attendeeCount'] ?? 0,
        rsvpCount: json['rsvpCount'] ?? 0,
        maxAttendees: json['maxAttendees'] ?? 100,
        createdAt: (json['createdAt'] as Timestamp).toDate(),
        updatedAt: (json['updatedAt'] as Timestamp).toDate(),
        createdByUserId: json['createdByUserId'],
        isUserGenerated: json['isUserGenerated'] ?? false,
        eventType: _parseEventType(json['eventType']),
        status: _parseEventStatus(json['status']),
        isPromoted: json['isPromoted'] ?? false,
        promotionExpiry: json['promotionExpiry'] != null
            ? (json['promotionExpiry'] as Timestamp).toDate()
            : null,
        metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      );
  final String id;
  final String? externalId; // Optional for external event sources
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> imageUrls; // Multiple images support
  final EventLocation location;
  final String? ticketUrl;
  final bool isFree;
  final double? ticketPrice; // For paid user events
  final String category;
  final List<String> tags; // User-defined tags
  final int attendeeCount;
  final int rsvpCount;
  final int maxAttendees; // Capacity limit
  final DateTime createdAt;
  final DateTime updatedAt;

  // User-generated event fields
  final String? createdByUserId; // User who created the event
  final bool isUserGenerated; // Distinguish from external APIs
  final EventType eventType; // Enum for different event sources
  final EventStatus status; // Draft, published, cancelled
  final bool isPromoted; // For ad placements
  final DateTime? promotionExpiry; // Ad campaign duration
  final Map<String, dynamic> metadata;

  // Helper methods for event visibility and status
  bool get isPublished => status == EventStatus.published;
  bool get isVisible => isPublished && endDate.isAfter(DateTime.now());
  bool get isActive => isVisible;
  bool get isDraft => status == EventStatus.draft;
  bool get isUnderReview => status == EventStatus.underReview;
  bool get isCancelled => status == EventStatus.cancelled;
  bool get isCompleted => status == EventStatus.completed;

  // Check if event has available spots
  bool get hasAvailableSpots => attendeeCount < maxAttendees;

  // Check if event is happening soon (within 24 hours)
  bool get isHappeningSoon {
    final now = DateTime.now();
    final timeDiff = startDate.difference(now);
    return timeDiff.inHours <= 24 && timeDiff.inHours >= 0;
  }

  // Convert to EventModel for backward compatibility
  event_model.EventModel toEventModel() {
    // Use primaryImageUrl getter which filters empty strings
    final url = primaryImageUrl.isNotEmpty ? primaryImageUrl : null;
    return event_model.EventModel(
      id: id,
      externalId: externalId ?? id, // Use id if no externalId
      name: name,
      description: description,
      startDate: startDate,
      endDate: endDate,
      imageUrl: url,
      location: event_model.EventLocation.fromJson(
        location.toJson(),
      ), // Convert location
      ticketUrl: ticketUrl,
      isFree: isFree,
      category: category,
      attendeeCount: attendeeCount,
      rsvpCount: rsvpCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      status: _convertToEventModelStatus(status),
      createdByUserId: createdByUserId ?? 'unknown',
    );
  }

  // Convert EnhancedEventModel status to EventModel status
  event_model.EventStatus _convertToEventModelStatus(
    EventStatus enhancedStatus,
  ) {
    switch (enhancedStatus) {
      case EventStatus.draft:
        return event_model.EventStatus.draft;
      case EventStatus.published:
        return event_model.EventStatus.published;
      case EventStatus.cancelled:
        return event_model.EventStatus.cancelled;
      case EventStatus.completed:
        return event_model.EventStatus.completed;
      case EventStatus.underReview:
        return event_model.EventStatus.draft; // Treat under review as draft
    }
  }

  // Helper methods to safely parse enums from Firestore
  static EventType _parseEventType(typeValue) {
    if (typeValue == null) return EventType.userGenerated;

    if (typeValue is String) {
      switch (typeValue.toLowerCase()) {
        case 'usergenerated':
        case 'user_generated':
          return EventType.userGenerated;
        case 'external':
          return EventType.external;
        case 'promoted':
          return EventType.promoted;
        default:
          return EventType.userGenerated;
      }
    }

    if (typeValue is int) {
      if (typeValue >= 0 && typeValue < EventType.values.length) {
        return EventType.values[typeValue];
      }
    }

    return EventType.userGenerated;
  }

  static EventStatus _parseEventStatus(statusValue) {
    if (statusValue == null) return EventStatus.published;

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
          return EventStatus.published;
      }
    }

    if (statusValue is int) {
      if (statusValue >= 0 && statusValue < EventStatus.values.length) {
        return EventStatus.values[statusValue];
      }
    }

    return EventStatus.published;
  }

  Map<String, dynamic> toFirestoreJson() => {
        'externalId': externalId,
        'name': name,
        'description': description,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'imageUrls': imageUrls,
        'location': location.toJson(),
        'ticketUrl': ticketUrl,
        'isFree': isFree,
        'ticketPrice': ticketPrice,
        'category': category,
        'tags': tags,
        'attendeeCount': attendeeCount,
        'rsvpCount': rsvpCount,
        'maxAttendees': maxAttendees,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'createdByUserId': createdByUserId,
        'isUserGenerated': isUserGenerated,
        'eventType': eventType.toString().split('.').last,
        'status': status.toString().split('.').last,
        'isPromoted': isPromoted,
        'promotionExpiry': promotionExpiry != null
            ? Timestamp.fromDate(promotionExpiry!)
            : null,
        'metadata': metadata,
      };

  EnhancedEventModel copyWith({
    String? id,
    String? externalId,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? imageUrls,
    EventLocation? location,
    String? ticketUrl,
    bool? isFree,
    double? ticketPrice,
    String? category,
    List<String>? tags,
    int? attendeeCount,
    int? rsvpCount,
    int? maxAttendees,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdByUserId,
    bool? isUserGenerated,
    EventType? eventType,
    EventStatus? status,
    bool? isPromoted,
    DateTime? promotionExpiry,
    Map<String, dynamic>? metadata,
  }) =>
      EnhancedEventModel(
        id: id ?? this.id,
        externalId: externalId ?? this.externalId,
        name: name ?? this.name,
        description: description ?? this.description,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        imageUrls: imageUrls ?? this.imageUrls,
        location: location ?? this.location,
        ticketUrl: ticketUrl ?? this.ticketUrl,
        isFree: isFree ?? this.isFree,
        ticketPrice: ticketPrice ?? this.ticketPrice,
        category: category ?? this.category,
        tags: tags ?? this.tags,
        attendeeCount: attendeeCount ?? this.attendeeCount,
        rsvpCount: rsvpCount ?? this.rsvpCount,
        maxAttendees: maxAttendees ?? this.maxAttendees,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        createdByUserId: createdByUserId ?? this.createdByUserId,
        isUserGenerated: isUserGenerated ?? this.isUserGenerated,
        eventType: eventType ?? this.eventType,
        status: status ?? this.status,
        isPromoted: isPromoted ?? this.isPromoted,
        promotionExpiry: promotionExpiry ?? this.promotionExpiry,
        metadata: metadata ?? this.metadata,
      );

  // Helper getters
  String get primaryImageUrl {
    final validUrls = imageUrls
        .where((url) => url.isNotEmpty && url.trim().isNotEmpty)
        .toList();
    return validUrls.isNotEmpty ? validUrls.first : '';
  }

  bool get hasImages {
    final validUrls = imageUrls
        .where((url) => url.isNotEmpty && url.trim().isNotEmpty)
        .toList();
    return validUrls.isNotEmpty;
  }

  bool get isPaid => !isFree && ticketPrice != null && ticketPrice! > 0;

  // Currency helper
  String get currency {
    return metadata['currency']?.toString() ?? 'USD';
  }

  String get currencySymbol {
    switch (currency) {
      case 'USD':
        return r'$';
      case 'NGN':
        return '₦';
      case 'GBP':
        return '£';
      case 'EUR':
        return '€';
      default:
        return r'$'; // Default to USD
    }
  }

  // isActive is already defined above as isVisible
  bool get canEdit {
    // Don't allow editing if event is cancelled or completed
    if (status == EventStatus.cancelled || status == EventStatus.completed) {
      return false;
    }

    // Don't allow editing if event starts within 1 hour
    final now = DateTime.now();
    final timeUntilStart = startDate.difference(now);
    if (timeUntilStart.inHours <= 1 && timeUntilStart.inMinutes > 0) {
      return false;
    }

    // Allow editing for draft, underReview, and published events
    return status == EventStatus.draft ||
        status == EventStatus.underReview ||
        status == EventStatus.published;
  }

  bool get isCapacityFull => attendeeCount >= maxAttendees;

  @override
  List<Object?> get props => [
        id,
        externalId,
        name,
        description,
        startDate,
        endDate,
        imageUrls,
        location,
        ticketUrl,
        isFree,
        ticketPrice,
        category,
        tags,
        attendeeCount,
        rsvpCount,
        maxAttendees,
        createdAt,
        updatedAt,
        createdByUserId,
        isUserGenerated,
        eventType,
        status,
        isPromoted,
        promotionExpiry,
        metadata,
      ];
}

// Enhanced EventLocation with additional fields
class EventLocation extends Equatable {
  const EventLocation({
    this.name,
    this.address,
    this.city,
    this.state,
    this.country,
    this.latitude,
    this.longitude,
    this.placeId,
    this.additionalInfo,
  });

  factory EventLocation.fromJson(Map<String, dynamic> json) => EventLocation(
        name: json['name'],
        address: json['address'],
        city: json['city'],
        state: json['state'],
        country: json['country'],
        latitude: json['latitude']?.toDouble(),
        longitude: json['longitude']?.toDouble(),
        placeId: json['placeId'],
        additionalInfo: json['additionalInfo'] != null
            ? Map<String, dynamic>.from(json['additionalInfo'])
            : null,
      );
  final String? name;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? placeId; // Google Places ID
  final Map<String, dynamic>? additionalInfo;

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'city': city,
        'state': state,
        'country': country,
        'latitude': latitude,
        'longitude': longitude,
        'placeId': placeId,
        'additionalInfo': additionalInfo,
      };

  String get displayAddress {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    return parts.join(', ');
  }

  String get shortAddress {
    if (name != null && name!.isNotEmpty) return name!;
    if (city != null && city!.isNotEmpty) return city!;
    return displayAddress;
  }

  bool get hasCoordinates => latitude != null && longitude != null;

  @override
  List<Object?> get props => [
        name,
        address,
        city,
        state,
        country,
        latitude,
        longitude,
        placeId,
        additionalInfo,
      ];
}

// Event creation data transfer object
class EventCreationData {
  String name = '';
  String description = '';
  DateTime? startDate;
  DateTime? endDate;
  EventLocation? location;
  List<String> imageUrls = [];
  bool isFree = true;
  double? ticketPrice;
  String currency = 'USD'; // Default to US Dollar
  String category = '';
  List<String> tags = [];
  int maxAttendees = 100;
  Map<String, dynamic> metadata = {};

  // Currency helper methods
  String get currencySymbol {
    switch (currency) {
      case 'USD':
        return r'$';
      case 'NGN':
        return '₦';
      case 'GBP':
        return '£';
      case 'EUR':
        return '€';
      default:
        return r'$'; // Default to USD
    }
  }

  String get currencyName {
    switch (currency) {
      case 'NGN':
        return 'Nigerian Naira';
      case 'USD':
        return 'US Dollar';
      case 'GBP':
        return 'British Pound';
      case 'EUR':
        return 'Euro';
      default:
        return 'Nigerian Naira';
    }
  }

  bool get isValid =>
      name.isNotEmpty &&
      description.isNotEmpty &&
      category.isNotEmpty &&
      startDate != null &&
      endDate != null &&
      location != null &&
      startDate!.isBefore(endDate!) &&
      startDate!.isAfter(DateTime.now());

  EnhancedEventModel toEventModel(String id, String createdByUserId) =>
      EnhancedEventModel.userGenerated(
        id: id,
        name: name,
        description: description,
        startDate: startDate!,
        endDate: endDate!,
        location: location!,
        createdByUserId: createdByUserId,
        imageUrls: imageUrls,
        isFree: isFree,
        ticketPrice: ticketPrice,
        category: category,
        tags: tags,
        maxAttendees: maxAttendees,
        metadata: {
          ...metadata,
          'currency': currency,
        },
      );
}
