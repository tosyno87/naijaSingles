import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../features/match/ui/widget/matches_card.dart';
import '../../../models/block_user_model.dart';
import '../../../models/user_model.dart';
import '../../constants/constants.dart';
import '../../utils/distance.dart';

class UserMessagingRepo {
  static FirebaseFirestore db = firebaseFireStoreInstance;
  static CollectionReference get docRef => db.collection('users');

  static FirebaseAuth firebaseAuth = firebaseAuthInstance;

  static Future<List<UserModel>> getMatches(UserModel currentUser) async {
    final User user = firebaseAuth.currentUser!;
    final QuerySnapshot querySnapshot = await db
        .collection('users/${user.uid}/Matches')
        .orderBy('timestamp', descending: true)
        .get();
    final List<UserModel> matches = [];
    if (querySnapshot.docs.isNotEmpty) {
      for (DocumentSnapshot documentSnapshot in querySnapshot.docs) {
        final DocumentSnapshot doc =
            await docRef.doc(documentSnapshot['Matches']).get();
        if (doc.exists) {
          final UserModel tempuser = UserModel.fromDocument(doc);
          if (currentUser.latitude != null &&
              currentUser.longitude != null &&
              tempuser.latitude != null &&
              tempuser.longitude != null) {
            tempuser.distanceBW = calculateDistance(
              currentUser.latitude!,
              currentUser.longitude!,
              tempuser.latitude!,
              tempuser.longitude!,
            ).round();
          }
          matches.add(tempuser);
          // matches.sort((a, b) => b.lastmsg!.compareTo(
          //     a.lastmsg!)); // Sort by lastmessage in descending order
        }
      }
    }
    return matches;
  }

  static Future<List<BlockUserModel>> getBlockUserList(
    UserModel currentUser,
    int perPage,
  ) async {
    final User user = firebaseAuth.currentUser!;
    final QuerySnapshot querySnapshot = await db
        .collection('users')
        .doc(user.uid)
        .collection('blockedlist')
        .orderBy('timestamp', descending: true)
        .limit(perPage)
        .get();

    final List<BlockUserModel> blockedUsers = [];

    if (querySnapshot.docs.isNotEmpty) {
      for (DocumentSnapshot documentSnapshot in querySnapshot.docs) {
        final DocumentSnapshot userDoc =
            await docRef.doc(documentSnapshot['blockedID']).get();
        if (userDoc.exists) {
          final UserModel user = UserModel.fromDocument(userDoc);
          final DateTime blockedTimestamp =
              documentSnapshot['timestamp'].toDate();
          final BlockUserModel blockedUser = BlockUserModel(
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
    UserModel currentUser,
    int perPage, {
    BlockUserModel? lastDocumentData,
  }) async {
    final User user = firebaseAuth.currentUser!;
    Query query = db
        .collection('users')
        .doc(user.uid)
        .collection('blockedlist')
        .orderBy('timestamp', descending: true)
        .limit(perPage);

    if (lastDocumentData != null) {
      query = query.startAfter([lastDocumentData.blockedTimestamp]);
    }

    final QuerySnapshot querySnapshot = await query.get();

    final List<BlockUserModel> blockList = [];

    if (querySnapshot.docs.isNotEmpty) {
      for (DocumentSnapshot documentSnapshot in querySnapshot.docs) {
        final DocumentSnapshot userDoc =
            await docRef.doc(documentSnapshot['blockedID']).get();
        if (userDoc.exists) {
          final UserModel user = UserModel.fromDocument(userDoc);
          final DateTime blockedTimestamp =
              documentSnapshot['timestamp'].toDate();
          final BlockUserModel blockedUser = BlockUserModel(
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

    final result = await db.collection('users').doc(userId).get();

    if (result.exists) {
      user = UserModel.fromDocument(result);
      return user;
    }

    // log("user ${user.toString()}");

    return user!;
  }

  static void addTexttoDb(
    CollectionReference chatReference,
    String text,
    String chatId,
    String senderId,
    secondId,
  ) {
    chatReference.add({
      'type': 'Msg',
      'text': text,
      'sender_id': senderId,
      'receiver_id': secondId,
      'isRead': false,
      'image_url': '',
      'time': FieldValue.serverTimestamp(),
      'users': [senderId, secondId],
      'unmatched': false,
    }).then((documentReference) {
      db.collection('chats').doc(chatId).set(
        {
          'text': text,
          'isRead': false,
          'sender_id': senderId,
          'receiver_id': secondId,
          'type': 'Msg',
          'time': FieldValue.serverTimestamp(),
          'users': [secondId, senderId],
          'unmatched': false,
        },
        SetOptions(merge: true),
      );
    });
    // Check if the "blocked" document exists in chatReference collection
    chatReference.doc('blocked').get().then((blockedDocSnapshot) {
      if (!blockedDocSnapshot.exists) {
        // Add the "blocked" document to chatReference collection
        chatReference.doc('blocked').set({
          'isBlocked': false,
          'blockedBy': '',
        });
      }
    }).catchError((error) {
      debugPrint('Error checking if blocked document exists: $error');
    });
  }

  static void sendImage(
    String? messageText,
    String? imageUrl,
    CollectionReference chatReference,
    String chatId,
    String? senderId,
    secondId,
  ) {
    chatReference.add({
      'type': 'Image',
      'text': messageText,
      'sender_id': senderId,
      'receiver_id': secondId,
      'isRead': false,
      'image_url': imageUrl,
      'time': FieldValue.serverTimestamp(),
      'users': [secondId, senderId],
      'unmatched': false,
    }).then((value) {
      db.collection('chats').doc(chatId).set(
        {
          'text': messageText,
          'isRead': false,
          'sender_id': senderId,
          'receiver_id': secondId,
          'type': 'Image',
          'time': FieldValue.serverTimestamp(),
          'users': [secondId, senderId],
          'unmatched': false,
        },
        SetOptions(merge: true),
      );
    });
    // Check if the "blocked" document exists in chatReference collection
    chatReference.doc('blocked').get().then((blockedDocSnapshot) {
      if (!blockedDocSnapshot.exists) {
        // Add the "blocked" document to chatReference collection
        chatReference.doc('blocked').set({
          'isBlocked': false,
          'blockedBy': '',
        });
      }
    }).catchError((error) {
      debugPrint('Error checking if blocked document exists: $error');
    });
  }
}
