import 'package:cloud_firestore/cloud_firestore.dart';

class MatchModel {
  MatchModel({
    required this.id,
    required this.users,
    required this.matchedAt,
    required this.matchStatus,
    this.chatThreadId,
  });

  // Create a MatchModel from a Firestore document
  factory MatchModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return MatchModel(
      id: doc.id,
      users: List<String>.from(data['users'] ?? []),
      matchedAt: (data['matchedAt'] as Timestamp?)?.toDate() ??
          (data['timestamp'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      matchStatus: data['matchStatus'] ?? 'matched',
      chatThreadId: data['chatThreadId'],
    );
  }
  final String id;
  final List<String> users;
  final DateTime matchedAt;
  final String matchStatus;
  final String? chatThreadId;

  // Convert MatchModel to a Map for Firestore
  Map<String, dynamic> toMap() => {
        'users': users,
        'matchedAt': FieldValue.serverTimestamp(),
        'matchStatus': matchStatus,
        if (chatThreadId != null) 'chatThreadId': chatThreadId,
      };

  // Create a copy of this MatchModel with updated fields
  MatchModel copyWith({
    String? id,
    List<String>? users,
    DateTime? matchedAt,
    String? matchStatus,
    String? chatThreadId,
  }) =>
      MatchModel(
        id: id ?? this.id,
        users: users ?? this.users,
        matchedAt: matchedAt ?? this.matchedAt,
        matchStatus: matchStatus ?? this.matchStatus,
        chatThreadId: chatThreadId ?? this.chatThreadId,
      );

  @override
  String toString() =>
      'MatchModel(id: $id, users: $users, matchedAt: $matchedAt, matchStatus: $matchStatus, chatThreadId: $chatThreadId)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MatchModel &&
        other.id == id &&
        other.users.length == users.length &&
        other.users.every(users.contains) &&
        other.matchStatus == matchStatus &&
        other.chatThreadId == chatThreadId;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      users.hashCode ^
      matchStatus.hashCode ^
      chatThreadId.hashCode;
}
