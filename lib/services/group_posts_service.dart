import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Group feed posts under `groups/{groupId}/posts`.
class GroupPost {
  GroupPost({
    required this.id,
    required this.authorId,
    required this.text,
    required this.createdAt,
    this.imageUrl,
  });

  factory GroupPost.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return GroupPost(
      id: doc.id,
      authorId: data['authorId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  final String id;
  final String authorId;
  final String text;
  final String? imageUrl;
  final DateTime createdAt;
}

class GroupPostsService {
  GroupPostsService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _posts(String groupId) =>
      _firestore.collection('groups').doc(groupId).collection('posts');

  Stream<List<GroupPost>> watchPosts(String groupId) => _posts(groupId)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map(
        (snap) => snap.docs.map(GroupPost.fromDoc).toList(),
      );

  Future<void> createPost({
    required String groupId,
    required String text,
    String? imageUrl,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in');
    await _posts(groupId).add({
      'authorId': uid,
      'text': text.trim(),
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
