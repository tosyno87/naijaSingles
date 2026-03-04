import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../common/constants/app_colors.dart'; // Import MVP colors
import '../../models/user_model.dart'; // Import UserModel
import '../../services/settings_service.dart'; // Import settings service for blocking
import '../dating/screens/user_detail_screen.dart'; // Import for profile viewing
import 'message_model.dart';
import 'services/chat_service.dart';

class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({
    required this.threadId,
    required this.userName,
    super.key,
    this.avatarUrl,
    this.otherUserId,
  });
  final String threadId;
  final String userName;
  final String? avatarUrl;
  final String? otherUserId;

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  String? _currentUserId;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // Listen to text changes for send button animation
    _messageController.addListener(() {
      final hasText = _messageController.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() {
          _hasText = hasText;
        });
      }
    });

    // Mark thread as read when opening
    _chatService.markThreadAsRead(widget.threadId);

    // Scroll to bottom when messages load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Validate message length locally
    if (text.length > 1000) {
      _showErrorSnackBar(
        'Message is too long. Please keep messages under 1000 characters.',
      );
      return;
    }

    try {
      final success =
          await _chatService.sendMessage(widget.threadId, text);
      if (success) {
        _messageController.clear();
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    } catch (error) {
      _showErrorSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background, // Use MVP background color
      appBar: AppBar(
        backgroundColor: AppColors.cardColor, // Use MVP card color
        elevation: 1,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.primaryGreen,
          ), // Use MVP primary color
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: _viewFullUserProfile,
          child: Row(
            children: [
              Hero(
                tag: 'avatar-${widget.threadId}',
                child: CircleAvatar(
                  radius: 16,
                  backgroundImage: widget.avatarUrl != null
                      ? NetworkImage(widget.avatarUrl!)
                      : const AssetImage(
                          'assets/images/placeholder_profile.jpg',
                        ) as ImageProvider,
                  onBackgroundImageError: (_, __) {},
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.userName,
                      style: GoogleFonts.montserrat(
                        // Use Montserrat for MVP
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary, // Use MVP text color
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Tap to view profile',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppColors.primaryGreen),
            onPressed: _showUserProfile,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.primaryGreen),
            onSelected: (value) {
              switch (value) {
                case 'block':
                  _showBlockUserDialog();
                  break;
                case 'report':
                  _showReportUserDialog();
                  break;
                case 'clear':
                  _showClearChatDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Block User'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Report User'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Clear Chat'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.getMessagesStream(widget.threadId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading messages',
                      style: GoogleFonts.montserrat(color: Colors.red),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
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
                          'Say hi to ${widget.userName}!',
                          style: GoogleFonts.montserrat(
                            // Use Montserrat for MVP
                            fontSize: 14,
                            color: AppColors.primaryGreen, // Use MVP primary color
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUserId;

                    // Group messages by date
                    final showDateSeparator = index == 0 ||
                        !_isSameDay(
                          messages[index].timestamp,
                          messages[index - 1].timestamp,
                        );

                    return Column(
                      children: [
                        if (showDateSeparator)
                          _buildDateSeparator(message.timestamp),
                        _buildMessageBubble(message, isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
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
                  // Emoji button
                  IconButton(
                    icon: const Icon(
                      Icons.emoji_emotions_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: _showEmojiPicker,
                  ),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (value) {
                          // No additional logic needed - text state is handled by listener
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Animated send button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _hasText ? AppColors.primaryGreen : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _hasText ? _sendMessage : null,
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Date separator
  Widget _buildDateSeparator(DateTime timestamp) => Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Divider(color: Colors.grey[300]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _formatDate(timestamp),
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
            Expanded(
              child: Divider(color: Colors.grey[300]),
            ),
          ],
        ),
      );

  // Message bubble
  Widget _buildMessageBubble(Message message, bool isMe) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: widget.avatarUrl != null
                    ? NetworkImage(widget.avatarUrl!)
                    : null,
                onBackgroundImageError:
                    widget.avatarUrl != null ? (_, __) {} : null,
                child: widget.avatarUrl == null
                    ? Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.grey[600],
                      )
                    : null,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.primaryGreen : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: isMe
                        ? const Radius.circular(20)
                        : const Radius.circular(4),
                    bottomRight: isMe
                        ? const Radius.circular(4)
                        : const Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        color: isMe ? Colors.white : Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.timestamp),
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            color: isMe
                                ? Colors.white.withValues(alpha: 0.8)
                                : Colors.grey[500],
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isRead ? Icons.done_all : Icons.done,
                            size: 14,
                            color: message.isRead
                                ? Colors.blue[300]
                                : Colors.white.withValues(alpha: 0.8),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  // Format time for message bubbles
  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour > 12
        ? timestamp.hour - 12
        : timestamp.hour == 0
            ? 12
            : timestamp.hour;
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  // Format date for separators
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      // Format as full date
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }

  // Check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) =>
      date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day;

  // Show emoji picker for enhanced messaging
  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 200,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 8,
                padding: const EdgeInsets.all(16),
                children: [
                  '😊',
                  '😂',
                  '❤️',
                  '👍',
                  '👎',
                  '😢',
                  '😮',
                  '😡',
                  '🎉',
                  '🔥',
                  '💯',
                  '👏',
                  '🙏',
                  '💪',
                  '✨',
                  '🌟',
                ]
                    .map(
                      (emoji) => GestureDetector(
                        onTap: () {
                          _messageController.text += emoji;
                          Navigator.pop(context);
                        },
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[100],
                          ),
                          child: Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Navigate to full user profile screen
  Future<void> _viewFullUserProfile() async {
    if (widget.otherUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User profile not available',
            style: GoogleFonts.montserrat(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.primaryGreen),
                const SizedBox(height: 16),
                Text(
                  'Loading profile...',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Fetch user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherUserId)
          .get();

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;

        // Convert Firestore data to UserModel
        final userModel = UserModel(
          id: widget.otherUserId,
          name: userData['name'] ?? widget.userName,
          age: userData['age'] ?? 0,
          imageUrl: List<String>.from(
            userData['photos'] ?? userData['imageUrl'] ?? [],
          ),
          address: userData['locationName'] ?? userData['address'],
          distanceBW: userData['distanceBW'],
          editInfo: userData['editInfo'] ?? {},
        );

        // Navigate to profile screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserDetailScreen(user: userModel),
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
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);

      log('Error loading user profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load profile',
            style: GoogleFonts.montserrat(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show user profile quick view (keeping for the info button)
  void _showUserProfile() {
    _viewFullUserProfile(); // Just redirect to full profile
  }

  // Build quick action button
  // ignore: unused_element
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: (color ?? AppColors.primaryGreen).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color ?? AppColors.primaryGreen,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: color ?? AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  // Show block user dialog
  // Show MVP-styled block user dialog
  void _showBlockUserDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning icon with MVP styling
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.block,
                color: Colors.red,
                size: 30,
              ),
            ),
            const SizedBox(height: 20),

            // Title with Poppins font
            Text(
              'Block ${widget.userName}?',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3748),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Description with MVP colors
            Text(
              'This will remove them from your matches, delete this conversation, and prevent future contact.',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: const Color(0xFF718096),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // MVP-styled action buttons
            Row(
              children: [
                // Cancel button with border
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF718096),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Block button with gradient and shadow
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE53E3E), Color(0xFFC53030)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE53E3E).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _blockUser();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Block',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Info text
            Text(
              'You can unblock them later in Settings',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: const Color(0xFFA0AEC0),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Show report user dialog
  void _showReportUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Report ${widget.userName}?',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Help us keep the community safe by reporting inappropriate behavior.',
          style: GoogleFonts.montserrat(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoonSnackBar('Report feature coming soon!');
            },
            child: Text(
              'Report',
              style: GoogleFonts.montserrat(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show clear chat dialog
  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear Chat History?',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'This will delete all messages in this conversation. This action cannot be undone.',
          style: GoogleFonts.montserrat(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoonSnackBar('Clear chat feature coming soon!');
            },
            child: Text(
              'Clear',
              style: GoogleFonts.montserrat(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show coming soon snackbar
  void _showComingSoonSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.montserrat(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
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

  // Block the user (called after confirmation from _showBlockUserDialog)
  Future<void> _blockUser() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (widget.otherUserId == null || currentUserId == null) return;

    // Show MVP-styled loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Loading indicator with MVP primary color
            Container(
              width: 50,
              height: 50,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Blocking user...',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2D3748),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      // Block the user using settings service
      final success = await SettingsService.blockUser(
        currentUserId,
        widget.otherUserId!,
        reason: 'Blocked from chat',
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (success) {
          // Show MVP-styled success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.green,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${widget.userName} has been blocked',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 3),
            ),
          );

          // Navigate back to messages list after a short delay
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pop(context); // Go back to messages list
            }
          });
        } else {
          _showErrorSnackBar('Failed to block user. Please try again.');
        }
      }
    } catch (e) {
      debugPrint('Error blocking user: $e');
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showErrorSnackBar('An error occurred while blocking the user.');
      }
    }
  }
}
