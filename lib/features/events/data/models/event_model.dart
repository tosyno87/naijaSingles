import 'package:equatable/equatable.dart';

enum EventStatus {
  draft,
  published,
  cancelled,
  completed,
  underReview,
}

class EventModel extends Equatable {
  final String id;
  final String eventbriteId;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String? imageUrl;
  final EventLocation location;
  final String? ticketUrl;
  final bool isFree;
  final String category;
  final int attendeeCount;
  final int rsvpCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final EventStatus status;
  final bool isPublic;

  const EventModel({
    required this.id,
    required this.eventbriteId,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.imageUrl,
    required this.location,
    this.ticketUrl,
    required this.isFree,
    required this.category,
    this.attendeeCount = 0,
    this.rsvpCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.status = EventStatus.published,
    this.isPublic = true,
  });

  // Helper method to safely parse EventStatus from Firestore
  static EventStatus _parseEventStatus(dynamic statusValue) {
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
          return EventStatus.published;
      }
    }
    
    // Handle integer values (enum index) - for backward compatibility
    if (statusValue is int) {
      if (statusValue >= 0 && statusValue < EventStatus.values.length) {
        return EventStatus.values[statusValue];
      }
    }
    
    return EventStatus.published;
  }

  factory EventModel.fromEventbriteJson(Map<String, dynamic> json) {
    return EventModel(
      id: '', // Will be set when saving to Firestore
      eventbriteId: json['id'] ?? '',
      name: json['name']?['text'] ?? '',
      description: json['description']?['text'] ?? '',
      startDate: DateTime.parse(json['start']?['utc'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['end']?['utc'] ?? DateTime.now().toIso8601String()),
      imageUrl: json['logo']?['url'],
      location: EventLocation.fromJson(json['venue'] ?? {}),
      ticketUrl: json['url'],
      isFree: json['is_free'] ?? false,
      category: json['category']?['name'] ?? 'General',
      attendeeCount: 0,
      rsvpCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: EventStatus.published,
      isPublic: true,
    );
  }

  factory EventModel.fromFirestoreJson(Map<String, dynamic> json, String docId) {
    return EventModel(
      id: docId,
      eventbriteId: json['eventbriteId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      startDate: DateTime.fromMillisecondsSinceEpoch(json['startDate']?.millisecondsSinceEpoch ?? 0),
      endDate: DateTime.fromMillisecondsSinceEpoch(json['endDate']?.millisecondsSinceEpoch ?? 0),
      imageUrl: json['imageUrl'],
      location: EventLocation.fromJson(json['location'] ?? {}),
      ticketUrl: json['ticketUrl'],
      isFree: json['isFree'] ?? false,
      category: json['category'] ?? 'General',
      attendeeCount: json['attendeeCount'] ?? 0,
      rsvpCount: json['rsvpCount'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']?.millisecondsSinceEpoch ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt']?.millisecondsSinceEpoch ?? 0),
      status: _parseEventStatus(json['status']),
      isPublic: json['isPublic'] ?? true,
    );
  }

  Map<String, dynamic> toFirestoreJson() {
    return {
      'eventbriteId': eventbriteId,
      'name': name,
      'description': description,
      'startDate': startDate,
      'endDate': endDate,
      'imageUrl': imageUrl,
      'location': location.toJson(),
      'ticketUrl': ticketUrl,
      'isFree': isFree,
      'category': category,
      'attendeeCount': attendeeCount,
      'rsvpCount': rsvpCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'status': status.toString().split('.').last,
      'isPublic': isPublic,
    };
  }

  EventModel copyWith({
    String? id,
    String? eventbriteId,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? imageUrl,
    EventLocation? location,
    String? ticketUrl,
    bool? isFree,
    String? category,
    int? attendeeCount,
    int? rsvpCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    EventStatus? status,
    bool? isPublic,
  }) {
    return EventModel(
      id: id ?? this.id,
      eventbriteId: eventbriteId ?? this.eventbriteId,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      ticketUrl: ticketUrl ?? this.ticketUrl,
      isFree: isFree ?? this.isFree,
      category: category ?? this.category,
      attendeeCount: attendeeCount ?? this.attendeeCount,
      rsvpCount: rsvpCount ?? this.rsvpCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  @override
  List<Object?> get props => [
        id,
        eventbriteId,
        name,
        description,
        startDate,
        endDate,
        imageUrl,
        location,
        ticketUrl,
        isFree,
        category,
        attendeeCount,
        rsvpCount,
        createdAt,
        updatedAt,
        status,
        isPublic,
      ];
}

class EventLocation extends Equatable {
  final String? name;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final double? latitude;
  final double? longitude;

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
    return EventLocation(
      name: json['name'],
      address: json['address']?['localized_address_display'],
      city: json['address']?['city'],
      state: json['address']?['region'],
      country: json['address']?['country'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  String get displayAddress {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    return parts.join(', ');
  }

  @override
  List<Object?> get props => [name, address, city, state, country, latitude, longitude];
}
