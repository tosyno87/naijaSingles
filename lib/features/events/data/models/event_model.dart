import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../../../common/utils/app_logger.dart';
import 'event_types.dart';

export 'event_types.dart';

class EventModel extends Equatable {
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
    this.externalId,
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
      String? imageUrl;

      AppLogger.debug('🔍 EventModel.fromFirestoreJson - Event ID: $docId');

      if (json['imageUrl'] != null &&
          json['imageUrl'].toString().trim().isNotEmpty) {
        imageUrl = json['imageUrl'].toString();
      } else if (json['imageUrls'] != null && json['imageUrls'] is List) {
        final imageUrlsList = json['imageUrls'] as List;
        final validUrls = imageUrlsList
            .map((e) => e?.toString() ?? '')
            .where((url) => url.trim().isNotEmpty)
            .toList();
        if (validUrls.isNotEmpty) {
          imageUrl = validUrls.first;
        }
      }

      return EventModel(
        id: docId,
        externalId: json['externalId'] ?? '',
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        startDate: parseDateTime(json['startDate']),
        endDate: parseDateTime(json['endDate']),
        imageUrl: imageUrl,
        location: EventLocation.fromJson(json['location'] ?? {}),
        ticketUrl: json['ticketUrl'],
        isFree: json['isFree'] ?? false,
        ticketPrice: json['ticketPrice']?.toDouble(),
        category: json['category'] ?? 'General',
        tags: List<String>.from(json['tags'] ?? []),
        attendeeCount: json['attendeeCount'] ?? 0,
        rsvpCount: json['rsvpCount'] ?? 0,
        createdAt: parseDateTime(json['createdAt']),
        updatedAt: parseDateTime(json['updatedAt']),
        status: parseEventStatus(json['status']),
        isPublic: json['isPublic'] ?? true,
        createdByUserId: json['createdByUserId'] ?? 'unknown',
        distanceFromUser: json['distanceFromUser']?.toDouble(),
      );
    } on Object catch (e, stackTrace) {
      AppLogger.error(
        '❌ Error parsing EventModel from Firestore',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  final String id;
  final String? externalId;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String? imageUrl;
  final EventLocation location;
  final String? ticketUrl;
  final bool isFree;
  final double? ticketPrice;
  final String category;
  final List<String> tags;
  final int attendeeCount;
  final int rsvpCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final EventStatus status;
  final bool isPublic;
  final String createdByUserId;
  final double? distanceFromUser;

  Map<String, dynamic> toFirestoreJson() => {
        'externalId': externalId,
        'name': name,
        'description': description,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'imageUrl': imageUrl,
        'location': location.toJson(),
        'ticketUrl': ticketUrl,
        'isFree': isFree,
        'ticketPrice': ticketPrice,
        'category': category,
        'tags': tags,
        'attendeeCount': attendeeCount,
        'rsvpCount': rsvpCount,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
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
