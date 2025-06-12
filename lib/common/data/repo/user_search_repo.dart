import 'package:naijasingles/common/utils/distance.dart' as distance;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:naijasingles/models/user_model.dart';

import '../../constants/constants.dart';

class UserSearchRepo {
  static FirebaseFirestore db = firebaseFireStoreInstance;
  static CollectionReference get docRef => db.collection('Users');

  static FirebaseAuth firebaseAuth = firebaseAuthInstance;
  static Map items = {};
  static List<UserModel> matches = [];
  static List<UserModel> newmatches = [];
  static List<String> likedByList = [];
  static List userRemoved = [];
  static int swipecount = 0;
  static List<UserModel> users = [];
  static Map likedMap = {};
  static Map disLikedMap = {};
  static getAccessItems() async {
    db
        .collection("Item_access")
        .snapshots()
        .listen((doc) {
      if (doc.docs.isNotEmpty) {
        items = doc.docs[0].data();
        // log(doc.docs[0].data().toString());
      }
    });
  }

  static Future<int> getSwipedCount(UserModel currentUser) async {
    final querySnapshot = await db
        .collection('/Users/${currentUser.id}/CheckedUser')
        .where(
          'timestamp',
          isGreaterThan:
              Timestamp.now().toDate().subtract(const Duration(days: 1)),
        )
        .get();

    final swipedCount = querySnapshot.docs.length;
    // log("from frpo count ${swipedCount.toString()}");

    return swipedCount;
  }

  static leftSwipe(UserModel currentUser, UserModel selectedUser) async {
    await docRef
        .doc(currentUser.id)
        .collection("CheckedUser")
        .doc(selectedUser.id)
        .set({
      'DislikedUser': selectedUser.id,
      'timestamp': DateTime.now(),
    }, SetOptions(merge: true));
  }

  static rightSwipe(UserModel currentUser, UserModel selectedUser) async {
    likedByList = await getLikedByList(currentUser);
    if ((likedByList.contains(selectedUser.id) ||
        (selectedUser.isBot ?? false))) {
      debugPrint("coming umder searchrepo in if rightswipe");
      await docRef
          .doc(currentUser.id)
          .collection("Matches")
          .doc(selectedUser.id)
          .set({
        'Matches': selectedUser.id,
        'isRead': false,
        'userName': selectedUser.name,
        'pictureUrl': selectedUser.imageUrl![0],
        'timestamp': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));
      await docRef
          .doc(selectedUser.id)
          .collection("Matches")
          .doc(currentUser.id)
          .set({
        'Matches': currentUser.id,
        'userName': currentUser.name,
        'pictureUrl': currentUser.imageUrl![0],
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));
    }

    await docRef
        .doc(currentUser.id)
        .collection("CheckedUser")
        .doc(selectedUser.id)
        .set({
      'LikedUser': selectedUser.id,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await docRef
        .doc(selectedUser.id)
        .collection("LikedBy")
        .doc(currentUser.id)
        .set({
      'LikedBy': currentUser.id,
      'timestamp': FieldValue.serverTimestamp()
    }, SetOptions(merge: true));
  }

  static Query query(UserModel currentUser) {
    if (currentUser.showGender == 'everyone') {
      return docRef
          .where(
            'age',
            isGreaterThanOrEqualTo: int.parse(currentUser.ageRange!['min']),
          )
          .where('age',
              isLessThanOrEqualTo: int.parse(currentUser.ageRange!['max']))
          .orderBy('age', descending: false);
    } else {
      return docRef
          .where('editInfo.userGender', isEqualTo: currentUser.showGender)
          .where(
            'age',
            isGreaterThanOrEqualTo: int.parse(currentUser.ageRange!['min']),
          )
          .where('age',
              isLessThanOrEqualTo: int.parse(currentUser.ageRange!['max']))
          //FOR FETCH USER WHO MATCH WITH USER SEXUAL ORIENTAION
          // .where('sexualOrientation.orientation',
          //     arrayContainsAny: currentUser.sexualOrientation)
          .orderBy('age', descending: false);
    }
  }

  static Future<List<UserModel>> getUserList(
    UserModel currentUser,
  ) async {
    List<String> checkedUserIds = [];

    final snapshot = await db
        .collection('/Users/${currentUser.id}/CheckedUser')
        .get();
    if (snapshot.docs.isNotEmpty) {
      for (final doc in snapshot.docs) {
        final likedUser = doc.data()['LikedUser'];
        final dislikedUser = doc.data()['DislikedUser'];

        if (likedUser != null) {
          checkedUserIds.add(likedUser);
        }
        if (dislikedUser != null) {
          checkedUserIds.add(dislikedUser);
        }
      }
    }

    final querySnapshot = await query(currentUser).get();
    if (querySnapshot.docs.isEmpty) {
      debugPrint("no more data");
      return [];
    }

    List<UserModel> userList = [];

    for (var doc in querySnapshot.docs) {
      // log(doc.data().toString());
      UserModel temp = UserModel.fromDocument(doc);
      // log("searchrepotemp ${temp.toString()}");
      var distance = calculateDistance(currentUser.latitude,
          currentUser.longitude, temp.latitude, temp.longitude);
      temp.distanceBW = distance.round();
      // log("tempid$distance");

      if (checkedUserIds.contains(temp.id)) {
        continue;
      }

      if (distance <= currentUser.maxDistance! &&
          temp.id != currentUser.id &&
          !temp.isBlocked!) {
        debugPrint("value coming}");
        userList.add(temp);
        // log("searchrepouser ${userList.toString()}");
      }
    }

    return userList;
  }

  static Future<List<String>> getLikedByList(UserModel currentUser) async {
    final snapshot = await docRef
        .doc(currentUser.id)
        .collection("LikedBy")
        .get();

    return snapshot.docs
        .map((f) => f['LikedBy'] as String)
        .toList();
  }

  static double calculateDistance(lat1, lon1, lat2, lon2) {
    return distance.calculateDistance(lat1, lon1, lat2, lon2);
  }
}
