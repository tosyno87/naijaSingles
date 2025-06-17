class Message {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isRead,
  });
}

class MessageThreadInfo {
  final String threadId;
  final String otherUserId;
  final String otherUserName;
  final String lastMessage;
  final String? lastMessageSenderId;
  final DateTime timestamp;
  final bool unread;
  final String? avatarUrl;
  final bool isOnline;

  MessageThreadInfo({
    required this.threadId,
    required this.otherUserId,
    required this.otherUserName,
    required this.lastMessage,
    this.lastMessageSenderId,
    required this.timestamp,
    required this.unread,
    this.avatarUrl,
    this.isOnline = false,
  });

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
      final hour = timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour == 0 ? 12 : timestamp.hour;
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
