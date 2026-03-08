import '../message_model.dart';

class ConversationQualityMetrics {
  const ConversationQualityMetrics({
    required this.conversationDepth,
    this.responseRate,
    this.medianReplyDelayMs,
  });

  final int conversationDepth;
  final double? responseRate;
  final int? medianReplyDelayMs;
}

ConversationQualityMetrics calculateConversationQualityMetrics(
  List<Message> messages, {
  required String currentUserId,
}) {
  if (messages.isEmpty) {
    return const ConversationQualityMetrics(conversationDepth: 0);
  }

  final sorted = List<Message>.from(messages)
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  var sentByCurrent = 0;
  var respondedByOther = 0;
  final replyDelaysMs = <int>[];

  for (var i = 0; i < sorted.length; i++) {
    final msg = sorted[i];
    if (msg.senderId != currentUserId) {
      continue;
    }
    sentByCurrent++;
    for (var j = i + 1; j < sorted.length; j++) {
      final next = sorted[j];
      if (next.senderId == currentUserId) {
        continue;
      }
      respondedByOther++;
      replyDelaysMs.add(
        next.timestamp.difference(msg.timestamp).inMilliseconds,
      );
      break;
    }
  }

  final responseRate =
      sentByCurrent > 0 ? respondedByOther / sentByCurrent : null;
  final medianReplyDelayMs = _median(replyDelaysMs);

  return ConversationQualityMetrics(
    conversationDepth: sorted.length,
    responseRate: responseRate,
    medianReplyDelayMs: medianReplyDelayMs,
  );
}

int? _median(List<int> values) {
  if (values.isEmpty) {
    return null;
  }
  final sorted = List<int>.from(values)..sort();
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) {
    return sorted[mid];
  }
  return ((sorted[mid - 1] + sorted[mid]) / 2).round();
}
