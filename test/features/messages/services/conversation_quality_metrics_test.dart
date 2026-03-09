import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/messages/message_model.dart';
import 'package:naijasingles/features/messages/services/conversation_quality_metrics.dart';

void main() {
  Message msg(
    String id,
    String senderId,
    DateTime timestamp,
  ) =>
      Message(
        id: id,
        senderId: senderId,
        text: 't',
        timestamp: timestamp,
        isRead: false,
      );

  group('calculateConversationQualityMetrics', () {
    test('returns null response/delay when only one sender exists', () {
      final start = DateTime.utc(2026, 3, 8, 12);
      final messages = <Message>[
        msg('1', 'me', start),
        msg('2', 'me', start.add(const Duration(minutes: 1))),
      ];

      final quality = calculateConversationQualityMetrics(
        messages,
        currentUserId: 'me',
      );

      expect(quality.conversationDepth, 2);
      expect(quality.responseRate, 0.0);
      expect(quality.medianReplyDelayMs, isNull);
    });

    test('computes zero delay when reply timestamp matches sender timestamp',
        () {
      final ts = DateTime.utc(2026, 3, 8, 12);
      final messages = <Message>[
        msg('1', 'me', ts),
        msg('2', 'other', ts),
      ];

      final quality = calculateConversationQualityMetrics(
        messages,
        currentUserId: 'me',
      );

      expect(quality.conversationDepth, 2);
      expect(quality.responseRate, 1.0);
      expect(quality.medianReplyDelayMs, 0);
    });

    test('pairs only first eligible reply after each current-user message', () {
      final start = DateTime.utc(2026, 3, 8, 12);
      final messages = <Message>[
        msg('1', 'me', start),
        msg('2', 'me', start.add(const Duration(minutes: 1))),
        msg('3', 'other', start.add(const Duration(minutes: 2))),
        msg('4', 'other', start.add(const Duration(minutes: 4))),
      ];

      final quality = calculateConversationQualityMetrics(
        messages,
        currentUserId: 'me',
      );

      expect(quality.conversationDepth, 4);
      expect(quality.responseRate, 1.0);
      // Delays: 2m (msg1->msg3), 1m (msg2->msg3) => median 90s.
      expect(quality.medianReplyDelayMs, 90000);
    });
  });
}
