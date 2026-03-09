import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/user_model.dart';
import '../../constants/constants.dart';

class UserRepo {
  static final userId = firebaseAuthInstance.currentUser!.uid;

  static Future<void> updateData(Map editInfo) async {
    // log('editinfo-----------$editInfo');
    try {
      await firebaseFireStoreInstance
          .collection('users')
          .doc(userId)
          .set({'editInfo': editInfo}, SetOptions(merge: true));
      log('User data updated successfully');
    } on Object catch (e) {
      log('Failed to update user data: $e');
      rethrow;
    }
  }

  static Future updatefilter(Map<String, dynamic> changeValues) async {
    log('filterinfo-----------$changeValues');
    try {
      await firebaseFireStoreInstance
          .collection('users')
          .doc(userId)
          .set(changeValues, SetOptions(merge: true));
      log('User filter updated successfully');
    } on Object catch (e) {
      log('Failed to update user filter: $e');
      rethrow;
    }
  }

// For unmatch user after match
  static Future unmatchUser(UserModel currentUser, String userId) async {
    final collectionRefrence = firebaseFireStoreInstance.collection('users');
    final chatCollection = firebaseFireStoreInstance.collection('chats');
    await collectionRefrence
        .doc(currentUser.id)
        .collection('CheckedUser')
        .doc(userId)
        .delete();
    await collectionRefrence
        .doc(userId)
        .collection('CheckedUser')
        .doc(currentUser.id)
        .delete();
    await collectionRefrence
        .doc(currentUser.id)
        .collection('LikedBy')
        .doc(userId)
        .delete();
    await collectionRefrence
        .doc(userId)
        .collection('LikedBy')
        .doc(currentUser.id)
        .delete();
    await collectionRefrence
        .doc(currentUser.id)
        .collection('Matches')
        .doc(userId)
        .delete();
    await collectionRefrence
        .doc(userId)
        .collection('Matches')
        .doc(currentUser.id)
        .delete();
    await chatCollection.doc(chatId1(currentUser, userId)).delete();
  }

  static String chatId1(UserModel currentUser, String userId) {
    final currentId = currentUser.id ?? '';
    if (currentId.compareTo(userId) <= 0) {
      return '$currentId-$userId';
    } else {
      return '$userId-$currentId';
    }
  }

  // for storing street view data

  static Future streetviewfilter(String option, List<String> userIds) async {
    log('filterinfo-----------$userIds');
    try {
      // Create a reference to the user's document in Firestore.
      final DocumentReference userDocRef =
          firebaseFireStoreInstance.collection('users').doc(userId);
      await userDocRef.update({
        'streetView': {
          'option': option,
          'userIds': userIds,
        },
      });
      log('street  filter updated successfully');
    } on Object catch (e) {
      log('Failed to update user filter: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getStreetViewData(String userId) async {
    try {
      final User? user = firebaseAuthInstance.currentUser;
      if (user != null) {
        final DocumentSnapshot userSnapshot = await firebaseFireStoreInstance
            .collection('users')
            .doc(userId)
            .get();
        final Map<String, dynamic>? userData =
            userSnapshot.data() as Map<String, dynamic>?;

        if (userData != null && userData.containsKey('streetView')) {
          final Map<String, dynamic> streetViewMap = userData['streetView'];

          return {
            'option': streetViewMap['option'] ?? 'None',
            'userIds': streetViewMap['userIds'] ?? [],
          };
        } else {
          return {
            'option': 'None',
            'userIds': [],
          };
        }
      }
    } on Object catch (error) {
      log('Error fetching data: $error');
    }

    return {
      'option': 'None',
      'userIds': [],
    };
  }
}
