import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/user_model.dart';
import '../../constants/constants.dart';
import '../../utils/distance.dart';

class ExploreMap {
  static CollectionReference docRef =
      firebaseFireStoreInstance.collection('users');

  static Future<List<QuerySnapshot>> query(UserModel currentUser) async {
    // for users who has streetview option everyone
    final Query everyoneQuery =
        docRef.where('streetView.option', isEqualTo: 'Everyone');

    // for users who have option others
    final Query userQuery =
        docRef.where('streetView.userIds', arrayContains: currentUser.id);

    final QuerySnapshot everyoneSnapshot = await everyoneQuery.get();
    final QuerySnapshot userSnapshot = await userQuery.get();

    return [everyoneSnapshot, userSnapshot];
  }

// for getting user under specifice radius in map

  static Future<List<UserModel>> getUserListForMap(
      UserModel currentUser,) async {
    final querySnapshots = await query(currentUser);

    // Check if both query snapshots are empty
    if (querySnapshots[0].docs.isEmpty && querySnapshots[1].docs.isEmpty) {
      debugPrint('No data found');
      return [];
    }

    final List<UserModel> userList = [];

    for (var doc in querySnapshots[0].docs) {
      final UserModel temp = UserModel.fromDocument(doc);
      final distance = calculateDistance(
          currentUser.currentCoordinates?['latitude'],
          currentUser.currentCoordinates?['longitude'],
          temp.currentCoordinates?['latitude'],
          temp.currentCoordinates?['longitude'],);
      temp.distanceBW = distance.round();

      if (distance <= 50.0 && temp.id != currentUser.id && !temp.isBlocked!) {
        userList.add(temp);
      }
    }

    for (var doc in querySnapshots[1].docs) {
      final UserModel temp = UserModel.fromDocument(doc);
      final distance = calculateDistance(
          currentUser.currentCoordinates?['latitude'],
          currentUser.currentCoordinates?['longitude'],
          temp.currentCoordinates?['latitude'],
          temp.currentCoordinates?['longitude'],);
      temp.distanceBW = distance.round();

      if (distance <= 50.0 && temp.id != currentUser.id && !temp.isBlocked!) {
        userList.add(temp);
      }
    }

    return userList;
  }
}
