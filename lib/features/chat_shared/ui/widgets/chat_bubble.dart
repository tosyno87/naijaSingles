import 'package:flutter/material.dart';

import '../../models/chat_message_view_model.dart';
import '../theme/chat_ui_tokens.dart';

/// Shared message bubble used by both DM and group chat screens.
///
/// Rendering adapts based on the [ChatMessageViewModel] flags:
/// - [ChatMessageViewModel.isSystemMessage] → centered chip
/// - [ChatMessageViewModel.senderName] non-null → sender label above text
/// - [ChatMessageViewModel.showReadReceipt] → read-receipt icon row
/// - [ChatMessageViewModel.senderAvatarUrl] → network avatar; falls back to
///   [avatarFallback] if provided, or a generic person icon.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    required this.message,
    super.key,
    this.avatarFallback,
    this.useTailRadius = true,
  });

  final ChatMessageViewModel message;

  /// Optional widget shown when `senderAvatarUrl` is null (e.g. a letter
  /// circle in group chat).
  final Widget? avatarFallback;

  /// When true the "own" bubble gets an asymmetric tail corner.
  /// DM screens pass true; group screens may pass false.
  final bool useTailRadius;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<ChatUiTokens>() ?? ChatUiTokens.defaults();

    if (message.isSystemMessage) {
      return _SystemChip(message: message, tokens: tokens);
    }

    final isOwn = message.isOwnMessage;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOwn) ...[
            _avatar(tokens),
            const SizedBox(width: 8),
          ],
          Flexible(child: _bubble(tokens, isOwn)),
        ],
      ),
    );
  }

  Widget _avatar(ChatUiTokens tokens) {
    if (message.senderAvatarUrl != null) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: NetworkImage(message.senderAvatarUrl!),
        onBackgroundImageError: (_, __) {},
      );
    }
    if (avatarFallback != null) {
      return avatarFallback!;
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.grey.shade200,
      child: Icon(Icons.person, size: 16, color: Colors.grey[600]),
    );
  }

  Widget _bubble(ChatUiTokens tokens, bool isOwn) {
    final borderRadius = useTailRadius
        ? BorderRadius.only(
            topLeft: Radius.circular(tokens.bubbleRadius),
            topRight: Radius.circular(tokens.bubbleRadius),
            bottomLeft: isOwn
                ? Radius.circular(tokens.bubbleRadius)
                : Radius.circular(tokens.bubbleTailRadius),
            bottomRight: isOwn
                ? Radius.circular(tokens.bubbleTailRadius)
                : Radius.circular(tokens.bubbleRadius),
          )
        : BorderRadius.circular(tokens.bubbleRadius);

    return Container(
      padding: tokens.bubblePadding,
      decoration: BoxDecoration(
        color: isOwn ? tokens.ownBubbleColor : tokens.otherBubbleColor,
        borderRadius: borderRadius,
        boxShadow: tokens.bubbleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.senderName != null && !isOwn)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(message.senderName!, style: tokens.senderNameStyle()),
            ),
          Text(message.text, style: tokens.messageStyle(isOwn: isOwn)),
          const SizedBox(height: 6),
          _timestampRow(tokens, isOwn),
        ],
      ),
    );
  }

  Widget _timestampRow(ChatUiTokens tokens, bool isOwn) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatChatTime(message.timestamp),
            style: tokens.timestampStyle(isOwn: isOwn),
          ),
          if (message.showReadReceipt && isOwn) ...[
            const SizedBox(width: 4),
            Icon(
              message.isRead ? Icons.done_all : Icons.done,
              size: 14,
              color: message.isRead
                  ? tokens.readReceiptReadColor
                  : tokens.readReceiptColor,
            ),
          ],
        ],
      );
}

class _SystemChip extends StatelessWidget {
  const _SystemChip({required this.message, required this.tokens});
  final ChatMessageViewModel message;
  final ChatUiTokens tokens;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: tokens.systemBubbleColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(message.text, style: tokens.systemMessageStyle()),
          ),
        ),
      );
}
