import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/user_model.dart';
import '../../messages/chat_thread_screen.dart';
import '../../messages/services/chat_service.dart';

class MatchProfileScreen extends StatefulWidget {
  const MatchProfileScreen({
    required this.user,
    super.key,
  });
  final UserModel user;

  @override
  State<MatchProfileScreen> createState() => _MatchProfileScreenState();
}

class _MatchProfileScreenState extends State<MatchProfileScreen>
    with SingleTickerProviderStateMixin {
  // Animation controller for like labelLarge
  late AnimationController _animationController;
  bool _isLiked = false;
  final ChatService _chatService = ChatService();
  bool _isLoadingMessage = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Start conversation with the matched user
  Future<void> _startConversation() async {
    if (_isLoadingMessage) return;

    setState(() {
      _isLoadingMessage = true;
    });

    try {
      unawaited(HapticFeedback.mediumImpact());
      // Get or create chat thread
      String? threadId = await _chatService.getChatThreadId(widget.user.id!);

      threadId ??= await _chatService.createChatThread(
        widget.user.id!,
        widget.user.name ?? 'User',
      );

      if (threadId != null && mounted) {
        // Navigate to chat thread
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatThreadScreen(
              threadId: threadId!,
              userName: widget.user.name ?? 'User',
              avatarUrl: widget.user.imageUrl?.isNotEmpty ?? false
                  ? widget.user.imageUrl![0]
                  : null,
              otherUserId: widget.user.id,
            ),
          ),
        );
      } else {
        throw Exception('Failed to create or find chat thread');
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString()}',
              style: GoogleFonts.montserrat(),
            ),
            backgroundColor: Colors.red.shade400,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMessage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Background color for the dating screens
    const Color backgroundColor = Colors.white;

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
          'Match Profile',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.brown.shade800,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Profile Card
            _buildProfileHeader(),

            // About Section
            _buildAboutSection(),

            // Interests Section
            _buildInterestsSection(),

            // Action Buttons
            _buildActionButtons(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Top profile card with image, name, age, location, and tags
  Widget _buildProfileHeader() => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Profile image
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Hero(
                tag: 'profile-${widget.user.id}',
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF008037),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(75),
                    child: widget.user.imageUrl != null &&
                            widget.user.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.user.imageUrl![0],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.person,
                                size: 80,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Name and age
            Text(
              '${widget.user.name}, ${widget.user.age}',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade800,
              ),
            ),

            const SizedBox(height: 4),

            // Location
            if (widget.user.living_in != null &&
                widget.user.living_in!.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.user.living_in!,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // Tags
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (widget.user.job_title != null &&
                      widget.user.job_title!.isNotEmpty)
                    _buildTag(widget.user.job_title!, true),
                  if (widget.user.profession != null &&
                      widget.user.profession!.isNotEmpty)
                    _buildTag(widget.user.profession!, false),
                  if (widget.user.education != null &&
                      widget.user.education!.isNotEmpty)
                    _buildTag(widget.user.education!, false),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      );

  // About section with bio
  Widget _buildAboutSection() => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About Me',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                widget.user.bio ?? 'No bio available',
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
      );

  // Interests section
  Widget _buildInterestsSection() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interests',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Profile Information',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );

  // Action labelLarges (Like, Pass, Message)
  Widget _buildActionButtons() => Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Pass labelLarge
            _buildCircleButton(
              icon: Icons.close,
              color: Colors.red.shade400,
              onTap: () {
                unawaited(HapticFeedback.mediumImpact());
                Navigator.pop(context);
              },
              label: 'Pass',
            ),

            // Like labelLarge
            _buildCircleButton(
              icon: _isLiked ? Icons.favorite : Icons.favorite_border,
              color: const Color(0xFF008037),
              onTap: () {
                unawaited(HapticFeedback.mediumImpact());
                setState(() {
                  _isLiked = !_isLiked;
                });
                _animationController.reset();
                unawaited(_animationController.forward());

                // Show a snackbar when liked
                if (_isLiked) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'You liked ${widget.user.name}!',
                        style: GoogleFonts.montserrat(),
                      ),
                      backgroundColor: const Color(0xFF008037),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              label: 'Like',
              isAnimated: true,
            ),

            // Message labelLarge
            _buildCircleButton(
              icon: _isLoadingMessage
                  ? Icons.hourglass_empty
                  : Icons.chat_bubble_outline,
              color: Colors.blue.shade400,
              onTap: _isLoadingMessage ? () {} : _startConversation,
              label: 'Message',
            ),
          ],
        ),
      );

  // Circle labelLarge with icon and label
  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String label,
    bool isAnimated = false,
  }) =>
      Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: isAnimated
                    ? AnimatedScale(
                        scale: _isLiked ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          icon,
                          color: color,
                          size: 30,
                        ),
                      )
                    : Icon(
                        icon,
                        color: color,
                        size: 30,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      );

  // Tag widget for profile attributes
  Widget _buildTag(String label, bool isPrimary) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isPrimary
              ? const Color(0xFF008037).withValues(alpha: 0.1)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPrimary ? const Color(0xFF008037) : Colors.grey[400]!,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isPrimary ? const Color(0xFF008037) : Colors.grey[700],
          ),
        ),
      );
}
