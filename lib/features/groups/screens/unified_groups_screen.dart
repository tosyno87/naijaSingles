import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:naijasingles/services/unified_group_service.dart';
import 'package:naijasingles/common/constants/app_colors.dart';
import 'package:naijasingles/features/group_chat/screens/create_group_screen.dart';
import 'package:naijasingles/features/groups/screens/group_details_screen.dart';

/// Unified Groups Screen that combines Cultural Groups and Group Chats
/// This eliminates redundancy and creates synergy between features
class UnifiedGroupsScreen extends StatefulWidget {
  const UnifiedGroupsScreen({super.key});

  @override
  State<UnifiedGroupsScreen> createState() => _UnifiedGroupsScreenState();
}

class _UnifiedGroupsScreenState extends State<UnifiedGroupsScreen>
    with TickerProviderStateMixin {
  final UnifiedGroupService _groupService = UnifiedGroupService();
  final TextEditingController _searchController = TextEditingController();
  
  List<UnifiedGroup> _groups = [];
  List<UnifiedGroup> _userGroups = [];
  bool _isLoading = false;
  bool _isSearching = false;
  GroupType? _selectedType;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadGroups();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);
    
    try {
      // Load public groups for discovery
      final publicGroupsStream = _groupService.getPublicGroups(type: _selectedType);
      final publicGroups = await publicGroupsStream.first;
      
      // Load user's groups
      final userGroupsStream = _groupService.getUserGroups();
      final userGroups = await userGroupsStream.first;
      
      setState(() {
        _groups = publicGroups;
        _userGroups = userGroups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading groups: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _searchGroups() async {
    if (_searchController.text.trim().isEmpty) {
      await _loadGroups();
      return;
    }

    setState(() => _isSearching = true);
    
    try {
      final searchResults = await _groupService.searchGroups(
        query: _searchController.text.trim(),
        type: _selectedType,
      );
      
      setState(() {
        _groups = searchResults;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching groups: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _joinGroup(UnifiedGroup group) async {
    try {
      await _groupService.joinGroup(group.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined ${group.name}!'),
            backgroundColor: AppColors.success,
          ),
        );
        await _loadGroups(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        String message;
        if (e.toString().contains('Already a member')) {
          message = 'You are already a member of ${group.name}';
        } else if (e.toString().contains('Group is full')) {
          message = '${group.name} is full. Try another group.';
        } else if (e.toString().contains('Group not found')) {
          message = 'This group no longer exists.';
        } else if (e.toString().contains('Group is not active')) {
          message = '${group.name} is currently inactive.';
        } else if (e.toString().contains('Permission denied')) {
          message = 'You don\'t have permission to join this group.';
        } else {
          message = 'Unable to join ${group.name}. Please try again.';
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

  Widget _buildActionButton(UnifiedGroup group) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isMember = group.isMember(currentUserId);
    
    if (isMember) {
      // User is already a member - show "Open Chat" or "View Group"
      return ElevatedButton(
        onPressed: () => _navigateToGroupDetails(group),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          group.enableChat ? 'Enter Chat' : 'View Group',
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else {
      // User is not a member - show "Join"
      return ElevatedButton(
        onPressed: () => _joinGroup(group),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'Join',
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
  }

  void _navigateToGroupDetails(UnifiedGroup group) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isMember = group.isMember(currentUserId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupDetailsScreen(
          group: group,
          isMember: isMember,
        ),
      ),
    ).then((result) {
      // Refresh groups if user joined or left a group
      if (result == true) {
        _loadGroups();
      }
    });
  }

  void _navigateToCreateGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateGroupScreen(),
      ),
    ).then((_) => _loadGroups()); // Refresh after creating
  }

  void _showGroupInfo(UnifiedGroup group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildGroupInfoSheet(group),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Communities',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Material(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(20),
              elevation: 2,
              child: InkWell(
                onTap: _navigateToCreateGroup,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppColors.buttonShadow,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          
          // Type Filter
          _buildTypeFilter(),
          
          // Tab Bar
          _buildTabBar(),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDiscoverTab(),
                _buildMyGroupsTab(),
                _buildCreatedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          if (value.isEmpty) {
            _loadGroups();
          }
        },
        onSubmitted: (_) => _searchGroups(),
        decoration: InputDecoration(
          hintText: 'Search communities...',
          hintStyle: GoogleFonts.montserrat(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.primaryGreen,
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _loadGroups();
                  },
                  icon: Icon(
                    Icons.clear,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: GroupType.values.length + 1,
        itemBuilder: (context, index) {
          final type = index == 0 ? null : GroupType.values[index - 1];
          final isSelected = _selectedType == type;
          final label = type == null ? 'All' : _getTypeLabel(type);
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedType = type);
                _loadGroups();
              },
              backgroundColor: Colors.white,
              selectedColor: AppColors.primaryGreen,
              side: BorderSide(
                color: isSelected ? AppColors.primaryGreen : AppColors.border,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow,
      ),
      child: TabBar(
        controller: _tabController,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: AppColors.primaryGreen,
            width: 3,
          ),
          insets: const EdgeInsets.symmetric(horizontal: 16),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: AppColors.primaryGreen,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        unselectedLabelStyle: GoogleFonts.montserrat(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Discover'),
          Tab(text: 'My Groups'),
          Tab(text: 'Created'),
        ],
      ),
    );
  }

  Widget _buildDiscoverTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryGreen,
        ),
      );
    }

    if (_groups.isEmpty) {
      return _buildEmptyState(
        icon: Icon(
          Icons.group_outlined,
          size: 64,
          color: Colors.grey[400],
        ),
        title: 'No Communities Found',
        subtitle: _isSearching
            ? 'Try adjusting your search terms to find communities that match your interests.'
            : 'Be the first to create a community and start building your network!',
        actionButton: _isSearching ? null : _buildCreateButton(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGroups,
      color: AppColors.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];
          return _buildGroupCard(group, showJoinButton: true);
        },
      ),
    );
  }

  Widget _buildMyGroupsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryGreen,
        ),
      );
    }

    if (_userGroups.isEmpty) {
      return _buildEmptyState(
        icon: Icon(
          Icons.group_outlined,
          size: 64,
          color: Colors.grey[400],
        ),
        title: 'No Groups Joined',
        subtitle: 'Discover and join communities that match your interests!',
        actionButton: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              _tabController.animateTo(0); // Switch to Discover tab
            },
            icon: const Icon(Icons.explore, size: 18),
            label: Text(
              'Discover Groups',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGroups,
      color: AppColors.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _userGroups.length,
        itemBuilder: (context, index) {
          final group = _userGroups[index];
          return _buildGroupCard(group, showJoinButton: false);
        },
      ),
    );
  }

  Widget _buildCreatedTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryGreen,
        ),
      );
    }

    // Filter groups created by current user
    final createdGroups = _userGroups.where((group) {
      return group.isCreator(FirebaseAuth.instance.currentUser?.uid ?? '');
    }).toList();

    if (createdGroups.isEmpty) {
      return _buildEmptyState(
        icon: Icon(
          Icons.group_outlined,
          size: 64,
          color: Colors.grey[400],
        ),
        title: 'No Groups Created',
        subtitle: 'Create your first community and start building your network!',
        actionButton: _buildCreateButton(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGroups,
      color: AppColors.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: createdGroups.length,
        itemBuilder: (context, index) {
          final group = createdGroups[index];
          return _buildGroupCard(group, showJoinButton: false, showAdminBadge: true);
        },
      ),
    );
  }

  Widget _buildGroupCard(UnifiedGroup group, {bool showJoinButton = true, bool showAdminBadge = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildGroupAvatar(group),
        title: Row(
          children: [
            Expanded(
              child: Text(
                group.name,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            if (showAdminBadge)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
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
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              group.description,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildTypeChip(group.type),
                const SizedBox(width: 8),
                Text(
                  '${group.memberCount}/${group.maxMembers}',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                if (group.enableChat) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                ],
                const Spacer(),
                if (group.lastMessageAt != null)
                  Text(
                    _formatLastActivityTime(group.lastActivityAt),
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: showJoinButton
            ? _buildActionButton(group)
            : null,
        onTap: () => _navigateToGroupDetails(group),
      ),
    );
  }

  Widget _buildGroupAvatar(UnifiedGroup group) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: _getTypeColor(group.type),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Icon(
        _getTypeIcon(group.type),
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildTypeChip(GroupType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getTypeColor(type).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _getTypeLabel(type).toUpperCase(),
        style: GoogleFonts.montserrat(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _getTypeColor(type),
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _navigateToCreateGroup,
        icon: const Icon(Icons.add, size: 18),
        label: Text(
          'Create Community',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required Widget icon,
    required String title,
    required String subtitle,
    Widget? actionButton,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(child: icon),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              subtitle,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.3,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionButton != null) ...[
              const SizedBox(height: 32),
              actionButton,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGroupInfoSheet(UnifiedGroup group) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                  'Community Info',
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                _buildInfoRow(Icons.group, 'Name', group.name),
                _buildInfoRow(Icons.description, 'Description', group.description),
                _buildInfoRow(Icons.category, 'Type', group.typeDisplayName),
                _buildInfoRow(Icons.people, 'Members', '${group.memberCount}/${group.maxMembers}'),
                if (group.location != null)
                  _buildInfoRow(Icons.location_on, 'Location', group.location!),
                if (group.tags.isNotEmpty)
                  _buildInfoRow(Icons.tag, 'Tags', group.tags.join(', ')),
                _buildInfoRow(Icons.chat, 'Chat', group.enableChat ? 'Enabled' : 'Disabled'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
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
  }

  String _getTypeLabel(GroupType type) {
    switch (type) {
      // Interest & Hobby Groups
      case GroupType.music:
        return 'Music';
      case GroupType.sports:
        return 'Sports';
      case GroupType.travel:
        return 'Travel';
      case GroupType.food:
        return 'Food';
      case GroupType.art:
        return 'Art';
      
      // Lifestyle & Career Groups
      case GroupType.career:
        return 'Career';
      case GroupType.fitness:
        return 'Fitness';
      case GroupType.gaming:
        return 'Gaming';
      case GroupType.reading:
        return 'Reading';
      case GroupType.movies:
        return 'Movies';
      
      // Social & Community Groups
      case GroupType.events:
        return 'Events';
      case GroupType.networking:
        return 'Networking';
      case GroupType.support:
        return 'Support';
      case GroupType.study:
        return 'Study';
      case GroupType.local:
        return 'Local';
      
      // Special Interest Groups
      case GroupType.tech:
        return 'Technology';
      case GroupType.fashion:
        return 'Fashion';
      case GroupType.pets:
        return 'Pets';
      case GroupType.parenting:
        return 'Parenting';
      case GroupType.seniors:
        return 'Seniors';
    }
  }

  Color _getTypeColor(GroupType type) {
    switch (type) {
      // Interest & Hobby Groups
      case GroupType.music:
        return Colors.purple;
      case GroupType.sports:
        return Colors.orange;
      case GroupType.travel:
        return Colors.blue;
      case GroupType.food:
        return Colors.red;
      case GroupType.art:
        return Colors.pink;
      
      // Lifestyle & Career Groups
      case GroupType.career:
        return Colors.indigo;
      case GroupType.fitness:
        return Colors.green;
      case GroupType.gaming:
        return Colors.deepPurple;
      case GroupType.reading:
        return Colors.brown;
      case GroupType.movies:
        return Colors.teal;
      
      // Social & Community Groups
      case GroupType.events:
        return Colors.amber;
      case GroupType.networking:
        return Colors.cyan;
      case GroupType.support:
        return Colors.lightBlue;
      case GroupType.study:
        return Colors.deepOrange;
      case GroupType.local:
        return Colors.lightGreen;
      
      // Special Interest Groups
      case GroupType.tech:
        return Colors.blueGrey;
      case GroupType.fashion:
        return Colors.pinkAccent;
      case GroupType.pets:
        return Colors.amberAccent;
      case GroupType.parenting:
        return Colors.lightGreenAccent;
      case GroupType.seniors:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(GroupType type) {
    switch (type) {
      // Interest & Hobby Groups
      case GroupType.music:
        return Icons.music_note;
      case GroupType.sports:
        return Icons.sports_soccer;
      case GroupType.travel:
        return Icons.travel_explore;
      case GroupType.food:
        return Icons.restaurant;
      case GroupType.art:
        return Icons.palette;
      
      // Lifestyle & Career Groups
      case GroupType.career:
        return Icons.work;
      case GroupType.fitness:
        return Icons.fitness_center;
      case GroupType.gaming:
        return Icons.sports_esports;
      case GroupType.reading:
        return Icons.menu_book;
      case GroupType.movies:
        return Icons.movie;
      
      // Social & Community Groups
      case GroupType.events:
        return Icons.event;
      case GroupType.networking:
        return Icons.people;
      case GroupType.support:
        return Icons.support_agent;
      case GroupType.study:
        return Icons.school;
      case GroupType.local:
        return Icons.location_on;
      
      // Special Interest Groups
      case GroupType.tech:
        return Icons.computer;
      case GroupType.fashion:
        return Icons.checkroom;
      case GroupType.pets:
        return Icons.pets;
      case GroupType.parenting:
        return Icons.child_care;
      case GroupType.seniors:
        return Icons.elderly;
    }
  }

  String _formatLastActivityTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}
