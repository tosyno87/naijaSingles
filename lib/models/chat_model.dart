import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  ChatModel({
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.type,
    required this.isRead,
    required this.timestamp,
  });
  factory ChatModel.from(doc) => ChatModel(
        senderId: doc['sender_id'],
        receiverId: doc['receiver_id'],
        type: doc['type'],
        text: doc['text'],
        isRead: doc['isRead'],
        timestamp: doc['time'],
      );
  String senderId;
  String receiverId;
  String? text;
  String type;
  bool isRead;
  Timestamp? timestamp;
}
