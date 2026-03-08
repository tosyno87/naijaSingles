import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/constants/app_colors.dart';
import '../../chat_shared/models/chat_message_view_model.dart';
import '../../chat_shared/ui/widgets/chat_bubble.dart';
import '../../chat_shared/ui/widgets/chat_composer.dart';
import '../../chat_shared/ui/widgets/chat_state_views.dart';
import '../data/services/group_chat_service.dart';

/// Group chat screen for displaying and managing group conversations
class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({
    required this.groupId,
    super.key,
  });
  final String groupId;

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final GroupChatService _groupChatService = GroupChatService();
  final TextEditingController _messageController = TextEditingController();
  GroupChat? _group;
  bool _isLoading = true;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
    unawaited(_loadGroupDetails());
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupDetails() async {
    try {
      final group = await _groupChatService.getGroupDetails(widget.groupId);

      if (mounted) {
        setState(() {
          _group = group;
          _isLoading = false;
        });
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load group details: $e');
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    try {
      _messageController.clear();
      await _groupChatService.sendGroupMessage(
        groupId: widget.groupId,
        text: text,
      );
    } on Object {
      _showErrorSnackBar('Failed to send message');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          title: Text(
            'Loading...',
            style: GoogleFonts.montserrat(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      );
    }

    if (_group == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          title: Text(
            'Group Not Found',
            style: GoogleFonts.montserrat(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const Center(
          child: Text('Group not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _group!.name,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${_group!.memberCount} members',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.info_outline,
              color: AppColors.textSecondary,
            ),
            onPressed: _showGroupInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<List<GroupMessage>>(
              stream: _groupChatService.getGroupMessages(widget.groupId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ChatLoadingView();
                }

                if (snapshot.hasError) {
                  return ChatErrorView(
                    message: 'Error: ${snapshot.error}',
                  );
                }

                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return ChatEmptyView(
                    subtitle: 'Start the conversation!',
                    subtitleColor: Colors.grey[500],
                  );
                }

                final currentUid =
                    FirebaseAuth.instance.currentUser?.uid;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isOwn = message.senderId == currentUid;

                    final vm = ChatMessageViewModel(
                      id: message.id,
                      text: message.text,
                      timestamp: message.timestamp,
                      senderId: message.senderId,
                      isOwnMessage: isOwn,
                      isSystemMessage:
                          message.messageType == MessageType.system,
                      senderName: isOwn ? null : message.senderId,
                    );

                    return ChatBubble(
                      message: vm,
                      useTailRadius: false,
                      avatarFallback: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primaryGreenLight,
                        child: Text(
                          message.senderId.isNotEmpty
                              ? message.senderId
                                  .substring(0, 1)
                                  .toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          ChatComposer(
            controller: _messageController,
            onSend: _sendMessage,
            hasText: _hasText,
            submitOnEnter: true,
          ),
        ],
      ),
    );
  }

  void _showGroupInfo() {
    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildGroupInfoSheet(),
      ),
    );
  }

  Widget _buildGroupInfoSheet() => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Group Info',
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildInfoRow(Icons.group, 'Name', _group!.name),
                    _buildInfoRow(
                      Icons.description,
                      'Description',
                      _group!.description,
                    ),
                    _buildInfoRow(
                      Icons.people,
                      'Members',
                      '${_group!.memberCount}',
                    ),
                    _buildInfoRow(Icons.category, 'Type', _group!.type.name),
                    if (_group!.location != null)
                      _buildInfoRow(
                        Icons.location_on,
                        'Location',
                        _group!.location!,
                      ),
                    const SizedBox(height: 20),
                    Text(
                      'Members',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._group!.memberIds.map(_buildMemberTile),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildInfoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryGreen, size: 20),
            const SizedBox(width: 12),
            Text(
              '$label: ',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildMemberTile(String memberId) {
    final isAdmin = _group!.adminIds.contains(memberId);
    final isCreator = _group!.creatorId == memberId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryGreenLight,
            child: Text(
              memberId.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memberId, // In real app, you'd get the user's name
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                if (isCreator)
                  Text(
                    'Creator',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else if (isAdmin)
                  Text(
                    'Admin',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
