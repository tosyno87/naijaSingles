import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../common/constants/app_colors.dart';
import '../../common/widgets/state_views/state_views.dart';
import '../dating/screens/user_detail_screen.dart'; // Import for profile viewing
import '../explore/explore_screen.dart'; // Import ExploreScreen directly
import 'chat_thread_screen.dart';
import 'message_model.dart';
import 'services/chat_service.dart';
import 'services/matched_user_profile_loader.dart';
import 'services/participant_profile_resolver.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final ChatService _chatService = ChatService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ParticipantProfileResolver _participantResolver =
      ParticipantProfileResolver();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundColor,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          automaticallyImplyLeading: false, // Hide back button on main screen
          title: Text(
            'Messages',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: StreamBuilder<List<MessageThreadInfo>>(
          stream: _getChatThreadsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }

            if (snapshot.hasError) {
              log('Error loading messages: ${snapshot.error}');
              return _buildErrorState(snapshot.error.toString());
            }

            final threads = snapshot.data ?? [];

            if (threads.isEmpty) {
              return _buildEmptyState();
            }

            return _buildMessagesList(threads);
          },
        ),
      );

  Stream<List<MessageThreadInfo>> _getChatThreadsStream() =>
      _chatService.getChatThreadsStream();

  Widget _buildLoadingState() =>
      const AppLoadingView(message: 'Loading conversations...');

  Widget _buildErrorState(String error) => AppErrorView(
        title: 'Error loading messages',
        onRetry: () {
          setState(() {});
        },
      );

  Widget _buildEmptyState() => AppEmptyView(
        title: 'No messages yet',
        subtitle:
            'Start matching with people to begin conversations and make meaningful connections.',
        icon: Icons.chat_bubble_outline,
        actionLabel: 'Start Matching',
        onAction: () {
          unawaited(
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ExploreScreen(showBackButton: true),
              ),
            ),
          );
        },
      );

  Widget _buildMessagesList(List<MessageThreadInfo> threads) =>
      ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: threads.length,
        separatorBuilder: (context, index) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final thread = threads[index];
          return _buildMessageThreadItem(thread);
        },
      );

  Widget _buildMessageThreadItem(MessageThreadInfo thread) => Dismissible(
        key: Key(thread.threadId),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.delete,
            color: Colors.white,
            size: 24,
          ),
        ),
        confirmDismiss: (direction) async => _showDeleteConfirmation(thread),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                _openChatThread(thread);
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Enhanced avatar with status and profile tap
                    Stack(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _viewUserProfile(thread),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.grey.shade100,
                              backgroundImage: thread.avatarUrl != null
                                  ? NetworkImage(thread.avatarUrl!)
                                  : null,
                              onBackgroundImageError:
                                  thread.avatarUrl != null ? (_, __) {} : null,
                              child: thread.avatarUrl == null
                                  ? Icon(
                                      Icons.person,
                                      size: 30,
                                      color: Colors.grey.shade500,
                                    )
                                  : null,
                            ),
                          ),
                        ),

                        // Unread indicator
                        if (thread.unread)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.cardColor,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Message content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  thread.otherUserName,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 17,
                                    fontWeight: thread.unread
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                thread.getRelativeTime(),
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: thread.unread
                                      ? AppColors.primaryGreen
                                      : AppColors.textTertiary,
                                  fontWeight: thread.unread
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            thread.lastMessage,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: thread.unread
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontWeight: thread.unread
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  void _openChatThread(MessageThreadInfo thread) {
    unawaited(_chatService.markThreadAsRead(thread.threadId));

    unawaited(
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatThreadScreen(
            threadId: thread.threadId,
            userName: thread.otherUserName,
            avatarUrl: thread.avatarUrl,
            otherUserId: thread.otherUserId,
          ),
        ),
      ),
    );
  }

  // Show delete confirmation dialog
  Future<bool?> _showDeleteConfirmation(MessageThreadInfo thread) async {
    if (!mounted) return false;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        contentPadding: const EdgeInsets.all(24),
        title: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline,
                color: AppColors.error,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Delete Conversation',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to delete your conversation with ${thread.otherUserName}?',
              style: GoogleFonts.montserrat(
                color: AppColors.textSecondary,
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will also unmatch you both. This action cannot be undone.',
                      style: GoogleFonts.montserrat(
                        color: AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context, false);
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: AppColors.textSecondary.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.montserrat(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    // Close dialog first
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context, true);
                    }
                    // Then delete chat thread
                    await _deleteChatThread(thread);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Delete',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      ),
    );
  }

  // Delete chat thread with loading indicator
  Future<void> _deleteChatThread(MessageThreadInfo thread) async {
    if (!mounted) return;

    // Show MVP compliant loading indicator
    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          contentPadding: const EdgeInsets.all(32),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Deleting Conversation',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we remove your conversation and unmatch you both...',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final success = await _chatService.deleteChatThread(thread.threadId);

      // Close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Conversation deleted and users unmatched',
                style: GoogleFonts.montserrat(color: Colors.white),
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to delete conversation',
                style: GoogleFonts.montserrat(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    } on FirebaseException catch (_) {
      // Close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error deleting conversation',
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } on Object {
      // Fallback for non-Firebase errors
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error deleting conversation',
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  // Method to view user profile from messages
  Future<void> _viewUserProfile(MessageThreadInfo thread) async {
    if (!mounted) return;

    try {
      // Show MVP compliant loading indicator
      unawaited(
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.cardColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            contentPadding: const EdgeInsets.all(32),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        color: AppColors.primaryGreen,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Loading Profile',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we fetch the user profile...',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );

      final userModel = await MatchedUserProfileLoader.load(
        firestore: _firestore,
        userId: thread.otherUserId,
        fallbackName: thread.otherUserName,
        fallbackAvatarUrl: thread.avatarUrl,
      );

      final String? loadedName = userModel.name;
      final String? loadedAvatar =
          (userModel.imageUrl != null && userModel.imageUrl!.isNotEmpty)
              ? userModel.imageUrl!.first as String?
              : null;
      if (loadedName != null && loadedName.trim().isNotEmpty) {
        unawaited(
          _participantResolver.writeThroughThreadCache(
            threadId: thread.threadId,
            userId: thread.otherUserId,
            name: loadedName.trim(),
            avatarUrl: loadedAvatar,
            cachedName: thread.otherUserName,
            cachedAvatarUrl: thread.avatarUrl,
          ),
        );
      }

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (!mounted) return;

      unawaited(
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserDetailScreen(
              user: userModel,
              showLikeActions: false,
            ),
          ),
        ),
      );
    } on Object catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      log('Error loading user profile: $e');
      if (!mounted) return;

      final fallbackUser = MatchedUserProfileLoader.buildFallback(
        userId: thread.otherUserId,
        fallbackName: thread.otherUserName,
        fallbackAvatarUrl: thread.avatarUrl,
      );

      unawaited(
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserDetailScreen(
              user: fallbackUser,
              showLikeActions: false,
            ),
          ),
        ),
      );
    }
  }
}
