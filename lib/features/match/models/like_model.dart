import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../common/utils/firestore_helpers.dart';

class LikeModel {
  LikeModel({
    required this.from,
    required this.to,
    required this.timestamp,
  });

  // Create a LikeModel from a Firestore document
  factory LikeModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return LikeModel(
      from: data['from'] ?? '',
      to: data['to'] ?? '',
      timestamp: parseDateTime(data['timestamp']),
    );
  }
  final String from;
  final String to;
  final DateTime timestamp;

  // Convert LikeModel to a Map for Firestore
  Map<String, dynamic> toMap() => {
        'from': from,
        'to': to,
        'timestamp': FieldValue.serverTimestamp(),
      };

  // Create a copy of this LikeModel with updated fields
  LikeModel copyWith({
    String? from,
    String? to,
    DateTime? timestamp,
  }) =>
      LikeModel(
        from: from ?? this.from,
        to: to ?? this.to,
        timestamp: timestamp ?? this.timestamp,
      );

  @override
  String toString() => 'LikeModel(from: $from, to: $to, timestamp: $timestamp)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LikeModel && other.from == from && other.to == to;
  }

  @override
  int get hashCode => from.hashCode ^ to.hashCode;
}
