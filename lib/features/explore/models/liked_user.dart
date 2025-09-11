import 'package:cloud_firestore/cloud_firestore.dart';

class LikedUser {
  final String currentUserId;
  final String likedUserId;
  final DateTime timestamp;

  LikedUser({
    required this.currentUserId,
    required this.likedUserId,
    required this.timestamp,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'currentUserId': currentUserId,
      'likedUserId': likedUserId,
      'timestamp': timestamp,
    };
  }

  // Create from Firestore document
  factory LikedUser.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LikedUser(
      currentUserId: data['currentUserId'] ?? '',
      likedUserId: data['likedUserId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}
