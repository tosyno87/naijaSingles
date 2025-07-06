import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer';

import 'services/chat_service.dart';
import 'message_model.dart';
import 'chat_thread_screen.dart';
import '../explore/explore_screen.dart'; // Import ExploreScreen directly
import '../dating/screens/user_detail_screen.dart'; // Import for profile viewing
import '../../models/user_model.dart'; // Import UserModel

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final ChatService _chatService = ChatService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Afropeep MVP Color Scheme
  static const Color backgroundColor = Color(0xFFFFF6E5); // Light cream
  static const Color primaryColor = Color(0xFF008037); // Deep green
  static const Color cardColor = Color(0xFFFFFFFF); // White for cards
  static final Color textPrimary = Colors.brown.shade800;
  static final Color textSecondary = Colors.brown.shade600;
  static final Color textLight = Colors.grey.shade600;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: textPrimary), // Fix back arrow color
        title: Text(
          'Messages',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: primaryColor, size: 28),
            onPressed: () {
              _showSearchDialog();
            },
          ),
        ],
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
  }

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
      List<MessageThreadInfo> threads = [];
      
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
          
          // Get other user's data
          final otherUserDoc = await _firestore.collection('users').doc(otherUserId).get();
          String otherUserName = 'User';
          String? avatarUrl;
          
          if (otherUserDoc.exists) {
            final userData = otherUserDoc.data() as Map<String, dynamic>?;
            otherUserName = userData?['name'] ?? 'User';
            
            // Get first photo as avatar
            final photos = userData?['photos'] as List<dynamic>?;
            if (photos != null && photos.isNotEmpty) {
              avatarUrl = photos.first as String?;
            }
          }
          
          // Get unread count for current user
          final unreadCount = data['unreadCount'] as Map<String, dynamic>?;
          final unread = (unreadCount?[currentUserId] ?? 0) > 0;
          
          threads.add(MessageThreadInfo(
            threadId: doc.id,
            otherUserId: otherUserId,
            otherUserName: otherUserName,
            lastMessage: data['lastMessageText'] ?? 'Say hello!',
            lastMessageSenderId: data['lastMessageSenderId'],
            timestamp: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
            unread: unread,
            avatarUrl: avatarUrl,
            isOnline: false, // TODO: Implement online status
          ));
        } catch (e) {
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
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
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
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
                // Navigate directly to ExploreScreen with back labelLarge
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ExploreScreen(showBackButton: true),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
  }

  Widget _buildMessagesList(List<MessageThreadInfo> threads) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: threads.length,
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final thread = threads[index];
        return _buildMessageThreadItem(thread);
      },
    );
  }

  Widget _buildMessageThreadItem(MessageThreadInfo thread) {
    return Dismissible(
      key: Key(thread.threadId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 24,
        ),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(thread);
      },
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
              ? Border.all(color: primaryColor.withValues(alpha: 0.3), width: 1.5)
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
                              color: thread.unread ? primaryColor : Colors.grey.shade300,
                              width: thread.unread ? 2.5 : 1,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.grey.shade100,
                            backgroundImage: thread.avatarUrl != null
                                ? NetworkImage(thread.avatarUrl!)
                                : null,
                            onBackgroundImageError: thread.avatarUrl != null 
                                ? (_, __) {} 
                                : null,
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
                          child: Icon(
                            Icons.visibility,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                      // Online indicator
                      if (thread.isOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                              border: Border.all(color: cardColor, width: 3),
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
                                onTap: () => _viewUserProfile(thread.otherUserId),
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
                                      color: primaryColor.withOpacity(0.7),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Text(
                              thread.getRelativeTime(),
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: thread.unread ? primaryColor : textLight,
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
                            color: thread.unread ? textPrimary : textSecondary,
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
  }

  void _openChatThread(MessageThreadInfo thread) {
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
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Search Messages',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        content: Text(
          'Search functionality coming soon!',
          style: GoogleFonts.montserrat(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.montserrat(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Show delete confirmation dialog
  Future<bool?> _showDeleteConfirmation(MessageThreadInfo thread) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Conversation',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete your conversation with ${thread.otherUserName}? This action cannot be undone.',
          style: GoogleFonts.montserrat(
            color: textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context, true);
              await _deleteChatThread(thread);
            },
            child: Text(
              'Delete',
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
  
  // Delete chat thread with loading indicator
  Future<void> _deleteChatThread(MessageThreadInfo thread) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: primaryColor),
            const SizedBox(height: 16),
            Text(
              'Deleting conversation...',
              style: GoogleFonts.montserrat(
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
    
    try {
      final success = await _chatService.deleteChatThread(thread.threadId);
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Conversation deleted',
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } else {
        // Show error message
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
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Show error message
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

  // Method to view user profile from messages
  Future<void> _viewUserProfile(String userId) async {
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
                CircularProgressIndicator(color: primaryColor),
                const SizedBox(height: 16),
                Text(
                  'Loading profile...',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Fetch user data from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        
        // Convert Firestore data to UserModel
        final userModel = UserModel(
          id: userId,
          name: userData['name'] ?? 'Unknown User',
          age: userData['age'] ?? 0,
          imageUrl: List<String>.from(userData['photos'] ?? userData['imageUrl'] ?? []),
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
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
            style: GoogleFonts.poppins(color: Colors.white),
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
