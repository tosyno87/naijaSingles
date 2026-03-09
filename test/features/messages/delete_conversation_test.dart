import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  group('Delete Conversation Tests', () {
    test('deleting a thread document removes it from Firestore', () async {
      final threadRef = fakeFirestore.collection('chatThreads').doc('thread1');

      await threadRef.set({
        'userIds': ['user1', 'user2'],
        'lastMessage': 'Hello',
        'lastTimestamp': DateTime.now().toIso8601String(),
      });

      var doc = await threadRef.get();
      expect(doc.exists, isTrue);

      await threadRef.delete();

      doc = await threadRef.get();
      expect(doc.exists, isFalse);
    });

    test('deleting a thread does not affect other threads', () async {
      final threads = fakeFirestore.collection('chatThreads');

      await threads.doc('thread1').set({
        'userIds': ['user1', 'user2'],
        'lastMessage': 'Hey',
      });
      await threads.doc('thread2').set({
        'userIds': ['user1', 'user3'],
        'lastMessage': 'Hi there',
      });

      await threads.doc('thread1').delete();

      final remaining = await threads.get();
      expect(remaining.docs.length, equals(1));
      expect(remaining.docs.first.id, equals('thread2'));
    });

    test('batch delete removes thread and associated match record', () async {
      await fakeFirestore.collection('chatThreads').doc('thread1').set({
        'userIds': ['user1', 'user2'],
        'lastMessage': 'Hello',
      });
      await fakeFirestore.collection('matches').doc('match1').set({
        'users': ['user1', 'user2'],
        'matchedAt': DateTime.now().toIso8601String(),
      });

      final batch = fakeFirestore.batch();
      batch.delete(fakeFirestore.collection('chatThreads').doc('thread1'));
      batch.delete(fakeFirestore.collection('matches').doc('match1'));
      await batch.commit();

      final threadDoc =
          await fakeFirestore.collection('chatThreads').doc('thread1').get();
      final matchDoc =
          await fakeFirestore.collection('matches').doc('match1').get();

      expect(threadDoc.exists, isFalse);
      expect(matchDoc.exists, isFalse);
    });

    test('soft-clearing a chat with clearedAt does not remove the document',
        () async {
      final threadRef = fakeFirestore.collection('chatThreads').doc('thread1');

      await threadRef.set({
        'userIds': ['user1', 'user2'],
        'lastMessage': 'Hey',
      });

      await threadRef.update({
        'clearedAt.user1': DateTime.now().toIso8601String(),
      });

      final doc = await threadRef.get();
      expect(doc.exists, isTrue);
      final data = doc.data()!;
      expect(data['clearedAt'], isA<Map>());
      expect((data['clearedAt'] as Map)['user1'], isNotNull);
    });

    test('clearing chat only affects the clearing user', () async {
      final threadRef = fakeFirestore.collection('chatThreads').doc('thread1');

      await threadRef.set({
        'userIds': ['user1', 'user2'],
        'lastMessage': 'Hey',
      });

      await threadRef.update({
        'clearedAt.user1': DateTime.now().toIso8601String(),
      });

      final doc = await threadRef.get();
      final clearedAt = doc.data()!['clearedAt'] as Map;
      expect(clearedAt.containsKey('user1'), isTrue);
      expect(clearedAt.containsKey('user2'), isFalse);
    });
  });
}
