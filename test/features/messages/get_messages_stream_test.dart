import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/messages/message_model.dart';
import 'package:naijasingles/features/messages/services/chat_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late ChatService chatService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    final mockUser = MockUser(uid: 'user1');
    mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
    chatService = ChatService(firestore: fakeFirestore, auth: mockAuth);
  });

  /// Seed a thread document with the given [clearedAt] map (may be null).
  Future<void> seedThread({
    String threadId = 't1',
    Map<String, dynamic>? clearedAt,
  }) async {
    final data = <String, dynamic>{
      'userIds': ['user1', 'user2'],
      'lastMessage': 'hey',
    };
    if (clearedAt != null) {
      data['clearedAt'] = clearedAt;
    }
    await fakeFirestore.collection('chatThreads').doc(threadId).set(data);
  }

  Future<void> addMessage(
    String threadId, {
    required String text,
    required String timestamp,
    String senderId = 'user2',
  }) async {
    await fakeFirestore
        .collection('chatThreads')
        .doc(threadId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
      'read': false,
    });
  }

  group('getMessagesStream', () {
    test('filters messages older than clearedAt', () async {
      await seedThread(
        clearedAt: {'user1': '2025-06-01T12:00:00Z'},
      );
      await addMessage(
        't1',
        text: 'old',
        timestamp: '2025-06-01T11:00:00Z',
      );
      await addMessage(
        't1',
        text: 'new',
        timestamp: '2025-06-01T13:00:00Z',
      );

      final messages = await chatService.getMessagesStream('t1').first;

      expect(messages, hasLength(1));
      expect(messages.single.text, 'new');
    });

    test('returns all messages when no clearedAt is set', () async {
      await seedThread();
      await addMessage('t1', text: 'a', timestamp: '2025-01-01T10:00:00Z');
      await addMessage('t1', text: 'b', timestamp: '2025-01-01T11:00:00Z');

      final messages = await chatService.getMessagesStream('t1').first;

      expect(messages, hasLength(2));
    });

    test('does not leak cleared messages before clearedAt arrives', () async {
      await seedThread(
        clearedAt: {'user1': '2025-06-01T12:00:00Z'},
      );
      await addMessage(
        't1',
        text: 'should-be-hidden',
        timestamp: '2025-06-01T11:00:00Z',
      );
      await addMessage(
        't1',
        text: 'visible',
        timestamp: '2025-06-01T13:00:00Z',
      );

      final emissions = <List<Message>>[];
      final sub = chatService.getMessagesStream('t1').listen(emissions.add);

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();

      for (final batch in emissions) {
        final texts = batch.map((m) => m.text).toList();
        expect(
          texts,
          isNot(contains('should-be-hidden')),
          reason: 'Cleared messages must never appear, even transiently',
        );
      }
    });

    test('re-filters when clearedAt is updated on the thread doc', () async {
      await seedThread();
      await addMessage('t1', text: 'a', timestamp: '2025-01-01T10:00:00Z');
      await addMessage('t1', text: 'b', timestamp: '2025-01-01T12:00:00Z');

      final emissions = <List<Message>>[];
      final sub = chatService.getMessagesStream('t1').listen(emissions.add);

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      await fakeFirestore.collection('chatThreads').doc('t1').update({
        'clearedAt.user1': '2025-01-01T11:00:00Z',
      });

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();

      expect(emissions, isNotEmpty);
      final last = emissions.last;
      expect(last.map((m) => m.text), equals(['b']));
    });

    test('only filters for the current user, not the other participant',
        () async {
      await seedThread(
        clearedAt: {'user2': '2025-06-01T12:00:00Z'},
      );
      await addMessage(
        't1',
        text: 'old',
        timestamp: '2025-06-01T11:00:00Z',
      );
      await addMessage(
        't1',
        text: 'new',
        timestamp: '2025-06-01T13:00:00Z',
      );

      final messages = await chatService.getMessagesStream('t1').first;

      expect(messages, hasLength(2));
    });

    test('returns unfiltered messages when uid is null (signed out)', () async {
      final signedOutAuth = MockFirebaseAuth();
      final signedOutService =
          ChatService(firestore: fakeFirestore, auth: signedOutAuth);

      await seedThread(
        clearedAt: {'user1': '2025-06-01T12:00:00Z'},
      );
      await addMessage(
        't1',
        text: 'old',
        timestamp: '2025-06-01T11:00:00Z',
      );
      await addMessage(
        't1',
        text: 'new',
        timestamp: '2025-06-01T13:00:00Z',
      );

      final messages = await signedOutService.getMessagesStream('t1').first;

      expect(messages, hasLength(2));
    });

    test('emits messages when thread document does not exist (no clearedAt)',
        () async {
      // Thread doc is absent -- the clearedAt listener receives a snapshot
      // with exists==false, yielding null. This also exercises the fallback
      // behaviour: the gate must still open (clearedAtReady = true) so
      // messages are not blocked indefinitely.
      await fakeFirestore
          .collection('chatThreads')
          .doc('t1')
          .collection('messages')
          .add({
        'senderId': 'user2',
        'text': 'orphan',
        'timestamp': '2025-01-01T10:00:00Z',
        'read': false,
      });

      final emissions = <List<Message>>[];
      final sub = chatService.getMessagesStream('t1').listen(emissions.add);

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();

      expect(emissions, isNotEmpty);
      expect(emissions.last.single.text, 'orphan');
    });

    test('subscription cancel tears down both listeners cleanly', () async {
      await seedThread();
      await addMessage('t1', text: 'msg', timestamp: '2025-01-01T10:00:00Z');

      final sub = chatService.getMessagesStream('t1').listen((_) {});

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
    });
  });
}
