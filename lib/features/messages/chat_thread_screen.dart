import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../common/constants/colors.dart'; // Import MVP colors
import 'services/chat_service.dart';
import 'message_model.dart';

class ChatThreadScreen extends StatefulWidget {
  final String threadId;
  final String userName;
  final String? avatarUrl;
  final String? otherUserId;

  const ChatThreadScreen({
    Key? key,
    required this.threadId,
    required this.userName,
    this.avatarUrl,
    this.otherUserId,
  }) : super(key: key);

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

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Validate message length locally
    if (text.length > 1000) {
      _showErrorSnackBar('Message is too long. Please keep messages under 1000 characters.');
      return;
    }

    _chatService.sendMessage(widget.threadId, text).then((success) {
      if (success) {
        _messageController.clear();
        // Scroll to bottom after sending message
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    }).catchError((error) {
      _showErrorSnackBar(error.toString().replaceAll('Exception: ', ''));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor, // Use MVP background color
      appBar: AppBar(
        backgroundColor: cardColor, // Use MVP card color
        elevation: 1,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: primaryColor), // Use MVP primary color
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Hero(
              tag: 'avatar-${widget.threadId}',
              child: CircleAvatar(
                radius: 16,
                backgroundImage: widget.avatarUrl != null
                    ? NetworkImage(widget.avatarUrl!)
                    : const AssetImage('assets/images/placeholder_profile.jpg') as ImageProvider,
                onBackgroundImageError: (_, __) {},
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.userName,
              style: GoogleFonts.montserrat( // Use Montserrat for MVP
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary, // Use MVP text color
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.videocam, color: primaryColor),
            onPressed: _showCallOptions,
          ),
          IconButton(
            icon: Icon(Icons.info_outline, color: primaryColor),
            onPressed: _showUserProfile,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: primaryColor),
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
                      style: GoogleFonts.poppins(color: Colors.red),
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
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Say hi to ${widget.userName}!',
                          style: GoogleFonts.montserrat( // Use Montserrat for MVP
                            fontSize: 14,
                            color: primaryColor, // Use MVP primary color
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUserId;
                    
                    // Group messages by date
                    final showDateSeparator = index == 0 || 
                        !_isSameDay(messages[index].timestamp, messages[index - 1].timestamp);
                    
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
                    icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
                    onPressed: _showEmojiPicker,
                  ),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: GoogleFonts.poppins(
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
                        style: GoogleFonts.poppins(
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
                      color: _hasText ? primaryColor : Colors.grey[300],
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
  Widget _buildDateSeparator(DateTime timestamp) {
    return Container(
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
              style: GoogleFonts.poppins(
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
  }
  
  // Message bubble
  Widget _buildMessageBubble(Message message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: widget.avatarUrl != null
                  ? NetworkImage(widget.avatarUrl!)
                  : null,
              onBackgroundImageError: widget.avatarUrl != null 
                  ? (_, __) {} 
                  : null,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? primaryColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
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
                    style: GoogleFonts.poppins(
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
                        style: GoogleFonts.poppins(
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
  }
  
  // Format time for message bubbles
  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour == 0 ? 12 : timestamp.hour;
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
  
  // Format date for separators
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      // Format as full date
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }
  
  // Check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }
  
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
                  '😊', '😂', '❤️', '👍', '👎', '😢', '😮', '😡',
                  '🎉', '🔥', '💯', '👏', '🙏', '💪', '✨', '🌟',
                ].map((emoji) => GestureDetector(
                  onTap: () {
                    _messageController.text += emoji;
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[100],
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Show call options
  void _showCallOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            ListTile(
              leading: Icon(Icons.call, color: primaryColor),
              title: Text(
                'Voice Call',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                _showComingSoonSnackBar('Voice call feature coming soon!');
              },
            ),
            ListTile(
              leading: Icon(Icons.videocam, color: primaryColor),
              title: Text(
                'Video Call',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                _showComingSoonSnackBar('Video call feature coming soon!');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  // Show user profile quick view
  void _showUserProfile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Profile header
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: widget.avatarUrl != null
                          ? NetworkImage(widget.avatarUrl!)
                          : null,
                      child: widget.avatarUrl == null
                          ? Icon(Icons.person, size: 50, color: Colors.grey[600])
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.userName,
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to view full profile',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Quick actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildQuickActionButton(
                          icon: Icons.call,
                          label: 'Call',
                          onTap: () {
                            Navigator.pop(context);
                            _showCallOptions();
                          },
                        ),
                        _buildQuickActionButton(
                          icon: Icons.block,
                          label: 'Block',
                          color: Colors.red,
                          onTap: () {
                            Navigator.pop(context);
                            _showBlockUserDialog();
                          },
                        ),
                        _buildQuickActionButton(
                          icon: Icons.report,
                          label: 'Report',
                          color: Colors.orange,
                          onTap: () {
                            Navigator.pop(context);
                            _showReportUserDialog();
                          },
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Full profile button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showComingSoonSnackBar('Full profile view coming soon!');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'View Full Profile',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build quick action button
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: (color ?? primaryColor).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color ?? primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: color ?? primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  // Show block user dialog
  void _showBlockUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Block ${widget.userName}?',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        content: Text(
          'You won\'t be able to see each other\'s profiles or send messages.',
          style: GoogleFonts.montserrat(
            color: textSecondary,
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
              _showComingSoonSnackBar('Block feature coming soon!');
            },
            child: Text(
              'Block',
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
            color: textPrimary,
          ),
        ),
        content: Text(
          'Help us keep the community safe by reporting inappropriate behavior.',
          style: GoogleFonts.montserrat(
            color: textSecondary,
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
            color: textPrimary,
          ),
        ),
        content: Text(
          'This will delete all messages in this conversation. This action cannot be undone.',
          style: GoogleFonts.montserrat(
            color: textSecondary,
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
        backgroundColor: primaryColor,
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
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
