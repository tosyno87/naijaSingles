class Message {
  Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isRead,
    this.imageUrl,
    this.messageType = 'text',
  });
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;
  final String messageType;
}

class MessageThreadInfo {
  MessageThreadInfo({
    required this.threadId,
    required this.otherUserId,
    required this.otherUserName,
    required this.lastMessage,
    required this.timestamp,
    required this.unread,
    this.lastMessageSenderId,
    this.avatarUrl,
  });
  final String threadId;
  final String otherUserId;
  final String otherUserName;
  final String lastMessage;
  final String? lastMessageSenderId;
  final DateTime timestamp;
  final bool unread;
  final String? avatarUrl;

  MessageThreadInfo copyWith({
    String? threadId,
    String? otherUserId,
    String? otherUserName,
    String? lastMessage,
    String? lastMessageSenderId,
    DateTime? timestamp,
    bool? unread,
    String? avatarUrl,
  }) =>
      MessageThreadInfo(
        threadId: threadId ?? this.threadId,
        otherUserId: otherUserId ?? this.otherUserId,
        otherUserName: otherUserName ?? this.otherUserName,
        lastMessage: lastMessage ?? this.lastMessage,
        lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
        timestamp: timestamp ?? this.timestamp,
        unread: unread ?? this.unread,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );

  // Helper method to format timestamp as relative time
  String getRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      // Format as date if more than a week old
      return '${timestamp.day}/${timestamp.month}';
    } else if (difference.inDays > 0) {
      // Format as day of week if within a week
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[timestamp.weekday - 1];
    } else if (difference.inHours > 0) {
      // Format as time if within a day
      final hour = timestamp.hour > 12
          ? timestamp.hour - 12
          : timestamp.hour == 0
              ? 12
              : timestamp.hour;
      final period = timestamp.hour >= 12 ? 'PM' : 'AM';
      final minute = timestamp.minute.toString().padLeft(2, '0');
      return '$hour:$minute $period';
    } else if (difference.inMinutes > 0) {
      // Format as minutes if within an hour
      return '${difference.inMinutes}m';
    } else {
      // Format as just now if within a minute
      return 'now';
    }
  }
}
