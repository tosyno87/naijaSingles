import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../common/constants/constants.dart';

class DiaryEntry {
  final String id;
  final String userId;
  final String content;
  final Timestamp timestamp;
  final String userName;
  final String? userImage;

  DiaryEntry({
    required this.id,
    required this.userId,
    required this.content,
    required this.timestamp,
    required this.userName,
    required this.userImage,
  });

  factory DiaryEntry.fromDocument(DocumentSnapshot doc) {
    return DiaryEntry(
      id: doc.id,
      userId: doc['userId'] as String,
      content: doc['content'] as String,
      timestamp: doc['timestamp'] as Timestamp,
      userName: doc['userName'] as String? ?? '',
      userImage: doc['userImage'] as String?,
    );
  }
}

class DiaryRepository {
  final CollectionReference diaryRef =
      firebaseFireStoreInstance.collection('diaryEntries');

  Future<void> addEntry({
    required String userId,
    required String content,
    required String userName,
    required String? userImage,
  }) async {
    await diaryRef.add({
      'userId': userId,
      'content': content,
      'userName': userName,
      'userImage': userImage,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<DiaryEntry>> entriesStream() {
    return diaryRef.orderBy('timestamp', descending: true).snapshots().map(
        (snapshot) => snapshot.docs
            .where((doc) => doc.data() != null)
            .map((doc) => DiaryEntry.fromDocument(doc))
            .toList());
  }
}
