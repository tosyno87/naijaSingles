// ⚠️ DEPRECATED: Use the canonical version at
// lib/features/groups/screens/group_details_screen.dart
// This file uses the legacy GroupModel/GroupService. The canonical version
// uses UnifiedGroup/UnifiedGroupService with richer features (notifications,
// reporting, member invites, etc.).
// TODO: Migrate callers (groups_screen.dart) to the canonical version,
// then delete this file.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../common/constants/app_colors.dart';
import '../../../../common/widgets/custom_3d_icons.dart';
import '../../../../models/group_model.dart';
import '../../data/services/group_service.dart';

@Deprecated('Use GroupDetailsScreen from groups/screens/ instead')
class GroupDetailsScreen extends StatefulWidget {
  const GroupDetailsScreen({
    required this.group,
    super.key,
  });
  final GroupModel group;

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen>
    with TickerProviderStateMixin {
  final GroupService _groupService = GroupService();
  late TabController _tabController;

  List<Map<String, dynamic>> _members = [];
  bool _isLoading = false;
  bool _isMember = false;
  bool _isAdmin = false;
  bool _isCreator = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkUserStatus();
    _loadMembers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _checkUserStatus() {
    final currentUserId = _groupService.currentUserId;
    if (currentUserId != null) {
      setState(() {
        _isMember = widget.group.isMember(currentUserId);
        _isAdmin = widget.group.isAdmin(currentUserId);
        _isCreator = widget.group.isCreator(currentUserId);
      });
    }
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);

    try {
      final members = await _groupService.getGroupMembers(widget.group.id!);
      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading members: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _joinGroup() async {
    final success = await _groupService.joinGroup(widget.group.id!);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully joined ${widget.group.name}!'),
          backgroundColor: AppColors.success,
        ),
      );
      _checkUserStatus();
      _loadMembers();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to join group'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _leaveGroup() async {
    final success = await _groupService.leaveGroup(widget.group.id!);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Left ${widget.group.name}'),
          backgroundColor: AppColors.info,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to leave group'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: CustomScrollView(
          slivers: [
            // App Bar
            _buildSliverAppBar(),

            // Group Info
            _buildGroupInfo(),

            // Tab Bar
            _buildTabBar(),

            // Tab Content
            _buildTabContent(),
          ],
        ),
      );

  Widget _buildSliverAppBar() => SliverAppBar(
        expandedHeight: 200,
        pinned: true,
        backgroundColor: AppColors.primaryGreen,
        flexibleSpace: FlexibleSpaceBar(
          background: DecoratedBox(
            decoration: BoxDecoration(
              gradient: _getCategoryGradient(),
            ),
            child: Stack(
              children: [
                // Group Image
                if (widget.group.imageUrl != null)
                  Positioned.fill(
                    child: Image.network(
                      widget.group.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultBackground(),
                    ),
                  )
                else
                  _buildDefaultBackground(),

                // Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),

                // Group Name
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Text(
                    widget.group.name,
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (_isCreator || _isAdmin)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    // TODO: Navigate to edit group screen
                    break;
                  case 'settings':
                    // TODO: Navigate to group settings
                    break;
                  case 'delete':
                    _showDeleteDialog();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit Group'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings),
                      SizedBox(width: 8),
                      Text('Settings'),
                    ],
                  ),
                ),
                if (_isCreator)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete Group',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      );

  Widget _buildDefaultBackground() => DecoratedBox(
        decoration: BoxDecoration(
          gradient: _getCategoryGradient(),
        ),
        child: Center(
          child: Custom3DIcons.groups(size: 80, color: Colors.white),
        ),
      );

  Widget _buildGroupInfo() => SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category and Cultural Info
              Row(
                children: [
                  _buildInfoChip(
                    icon:
                        GroupCategories.categoryIcons[widget.group.category] ??
                            '🌟',
                    label: widget.group.categoryDisplay,
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(width: 8),
                  if (widget.group.culturalInfo != null)
                    _buildInfoChip(
                      icon: '🌍',
                      label: widget.group.culturalDisplay,
                      color: AppColors.culture,
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                widget.group.description,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 16),

              // Stats Row
              Row(
                children: [
                  _buildStatItem(
                    icon: Icons.people,
                    label: 'Members',
                    value:
                        '${widget.group.memberCount}/${widget.group.maxMembers}',
                  ),
                  const SizedBox(width: 24),
                  if (widget.group.location != null)
                    _buildStatItem(
                      icon: Icons.location_on,
                      label: 'Location',
                      value: widget.group.location!,
                    ),
                  const SizedBox(width: 24),
                  _buildStatItem(
                    icon: Icons.calendar_today,
                    label: 'Created',
                    value: _formatDate(widget.group.createdAt),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      );

  Widget _buildInfoChip({
    required String icon,
    required String label,
    required Color color,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      );

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      );

  Widget _buildActionButtons() => Row(
        children: [
          if (!_isMember)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _joinGroup,
                icon: Custom3DIcons.add(size: 20),
                label: const Text('Join Group'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          else ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _leaveGroup,
                icon: const Icon(Icons.exit_to_app),
                label: const Text('Leave Group'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigate to group chat
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Group chat coming soon!'),
                      backgroundColor: AppColors.info,
                    ),
                  );
                },
                icon: Custom3DIcons.chat(size: 20),
                label: const Text('Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.info,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      );

  Widget _buildTabBar() => SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppColors.cardShadow,
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.primaryGreen,
            ),
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            unselectedLabelStyle: GoogleFonts.montserrat(
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'Members'),
              Tab(text: 'Posts'),
              Tab(text: 'Events'),
            ],
          ),
        ),
      );

  Widget _buildTabContent() => SliverFillRemaining(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildMembersTab(),
            _buildPostsTab(),
            _buildEventsTab(),
          ],
        ),
      );

  Widget _buildMembersTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryGreen,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        return _buildMemberCard(member);
      },
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            // Profile Image
            CircleAvatar(
              radius: 24,
              backgroundImage: member['imageUrl'] != null
                  ? NetworkImage(member['imageUrl'])
                  : null,
              child:
                  member['imageUrl'] == null ? Custom3DIcons.profile() : null,
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
                        member['name'],
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (member['isCreator'])
                        _buildRoleBadge('Creator', AppColors.warning)
                      else if (member['isAdmin'])
                        _buildRoleBadge('Admin', AppColors.info),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Joined ${_formatDate(DateTime.parse(member['joinedAt']))}',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            if (_isAdmin &&
                !member['isCreator'] &&
                member['id'] != _groupService.currentUserId)
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'make_admin':
                      _makeAdmin(member['id']);
                      break;
                    case 'remove_admin':
                      _removeAdmin(member['id']);
                      break;
                    case 'remove_member':
                      _removeMember(member['id']);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (!member['isAdmin'])
                    const PopupMenuItem(
                      value: 'make_admin',
                      child: Row(
                        children: [
                          Icon(Icons.admin_panel_settings),
                          SizedBox(width: 8),
                          Text('Make Admin'),
                        ],
                      ),
                    ),
                  if (member['isAdmin'])
                    const PopupMenuItem(
                      value: 'remove_admin',
                      child: Row(
                        children: [
                          Icon(Icons.remove_moderator),
                          SizedBox(width: 8),
                          Text('Remove Admin'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'remove_member',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Remove Member',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      );

  Widget _buildRoleBadge(String role, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          role,
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      );

  Widget _buildPostsTab() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 64, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text(
              'Group Posts Coming Soon!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Share updates, photos, and discussions with your group members.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildEventsTab() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event, size: 64, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text(
              'Group Events Coming Soon!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Create and join events organized by your group members.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Future<void> _makeAdmin(String userId) async {
    final success = await _groupService.addAdmin(widget.group.id!, userId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin added successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadMembers();
    }
  }

  Future<void> _removeAdmin(String userId) async {
    final success = await _groupService.removeAdmin(widget.group.id!, userId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin removed successfully'),
          backgroundColor: AppColors.info,
        ),
      );
      _loadMembers();
    }
  }

  void _removeMember(String userId) {
    // TODO: Implement remove member functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Remove member functionality coming soon!'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text(
          'Are you sure you want to delete "${widget.group.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _groupService.deleteGroup(widget.group.id!);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Group deleted successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  LinearGradient _getCategoryGradient() {
    switch (widget.group.category.toLowerCase()) {
      case 'cultural':
        return const LinearGradient(
          colors: [AppColors.culture, AppColors.heritage],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'professional':
        return const LinearGradient(
          colors: [AppColors.business, AppColors.success],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'social':
        return const LinearGradient(
          colors: [AppColors.community, AppColors.info],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'educational':
        return const LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.primaryGreenLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'religious':
        return const LinearGradient(
          colors: [AppColors.warning, AppColors.error],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'regional':
        return const LinearGradient(
          colors: [AppColors.textPrimary, AppColors.textSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return AppColors.primaryGradient;
    }
  }
}
