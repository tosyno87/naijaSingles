import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/match_bloc.dart';
import '../../../models/user_model.dart';
import '../../../common/constants/colors.dart';

class MatchNotificationDialog extends StatefulWidget {
  final String matchId;
  final String otherUserId;
  final String? chatThreadId;
  final UserModel? otherUser;

  const MatchNotificationDialog({
    Key? key,
    required this.matchId,
    required this.otherUserId,
    this.chatThreadId,
    this.otherUser,
  }) : super(key: key);

  @override
  State<MatchNotificationDialog> createState() => _MatchNotificationDialogState();
}

class _MatchNotificationDialogState extends State<MatchNotificationDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _dismissDialog() {
    context.read<MatchBloc>().add(const DismissMatchNotificationEvent());
    Navigator.of(context).pop();
  }

  void _goToChat() {
    if (widget.chatThreadId != null) {
      Navigator.of(context).pop();
      // Navigate to chat screen
      Navigator.pushNamed(
        context,
        '/chat',
        arguments: {
          'threadId': widget.chatThreadId,
          'otherUserId': widget.otherUserId,
          'otherUserName': widget.otherUser?.name ?? 'User',
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withValues(alpha: 0.9),
                  primaryColor.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Match icon with animation
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Match text
                const Text(
                  "It's a Match! 🎉",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12),
                
                Text(
                  "You and ${widget.otherUser?.name ?? 'this person'} liked each other!",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // User avatars (if available)
                if (widget.otherUser?.imageUrl?.isNotEmpty == true)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Current user avatar placeholder
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      
                      const SizedBox(width: 20),
                      
                      // Heart icon
                      const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 30,
                      ),
                      
                      const SizedBox(width: 20),
                      
                      // Other user avatar
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          image: DecorationImage(
                            image: NetworkImage(widget.otherUser!.imageUrl![0]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                
                const SizedBox(height: 30),
                
                // Action labelLarges
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _dismissDialog,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Keep Swiping',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _goToChat,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          'Say Hello!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper function to show the match dialog
void showMatchDialog(
  BuildContext context, {
  required String matchId,
  required String otherUserId,
  String? chatThreadId,
  UserModel? otherUser,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => MatchNotificationDialog(
      matchId: matchId,
      otherUserId: otherUserId,
      chatThreadId: chatThreadId,
      otherUser: otherUser,
    ),
  );
}
