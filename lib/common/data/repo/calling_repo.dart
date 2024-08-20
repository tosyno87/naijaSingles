import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../features/calling/ui/dial_page.dart';
import '../../../models/user_model.dart';
import '../../constants/constants.dart';
import '../../widets/custom_snackbar.dart';

class CallingRepo {
  static final db = firebaseFireStoreInstance;
  static CollectionReference callRef = db.collection("calls");

  static addCallingData(channelName, callType) async {
    await callRef.doc(channelName).delete().then((_) async {
      await callRef.doc(channelName).set({
        'callType': callType,
        'calling': true,
        'response': "Awaiting",
        'channel_id': channelName,
        'last_call': FieldValue.serverTimestamp()
      });
    });
  }

  static Future<void> onJoin(callType, bool isBlocked, String chatId, senderId,
      BuildContext context, UserModel second) async {
    String receiverId = second.id!;
    if (!isBlocked) {
      await db.collection("chats").doc(chatId).collection('messages').add({
        'type': 'Call',
        'text': callType,
        'sender_id': senderId,
        'receiver_id': second.id,
        'isRead': false,
        'image_url': "",
        'time': FieldValue.serverTimestamp(),
        'users': [second.id, senderId],
        'unmatched': false
      }).then((value) {
        db.collection('chats').doc(chatId).set({
          'text': callType,
          'isRead': false,
          'sender_id': senderId,
          'receiver_id': second.id,
          'type': 'Call',
          'users': [second.id, senderId],
          'unmatched': false,
          'time': FieldValue.serverTimestamp()
        }, SetOptions(merge: true));
      });

      db
          .collection("chats")
          .doc(chatId)
          .collection('messages')
          .doc("blocked")
          .get()
          .then((blockedDocSnapshot) {
        if (!blockedDocSnapshot.exists) {
          // Add the "blocked" document to chatReference collection
          db
              .collection("chats")
              .doc(chatId)
              .collection('messages')
              .doc("blocked")
              .set({
            'isBlocked': false,
            'blockedBy': '',
          });
        }
      }).catchError((error) {
        debugPrint("Error checking if blocked document exists: $error");
      });

      if (context.mounted) {
        try {
          debugPrint('--------startcall----- $callType');

          final HttpsCallable callable = FirebaseFunctions.instance
              .httpsCallable('sendOnlyCallNotification');
          await callable.call({
            "senderId": senderId,
            "recieverId": receiverId,
            "chatId": chatId,
            "callType": callType
          }).then((value) async {
            debugPrint('----sucsessfully called');
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DialCall(
                    channelName: chatId, receiver: second, callType: callType),
              ),
            );
          });
        } catch (e) {
          debugPrint('-----------$e');
        }
      }
    } else {
      CustomSnackbar.showSnackBarSimple("Blocked!".tr().toString(), context);
    }
  }
}
