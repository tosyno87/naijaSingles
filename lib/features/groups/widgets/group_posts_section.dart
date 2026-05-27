import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/constants/app_colors.dart';
import '../../../common/constants/app_spacing.dart';
import '../../../services/group_posts_service.dart';

/// Group feed: list posts and compose new ones (members only).
class GroupPostsSection extends StatefulWidget {
  const GroupPostsSection({
    required this.groupId,
    required this.isMember,
    super.key,
  });

  final String groupId;
  final bool isMember;

  @override
  State<GroupPostsSection> createState() => _GroupPostsSectionState();
}

class _GroupPostsSectionState extends State<GroupPostsSection> {
  final GroupPostsService _postsService = GroupPostsService();
  final TextEditingController _composer = TextEditingController();
  bool _posting = false;

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    final text = _composer.text.trim();
    if (text.isEmpty || _posting) return;
    setState(() => _posting = true);
    try {
      await _postsService.createPost(groupId: widget.groupId, text: text);
      _composer.clear();
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not post: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: AppSpacing.pagePadding,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Group posts',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (widget.isMember) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _composer,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Share with the group...',
                      hintStyle: GoogleFonts.montserrat(fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _posting ? null : _submitPost,
                  color: AppColors.primaryGreen,
                  icon: _posting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Join the group to post and comment.',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          StreamBuilder<List<GroupPost>>(
            stream: _postsService.watchPosts(widget.groupId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final posts = snapshot.data ?? [];
              if (posts.isEmpty) {
                return Text(
                  'No posts yet. Start the conversation!',
                  style: GoogleFonts.montserrat(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: posts.length,
                separatorBuilder: (_, __) => const Divider(height: 20),
                itemBuilder: (context, index) {
                  final post = posts[index];
                  final isAuthor =
                      post.authorId == FirebaseAuth.instance.currentUser?.uid;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isAuthor ? 'You' : 'Member',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            _formatTime(post.createdAt),
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        post.text,
                        style: GoogleFonts.montserrat(fontSize: 15),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
