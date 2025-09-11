import 'package:equatable/equatable.dart';

enum RSVPStatus {
  going,
  interested,
  notGoing,
  none,
}

extension RSVPStatusExtension on RSVPStatus {
  String get displayName {
    switch (this) {
      case RSVPStatus.going:
        return "I'm Going";
      case RSVPStatus.interested:
        return "Interested";
      case RSVPStatus.notGoing:
        return "Not Going";
      case RSVPStatus.none:
        return "No Response";
    }
  }

  String get value {
    switch (this) {
      case RSVPStatus.going:
        return 'going';
      case RSVPStatus.interested:
        return 'interested';
      case RSVPStatus.notGoing:
        return 'not_going';
      case RSVPStatus.none:
        return 'none';
    }
  }

  static RSVPStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'going':
        return RSVPStatus.going;
      case 'interested':
        return RSVPStatus.interested;
      case 'not_going':
        return RSVPStatus.notGoing;
      default:
        return RSVPStatus.none;
    }
  }
}

class RSVPModel extends Equatable {
  final String id;
  final String userId;
  final String eventId;
  final RSVPStatus status;
  final DateTime rsvpDate;
  final Map<String, dynamic>? userProfile;
  final String? notes;

  const RSVPModel({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.status,
    required this.rsvpDate,
    this.userProfile,
    this.notes,
  });

  factory RSVPModel.fromFirestoreJson(Map<String, dynamic> json, String docId) {
    return RSVPModel(
      id: docId,
      userId: json['userId'] ?? '',
      eventId: json['eventId'] ?? '',
      status: RSVPStatusExtension.fromString(json['status'] ?? 'none'),
      rsvpDate: DateTime.fromMillisecondsSinceEpoch(
        json['rsvpDate']?.millisecondsSinceEpoch ?? 
        json['timestamp']?.millisecondsSinceEpoch ?? 0,
      ),
      userProfile: json['userProfile'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toFirestoreJson() {
    return {
      'userId': userId,
      'eventId': eventId,
      'status': status.value,
      'rsvpDate': rsvpDate,
      'timestamp': rsvpDate, // Add timestamp field for Firestore rules compatibility
      'userProfile': userProfile,
      'notes': notes,
    };
  }

  RSVPModel copyWith({
    String? id,
    String? userId,
    String? eventId,
    RSVPStatus? status,
    DateTime? rsvpDate,
    Map<String, dynamic>? userProfile,
    String? notes,
  }) {
    return RSVPModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      status: status ?? this.status,
      rsvpDate: rsvpDate ?? this.rsvpDate,
      userProfile: userProfile ?? this.userProfile,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        eventId,
        status,
        rsvpDate,
        userProfile,
        notes,
      ];
}

class EventAttendeeModel extends Equatable {
  final String userId;
  final String eventId;
  final RSVPStatus status;
  final DateTime rsvpDate;
  final String userName;
  final String? userAvatar;
  final int? userAge;
  final String? userLocation;

  const EventAttendeeModel({
    required this.userId,
    required this.eventId,
    required this.status,
    required this.rsvpDate,
    required this.userName,
    this.userAvatar,
    this.userAge,
    this.userLocation,
  });

  factory EventAttendeeModel.fromFirestoreJson(Map<String, dynamic> json) {
    return EventAttendeeModel(
      userId: json['userId'] ?? '',
      eventId: json['eventId'] ?? '',
      status: RSVPStatusExtension.fromString(json['status'] ?? 'none'),
      rsvpDate: DateTime.fromMillisecondsSinceEpoch(
        json['rsvpDate']?.millisecondsSinceEpoch ?? 0,
      ),
      userName: json['userProfile']?['name'] ?? 'Unknown User',
      userAvatar: json['userProfile']?['avatar'],
      userAge: json['userProfile']?['age'],
      userLocation: json['userProfile']?['location'],
    );
  }

  @override
  List<Object?> get props => [
        userId,
        eventId,
        status,
        rsvpDate,
        userName,
        userAvatar,
        userAge,
        userLocation,
      ];
}
