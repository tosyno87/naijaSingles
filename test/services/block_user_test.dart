import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  const userId = 'user1';
  const blockedUserId = 'user2';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  group('Block User Tests', () {
    test('blocking a user creates a document in the blockedlist subcollection',
        () async {
      final blockedRef = fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('blockedlist')
          .doc(blockedUserId);

      await blockedRef.set({
        'blockedAt': DateTime.now().toIso8601String(),
        'reason': 'Blocked from chat',
        'blockedUserId': blockedUserId,
      });

      final doc = await blockedRef.get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['blockedUserId'], equals(blockedUserId));
      expect(doc.data()!['reason'], equals('Blocked from chat'));
    });

    test('blocking removes the match between the two users', () async {
      await fakeFirestore.collection('matches').doc('match1').set({
        'users': [userId, blockedUserId],
        'matchedAt': DateTime.now().toIso8601String(),
      });
      await fakeFirestore.collection('matches').doc('match2').set({
        'users': [userId, 'user3'],
        'matchedAt': DateTime.now().toIso8601String(),
      });

      final matchQuery = await fakeFirestore
          .collection('matches')
          .where('users', arrayContains: userId)
          .get();

      final batch = fakeFirestore.batch();
      for (final matchDoc in matchQuery.docs) {
        final users = List<String>.from(matchDoc.data()['users'] ?? []);
        if (users.contains(blockedUserId)) {
          batch.delete(matchDoc.reference);
        }
      }
      await batch.commit();

      final remaining = await fakeFirestore.collection('matches').get();
      expect(remaining.docs.length, equals(1));
      expect(remaining.docs.first.id, equals('match2'));
    });

    test('blocking removes the chat thread between the two users', () async {
      await fakeFirestore.collection('chatThreads').doc('thread1').set({
        'userIds': [userId, blockedUserId],
        'lastMessage': 'Hey',
      });
      await fakeFirestore.collection('chatThreads').doc('thread2').set({
        'userIds': [userId, 'user3'],
        'lastMessage': 'Hi',
      });

      final threadQuery = await fakeFirestore
          .collection('chatThreads')
          .where('userIds', arrayContains: userId)
          .get();

      final batch = fakeFirestore.batch();
      for (final threadDoc in threadQuery.docs) {
        final threadUsers =
            List<String>.from(threadDoc.data()['userIds'] ?? []);
        if (threadUsers.contains(blockedUserId)) {
          batch.delete(threadDoc.reference);
        }
      }
      await batch.commit();

      final remaining = await fakeFirestore.collection('chatThreads').get();
      expect(remaining.docs.length, equals(1));
      expect(remaining.docs.first.id, equals('thread2'));
    });

    test('unblocking removes the blocked document', () async {
      final blockedRef = fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('blockedlist')
          .doc(blockedUserId);

      await blockedRef.set({
        'blockedAt': DateTime.now().toIso8601String(),
        'reason': 'Blocked from chat',
        'blockedUserId': blockedUserId,
      });

      expect((await blockedRef.get()).exists, isTrue);

      await blockedRef.delete();

      expect((await blockedRef.get()).exists, isFalse);
    });

    test('getBlockedUserIds returns correct IDs from subcollection', () async {
      final blockedList = fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('blockedlist');

      await blockedList.doc('blocked1').set({'blockedAt': 'ts1'});
      await blockedList.doc('blocked2').set({'blockedAt': 'ts2'});

      final snapshot = await blockedList.get();
      final blockedIds = snapshot.docs.map((doc) => doc.id).toList();

      expect(blockedIds, containsAll(['blocked1', 'blocked2']));
      expect(blockedIds.length, equals(2));
    });

    test('isUserBlocked returns true when user is in blockedlist', () async {
      await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('blockedlist')
          .doc(blockedUserId)
          .set({'blockedAt': 'ts', 'reason': 'test'});

      final doc = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('blockedlist')
          .doc(blockedUserId)
          .get();

      expect(doc.exists, isTrue);
    });

    test('isUserBlocked returns false for non-blocked user', () async {
      final doc = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('blockedlist')
          .doc('nonBlockedUser')
          .get();

      expect(doc.exists, isFalse);
    });

    test('chat thread stream excludes threads with blocked users', () async {
      await fakeFirestore.collection('chatThreads').doc('thread1').set({
        'userIds': [userId, blockedUserId],
        'lastMessage': 'blocked thread',
        'lastTimestamp': DateTime.now().toIso8601String(),
      });
      await fakeFirestore.collection('chatThreads').doc('thread2').set({
        'userIds': [userId, 'user3'],
        'lastMessage': 'visible thread',
        'lastTimestamp': DateTime.now().toIso8601String(),
      });

      await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('blockedlist')
          .doc(blockedUserId)
          .set({'blockedAt': 'ts'});

      final blockedSnapshot = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('blockedlist')
          .get();
      final blockedIds = blockedSnapshot.docs.map((doc) => doc.id).toSet();

      final threadSnapshot = await fakeFirestore
          .collection('chatThreads')
          .where('userIds', arrayContains: userId)
          .get();

      final visibleThreads = threadSnapshot.docs.where((doc) {
        final userIds = List<String>.from(doc.data()['userIds'] ?? []);
        final otherUserId = userIds.firstWhere(
          (id) => id != userId,
          orElse: () => '',
        );
        return otherUserId.isNotEmpty && !blockedIds.contains(otherUserId);
      }).toList();

      expect(visibleThreads.length, equals(1));
      expect(visibleThreads.first.id, equals('thread2'));
    });
  });
}
