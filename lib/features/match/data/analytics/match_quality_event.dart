import 'package:cloud_firestore/cloud_firestore.dart';

enum MatchQualityEventType {
  impression,
  action,
  match,
  conversationStart,
  latency,
}

enum MatchQualityActionType {
  pass,
  connect,
  superLike,
}

class MatchQualityEvent {
  const MatchQualityEvent({
    required this.type,
    required this.userIdHash,
    required this.mode,
    required this.timestamp,
    this.candidateIdHash,
    this.actionType,
    this.scoreSnapshot,
    this.distanceBucket,
    this.latencyMs,
    this.metadata,
  });

  final MatchQualityEventType type;
  final String userIdHash;
  final String? candidateIdHash;
  final String mode;
  final DateTime timestamp;
  final MatchQualityActionType? actionType;
  final Map<String, double>? scoreSnapshot;
  final String? distanceBucket;
  final int? latencyMs;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'userIdHash': userIdHash,
        'candidateIdHash': candidateIdHash,
        'mode': mode,
        'timestamp': Timestamp.fromDate(timestamp),
        'actionType': actionType?.name,
        'scoreSnapshot': scoreSnapshot,
        'distanceBucket': distanceBucket,
        'latencyMs': latencyMs,
        'metadata': metadata,
      }..removeWhere((key, value) => value == null);
}
