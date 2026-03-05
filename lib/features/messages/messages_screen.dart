import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../common/constants/app_colors.dart';
import '../../models/user_model.dart'; // Import UserModel
import '../dating/screens/user_detail_screen.dart'; // Import for profile viewing
import '../explore/explore_screen.dart'; // Import ExploreScreen directly
import 'chat_thread_screen.dart';
import 'message_model.dart';
import 'services/chat_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final ChatService _chatService = ChatService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Afropeep MVP Color Scheme
  static const Color primaryColor = Color(0xFF008037); // Deep green
  static const Color cardColor = Color(0xFFFFFFFF); // White for cards
  static const Color errorColor = Color(0xFFFF5A5F); // Red for errors/delete
  static const Color successColor = Color(0xFF4CAF50); // Green for success
  static final Color textPrimary = Colors.brown.shade800;
  static final Color textSecondary = Colors.brown.shade600;
  static final Color textLight = Colors.grey.shade600;

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
              color: textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: StreamBuilder<List<MessageThreadInfo>>(
          stream: _getChatThreadsStreamWithUserData(),
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

  // Enhanced stream that includes user data (with fallback for missing index)
  Stream<List<MessageThreadInfo>> _getChatThreadsStreamWithUserData() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    // Use a simpler query that doesn't require a composite index
    // We'll sort in memory instead of using orderBy
    return FirebaseFirestore.instance
        .collection('chatThreads')
        .where('userIds', arrayContains: currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<MessageThreadInfo> threads = [];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();

          // Find the other user's ID
          final userIds = List<String>.from(data['userIds'] ?? []);
          final otherUserId = userIds.firstWhere(
            (id) => id != currentUserId,
            orElse: () => '',
          );

          if (otherUserId.isEmpty) continue;

          // Try to fetch the other user's profile. If the read is denied
          // (e.g., paused/incognito user blocked by Firestore rules), fall
          // back to cached data from the chat thread document so threads
          // remain visible.
          String otherUserName = 'User';
          String? avatarUrl;
          try {
            final otherUserDoc =
                await _firestore.collection('users').doc(otherUserId).get();

            if (otherUserDoc.exists) {
              final userData = otherUserDoc.data();
              otherUserName = userData?['name'] ?? 'User';

              final photos = userData?['photos'] as List<dynamic>?;
              if (photos != null && photos.isNotEmpty) {
                avatarUrl = photos.first as String?;
              }
            }
          } on Exception catch (_) {
            // Profile read denied (paused/incognito). Use the cached name
            // stored on the chat thread document at match-creation time.
            final userNames = data['userNames'] as Map<String, dynamic>?;
            otherUserName = userNames?[otherUserId] as String? ?? 'User';
          }

          // Get unread count for current user
          final unreadCount = data['unreadCount'] as Map<String, dynamic>?;
          final unread = (unreadCount?[currentUserId] ?? 0) > 0;

          threads.add(
            MessageThreadInfo(
              threadId: doc.id,
              otherUserId: otherUserId,
              otherUserName: otherUserName,
              lastMessage: data['lastMessageText'] ?? 'Say hello!',
              lastMessageSenderId: data['lastMessageSenderId'],
              timestamp: (data['lastUpdated'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
              unread: unread,
              avatarUrl: avatarUrl,
            ),
          );
        } on Object catch (e) {
          log('Error processing thread: $e');
          continue;
        }
      }

      // Sort by timestamp in memory (since we can't use orderBy without index)
      threads.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return threads;
    }).handleError((error) {
      log('Error in _getChatThreadsStreamWithUserData: $error');
      return <MessageThreadInfo>[];
    });
  }

  Widget _buildLoadingState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: primaryColor,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading conversations...',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: textSecondary,
              ),
            ),
          ],
        ),
      );

  Widget _buildErrorState(String error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading messages',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your connection and try again',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {}); // Trigger rebuild
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No messages yet',
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Start matching with people to begin conversations and make meaningful connections.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  unawaited(
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            const ExploreScreen(showBackButton: true),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  elevation: 2,
                ),
                child: Text(
                  'Start Matching',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
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
            color: errorColor,
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
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
            border: thread.unread
                ? Border.all(
                    color: primaryColor.withValues(alpha: 0.3),
                    width: 1.5,
                  )
                : null,
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
                          onTap: () => _viewUserProfile(thread.otherUserId),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: thread.unread
                                    ? primaryColor
                                    : Colors.grey.shade300,
                                width: thread.unread ? 2.5 : 1,
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

                        // Profile view indicator
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.visibility,
                              color: Colors.white,
                              size: 12,
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
                                color: primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: cardColor, width: 2),
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
                                child: GestureDetector(
                                  onTap: () =>
                                      _viewUserProfile(thread.otherUserId),
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          thread.otherUserName,
                                          style: GoogleFonts.montserrat(
                                            fontSize: 17,
                                            fontWeight: thread.unread
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            color: textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color:
                                            primaryColor.withValues(alpha: 0.7),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Text(
                                thread.getRelativeTime(),
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color:
                                      thread.unread ? primaryColor : textLight,
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
                              color:
                                  thread.unread ? textPrimary : textSecondary,
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
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        contentPadding: const EdgeInsets.all(24),
        title: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline,
                color: errorColor,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Delete Conversation',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: textPrimary,
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
                color: textSecondary,
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: errorColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: errorColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: errorColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will also unmatch you both. This action cannot be undone.',
                      style: GoogleFonts.montserrat(
                        color: errorColor,
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
                          color: textSecondary.withValues(alpha: 0.3)),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.montserrat(
                      color: textSecondary,
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
                    backgroundColor: errorColor,
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
          backgroundColor: cardColor,
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
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: primaryColor,
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
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we remove your conversation and unmatch you both...',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: textSecondary,
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
              backgroundColor: successColor,
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
  Future<void> _viewUserProfile(String userId) async {
    if (!mounted) return;

    try {
      // Show MVP compliant loading indicator
      unawaited(
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: cardColor,
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
                    color: primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        color: primaryColor,
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
                    color: textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we fetch the user profile...',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );

      // Fetch user data from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();

      // Close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (!mounted) return;

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;

        // Convert Firestore data to UserModel
        final userModel = UserModel(
          id: userId,
          name: userData['name'] ?? 'Unknown User',
          age: userData['age'] ?? 0,
          imageUrl: List<String>.from(
            userData['photos'] ?? userData['imageUrl'] ?? [],
          ),
          address: userData['locationName'] ?? userData['address'],
          distanceBW: userData['distanceBW'],
          editInfo: userData['editInfo'] ?? {},
        );

        // Navigate to profile screen
        unawaited(
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserDetailScreen(user: userModel),
            ),
          ),
        );
      } else {
        // Show error if user not found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User profile not found',
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
    } on Object catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      log('Error loading user profile: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load profile',
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
