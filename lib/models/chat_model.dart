import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  String senderId;
  String receiverId;
  String? text;
  String type;
  bool isRead;
  Timestamp? timestamp;
  ChatModel(
      {required this.senderId,
      required this.receiverId,
      required this.text,
      required this.type,
      required this.isRead,
      required this.timestamp});
  factory ChatModel.from(doc) {
    return ChatModel(
      senderId: doc['sender_id'],
      receiverId: doc['receiver_id'],
      type: doc['type'],
      text: doc['text'],
      isRead: doc['isRead'],
      timestamp: doc['time'],
    );
  }
}
