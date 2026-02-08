import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/user_model.dart';
import '../../constants/constants.dart';

class PaginationRepo {
  static final db = firebaseFireStoreInstance;

  static void updateNotification(
    UserModel currentUser,
    QueryDocumentSnapshot<Object?> doc,
  ) {
    db
        .collection('users/${currentUser.id}/Matches')
        .doc('${doc.get("Matches")}')
        .update({'isRead': true});
  }

  static Stream<QuerySnapshot> listenForNotifications(
    int perPage,
    CollectionReference notificationReference,
  ) =>
      notificationReference
          .orderBy('timestamp', descending: true)
          .limit(perPage)
          .snapshots();

  static Stream<QuerySnapshot> listenForMessages(
    int perPage,
    CollectionReference chatReference,
  ) =>
      chatReference
          .orderBy('time', descending: true)
          .limit(perPage)
          .snapshots();

  static Future<QuerySnapshot> getMoreNotifications(
    int perPage,
    DocumentSnapshot? lastVisibleDocument,
    CollectionReference notificationReference,
  ) async {
    final QuerySnapshot snapshot = await notificationReference
        .orderBy('timestamp', descending: true)
        .startAfterDocument(lastVisibleDocument!)
        .limit(perPage)
        .get();

    return snapshot;
  }

  static Future<QuerySnapshot> getMoreMessages(
    int perPage,
    DocumentSnapshot? lastVisibleDocument,
    CollectionReference chatReference,
  ) async {
    final QuerySnapshot snapshot = await chatReference
        .orderBy('time', descending: true)
        .startAfterDocument(lastVisibleDocument!)
        .limit(perPage)
        .get();

    return snapshot;
  }

  static Future<QuerySnapshot> getMoreChats(
    int perPage,
    DocumentSnapshot? lastVisibleDocument,
    UserModel currentUser,
  ) async {
    final QuerySnapshot snapshot = await db
        .collection('chats')
        .where('users', arrayContains: currentUser.id)
        .where(
          'unmatched',
          isEqualTo: false,
        )
        .orderBy('time', descending: true)
        .startAfterDocument(lastVisibleDocument!)
        .limit(perPage)
        .get();

    return snapshot;
  }
}
