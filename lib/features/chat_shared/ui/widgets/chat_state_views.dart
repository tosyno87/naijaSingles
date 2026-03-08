import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../common/constants/app_colors.dart';

/// Loading spinner shown while a chat stream is connecting.
class ChatLoadingView extends StatelessWidget {
  const ChatLoadingView({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Loading chat messages',
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      );
}

/// Full-screen error state for chat streams.
class ChatErrorView extends StatelessWidget {
  const ChatErrorView({required this.message, super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Chat error: $message',
        liveRegion: true,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: GoogleFonts.montserrat(color: Colors.red, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
}

/// Empty state shown when a thread has no messages yet.
///
/// [subtitle] and [subtitleColor] allow per-context copy like
/// "Say hi to Ada!" (DM) vs "Start the conversation!" (group).
class ChatEmptyView extends StatelessWidget {
  const ChatEmptyView({
    required this.subtitle,
    super.key,
    this.subtitleColor,
  });

  final String subtitle;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'No messages yet. $subtitle',
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: Colors.grey[400],
                semanticLabel: 'Empty chat',
              ),
              const SizedBox(height: 16),
              Text(
                'No messages yet',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: subtitleColor ?? AppColors.primaryGreen,
                ),
              ),
            ],
          ),
        ),
      );
}
