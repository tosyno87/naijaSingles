import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/messages/services/chat_service.dart';

void main() {
  group('ChatService', () {
    test('streams current user threads ordered by most recent update', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'current-user'),
      );
      final service = ChatService(firestore: firestore, auth: auth);

      await firestore.collection('chatThreads').doc('older-thread').set({
        'userIds': ['current-user', 'older-match'],
        'userNames': {
          'current-user': 'Current User',
          'older-match': 'Older Match',
        },
        'lastMessageText': 'Older message',
        'lastUpdated': Timestamp.fromDate(DateTime(2026, 5, 1, 10)),
        'unreadCount': {'current-user': 0},
      });
      await firestore.collection('chatThreads').doc('newer-thread').set({
        'userIds': ['current-user', 'newer-match'],
        'userNames': {
          'current-user': 'Current User',
          'newer-match': 'Newer Match',
        },
        'lastMessageText': 'Newer message',
        'lastUpdated': Timestamp.fromDate(DateTime(2026, 5, 2, 10)),
        'unreadCount': {'current-user': 1},
      });
      await firestore.collection('chatThreads').doc('unrelated-thread').set({
        'userIds': ['someone-else', 'another-user'],
        'lastMessageText': 'Should not be visible',
        'lastUpdated': Timestamp.fromDate(DateTime(2026, 5, 3, 10)),
      });

      final threads = await service.getChatThreadsStream().first;

      expect(threads.map((thread) => thread.threadId), [
        'newer-thread',
        'older-thread',
      ]);
      expect(threads.first.otherUserName, 'Newer Match');
      expect(threads.first.unread, isTrue);
    });
  });
}
