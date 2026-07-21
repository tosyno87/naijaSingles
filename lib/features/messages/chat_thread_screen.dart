import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../common/constants/app_colors.dart';
import '../../common/widgets/state_views/state_views.dart';
import '../../services/media_sharing_service.dart';
import '../../services/settings_service.dart';
import '../chat_shared/models/chat_message_view_model.dart';
import '../chat_shared/ui/widgets/chat_bubble.dart';
import '../chat_shared/ui/widgets/chat_composer.dart';
import '../dating/screens/user_detail_screen.dart';
import 'message_model.dart';
import 'services/chat_service.dart';
import 'services/matched_user_profile_loader.dart';
import 'services/participant_profile_resolver.dart';
import 'widgets/pre_meet_safety_sheet.dart';

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
  final MediaSharingService _mediaService = MediaSharingService();
  final ImagePicker _imagePicker = ImagePicker();
  final ParticipantProfileResolver _participantResolver =
      ParticipantProfileResolver();
  String? _currentUserId;
  Timer? _typingDebounce;
  Timer? _typingHeartbeat;
  bool _typingIndicatorActive = false;
  DateTime? _lastTypingWriteAt;
  bool _showSearch = false;
  String _searchQuery = '';
  String? _replyToMessageId;
  String? _replyPreview;
  int _lastMessageCount = 0;
  String? _lastMessageId;
  late String _displayName;
  String? _displayAvatarUrl;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _displayName = widget.userName;
    _displayAvatarUrl = widget.avatarUrl;

    // Do not setState here — rebuilding the message list while typing causes
    // visible shake. Composer watches the controller via ValueListenableBuilder.
    _messageController.addListener(_onComposerTextChanged);

    unawaited(_chatService.markThreadAsRead(widget.threadId));
    unawaited(_resolveParticipantDisplay());

    // Scroll to bottom when messages load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _onComposerTextChanged() {
    final bool hasText = _messageController.text.trim().isNotEmpty;
    if (!hasText) {
      _typingDebounce?.cancel();
      _typingHeartbeat?.cancel();
      _typingHeartbeat = null;
      if (_typingIndicatorActive) {
        _typingIndicatorActive = false;
        unawaited(_chatService.setTyping(widget.threadId, isTyping: false));
      }
      return;
    }

    // Write on start, then heartbeat every 4s so watchers (8s TTL) stay fresh
    // without a Firestore write on every keystroke.
    _publishTypingHeartbeat(force: !_typingIndicatorActive);
    _typingIndicatorActive = true;
    _typingHeartbeat ??= Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_typingIndicatorActive) return;
      _publishTypingHeartbeat(force: true);
    });

    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), () {
      _typingHeartbeat?.cancel();
      _typingHeartbeat = null;
      _typingIndicatorActive = false;
      unawaited(_chatService.setTyping(widget.threadId, isTyping: false));
    });
  }

  void _publishTypingHeartbeat({required bool force}) {
    final DateTime now = DateTime.now();
    final DateTime? last = _lastTypingWriteAt;
    if (!force && last != null && now.difference(last).inSeconds < 4) {
      return;
    }
    _lastTypingWriteAt = now;
    unawaited(_chatService.setTyping(widget.threadId, isTyping: true));
  }

  Future<void> _resolveParticipantDisplay() async {
    final String? otherUserId = widget.otherUserId;
    if (otherUserId == null || otherUserId.isEmpty) {
      return;
    }

    try {
      await _participantResolver.ensureMatchMirrors(
        currentUserId: _currentUserId ?? '',
        otherUserId: otherUserId,
      );

      final ParticipantDisplayInfo display = await _participantResolver.resolve(
        userId: otherUserId,
        cachedName: widget.userName,
        cachedAvatarUrl: widget.avatarUrl,
      );

      if (!mounted) return;

      setState(() {
        _displayName = display.name;
        _displayAvatarUrl = display.avatarUrl ?? widget.avatarUrl;
      });

      if (display.fromLiveProfile &&
          !ParticipantProfileResolver.isPlaceholderName(display.name)) {
        unawaited(
          _participantResolver.writeThroughThreadCache(
            threadId: widget.threadId,
            userId: otherUserId,
            name: display.name,
            avatarUrl: display.avatarUrl,
            cachedName: widget.userName,
            cachedAvatarUrl: widget.avatarUrl,
          ),
        );
      }
    } on Object catch (e) {
      log('Error resolving chat participant display: $e');
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onComposerTextChanged);
    _typingDebounce?.cancel();
    _typingHeartbeat?.cancel();
    if (_typingIndicatorActive) {
      unawaited(_chatService.setTyping(widget.threadId, isTyping: false));
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = false}) {
    if (!_scrollController.hasClients) {
      return;
    }
    // reverse: true ListView — visual bottom is offset 0.
    const double target = 0;
    final double current = _scrollController.position.pixels;
    if ((current - target).abs() < 1.0) {
      return;
    }
    if (animated) {
      unawaited(
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        ),
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  /// With [ListView.reverse], offset 0 is the newest messages.
  /// True when the user is still "following" the live conversation.
  bool get _isNearBottom {
    if (!_scrollController.hasClients) {
      return true;
    }
    return _scrollController.position.pixels <= 80;
  }

  Future<void> _pickAndSendImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;
      await _mediaService.shareImage(
        threadId: widget.threadId,
        imagePath: picked.path,
      );
      // StreamBuilder scrolls once the new message arrives — avoid a second
      // competing animateTo that causes the bounce.
    } on Object catch (error) {
      _showErrorSnackBar('Could not send image: $error');
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    // Validate message length locally
    if (text.length > 1000) {
      _showErrorSnackBar(
        'Message is too long. Please keep messages under 1000 characters.',
      );
      return;
    }

    try {
      final success = await _chatService.sendMessage(
        widget.threadId,
        text,
        replyToMessageId: _replyToMessageId,
      );
      if (success) {
        _messageController.clear();
        // Avoid rebuilding the message list unless the reply bar must close.
        if (_replyToMessageId != null || _replyPreview != null) {
          setState(() {
            _replyToMessageId = null;
            _replyPreview = null;
          });
        }
        // reverse ListView already shows the new bubble at the bottom —
        // do not jumpTo(0); that is what shook the screen on send.
      }
    } on Object catch (error) {
      _showErrorSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface, // Use MVP background color
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
                  backgroundImage: _displayAvatarUrl != null
                      ? NetworkImage(_displayAvatarUrl ?? '')
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
                      _displayName,
                      style: GoogleFonts.montserrat(
                        // Use Montserrat for MVP
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary, // Use MVP text color
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    StreamBuilder<List<String>>(
                      stream: _chatService.watchOtherUsersTyping(
                        widget.threadId,
                      ),
                      builder: (context, snapshot) {
                        final typing = snapshot.data?.isNotEmpty ?? false;
                        return Text(
                          typing ? 'typing...' : 'Tap to view profile',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            color: typing
                                ? AppColors.primaryGreen
                                : AppColors.textSecondary,
                            fontStyle:
                                typing ? FontStyle.italic : FontStyle.normal,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? Icons.close : Icons.search,
              color: AppColors.primaryGreen,
            ),
            onPressed: () => setState(() => _showSearch = !_showSearch),
          ),
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
                case 'safety':
                  unawaited(PreMeetSafetySheet.show(context));
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'safety',
                child: Text('Safety tips'),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Text(
                  'Block User',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Text(
                  'Report User',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Text(
                  'Clear Chat',
                  style: TextStyle(color: Colors.black87),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search in conversation',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          // Chat messages
          Expanded(
            child: RepaintBoundary(
              child: StreamBuilder<List<Message>>(
                stream: _chatService.getMessagesStream(widget.threadId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AppLoadingView(message: 'Loading messages...');
                  }

                  if (snapshot.hasError) {
                    return AppErrorView(
                      title: 'Unable to load messages',
                      message: 'Error loading messages',
                      onRetry: () => setState(() {}),
                    );
                  }

                  var messages = snapshot.data ?? [];
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    messages = messages
                        .where((m) => m.text.toLowerCase().contains(q))
                        .toList();
                  }

                  if (messages.isEmpty) {
                    return AppEmptyView(
                      title: 'No Messages Yet',
                      subtitle: 'Say hi to $_displayName!',
                      icon: Icons.chat_bubble_outline,
                    );
                  }

                  final String? newestId =
                      messages.isNotEmpty ? messages.last.id : null;
                  final bool shouldScroll =
                      messages.length != _lastMessageCount ||
                          newestId != _lastMessageId;
                  if (shouldScroll) {
                    _lastMessageCount = messages.length;
                    _lastMessageId = newestId;
                    // Capture before the new ListView lays out. After insert,
                    // reverse-list extent growth can push pixels past 80 even
                    // when the user was in the follow zone.
                    final bool followLiveEdge = _isNearBottom;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      // _scrollToBottom no-ops within 1px of 0 (avoids send shake).
                      if (followLiveEdge) {
                        _scrollToBottom();
                      }
                    });
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      // reverse: true → index 0 is the newest message.
                      final int messageIndex = messages.length - 1 - index;
                      final message = messages[messageIndex];
                      final isMe = message.senderId == _currentUserId;

                      final showDateSeparator = messageIndex == 0 ||
                          !_isSameDay(
                            messages[messageIndex].timestamp,
                            messages[messageIndex - 1].timestamp,
                          );

                      final vm = ChatMessageViewModel(
                        id: message.id,
                        text: message.text,
                        timestamp: message.timestamp,
                        senderId: message.senderId,
                        isOwnMessage: isMe,
                        senderAvatarUrl: isMe ? null : _displayAvatarUrl,
                        isRead: message.isRead,
                        showReadReceipt: true,
                        imageUrl: message.imageUrl,
                      );

                      return Column(
                        children: [
                          if (showDateSeparator)
                            _buildDateSeparator(message.timestamp),
                          GestureDetector(
                            onLongPress: () => _showMessageActions(message.id),
                            child: ChatBubble(message: vm),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),

          if (_replyPreview != null)
            Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Replying: $_replyPreview',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _replyToMessageId = null;
                      _replyPreview = null;
                    }),
                  ),
                ],
              ),
            ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _messageController,
            builder: (BuildContext context, TextEditingValue value, _) {
              final bool hasText = value.text.trim().isNotEmpty;
              return ChatComposer(
                controller: _messageController,
                onSend: _sendMessage,
                hasText: hasText,
                showAttachButton: true,
                onAttachTap: _pickAndSendImage,
                showEmojiButton: true,
                onEmojiTap: _showEmojiPicker,
              );
            },
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
    unawaited(
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
      unawaited(
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
                  const CircularProgressIndicator(
                    color: AppColors.primaryGreen,
                  ),
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
        ),
      );

      final userModel = await MatchedUserProfileLoader.load(
        firestore: FirebaseFirestore.instance,
        userId: widget.otherUserId!,
        fallbackName: _displayName,
        fallbackAvatarUrl: _displayAvatarUrl,
      );

      final String? loadedName = userModel.name;
      final String? loadedAvatar =
          (userModel.imageUrl != null && userModel.imageUrl!.isNotEmpty)
              ? userModel.imageUrl!.first as String?
              : null;
      if (loadedName != null && loadedName.trim().isNotEmpty) {
        unawaited(
          _participantResolver.writeThroughThreadCache(
            threadId: widget.threadId,
            userId: widget.otherUserId!,
            name: loadedName.trim(),
            avatarUrl: loadedAvatar,
            cachedName: _displayName,
            cachedAvatarUrl: _displayAvatarUrl,
          ),
        );
        if (mounted) {
          setState(() {
            _displayName = loadedName.trim();
            if (loadedAvatar != null && loadedAvatar.isNotEmpty) {
              _displayAvatarUrl = loadedAvatar;
            }
          });
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }

      if (!mounted) {
        return;
      }

      unawaited(
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserDetailScreen(
              user: userModel,
              showLikeActions: false,
            ),
          ),
        ),
      );
    } on Object catch (e) {
      if (mounted) {
        Navigator.pop(context);
      }

      log('Error loading user profile: $e');
      if (!mounted) {
        return;
      }

      final fallbackUser = MatchedUserProfileLoader.buildFallback(
        userId: widget.otherUserId!,
        fallbackName: _displayName,
        fallbackAvatarUrl: _displayAvatarUrl,
      );

      unawaited(
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserDetailScreen(
              user: fallbackUser,
              showLikeActions: false,
            ),
          ),
        ),
      );
    }
  }

  // Show user profile quick view (keeping for the info button)
  void _showUserProfile() {
    unawaited(_viewFullUserProfile());
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
    unawaited(
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
                'Block $_displayName?',
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
                            color:
                                const Color(0xFFE53E3E).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          unawaited(_blockUser());
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
      ),
    );
  }

  // Show report user dialog with reason picker
  void _showReportUserDialog() {
    String? selectedReason;
    final reasons = [
      'Harassment',
      'Spam',
      'Fake profile',
      'Inappropriate content',
      'Other',
    ];

    unawaited(
      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.report,
                    color: Colors.orange,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Report $_displayName?',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Help us keep the community safe by selecting a reason.',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: const Color(0xFF718096),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ...reasons.map(
                  (reason) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () =>
                          setDialogState(() => selectedReason = reason),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedReason == reason
                                ? Colors.orange
                                : Colors.grey.shade300,
                            width: selectedReason == reason ? 2 : 1,
                          ),
                          color: selectedReason == reason
                              ? Colors.orange.withValues(alpha: 0.05)
                              : Colors.white,
                        ),
                        child: Text(
                          reason,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: selectedReason == reason
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: const Color(0xFF2D3748),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.montserrat(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: selectedReason == null
                            ? null
                            : () {
                                Navigator.pop(context);
                                unawaited(_submitReport(selectedReason!));
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          disabledBackgroundColor: Colors.grey.shade300,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Report',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
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

  Future<void> _submitReport(String reason) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final otherUserId = widget.otherUserId;
    if (currentUserId == null || otherUserId == null) {
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'reporterId': currentUserId,
        'reportedUserId': otherUserId,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'context': 'chat_thread',
        'threadId': widget.threadId,
      });

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Report submitted. We\'ll review it shortly.',
            style: GoogleFonts.montserrat(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } on Object catch (e) {
      debugPrint('Error submitting report: $e');
      if (!mounted) {
        return;
      }
      _showErrorSnackBar('Failed to submit report. Please try again.');
    }
  }

  // Show clear chat dialog
  void _showClearChatDialog() {
    unawaited(
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.clear_all,
                  color: Colors.red,
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Clear Chat History?',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Messages will be hidden from your view. This cannot be undone.',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: const Color(0xFF718096),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.montserrat(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        unawaited(_clearChat());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Clear',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
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
    );
  }

  /// Soft-delete: stamp `clearedAt` on the thread so the client hides older
  /// messages. We cannot hard-delete the other user's messages because
  /// Firestore rules restrict delete to the message sender.
  Future<void> _clearChat() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('chatThreads')
          .doc(widget.threadId)
          .update({
        'clearedAt.$currentUserId': FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Chat history cleared.',
            style: GoogleFonts.montserrat(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } on Object catch (e) {
      debugPrint('Error clearing chat: $e');
      if (!mounted) {
        return;
      }
      _showErrorSnackBar('Failed to clear chat. Please try again.');
    }
  }

  // Show error snackbar
  Future<void> _showMessageActions(String messageId) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () => Navigator.pop(ctx, 'reply'),
            ),
            ListTile(
              leading: const Icon(Icons.emoji_emotions_outlined),
              title: const Text('React'),
              onTap: () => Navigator.pop(ctx, 'react'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'reply') {
      setState(() {
        _replyToMessageId = messageId;
        _replyPreview = _messageController.text.isNotEmpty
            ? _messageController.text
            : 'message';
      });
    } else if (action == 'react') {
      await _chatService.addReaction(
        threadId: widget.threadId,
        messageId: messageId,
        emoji: '❤️',
      );
    }
  }

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
    final otherUserId = widget.otherUserId;
    if (otherUserId == null || currentUserId == null) {
      return;
    }

    // Track the dialog's navigator so we dismiss the correct route even
    // if the timing is tight.
    NavigatorState? dialogNav;
    bool dialogOpen = false;
    bool dismissPending = false;

    void tryDismissDialog() {
      if (dialogOpen && dialogNav != null && dialogNav!.mounted) {
        dialogNav!.pop();
        dialogOpen = false;
        dismissPending = false;
      } else {
        dismissPending = true;
      }
    }

    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          dialogNav = Navigator.of(dialogContext);
          dialogOpen = true;
          if (dismissPending) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (dialogOpen && dialogNav != null && dialogNav!.mounted) {
                dialogNav!.pop();
                dialogOpen = false;
                dismissPending = false;
              }
            });
          }
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.all(32),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
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
          );
        },
      ).then((_) {
        dialogOpen = false;
        dismissPending = false;
      }),
    );

    try {
      final success = await SettingsService.blockUser(
        currentUserId,
        otherUserId,
        reason: 'Blocked from chat',
      );

      if (!mounted) {
        return;
      }
      tryDismissDialog();

      if (success) {
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
                      '$_displayName has been blocked',
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

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      } else {
        _showErrorSnackBar('Failed to block user. Please try again.');
      }
    } on Object catch (e) {
      debugPrint('Error blocking user: $e');
      if (!mounted) {
        return;
      }
      tryDismissDialog();
      _showErrorSnackBar('An error occurred while blocking the user.');
    }
  }
}
