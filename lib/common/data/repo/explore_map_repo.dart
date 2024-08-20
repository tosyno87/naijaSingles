import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/user_model.dart';
import '../../constants/constants.dart';

class ExploreMap {
  static CollectionReference docRef =
      firebaseFireStoreInstance.collection('Users');

  static Future<List<QuerySnapshot>> query(UserModel currentUser) async {
    // for users who has streetview option everyone
    Query everyoneQuery =
        docRef.where('streetView.option', isEqualTo: 'Everyone');

    // for users who have option others
    Query userQuery =
        docRef.where('streetView.userIds', arrayContains: currentUser.id);

    QuerySnapshot everyoneSnapshot = await everyoneQuery.get();
    QuerySnapshot userSnapshot = await userQuery.get();

    return [everyoneSnapshot, userSnapshot];
  }

// for getting user under specifice radius in map

  static Future<List<UserModel>> getUserListForMap(
      UserModel currentUser) async {
    final querySnapshots = await query(currentUser);

    // Check if both query snapshots are empty
    if (querySnapshots[0].docs.isEmpty && querySnapshots[1].docs.isEmpty) {
      debugPrint("No data found");
      return [];
    }

    List<UserModel> userList = [];

    for (var doc in querySnapshots[0].docs) {
      UserModel temp = UserModel.fromDocument(doc);
      var distance = calculateDistance(
          currentUser.currentCoordinates?['latitude'],
          currentUser.currentCoordinates?['longitude'],
          temp.currentCoordinates?['latitude'],
          temp.currentCoordinates?['longitude']);
      temp.distanceBW = distance.round();

      if (distance <= 50.0 && temp.id != currentUser.id && !temp.isBlocked!) {
        userList.add(temp);
      }
    }

    for (var doc in querySnapshots[1].docs) {
      UserModel temp = UserModel.fromDocument(doc);
      var distance = calculateDistance(
          currentUser.currentCoordinates?['latitude'],
          currentUser.currentCoordinates?['longitude'],
          temp.currentCoordinates?['latitude'],
          temp.currentCoordinates?['longitude']);
      temp.distanceBW = distance.round();

      if (distance <= 50.0 && temp.id != currentUser.id && !temp.isBlocked!) {
        userList.add(temp);
      }
    }

    return userList;
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
