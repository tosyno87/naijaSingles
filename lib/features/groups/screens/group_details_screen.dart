import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/constants/app_colors.dart';
import '../../../models/group_join_exception.dart';
import '../../../services/group_notification_service.dart';
import '../../../services/group_unread_service.dart';
import '../../../services/unified_group_service.dart';
import '../../../services/user_service.dart';
import '../../../widgets/full_screen_image_viewer.dart';
import '../../../widgets/group_info_modal.dart';
import '../../../widgets/group_notification_toggle.dart';
import '../../../widgets/group_report_modal.dart';
import '../../group_chat/screens/group_chat_screen.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_shimmer.dart';
import '../widgets/invite_members_modal.dart';
import 'group_settings_screen.dart';

/// Enhanced Group Details Screen for members
/// Provides comprehensive group information and member-specific actions
class GroupDetailsScreen extends StatefulWidget {
  const GroupDetailsScreen({
    required this.group,
    required this.isMember,
    super.key,
  });
  final UnifiedGroup group;
  final bool isMember;

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  final UnifiedGroupService _groupService = UnifiedGroupService();
  final UserService _userService = UserService();
  final GroupNotificationService _notificationService =
      GroupNotificationService();
  final GroupUnreadService _unreadService = GroupUnreadService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.backgroundColor,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(
            widget.group.name,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (widget.isMember) ...[
              IconButton(
                onPressed: _showGroupOptions,
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ],
        ),
        body: widget.isMember && widget.group.enableChat
            ? _buildChatInterface()
            : _buildGroupDetails(),
      );

  Widget _buildChatInterface() => Column(
        children: [
          // Group info header
          _buildChatHeader(),
          // Messages list
          Expanded(
            child: _buildMessagesList(),
          ),
          // Message input
          _buildMessageInput(),
        ],
      );

  Widget _buildChatHeader() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryGreen.withOpacity(0.2),
              child: widget.group.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        widget.group.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.group,
                          color: AppColors.primaryGreen,
                          size: 20,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.group,
                      color: AppColors.primaryGreen,
                      size: 20,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.group.name,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '${widget.group.memberCount} members',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _showGroupInfoModal,
              icon: const Icon(
                Icons.info_outline,
                color: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
      );

  Widget _buildMessagesList() => StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('unifiedGroups')
            .doc(widget.group.id)
            .collection('messages')
            .orderBy(
              'timestamp',
              descending: false,
            ) // Oldest first for proper display
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: 3, // Show 3 shimmer messages
              itemBuilder: (context, index) => MessageShimmer(
                isCurrentUser:
                    index % 2 == 0, // Alternate between user and other
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading messages',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final messages = snapshot.data?.docs ?? [];

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
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start the conversation!',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          // Auto-scroll to bottom when new messages arrive
          if (messages.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final messageDoc = messages[index];
              final messageData = messageDoc.data() as Map<String, dynamic>;
              final currentUserId =
                  FirebaseAuth.instance.currentUser?.uid ?? '';

              return MessageBubble(
                messageId: messageDoc.id,
                text: messageData['text'] ?? '',
                senderId: messageData['senderId'] ?? '',
                senderName: messageData['senderId'] == currentUserId
                    ? (FirebaseAuth.instance.currentUser?.displayName ?? 'You')
                    : (messageData['senderName'] ?? 'Unknown'),
                timestamp: (messageData['timestamp'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                isCurrentUser: messageData['senderId'] == currentUserId,
              );
            },
          );
        },
      );

  Widget _buildMessageInput() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.montserrat(
                    color: Colors.grey[500],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.primaryGreen),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: GoogleFonts.montserrat(),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (value) {
                  setState(() {}); // Rebuild to update send button state
                },
              ),
            ),
            const SizedBox(width: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(24),
              ),
              child: IconButton(
                onPressed: _messageController.text.trim().isEmpty
                    ? null
                    : _sendMessage,
                icon: const Icon(
                  Icons.send,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore
          .collection('unifiedGroups')
          .doc(widget.group.id)
          .collection('messages')
          .add({
        'text': text,
        'senderId': currentUser.uid,
        'senderName': currentUser.displayName ?? 'You',
        'timestamp': FieldValue.serverTimestamp(),
        'groupId': widget.group.id,
        'readBy': {currentUser.uid: true}, // Mark as read by sender
        'readAt': {currentUser.uid: FieldValue.serverTimestamp()},
      });

      // Increment unread count for other members
      await _unreadService.incrementUnreadCount(
        widget.group.id,
        excludeUserId: currentUser.uid,
      );

      _messageController.clear();
      setState(() {}); // Update send button state
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildGroupDetails() => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGroupHeader(),
            _buildGroupInfo(),
            _buildMemberSection(),
            _buildActionButtons(),
            const SizedBox(height: 20),
          ],
        ),
      );

  Widget _buildGroupHeader() => Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildGroupAvatar(),
              const SizedBox(height: 16),
              Text(
                widget.group.name,
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.group.description,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              _buildGroupStats(),
            ],
          ),
        ),
      );

  Widget _buildGroupAvatar() => GestureDetector(
        onTap: _showGroupImageOptions,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: widget.group.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    widget.group.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildDefaultAvatar(),
                  ),
                )
              : _buildDefaultAvatar(),
        ),
      );

  Widget _buildDefaultAvatar() => Icon(
        Icons.group,
        size: 50,
        color: Colors.white.withOpacity(0.8),
      );

  Widget _buildGroupStats() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            icon: Icons.people,
            label: 'Members',
            value: '${widget.group.memberCount}/${widget.group.maxMembers}',
          ),
          _buildStatItem(
            icon: Icons.category,
            label: 'Type',
            value: widget.group.typeDisplayName,
          ),
          _buildStatItem(
            icon: Icons.access_time,
            label: 'Created',
            value: _formatDate(widget.group.createdAt),
          ),
        ],
      );

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) =>
      Column(
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.8),
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      );

  Widget _buildGroupInfo() => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Group Information',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.location_on,
              label: 'Location',
              value: widget.group.location ?? 'Not specified',
            ),
            if (widget.group.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.tag,
                label: 'Tags',
                value: widget.group.tags.join(', '),
              ),
            ],
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.chat,
              label: 'Chat',
              value: widget.group.enableChat ? 'Enabled' : 'Disabled',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.public,
              label: 'Visibility',
              value: widget.group.isPublic ? 'Public' : 'Private',
            ),
          ],
        ),
      );

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) =>
      Row(
        children: [
          Icon(
            icon,
            color: AppColors.primaryGreen,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildMemberSection() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Members',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '${widget.group.memberCount} members',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMemberList(),
          ],
        ),
      );

  Widget _buildMemberList() {
    // Show first 6 members with "View All" option
    final displayMembers = widget.group.memberIds.take(6).toList();
    final hasMoreMembers = widget.group.memberIds.length > 6;

    return Column(
      children: [
        ...displayMembers.map(_buildMemberTile),
        if (hasMoreMembers) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: _showAllMembers,
            child: Text(
              'View all ${widget.group.memberIds.length} members',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMemberTile(String memberId) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isCurrentUser = memberId == currentUserId;
    final isCreator = memberId == widget.group.creatorId;
    final isAdmin = widget.group.adminIds.contains(memberId);
    final canRemoveMembers = _canEditGroup() && !isCreator && !isCurrentUser;

    return FutureBuilder<UserProfile?>(
      future: _userService.getUserProfile(memberId),
      builder: (context, snapshot) {
        final userProfile = snapshot.data;
        final displayName =
            userProfile?.displayName ?? (isCurrentUser ? 'You' : 'Member');
        final avatarUrl = userProfile?.avatarUrl;
        final initials = userProfile?.initials ?? (isCurrentUser ? 'Y' : 'M');

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryGreen.withOpacity(0.2),
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    initials,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  )
                : null,
          ),
          title: Text(
            displayName,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          subtitle: Row(
            children: [
              if (isCreator)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'CREATOR',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              if (isAdmin && !isCreator) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ADMIN',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          trailing: canRemoveMembers
              ? IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: () =>
                      _showRemoveMemberConfirmation(memberId, displayName),
                  tooltip: 'Remove member',
                )
              : null,
          onTap: () => _navigateToMemberProfile(memberId),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    if (!widget.isMember) {
      return _buildJoinButton();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (widget.group.enableChat) ...[
            _buildPrimaryButton(
              text: 'Open Chat',
              icon: Icons.chat,
              onPressed: _openGroupChat,
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: _buildSecondaryButton(
                  text: 'Invite Members',
                  icon: Icons.person_add,
                  onPressed: _inviteMembers,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDangerButton(
                  text: 'Leave Group',
                  icon: Icons.exit_to_app,
                  onPressed: _leaveGroup,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJoinButton() => Container(
        margin: const EdgeInsets.all(16),
        child: _buildPrimaryButton(
          text: 'Join Group',
          icon: Icons.group_add,
          onPressed: _joinGroup,
        ),
      );

  Widget _buildPrimaryButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) =>
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    text,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildSecondaryButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) =>
      DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryGreen, width: 2),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: AppColors.primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    text,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildDangerButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) =>
      DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    text,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  // Action methods
  void _openGroupChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupChatScreen(groupId: widget.group.id),
      ),
    );
  }

  void _inviteMembers() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InviteMembersModal(group: widget.group),
    ).then((refresh) {
      // Refresh the screen if members were added
      if (refresh == true && mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _leaveGroup() async {
    final confirmed = await _showLeaveConfirmation();
    if (!confirmed) return;

    try {
      await _groupService.leaveGroup(widget.group.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully left ${widget.group.name}'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate group was left
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to leave group: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _joinGroup() async {
    try {
      await _groupService.joinGroup(widget.group.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined ${widget.group.name}!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(
          context,
          true,
        ); // Return true to indicate group was joined
      }
    } catch (e) {
      if (mounted) {
        String message;
        if (e is GroupJoinException) {
          switch (e.type) {
            case GroupJoinErrorType.alreadyMember:
              message = 'You are already a member of this group.';
              break;
            case GroupJoinErrorType.groupFull:
              message = 'This group is full. Try another group.';
              break;
            default:
              message = 'Failed to join group. Please try again.';
          }
        } else {
          message =
              'Failed to join group. Please check your connection and try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<bool> _showLeaveConfirmation() async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Leave Group'),
          content:
              Text('Are you sure you want to leave "${widget.group.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Leave',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ) ??
      false;

  void _showGroupOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Group Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        GroupSettingsScreen(group: widget.group),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notification Settings'),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => GroupNotificationToggle(
                    groupId: widget.group.id,
                    groupName: widget.group.name,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Report Group'),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => GroupReportModal(
                    groupId: widget.group.id,
                    groupName: widget.group.name,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAllMembers() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Members (${widget.group.memberIds.length})',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: widget.group.memberIds.length,
                itemBuilder: (context, index) {
                  final memberId = widget.group.memberIds[index];
                  return _buildMemberTile(memberId);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupInfoModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GroupInfoModal(group: widget.group),
    );
  }

  void _showGroupImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.group.imageUrl != null) ...[
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.visibility,
                    color: AppColors.primaryGreen,
                    size: 24,
                  ),
                ),
                title: Text(
                  'View Full Image',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  FullScreenImageViewer.show(
                    context: context,
                    imageUrl: widget.group.imageUrl!,
                    title: widget.group.name,
                  );
                },
              ),
            ],
            if (widget.isMember && _canEditGroup()) ...[
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: AppColors.primaryGreen,
                    size: 24,
                  ),
                ),
                title: Text(
                  widget.group.imageUrl != null
                      ? 'Change Group Photo'
                      : 'Add Group Photo',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _editGroupPhoto();
                },
              ),
            ],
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.grey[600],
                  size: 24,
                ),
              ),
              title: Text(
                'Cancel',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  bool _canEditGroup() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return currentUserId == widget.group.creatorId ||
        widget.group.adminIds.contains(currentUserId);
  }

  void _editGroupPhoto() {
    // Navigate to group settings where photo editing is available
    Navigator.pop(context); // Close the image options modal
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupSettingsScreen(group: widget.group),
      ),
    ).then((_) {
      // Refresh the screen after returning from settings
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _navigateToMemberProfile(String memberId) {
    // Navigate to user profile screen
    // For now, show a snackbar. This can be enhanced to navigate to a profile screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Viewing ${memberId == FirebaseAuth.instance.currentUser?.uid ? "your" : "member"} profile'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  Future<void> _showRemoveMemberConfirmation(
      String memberId, String memberName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Remove Member',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to remove $memberName from this group?',
          style: GoogleFonts.montserrat(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(
                color: Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Remove',
              style: GoogleFonts.montserrat(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _removeMember(memberId, memberName);
    }
  }

  Future<void> _removeMember(String memberId, String memberName) async {
    try {
      await _groupService.removeMemberFromGroup(
        groupId: widget.group.id,
        userId: memberId,
        reason: 'Removed by admin',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$memberName has been removed from the group'),
            backgroundColor: AppColors.success,
          ),
        );
        // Refresh the screen
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove member: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else {
      return 'Today';
    }
  }
}
