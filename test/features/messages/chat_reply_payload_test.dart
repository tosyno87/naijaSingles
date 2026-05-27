import 'package:flutter_test/flutter_test.dart';

/// Documents expected Firestore payload shape for reply messages.
Map<String, dynamic> buildTextMessagePayload({
  required String senderId,
  required String text,
  String? replyToMessageId,
}) {
  return {
    'senderId': senderId,
    'text': text.trim(),
    'messageType': 'text',
    'read': false,
    if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
  };
}

void main() {
  test('reply payload includes parent message id', () {
    final payload = buildTextMessagePayload(
      senderId: 'user_a',
      text: 'Sounds good!',
      replyToMessageId: 'msg_parent',
    );
    expect(payload['replyToMessageId'], 'msg_parent');
    expect(payload['messageType'], 'text');
  });

  test('plain text payload omits reply field', () {
    final payload = buildTextMessagePayload(
      senderId: 'user_a',
      text: 'Hello',
    );
    expect(payload.containsKey('replyToMessageId'), false);
  });
}
