import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/chat_ui_tokens.dart';

/// Shared message composer bar used by DM and group chat screens.
///
/// Feature flags control per-context behaviour:
/// - [showEmojiButton] / [onEmojiTap] — only DM uses the emoji picker
/// - [animateSendButton] — DM fades send between active/inactive
/// - [submitOnEnter] — group sends on keyboard submit
class ChatComposer extends StatelessWidget {
  const ChatComposer({
    required this.controller,
    required this.onSend,
    required this.hasText,
    super.key,
    this.showEmojiButton = false,
    this.onEmojiTap,
    this.animateSendButton = true,
    this.submitOnEnter = false,
    this.maxLines = 4,
    this.hintText = 'Type a message...',
    this.showAttachButton = false,
    this.onAttachTap,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool hasText;
  final bool showAttachButton;
  final VoidCallback? onAttachTap;
  final bool showEmojiButton;
  final VoidCallback? onEmojiTap;
  final bool animateSendButton;
  final bool submitOnEnter;
  final int maxLines;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<ChatUiTokens>() ?? ChatUiTokens.defaults();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.composerBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (showAttachButton)
              IconButton(
                icon: const Icon(Icons.image_outlined, color: Colors.grey),
                onPressed: onAttachTap,
              ),
            if (showEmojiButton)
              IconButton(
                icon: const Icon(
                  Icons.emoji_emotions_outlined,
                  color: Colors.grey,
                ),
                onPressed: onEmojiTap,
              ),
            Expanded(
              child: Container(
                constraints: BoxConstraints(maxHeight: maxLines * 24.0),
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(tokens.inputBorderRadius),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: tokens.inputFillColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  maxLines: maxLines,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: submitOnEnter ? TextInputAction.send : null,
                  onSubmitted: submitOnEnter ? (_) => onSend() : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _sendButton(tokens),
          ],
        ),
      ),
    );
  }

  Widget _sendButton(ChatUiTokens tokens) {
    if (animateSendButton) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: hasText
              ? tokens.sendButtonActiveColor
              : tokens.sendButtonInactiveColor,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          onPressed: hasText ? onSend : null,
          icon: const Icon(Icons.send, color: Colors.white, size: 20),
        ),
      );
    }

    return GestureDetector(
      onTap: onSend,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tokens.sendButtonActiveColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.send, color: Colors.white, size: 20),
      ),
    );
  }
}
