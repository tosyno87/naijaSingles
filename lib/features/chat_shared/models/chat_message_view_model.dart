/// Unified render model that normalises DM [Message] and [GroupMessage]
/// into a single type the shared chat widgets can consume.
class ChatMessageViewModel {
  const ChatMessageViewModel({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.senderId,
    required this.isOwnMessage,
    this.senderName,
    this.senderAvatarUrl,
    this.isRead = false,
    this.isSystemMessage = false,
    this.showReadReceipt = false,
    this.imageUrl,
  });

  final String id;
  final String text;
  final String? imageUrl;
  final DateTime timestamp;
  final String senderId;
  final bool isOwnMessage;

  /// Display name for group chats; null hides the sender row.
  final String? senderName;

  /// Network avatar URL; when null the bubble falls back to a placeholder.
  final String? senderAvatarUrl;

  /// Whether this message has been read by the other party (DM only).
  final bool isRead;

  /// System/admin messages rendered as centered chips (group only).
  final bool isSystemMessage;

  /// Whether to render the read-receipt icon row (DM only).
  final bool showReadReceipt;
}

/// Shared time formatter used by both DM and group bubble timestamps.
String formatChatTime(DateTime timestamp) {
  final hour = timestamp.hour > 12
      ? timestamp.hour - 12
      : timestamp.hour == 0
          ? 12
          : timestamp.hour;
  final period = timestamp.hour >= 12 ? 'PM' : 'AM';
  final minute = timestamp.minute.toString().padLeft(2, '0');
  return '$hour:$minute $period';
}
