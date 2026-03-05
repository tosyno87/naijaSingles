import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/constants/app_colors.dart';
import '../../../services/group_unread_service.dart';
import '../../group_chat/screens/create_group_screen.dart';
import '../data/services/unified_group_service.dart';
import '../widgets/unified_group_card.dart';
import 'group_details_screen.dart';

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
  final GroupUnreadService _unreadService = GroupUnreadService();
  final TextEditingController _searchController = TextEditingController();

  List<UnifiedGroup> _groups = [];
  List<UnifiedGroup> _userGroups = [];
  Map<String, int> _unreadCounts = {};
  bool _isLoading = false;
  bool _isSearching = false;
  GroupType? _selectedType;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_onSearchTextChanged);
    unawaited(_loadGroups());
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    setState(() {});
  }

  Future<void> _loadGroups() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final publicGroupsStream =
          _groupService.getPublicGroups(type: _selectedType);
      final publicGroups = await publicGroupsStream.first;

      final userGroupsStream = _groupService.getUserGroups();
      final userGroups = await userGroupsStream.first;

      final unreadResults = await Future.wait(
        userGroups.map((g) => _unreadService.getUnreadCount(g.id)),
      );
      final counts = {
        for (var i = 0; i < userGroups.length; i++)
          userGroups[i].id: unreadResults[i],
      };

      if (!mounted) return;
      setState(() {
        _groups = publicGroups;
        _userGroups = userGroups;
        _unreadCounts = counts;
        _isLoading = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading groups: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _searchGroups() async {
    if (_searchController.text.trim().isEmpty) {
      await _loadGroups();
      return;
    }

    if (!mounted) return;
    setState(() => _isSearching = true);

    try {
      final searchResults = await _groupService.searchGroups(
        query: _searchController.text.trim(),
        type: _selectedType,
      );

      if (!mounted) return;
      setState(() {
        _groups = searchResults;
        _isSearching = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching groups: $e'),
          backgroundColor: AppColors.error,
        ),
      );
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
    } on Object catch (e) {
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

  Widget _buildCard(UnifiedGroup group, {bool showAdminBadge = false}) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final member = group.isMember(uid);
    final admin = showAdminBadge && group.isAdmin(uid);
    final isFeatured =
        group.memberCount > 20 ||
        DateTime.now().difference(group.lastActivityAt).inHours < 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: UnifiedGroupCard(
        group: group,
        isMember: member,
        isAdmin: admin,
        featured: isFeatured,
        hasUnread: member && (_unreadCounts[group.id] ?? 0) > 0,
        onTap: () => _navigateToGroupDetails(group),
        onJoin: member ? null : () => _joinGroup(group),
      ),
    );
  }

  Future<void> _navigateToGroupDetails(UnifiedGroup group) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isMember = group.isMember(currentUserId);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupDetailsScreen(
          group: group,
          isMember: isMember,
        ),
      ),
    );
    if (!mounted) return;
    if (result == true) {
      unawaited(_loadGroups());
    }
  }

  Future<void> _navigateToCreateGroup() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateGroupScreen(),
      ),
    );
    if (!mounted) return;
    unawaited(_loadGroups());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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

  Widget _buildSearchBar() => Container(
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
              unawaited(_loadGroups());
            }
          },
          onSubmitted: (_) => _searchGroups(),
          decoration: InputDecoration(
            hintText: 'Search communities...',
            hintStyle: GoogleFonts.montserrat(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: AppColors.primaryGreen,
              size: 20,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      unawaited(_loadGroups());
                    },
                    icon: const Icon(
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

  Widget _buildTypeFilter() => Container(
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
                  unawaited(_loadGroups());
                },
                backgroundColor: Colors.white,
                selectedColor: AppColors.primaryGreen,
                side: BorderSide(
                  color: isSelected ? AppColors.primaryGreen : AppColors.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                labelPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            );
          },
        ),
      );

  Widget _buildTabBar() => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppColors.cardShadow,
        ),
        child: TabBar(
          controller: _tabController,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(
              color: AppColors.primaryGreen,
              width: 3,
            ),
            insets: EdgeInsets.symmetric(horizontal: 16),
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
          return _buildCard(group);
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
          return _buildCard(group, showAdminBadge: false);
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
    final createdGroups = _userGroups
        .where(
          (group) =>
              group.isCreator(FirebaseAuth.instance.currentUser?.uid ?? ''),
        )
        .toList();

    if (createdGroups.isEmpty) {
      return _buildEmptyState(
        icon: Icon(
          Icons.group_outlined,
          size: 64,
          color: Colors.grey[400],
        ),
        title: 'No Groups Created',
        subtitle:
            'Create your first community and start building your network!',
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
          return _buildCard(group, showAdminBadge: true);
        },
      ),
    );
  }

  Widget _buildCreateButton() => SizedBox(
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

  Widget _buildEmptyState({
    required Widget icon,
    required String title,
    required String subtitle,
    Widget? actionButton,
  }) =>
      Center(
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
                      color: Colors.black.withValues(alpha: 0.05),
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

}
