import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/user_model.dart';
import '../../constants/constants.dart';

class PaginationRepo {
  static final db = firebaseFireStoreInstance;

  static updateNotification(
      UserModel currentUser, QueryDocumentSnapshot<Object?> doc) {
    db
        .collection("/Users/${currentUser.id}/Matches")
        .doc('${doc.get("Matches")}')
        .update({'isRead': true});
  }

  static Stream<QuerySnapshot> listenForNotifications(
      int perPage, CollectionReference notificationReference) {
    return notificationReference
        .orderBy('timestamp', descending: true)
        .limit(perPage)
        .snapshots();
  }

  static Stream<QuerySnapshot> listenForMessages(
      int perPage, CollectionReference chatReference) {
    return chatReference
        .orderBy('time', descending: true)
        .limit(perPage)
        .snapshots();
  }

  static Future<QuerySnapshot> getMoreNotifications(
      int perPage,
      DocumentSnapshot? lastVisibleDocument,
      CollectionReference notificationReference) async {
    QuerySnapshot snapshot = await notificationReference
        .orderBy('timestamp', descending: true)
        .startAfterDocument(lastVisibleDocument!)
        .limit(perPage)
        .get();

    return snapshot;
  }

  static Future<QuerySnapshot> getMoreMessages(
      int perPage,
      DocumentSnapshot? lastVisibleDocument,
      CollectionReference chatReference) async {
    QuerySnapshot snapshot = await chatReference
        .orderBy('time', descending: true)
        .startAfterDocument(lastVisibleDocument!)
        .limit(perPage)
        .get();

    return snapshot;
  }

  static Future<QuerySnapshot> getMoreChats(int perPage,
      DocumentSnapshot? lastVisibleDocument, UserModel currentUser) async {
    QuerySnapshot snapshot = await db
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
