import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/constants/app_colors.dart';
import '../data/services/unified_group_service.dart';

/// Comprehensive Member Management Screen
/// Provides full control over group members with modern UI
class MemberManagementScreen extends StatefulWidget {
  const MemberManagementScreen({
    required this.group,
    super.key,
  });
  final UnifiedGroup group;

  @override
  State<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final UnifiedGroupService _groupService = UnifiedGroupService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _inviteMessageController =
      TextEditingController();

  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _inviteMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Manage Members',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add, color: AppColors.primaryGreen),
              onPressed: _showInviteDialog,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryGreen,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primaryGreen,
            labelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Members'),
              Tab(text: 'Admins'),
              Tab(text: 'Invite'),
            ],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              controller: _tabController,
              children: [
                _buildMembersTab(),
                _buildAdminsTab(),
                _buildInviteTab(),
              ],
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.2),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _buildMembersTab() => Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _buildMembersList(),
          ),
        ],
      );

  Widget _buildAdminsTab() => _buildAdminsList();

  Widget _buildInviteTab() => _buildInviteSection();

  Widget _buildSearchBar() => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search members...',
            hintStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
            prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: _onSearchChanged,
        ),
      );

  Widget _buildMembersList() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final members = widget.group.memberIds;
    final admins = widget.group.adminIds;
    final creatorId = widget.group.creatorId;

    if (members.isEmpty) {
      return _buildEmptyState(
        'No members yet',
        'Invite people to join your group',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final memberId = members[index];
        final isAdmin = admins.contains(memberId);
        final isCreator = creatorId == memberId;
        final isCurrentUser = memberId == currentUserId;

        return _buildMemberCard(
          memberId: memberId,
          isAdmin: isAdmin,
          isCreator: isCreator,
          isCurrentUser: isCurrentUser,
          canManage: _canManageMember(memberId),
        );
      },
    );
  }

  Widget _buildAdminsList() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final admins = widget.group.adminIds;
    final creatorId = widget.group.creatorId;

    if (admins.isEmpty) {
      return _buildEmptyState('No admins', 'Promote members to admin status');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: admins.length,
      itemBuilder: (context, index) {
        final adminId = admins[index];
        final isCreator = creatorId == adminId;
        final isCurrentUser = adminId == currentUserId;

        return _buildMemberCard(
          memberId: adminId,
          isAdmin: true,
          isCreator: isCreator,
          isCurrentUser: isCurrentUser,
          canManage: _canManageMember(adminId),
        );
      },
    );
  }

  Widget _buildInviteSection() => Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invite New Members',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Search for users by name, email, or username to invite them to your group.',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          _buildSearchBar(),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? _buildEmptyState(
                        'No search results',
                        'Try searching for users to invite',
                      )
                    : _buildSearchResults(),
          ),
        ],
      );

  Widget _buildMemberCard({
    required String memberId,
    required bool isAdmin,
    required bool isCreator,
    required bool isCurrentUser,
    required bool canManage,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primaryGreen,
              child: Text(
                memberId.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Member Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _getUserDisplayName(memberId),
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isCreator)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'CREATOR',
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      else if (isAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            borderRadius: BorderRadius.circular(12),
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
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCurrentUser ? 'You' : 'Member',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Action Buttons
            if (canManage && !isCurrentUser)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (value) => _handleMemberAction(value, memberId),
                itemBuilder: (context) => [
                  if (!isAdmin && !isCreator)
                    const PopupMenuItem(
                      value: 'promote',
                      child: Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            color: AppColors.primaryGreen,
                          ),
                          SizedBox(width: 8),
                          Text('Promote to Admin'),
                        ],
                      ),
                    ),
                  if (isAdmin && !isCreator)
                    const PopupMenuItem(
                      value: 'demote',
                      child: Row(
                        children: [
                          Icon(Icons.person, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Demote to Member'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Remove from Group'),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      );

  Widget _buildSearchResults() => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final user = _searchResults[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryGreen,
                  backgroundImage:
                      user['photoUrl'] != null && user['photoUrl'].isNotEmpty
                          ? NetworkImage(user['photoUrl'])
                          : null,
                  child: user['photoUrl'] == null || user['photoUrl'].isEmpty
                      ? Text(
                          user['displayName'].substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['displayName'],
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        user['email'],
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _inviteUser(user['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Invite',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        },
      );

  Widget _buildEmptyState(String title, String subtitle) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    _groupService
        .searchUsersForInvitation(
      query: query,
      groupId: widget.group.id,
    )
        .then((results) {
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  void _handleMemberAction(String action, String memberId) {
    switch (action) {
      case 'promote':
        _promoteMember(memberId);
        break;
      case 'demote':
        _demoteMember(memberId);
        break;
      case 'remove':
        _removeMember(memberId);
        break;
    }
  }

  Future<void> _promoteMember(String memberId) async {
    try {
      setState(() => _isLoading = true);
      await _groupService.promoteMemberToAdmin(
        groupId: widget.group.id,
        userId: memberId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member promoted to admin'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _demoteMember(String memberId) async {
    try {
      setState(() => _isLoading = true);
      await _groupService.demoteAdminToMember(
        groupId: widget.group.id,
        userId: memberId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin demoted to member'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeMember(String memberId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: const Text(
            'Are you sure you want to remove this member from the group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        setState(() => _isLoading = true);
        await _groupService.removeMemberFromGroup(
          groupId: widget.group.id,
          userId: memberId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Member removed from group'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _inviteUser(String userId) async {
    try {
      setState(() => _isLoading = true);
      await _groupService.sendGroupInvitation(
        groupId: widget.group.id,
        userId: userId,
        message: _inviteMessageController.text.isNotEmpty
            ? _inviteMessageController.text
            : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation sent successfully'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        // Remove from search results
        setState(() {
          _searchResults.removeWhere((user) => user['id'] == userId);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Members'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _inviteMessageController,
              decoration: const InputDecoration(
                labelText: 'Custom message (optional)',
                hintText: 'Add a personal message to your invitation',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _tabController.animateTo(2); // Switch to invite tab
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  bool _canManageMember(String memberId) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return false;

    // Only creator can manage members
    return widget.group.creatorId == currentUserId;
  }

  String _getUserDisplayName(String userId) {
    // In a real app, you'd fetch this from user data
    return 'User ${userId.substring(0, 8)}';
  }
}
