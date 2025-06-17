import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatThreadScreen extends StatefulWidget {
  final String threadId;
  final String userName;

  const ChatThreadScreen({
    Key? key,
    required this.threadId,
    required this.userName,
  }) : super(key: key);

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Load dummy messages
    _loadDummyMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadDummyMessages() {
    // Add some dummy messages for demonstration
    _messages.addAll([
      ChatMessage(
        text: 'Hi there! How are you?',
        isMe: false,
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      ),
      ChatMessage(
        text: 'I\'m good, thanks for asking! How about you?',
        isMe: true,
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 1, minutes: 45)),
      ),
      ChatMessage(
        text: 'I\'m doing well. What are your plans for the weekend?',
        isMe: false,
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 1, minutes: 30)),
      ),
      ChatMessage(
        text: 'I\'m thinking of checking out that new restaurant in town. Would you like to join me?',
        isMe: true,
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
      ),
      ChatMessage(
        text: 'That sounds great! I\'d love to join you.',
        isMe: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      ChatMessage(
        text: 'Perfect! How about Saturday at 7pm?',
        isMe: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      ChatMessage(
        text: 'Saturday at 7pm works for me. Looking forward to it!',
        isMe: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
    ]);
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          text: _messageController.text.trim(),
          isMe: true,
          timestamp: DateTime.now(),
        ),
      );
      _messageController.clear();
    });

    // Scroll to bottom after sending message
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Simulate reply after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: 'Thanks for your message! This is a demo reply.',
              isMe: false,
              timestamp: DateTime.now(),
            ),
          );
        });

        // Scroll to bottom after receiving reply
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Background color for the dating screens
    const Color backgroundColor = Color(0xFFFDF6EC);
    
    // Deep green color for accents
    const Color deepGreen = Color(0xFF008037);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: deepGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Hero(
              tag: 'avatar-${widget.threadId}',
              child: CircleAvatar(
                radius: 16,
                backgroundImage: const AssetImage('assets/images/placeholder_profile.jpg'),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.userName,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: deepGreen),
            onPressed: () {
              // Call functionality to be implemented
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Call feature coming soon!',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: deepGreen,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: deepGreen),
            onPressed: () {
              // More options functionality to be implemented
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          
          // Typing indicator
          if (_isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Text(
                '${widget.userName} is typing...',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
            ),
          
          // Message input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.grey),
                  onPressed: () {
                    // Attachment functionality to be implemented
                  },
                ),
                Expanded(
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
                        vertical: 10,
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
                      // Simulate typing indicator
                      if (value.isNotEmpty && !_isTyping) {
                        setState(() {
                          _isTyping = true;
                        });
                        Future.delayed(const Duration(seconds: 3), () {
                          if (mounted) {
                            setState(() {
                              _isTyping = false;
                            });
                          }
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: deepGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Message bubble
  Widget _buildMessageBubble(ChatMessage message) {
    final isMe = message.isMe;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: const AssetImage('assets/images/placeholder_profile.jpg'),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF008037) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                  bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
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
                      fontSize: 14,
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: isMe ? Colors.white.withOpacity(0.7) : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (isMe) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.check_circle,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ],
      ),
    );
  }
  
  // Format time for message bubbles
  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour;
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}

// Model class for chat messages
class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
  });
}
