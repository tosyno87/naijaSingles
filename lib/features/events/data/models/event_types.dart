import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../../../common/utils/app_logger.dart';

enum EventStatus { draft, published, cancelled, completed, underReview }

enum EventType { userGenerated, external, promoted }

EventStatus parseEventStatus(Object? statusValue) {
  if (statusValue == null) {
    return EventStatus.published;
  }

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

EventType parseEventType(Object? typeValue) {
  if (typeValue == null) {
    return EventType.userGenerated;
  }

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

/// Safely parses various date representations from Firestore.
DateTime parseDateTime(Object? dateValue) {
  if (dateValue == null) {
    return DateTime.now();
  }

  if (dateValue is Timestamp) {
    try {
      return dateValue.toDate();
    } on Exception {
      return DateTime.now();
    }
  }

  if (dateValue is DateTime) {
    return dateValue;
  }

  if (dateValue is int) {
    try {
      return DateTime.fromMillisecondsSinceEpoch(dateValue);
    } on Exception {
      return DateTime.now();
    }
  }

  if (dateValue is String) {
    try {
      return DateTime.parse(dateValue);
    } on FormatException {
      return DateTime.now();
    }
  }

  if (dateValue is Map && dateValue.containsKey('millisecondsSinceEpoch')) {
    try {
      return DateTime.fromMillisecondsSinceEpoch(
        dateValue['millisecondsSinceEpoch'] as int,
      );
    } on Exception {
      return DateTime.now();
    }
  }

  return DateTime.now();
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
    this.placeId,
    this.additionalInfo,
  });

  factory EventLocation.fromJson(Map<String, dynamic> json) {
    try {
      return EventLocation(
        name: json['name'] as String?,
        address: json['address'] is String
            ? json['address'] as String
            : (json['address'] as Map<String, dynamic>?)?['localized_address_display'] as String?,
        city: (json['city'] ?? (json['address'] as Map<String, dynamic>?)?['city']) as String?,
        state: (json['state'] ?? (json['address'] as Map<String, dynamic>?)?['region']) as String?,
        country: (json['country'] ?? (json['address'] as Map<String, dynamic>?)?['country']) as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        placeId: json['placeId'] as String?,
        additionalInfo: json['additionalInfo'] != null
            ? Map<String, dynamic>.from(json['additionalInfo'] as Map)
            : null,
      );
    } catch (e, stackTrace) {
      AppLogger.error('❌ Error parsing EventLocation',
          error: e, stackTrace: stackTrace);
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
  final String? placeId;
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
    if (address != null && address!.isNotEmpty) {
      parts.add(address!);
    }
    if (city != null && city!.isNotEmpty) {
      parts.add(city!);
    }
    if (state != null && state!.isNotEmpty) {
      parts.add(state!);
    }
    return parts.join(', ');
  }

  String get shortAddress {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }
    if (city != null && city!.isNotEmpty) {
      return city!;
    }
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
