import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../dating/screens/match_profile_screen.dart';
import 'message_thread_model.dart';
import 'chat_thread_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  // Sample data for message threads
  final List<MessageThread> _messageThreads = [
    MessageThread(
      matchId: '1',
      name: 'Amina',
      avatarUrl: 'assets/images/placeholder_profile.jpg',
      lastMessage: 'Hey, how are you doing today?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      isOnline: true,
      unread: true,
    ),
    MessageThread(
      matchId: '2',
      name: 'Tunde',
      avatarUrl: 'assets/images/placeholder_profile.jpg',
      lastMessage: 'I\'ll be there in 10 minutes',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      isOnline: false,
      unread: false,
    ),
    MessageThread(
      matchId: '3',
      name: 'Ngozi',
      avatarUrl: 'assets/images/placeholder_profile.jpg',
      lastMessage: 'That sounds great! Looking forward to it.',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      isOnline: true,
      unread: true,
    ),
    MessageThread(
      matchId: '4',
      name: 'Kwame',
      avatarUrl: 'assets/images/placeholder_profile.jpg',
      lastMessage: 'Did you see the new restaurant that opened?',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isOnline: false,
      unread: false,
    ),
    MessageThread(
      matchId: '5',
      name: 'Zainab',
      avatarUrl: 'assets/images/placeholder_profile.jpg',
      lastMessage: 'Thanks for the recommendation!',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      isOnline: true,
      unread: false,
    ),
    MessageThread(
      matchId: '6',
      name: 'Chijioke',
      avatarUrl: 'assets/images/placeholder_profile.jpg',
      lastMessage: 'Let\'s meet up this weekend',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      isOnline: false,
      unread: true,
    ),
    MessageThread(
      matchId: '7',
      name: 'Fatima',
      avatarUrl: 'assets/images/placeholder_profile.jpg',
      lastMessage: 'I enjoyed our conversation yesterday',
      timestamp: DateTime.now().subtract(const Duration(days: 4)),
      isOnline: false,
      unread: false,
    ),
  ];

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: deepGreen),
          onPressed: () => Navigator.pop(context),
        ),
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
      body: _messageThreads.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              itemCount: _messageThreads.length,
              itemBuilder: (context, index) {
                final thread = _messageThreads[index];
                return _buildMessageThreadItem(thread);
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
  Widget _buildMessageThreadItem(MessageThread thread) {
    return InkWell(
      onTap: () {
        // Mark as read when tapped
        setState(() {
          final index = _messageThreads.indexWhere((t) => t.matchId == thread.matchId);
          if (index != -1) {
            _messageThreads[index] = MessageThread(
              matchId: thread.matchId,
              name: thread.name,
              avatarUrl: thread.avatarUrl,
              lastMessage: thread.lastMessage,
              timestamp: thread.timestamp,
              isOnline: thread.isOnline,
              unread: false, // Mark as read
            );
          }
        });
        
        // Navigate to chat thread screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatThreadScreen(threadId: thread.matchId, userName: thread.name),
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
                  tag: 'avatar-${thread.matchId}',
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: AssetImage(thread.avatarUrl),
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
                        thread.name,
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
