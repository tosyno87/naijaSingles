import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hookup4u2/features/match/ui/widget/matches_card.dart';

import '../../../models/block_user_model.dart';
import '../../../models/user_model.dart';
import '../../constants/constants.dart';

class UserMessagingRepo {
  static final db = firebaseFireStoreInstance;
  static CollectionReference docRef = db.collection('Users');

  static FirebaseAuth firebaseAuth = firebaseAuthInstance;

  static Future<List<UserModel>> getMatches(UserModel currentUser) async {
    User user = firebaseAuth.currentUser!;
    QuerySnapshot querySnapshot = await db
        .collection('/Users/${user.uid}/Matches')
        .orderBy('timestamp', descending: true)
        .get();
    List<UserModel> matches = [];
    if (querySnapshot.docs.isNotEmpty) {
      for (DocumentSnapshot documentSnapshot in querySnapshot.docs) {
        DocumentSnapshot doc =
            await docRef.doc(documentSnapshot['Matches']).get();
        if (doc.exists) {
          UserModel tempuser = UserModel.fromDocument(doc);
          tempuser.distanceBW = calculateDistance(currentUser.latitude,
                  currentUser.longitude, tempuser.latitude, tempuser.longitude)
              .round();
          matches.add(tempuser);
          // matches.sort((a, b) => b.lastmsg!.compareTo(
          //     a.lastmsg!)); // Sort by lastmessage in descending order
        }
      }
    }
    return matches;
  }

  static Future<List<BlockUserModel>> getBlockUserList(
      UserModel currentUser, int perPage) async {
    User user = firebaseAuth.currentUser!;
    QuerySnapshot querySnapshot = await db
        .collection('Users')
        .doc(user.uid)
        .collection('blockedlist')
        .orderBy('timestamp', descending: true)
        .limit(perPage)
        .get();

    List<BlockUserModel> blockedUsers = [];

    if (querySnapshot.docs.isNotEmpty) {
      for (DocumentSnapshot documentSnapshot in querySnapshot.docs) {
        DocumentSnapshot userDoc =
            await docRef.doc(documentSnapshot['blockedID']).get();
        if (userDoc.exists) {
          UserModel user = UserModel.fromDocument(userDoc);
          DateTime blockedTimestamp = documentSnapshot['timestamp'].toDate();
          BlockUserModel blockedUser = BlockUserModel(
            name: user.name!,
            imageUrl: user.imageUrl!.first,
            id: user.id!,
            chatID: chatId(currentUser, user),
            blockedTimestamp: blockedTimestamp,
          );
          blockedUsers.add(blockedUser);
        }
      }
    }

    return blockedUsers;
  }

  static Future<List<BlockUserModel>> loadMoreBlockUsers(
      UserModel currentUser, int perPage,
      {BlockUserModel? lastDocumentData}) async {
    User user = firebaseAuth.currentUser!;
    Query query = db
        .collection('Users')
        .doc(user.uid)
        .collection('blockedlist')
        .orderBy('timestamp', descending: true)
        .limit(perPage);

    if (lastDocumentData != null) {
      query = query.startAfter([lastDocumentData.blockedTimestamp]);
    }

    QuerySnapshot querySnapshot = await query.get();

    List<BlockUserModel> blockList = [];

    if (querySnapshot.docs.isNotEmpty) {
      for (DocumentSnapshot documentSnapshot in querySnapshot.docs) {
        DocumentSnapshot userDoc =
            await docRef.doc(documentSnapshot['blockedID']).get();
        if (userDoc.exists) {
          UserModel user = UserModel.fromDocument(userDoc);
          DateTime blockedTimestamp = documentSnapshot['timestamp'].toDate();
          BlockUserModel blockedUser = BlockUserModel(
            name: user.name!,
            imageUrl: user.imageUrl!.first,
            id: user.id!,
            chatID: chatId(currentUser, user),
            blockedTimestamp: blockedTimestamp,
          );
          blockList.add(blockedUser);
        }
      }
    }

    return blockList;
  }

  static Stream<QuerySnapshot> query(UserModel currentUser, int perPage) {
    return db
        .collection('chats')
        .where('users', arrayContains: currentUser.id)
        .where(
          'unmatched',
          isEqualTo: false,
        )
        .orderBy('time', descending: true)
        .limit(perPage)
        .snapshots();
    //??'lastMessage.time',
  }

  static Future<UserModel> getChatUserDetails({required String userId}) async {
    UserModel? user;

    var result = await db.collection('Users').doc(userId).get();

    if (result.exists) {
      user = UserModel.fromDocument(result);
      return user;
    }

    // log("user ${user.toString()}");

    return user!;
  }

  static addTexttoDb(CollectionReference chatReference, String text,
      String chatId, String senderId, secondId) {
    chatReference.add({
      'type': 'Msg',
      'text': text,
      'sender_id': senderId,
      'receiver_id': secondId,
      'isRead': false,
      'image_url': '',
      'time': FieldValue.serverTimestamp(),
      'users': [senderId, secondId],
      'unmatched': false
    }).then((documentReference) {
      db.collection('chats').doc(chatId).set({
        'text': text,
        'isRead': false,
        'sender_id': senderId,
        'receiver_id': secondId,
        'type': 'Msg',
        'time': FieldValue.serverTimestamp(),
        'users': [secondId, senderId],
        'unmatched': false
      }, SetOptions(merge: true));
    });
    // Check if the "blocked" document exists in chatReference collection
    chatReference.doc("blocked").get().then((blockedDocSnapshot) {
      if (!blockedDocSnapshot.exists) {
        // Add the "blocked" document to chatReference collection
        chatReference.doc("blocked").set({
          'isBlocked': false,
          'blockedBy': '',
        });
      }
    }).catchError((error) {
      debugPrint("Error checking if blocked document exists: $error");
    });
  }

  static void sendImage(
      String? messageText,
      String? imageUrl,
      CollectionReference chatReference,
      String chatId,
      String? senderId,
      secondId) {
    chatReference.add({
      'type': 'Image',
      'text': messageText,
      'sender_id': senderId,
      'receiver_id': secondId,
      'isRead': false,
      'image_url': imageUrl,
      'time': FieldValue.serverTimestamp(),
      'users': [secondId, senderId],
      'unmatched': false
    }).then((value) {
      db.collection('chats').doc(chatId).set({
        'text': messageText,
        'isRead': false,
        'sender_id': senderId,
        'receiver_id': secondId,
        'type': 'Image',
        'time': FieldValue.serverTimestamp(),
        'users': [secondId, senderId],
        'unmatched': false
      }, SetOptions(merge: true));
    });
    // Check if the "blocked" document exists in chatReference collection
    chatReference.doc("blocked").get().then((blockedDocSnapshot) {
      if (!blockedDocSnapshot.exists) {
        // Add the "blocked" document to chatReference collection
        chatReference.doc("blocked").set({
          'isBlocked': false,
          'blockedBy': '',
        });
      }
    }).catchError((error) {
      debugPrint("Error checking if blocked document exists: $error");
    });
  }

  static double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
}
