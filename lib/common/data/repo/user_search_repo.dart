import 'package:naijasingles/common/utils/distance.dart' as distance;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:naijasingles/models/user_model.dart';
import 'package:naijasingles/features/match/services/likes_service.dart';

import '../../constants/constants.dart';

class UserSearchRepo {
  static FirebaseFirestore db = firebaseFireStoreInstance;
  static CollectionReference get docRef => db.collection('users');

  static FirebaseAuth firebaseAuth = firebaseAuthInstance;
  static final LikesService _likesService = LikesService();
  
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
        .collection('users/${currentUser.id}/CheckedUser')
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

  static Future<void> leftSwipe(
      UserModel currentUser, UserModel selectedUser) async {
    await docRef
        .doc(currentUser.id)
        .collection("CheckedUser")
        .doc(selectedUser.id)
        .set({
      'DislikedUser': selectedUser.id,
      'timestamp': DateTime.now(),
    }, SetOptions(merge: true));
  }

  static Future<String?> rightSwipe(
      UserModel currentUser, UserModel selectedUser) async {
    try {
      // Use the new likes service for mutual like detection
      final currentUserId = currentUser.id;
      final selectedUserId = selectedUser.id;
      
      String? matchId;
      
      if (currentUserId != null && selectedUserId != null) {
        matchId = await _likesService.handleLike(currentUserId, selectedUserId);
        
        if (matchId != null) {
          debugPrint("🎉 Match created! Match ID: $matchId");
          // Return the match ID so the UI can show the match modal
          return matchId;
        } else {
          debugPrint("Like saved, waiting for mutual like");
        }
      }

      // Keep legacy behavior for backward compatibility
      likedByList = await getLikedByList(currentUser);
      if ((likedByList.contains(selectedUser.id) ||
          (selectedUser.isBot ?? false))) {
        debugPrint("Legacy match creation for backward compatibility");
        await docRef
            .doc(currentUser.id)
            .collection("Matches")
            .doc(selectedUser.id)
            .set({
          'Matches': selectedUser.id,
          'isRead': false,
          'userName': selectedUser.name ?? 'Unknown',
          'pictureUrl': selectedUser.imageUrl?.isNotEmpty == true ? selectedUser.imageUrl![0] : '',
          'timestamp': FieldValue.serverTimestamp()
        }, SetOptions(merge: true));
        await docRef
            .doc(selectedUser.id)
            .collection("Matches")
            .doc(currentUser.id)
            .set({
          'Matches': currentUser.id,
          'userName': currentUser.name ?? 'Unknown',
          'pictureUrl': currentUser.imageUrl?.isNotEmpty == true ? currentUser.imageUrl![0] : '',
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp()
        }, SetOptions(merge: true));
        
        // Return a legacy match indicator
        return 'legacy_match';
      }

      // Update legacy CheckedUser collection
      await docRef
          .doc(currentUser.id)
          .collection("CheckedUser")
          .doc(selectedUser.id)
          .set({
        'LikedUser': selectedUser.id,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Update legacy LikedBy collection
      await docRef
          .doc(selectedUser.id)
          .collection("LikedBy")
          .doc(currentUser.id)
          .set({
        'LikedBy': currentUser.id,
        'timestamp': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));
      
      return null; // No match created
    } catch (e) {
      debugPrint('Error in rightSwipe: $e');
      // Fallback to legacy behavior if new system fails
      await _legacyRightSwipe(currentUser, selectedUser);
      return null;
    }
  }

  /// Legacy right swipe implementation as fallback
  static Future<void> _legacyRightSwipe(
      UserModel currentUser, UserModel selectedUser) async {
    likedByList = await getLikedByList(currentUser);
    if ((likedByList.contains(selectedUser.id) ||
        (selectedUser.isBot ?? false))) {
      debugPrint("coming under searchrepo in if rightswipe");
      await docRef
          .doc(currentUser.id)
          .collection("Matches")
          .doc(selectedUser.id)
          .set({
        'Matches': selectedUser.id,
        'isRead': false,
        'userName': selectedUser.name ?? 'Unknown',
        'pictureUrl': selectedUser.imageUrl?.isNotEmpty == true ? selectedUser.imageUrl![0] : '',
        'timestamp': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));
      await docRef
          .doc(selectedUser.id)
          .collection("Matches")
          .doc(currentUser.id)
          .set({
        'Matches': currentUser.id,
        'userName': currentUser.name ?? 'Unknown',
        'pictureUrl': currentUser.imageUrl?.isNotEmpty == true ? currentUser.imageUrl![0] : '',
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

    try {
      // Debug logging
      debugPrint('Getting user list for: ${currentUser.id}');
      debugPrint('Current user auth: ${firebaseAuth.currentUser?.uid}');
      
      final snapshot = await db
          .collection('users/${currentUser.id}/CheckedUser') // Fixed: using lowercase 'users'
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

      debugPrint('Querying main users collection...');
      final querySnapshot = await query(currentUser).get();
      debugPrint('Query returned ${querySnapshot.docs.length} documents');
      
      if (querySnapshot.docs.isEmpty) {
        debugPrint("no more data");
        return [];
      }

      List<UserModel> userList = [];

      for (var doc in querySnapshot.docs) {
        try {
          debugPrint('Processing document: ${doc.id}');
          UserModel temp = UserModel.fromDocument(doc);
          debugPrint('Created UserModel for: ${temp.name}');
          
          var distance = calculateDistance(currentUser.latitude,
              currentUser.longitude, temp.latitude, temp.longitude);
          temp.distanceBW = distance.round();

          if (checkedUserIds.contains(temp.id)) {
            debugPrint('Skipping already checked user: ${temp.name}');
            continue;
          }

          if (distance <= currentUser.maxDistance! &&
              temp.id != currentUser.id &&
              !temp.isBlocked!) {
            debugPrint("Adding user: ${temp.name}");
            userList.add(temp);
          } else {
            debugPrint('Filtered out user: ${temp.name} (distance: $distance, maxDistance: ${currentUser.maxDistance}, blocked: ${temp.isBlocked})');
          }
        } catch (e) {
          debugPrint('Error processing document ${doc.id}: $e');
          // Continue with next document instead of failing completely
          continue;
        }
      }

      debugPrint('Final user list size: ${userList.length}');
      return userList;
    } catch (e) {
      debugPrint('Error in getUserList: $e');
      rethrow;
    }
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
