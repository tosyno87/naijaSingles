import 'package:cloud_firestore/cloud_firestore.dart';

class MatchModel {
  final String id;
  final List<String> users;
  final DateTime timestamp;
  final String matchStatus;

  MatchModel({
    required this.id,
    required this.users,
    required this.timestamp,
    required this.matchStatus,
  });

  // Create a MatchModel from a Firestore document
  factory MatchModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return MatchModel(
      id: doc.id,
      users: List<String>.from(data['users'] ?? []),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      matchStatus: data['matchStatus'] ?? 'matched',
    );
  }

  // Convert MatchModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'users': users,
      'timestamp': Timestamp.fromDate(timestamp),
      'matchStatus': matchStatus,
    };
  }

  // Create a copy of this MatchModel with updated fields
  MatchModel copyWith({
    String? id,
    List<String>? users,
    DateTime? timestamp,
    String? matchStatus,
  }) {
    return MatchModel(
      id: id ?? this.id,
      users: users ?? this.users,
      timestamp: timestamp ?? this.timestamp,
      matchStatus: matchStatus ?? this.matchStatus,
    );
  }
}
