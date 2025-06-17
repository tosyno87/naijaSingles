import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart';

import '../../messages/services/chat_service.dart';
import '../../messages/chat_thread_screen.dart';

class MatchConfirmationModal extends StatefulWidget {
  final String currentUserImageUrl;
  final String matchedUserImageUrl;
  final String matchedUserName;
  final String matchedUserId;

  const MatchConfirmationModal({
    Key? key,
    required this.currentUserImageUrl,
    required this.matchedUserImageUrl,
    required this.matchedUserName,
    required this.matchedUserId,
  }) : super(key: key);

  @override
  State<MatchConfirmationModal> createState() => _MatchConfirmationModalState();
}

class _MatchConfirmationModalState extends State<MatchConfirmationModal> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final ChatService _chatService = ChatService();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Handle sending a message to the matched user
  Future<void> _handleSendMessage() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // Create or get chat thread
      final threadId = await _chatService.createChatThread(
        widget.matchedUserId,
        widget.matchedUserName,
      );
      
      if (threadId != null) {
        if (!mounted) return;
        
        // Close the modal
        Navigator.pop(context);
        
        // Navigate to chat thread
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatThreadScreen(
              threadId: threadId,
              userName: widget.matchedUserName,
              avatarUrl: widget.matchedUserImageUrl,
              otherUserId: widget.matchedUserId,
            ),
          ),
        );
      } else {
        // Show error
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create chat. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      debugPrint('Error in _handleSendMessage: $e');
      // Show error
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again later.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isWideScreen = screenSize.width > 400;
    
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF6EC),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF008037).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: const Color(0xFF008037).withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Celebration animation would go here
                // Using a placeholder for now
                Container(
                  height: 60,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.favorite,
                    color: Color(0xFF008037),
                    size: 50,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Title with fade animation
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    "💚 It's a Match!",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4E2B1B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Subtitle with fade animation
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    "You and ${widget.matchedUserName} like each other",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: const Color(0xFF4E2B1B).withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Profile pictures
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Current user avatar
                    _buildProfileAvatar(widget.currentUserImageUrl),
                    
                    const SizedBox(width: 20),
                    
                    // Heart icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF008037).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Color(0xFF008037),
                        size: 24,
                      ),
                    ),
                    
                    const SizedBox(width: 20),
                    
                    // Matched user avatar
                    _buildProfileAvatar(widget.matchedUserImageUrl),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Action buttons
                isWideScreen
                    ? _buildHorizontalButtons()
                    : _buildVerticalButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildProfileAvatar(String imageUrl) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF008037).withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[300],
            child: const Icon(
              Icons.person,
              size: 50,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHorizontalButtons() {
    return Row(
      children: [
        // Keep Exploring button
        Expanded(
          child: OutlinedButton(
            onPressed: _isProcessing ? null : () {
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: _isProcessing ? Colors.grey : const Color(0xFF008037),
                width: 2,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Keep Exploring',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _isProcessing ? Colors.grey : const Color(0xFF008037),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Send Message button
        Expanded(
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _handleSendMessage,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008037),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              disabledBackgroundColor: Colors.grey,
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Send Message',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildVerticalButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Send Message button
        ElevatedButton(
          onPressed: _isProcessing ? null : _handleSendMessage,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF008037),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            disabledBackgroundColor: Colors.grey,
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Send Message',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
        
        const SizedBox(height: 12),
        
        // Keep Exploring button
        OutlinedButton(
          onPressed: _isProcessing ? null : () {
            Navigator.pop(context);
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: _isProcessing ? Colors.grey : const Color(0xFF008037),
              width: 2,
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            'Keep Exploring',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _isProcessing ? Colors.grey : const Color(0xFF008037),
            ),
          ),
        ),
      ],
    );
  }
}
