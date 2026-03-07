import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'event_types.dart';

export 'event_types.dart';

class EnhancedEventModel extends Equatable {
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
    this.creatorId,
    this.isUserGenerated = false,
    this.eventType = EventType.userGenerated,
    this.status = EventStatus.published,
    this.isPromoted = false,
    this.promotionExpiry,
    this.metadata = const {},
  });

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
    EventStatus status = EventStatus.published,
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

  factory EnhancedEventModel.fromFirestoreJson(
    Map<String, dynamic> json,
    String docId,
  ) =>
      EnhancedEventModel(
        id: docId,
        externalId: json['externalId'],
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        startDate: parseDateTime(json['startDate']),
        endDate: parseDateTime(json['endDate']),
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
        createdAt: parseDateTime(json['createdAt']),
        updatedAt: parseDateTime(json['updatedAt']),
        createdByUserId: json['createdByUserId'],
        creatorId: json['creatorId'],
        isUserGenerated: json['isUserGenerated'] ?? false,
        eventType: parseEventType(json['eventType']),
        status: parseEventStatus(json['status']),
        isPromoted: json['isPromoted'] ?? false,
        promotionExpiry: json['promotionExpiry'] != null
            ? parseDateTime(json['promotionExpiry'])
            : null,
        metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      );

  final String id;
  final String? externalId;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> imageUrls;
  final EventLocation location;
  final String? ticketUrl;
  final bool isFree;
  final double? ticketPrice;
  final String category;
  final List<String> tags;
  final int attendeeCount;
  final int rsvpCount;
  final int maxAttendees;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdByUserId;
  final String? creatorId;
  final bool isUserGenerated;
  final EventType eventType;
  final EventStatus status;
  final bool isPromoted;
  final DateTime? promotionExpiry;
  final Map<String, dynamic> metadata;

  bool get isPublished => status == EventStatus.published;
  String? get ownerUserId => createdByUserId ?? creatorId;
  bool get isVisible => isPublished && endDate.isAfter(DateTime.now());
  bool get isActive => isVisible;
  bool get isDraft => status == EventStatus.draft;
  bool get isUnderReview => status == EventStatus.underReview;
  bool get isCancelled => status == EventStatus.cancelled;
  bool get isCompleted => status == EventStatus.completed;
  bool get hasAvailableSpots => attendeeCount < maxAttendees;

  bool get isHappeningSoon {
    final now = DateTime.now();
    final timeDiff = startDate.difference(now);
    return timeDiff.inHours <= 24 && timeDiff.inHours >= 0;
  }

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

  String get currency => metadata['currency']?.toString() ?? 'USD';

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
        return r'$';
    }
  }

  bool get canEdit {
    if (status == EventStatus.cancelled || status == EventStatus.completed) {
      return false;
    }
    final now = DateTime.now();
    final timeUntilStart = startDate.difference(now);
    if (timeUntilStart.inHours <= 1 && timeUntilStart.inMinutes > 0) {
      return false;
    }
    return status == EventStatus.draft ||
        status == EventStatus.underReview ||
        status == EventStatus.published;
  }

  bool get isCapacityFull => attendeeCount >= maxAttendees;

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
        if (creatorId != null) 'creatorId': creatorId,
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
    String? creatorId,
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
        creatorId: creatorId ?? this.creatorId,
        isUserGenerated: isUserGenerated ?? this.isUserGenerated,
        eventType: eventType ?? this.eventType,
        status: status ?? this.status,
        isPromoted: isPromoted ?? this.isPromoted,
        promotionExpiry: promotionExpiry ?? this.promotionExpiry,
        metadata: metadata ?? this.metadata,
      );

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
        creatorId,
        isUserGenerated,
        eventType,
        status,
        isPromoted,
        promotionExpiry,
        metadata,
      ];
}

class EventCreationData {
  String name = '';
  String description = '';
  DateTime? startDate;
  DateTime? endDate;
  EventLocation? location;
  List<String> imageUrls = [];
  bool isFree = true;
  double? ticketPrice;
  String currency = 'USD';
  String category = '';
  List<String> tags = [];
  int maxAttendees = 100;
  Map<String, dynamic> metadata = {};

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
        return r'$';
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
