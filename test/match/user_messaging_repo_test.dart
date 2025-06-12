import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/common/constants/constants.dart';
import 'package:naijasingles/common/data/repo/user_messaging_repo.dart';
import 'package:naijasingles/models/user_model.dart';

void main() {
  test('getChatUserDetails returns user data', () async {
    firebaseFireStoreInstance = FakeFirebaseFirestore();
    firebaseAuthInstance = MockFirebaseAuth();
    UserMessagingRepo.db = firebaseFireStoreInstance;
    UserMessagingRepo.firebaseAuth = firebaseAuthInstance;

    await firebaseFireStoreInstance.collection('Users').doc('1').set({
      'userId': '1',
      'UserName': 'Test',
      'isBlocked': false,
      'location': {'address': '', 'latitude': 0, 'longitude': 0},
      'Pictures': []
    });

    final user = await UserMessagingRepo.getChatUserDetails(userId: '1');
    expect(user.id, '1');
  });
}
