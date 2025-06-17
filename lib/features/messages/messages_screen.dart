import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'services/chat_service.dart';
import 'message_model.dart';
import 'chat_thread_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    // Background color for the dating screens
    const Color backgroundColor = Color(0xFFFDF6EC);
    
    // Deep green color for accents
    const Color deepGreen = Color(0xFF008037);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Text(
          'Messages',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.brown.shade800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: deepGreen),
            onPressed: () {
              // Search functionality to be implemented
            },
          ),
        ],
      ),
      body: StreamBuilder<List<MessageThreadInfo>>(
        stream: _chatService.getChatThreadsStream(),
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
          
          final threads = snapshot.data ?? [];
          
          if (threads.isEmpty) {
            return _buildEmptyState();
          }
          
          return ListView.builder(
            itemCount: threads.length,
            itemBuilder: (context, index) {
              final thread = threads[index];
              return _buildMessageThreadItem(thread);
            },
          );
        },
      ),
    );
  }
  
  // Empty state when there are no messages
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start matching with people to begin conversations',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  // Message thread item
  Widget _buildMessageThreadItem(MessageThreadInfo thread) {
    return InkWell(
      onTap: () {
        // Mark as read when tapped
        _chatService.markThreadAsRead(thread.threadId);
        
        // Navigate to chat thread screen
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
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: thread.unread ? const Color(0xFFF0F8F1) : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                Hero(
                  tag: 'avatar-${thread.threadId}',
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: thread.avatarUrl != null
                        ? NetworkImage(thread.avatarUrl!)
                        : const AssetImage('assets/images/placeholder_profile.jpg') as ImageProvider,
                    onBackgroundImageError: (_, __) {},
                  ),
                ),
                if (thread.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Message content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        thread.otherUserName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: thread.unread ? FontWeight.bold : FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        thread.getRelativeTime(),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: thread.unread ? const Color(0xFF008037) : Colors.grey[500],
                          fontWeight: thread.unread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          thread.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: thread.unread ? Colors.black87 : Colors.grey[600],
                            fontWeight: thread.unread ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (thread.unread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFF008037),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
