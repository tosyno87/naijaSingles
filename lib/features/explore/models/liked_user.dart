import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../common/utils/firestore_helpers.dart';

class LikedUser {
  LikedUser({
    required this.currentUserId,
    required this.likedUserId,
    required this.timestamp,
  });

  // Create from Firestore document
  factory LikedUser.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LikedUser(
      currentUserId: data['currentUserId'] ?? '',
      likedUserId: data['likedUserId'] ?? '',
      timestamp: parseDateTime(data['timestamp']),
    );
  }
  final String currentUserId;
  final String likedUserId;
  final DateTime timestamp;

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() => {
        'currentUserId': currentUserId,
        'likedUserId': likedUserId,
        'timestamp': timestamp,
      };
}
