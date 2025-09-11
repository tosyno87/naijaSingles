import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  String senderName, senderId, selectedUserId, text, photoUrl;
  File photo;
  Timestamp timestamp;

  Message({
    required this.senderName,
    required this.senderId,
    required this.selectedUserId,
    required this.text,
    required this.photoUrl,
    required this.photo,
    required this.timestamp,
  });
}
