import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/services/enhanced_chat_service.dart';

void main() {
  group('EnhancedMessage', () {
    EnhancedMessage createMessage({
      String id = 'msg_1',
      String text = 'Hello',
      String senderId = 'sender_1',
      DateTime? timestamp,
      bool isRead = false,
      List<String> readBy = const [],
      Map<String, List<String>> reactions = const {},
      String? replyToMessageId,
      List<String> attachments = const [],
      bool isEdited = false,
      DateTime? editedAt,
      bool isDeleted = false,
      DateTime? deletedAt,
    }) {
      return EnhancedMessage(
        id: id,
        text: text,
        senderId: senderId,
        timestamp: timestamp ?? DateTime(2026, 3, 4),
        isRead: isRead,
        readBy: readBy,
        reactions: reactions,
        replyToMessageId: replyToMessageId,
        attachments: attachments,
        isEdited: isEdited,
        editedAt: editedAt,
        isDeleted: isDeleted,
        deletedAt: deletedAt,
      );
    }

    group('isReadBy', () {
      test('returns true when userId is in readBy list', () {
        final message = createMessage(
          readBy: ['user_a', 'user_b', 'user_c'],
        );

        expect(message.isReadBy('user_a'), isTrue);
        expect(message.isReadBy('user_b'), isTrue);
        expect(message.isReadBy('user_c'), isTrue);
      });

      test('returns false when userId is not in readBy list', () {
        final message = createMessage(
          readBy: ['user_a', 'user_b'],
        );

        expect(message.isReadBy('user_z'), isFalse);
      });

      test('returns false when readBy is empty', () {
        final message = createMessage(readBy: []);

        expect(message.isReadBy('user_a'), isFalse);
      });
    });

    group('getReactionCount', () {
      test('returns correct count for a specific emoji', () {
        final message = createMessage(
          reactions: {
            '❤️': ['user_a', 'user_b', 'user_c'],
            '👍': ['user_a'],
          },
        );

        expect(message.getReactionCount('❤️'), 3);
        expect(message.getReactionCount('👍'), 1);
      });

      test('returns 0 for emoji with no reactions', () {
        final message = createMessage(
          reactions: {
            '❤️': ['user_a'],
          },
        );

        expect(message.getReactionCount('🔥'), 0);
      });

      test('returns 0 when reactions map is empty', () {
        final message = createMessage(reactions: {});

        expect(message.getReactionCount('❤️'), 0);
      });
    });

    group('hasUserReacted', () {
      test('returns true when user has reacted with the given emoji', () {
        final message = createMessage(
          reactions: {
            '❤️': ['user_a', 'user_b'],
            '👍': ['user_c'],
          },
        );

        expect(message.hasUserReacted('user_a', '❤️'), isTrue);
        expect(message.hasUserReacted('user_b', '❤️'), isTrue);
        expect(message.hasUserReacted('user_c', '👍'), isTrue);
      });

      test('returns false when user has not reacted with the given emoji', () {
        final message = createMessage(
          reactions: {
            '❤️': ['user_a'],
          },
        );

        expect(message.hasUserReacted('user_b', '❤️'), isFalse);
      });

      test('returns false when emoji is not in reactions', () {
        final message = createMessage(
          reactions: {
            '❤️': ['user_a'],
          },
        );

        expect(message.hasUserReacted('user_a', '🔥'), isFalse);
      });

      test('returns false when reactions is empty', () {
        final message = createMessage(reactions: {});

        expect(message.hasUserReacted('user_a', '❤️'), isFalse);
      });
    });

    group('getUsersWhoReacted', () {
      test('returns list of users for a given emoji', () {
        final message = createMessage(
          reactions: {
            '❤️': ['user_a', 'user_b'],
          },
        );

        expect(
          message.getUsersWhoReacted('❤️'),
          ['user_a', 'user_b'],
        );
      });

      test('returns empty list for emoji with no reactions', () {
        final message = createMessage(reactions: {});

        expect(message.getUsersWhoReacted('❤️'), isEmpty);
      });
    });

    group('isEdited field', () {
      test('is false and editedAt is null for unedited messages', () {
        final message = createMessage();

        expect(message.isEdited, isFalse);
        expect(message.editedAt, isNull);
      });

      test('is true with editedAt set for edited messages', () {
        final editTime = DateTime(2026, 3, 4, 12, 30);
        final message = createMessage(
          isEdited: true,
          editedAt: editTime,
        );

        expect(message.isEdited, isTrue);
        expect(message.editedAt, editTime);
      });
    });

    group('isDeleted field', () {
      test('is false and deletedAt is null for active messages', () {
        final message = createMessage();

        expect(message.isDeleted, isFalse);
        expect(message.deletedAt, isNull);
      });

      test('is true with deletedAt set for deleted messages', () {
        final deleteTime = DateTime(2026, 3, 4, 14, 0);
        final message = createMessage(
          isDeleted: true,
          deletedAt: deleteTime,
        );

        expect(message.isDeleted, isTrue);
        expect(message.deletedAt, deleteTime);
      });
    });

    group('fromMap', () {
      test('parses a complete data map correctly', () {
        final timestamp = DateTime(2026, 3, 4, 10, 0);
        final editedAt = DateTime(2026, 3, 4, 10, 5);

        final message = EnhancedMessage.fromMap('msg_42', {
          'text': 'Hey there!',
          'senderId': 'sender_x',
          'timestamp': null,
          'isRead': true,
          'readBy': ['user_a', 'user_b'],
          'reactions': <String, dynamic>{
            '❤️': ['user_a'],
            '👍': ['user_b', 'user_c'],
          },
          'replyToMessageId': 'msg_41',
          'attachments': ['file1.jpg', 'file2.png'],
          'isEdited': true,
          'editedAt': null,
          'isDeleted': false,
          'deletedAt': null,
        });

        expect(message.id, 'msg_42');
        expect(message.text, 'Hey there!');
        expect(message.senderId, 'sender_x');
        expect(message.isRead, isTrue);
        expect(message.readBy, ['user_a', 'user_b']);
        expect(message.getReactionCount('❤️'), 1);
        expect(message.getReactionCount('👍'), 2);
        expect(message.replyToMessageId, 'msg_41');
        expect(message.attachments, ['file1.jpg', 'file2.png']);
        expect(message.isEdited, isTrue);
        expect(message.isDeleted, isFalse);
      });

      test('handles missing fields with sensible defaults', () {
        final message = EnhancedMessage.fromMap('msg_empty', {});

        expect(message.id, 'msg_empty');
        expect(message.text, '');
        expect(message.senderId, '');
        expect(message.isRead, isFalse);
        expect(message.readBy, isEmpty);
        expect(message.reactions, isEmpty);
        expect(message.replyToMessageId, isNull);
        expect(message.attachments, isEmpty);
        expect(message.isEdited, isFalse);
        expect(message.editedAt, isNull);
        expect(message.isDeleted, isFalse);
        expect(message.deletedAt, isNull);
      });
    });

    group('constructor field assignment', () {
      test('all required fields are stored correctly', () {
        final ts = DateTime(2026, 3, 4, 9, 0);
        final message = EnhancedMessage(
          id: 'msg_100',
          text: 'Test message',
          senderId: 'sender_100',
          timestamp: ts,
          isRead: true,
          readBy: ['reader_1'],
          reactions: {
            '😂': ['user_x'],
          },
          attachments: ['photo.jpg'],
          isEdited: false,
          isDeleted: false,
          replyToMessageId: 'msg_99',
        );

        expect(message.id, 'msg_100');
        expect(message.text, 'Test message');
        expect(message.senderId, 'sender_100');
        expect(message.timestamp, ts);
        expect(message.isRead, isTrue);
        expect(message.readBy, ['reader_1']);
        expect(message.reactions, {'😂': ['user_x']});
        expect(message.attachments, ['photo.jpg']);
        expect(message.replyToMessageId, 'msg_99');
      });
    });

    group('toString', () {
      test('includes id, text, senderId, and timestamp', () {
        final message = createMessage(
          id: 'msg_str',
          text: 'Hello world',
          senderId: 'user_str',
        );
        final str = message.toString();

        expect(str, contains('msg_str'));
        expect(str, contains('Hello world'));
        expect(str, contains('user_str'));
      });
    });
  });
}
