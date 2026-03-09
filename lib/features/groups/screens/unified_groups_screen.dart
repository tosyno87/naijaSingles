import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/constants/app_colors.dart';
import '../../../common/widgets/state_views/state_views.dart';
import '../../../services/group_unread_service.dart';
import '../../../services/user_service.dart';
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
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();

  List<UnifiedGroup> _groups = [];
  List<UnifiedGroup> _userGroups = [];
  Map<String, int> _unreadCounts = {};
  Map<String, List<String?>> _memberAvatars = {};
  bool _isLoading = false;
  bool _isSearching = false;
  String? _loadError;
  GroupType? _selectedType;
  Timer? _searchDebounce;
  int _requestVersion = 0;

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
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (_searchController.text.trim().isEmpty) {
        unawaited(_loadGroups());
      } else {
        unawaited(_searchGroups());
      }
    });
  }

  Future<void> _loadGroups() async {
    if (!mounted) return;
    final version = ++_requestVersion;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final publicGroupsStream =
          _groupService.getPublicGroups(type: _selectedType);
      final publicGroups = await publicGroupsStream.first;

      final userGroupsStream = _groupService.getUserGroups();
      final userGroups = await userGroupsStream.first;

      if (!mounted || version != _requestVersion) return;
      setState(() {
        _groups = publicGroups;
        _userGroups = userGroups;
        _isLoading = false;
        _loadError = null;
      });

      unawaited(_loadUnreadCounts(userGroups, version));
      unawaited(_loadMemberAvatars([...publicGroups, ...userGroups], version));
    } on Object catch (e) {
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Error loading groups. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading groups: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _loadUnreadCounts(List<UnifiedGroup> groups, int version) async {
    if (groups.isEmpty) return;
    try {
      final results = await Future.wait(
        groups.map((g) => _unreadService.getUnreadCount(g.id)),
      );
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _unreadCounts = {
          for (var i = 0; i < groups.length; i++) groups[i].id: results[i],
        };
      });
    } on Object {
      // Non-critical; cards render fine without unread badges
    }
  }

  Future<void> _loadMemberAvatars(
    List<UnifiedGroup> groups,
    int version,
  ) async {
    if (groups.isEmpty) return;
    try {
      final seen = <String>{};
      final unique = groups.where((g) => seen.add(g.id)).toList();

      final groupResults = await Future.wait(
        unique.map((group) {
          final ids = group.memberIds.take(3).toList();
          if (ids.isEmpty) return Future.value(<String?>[]);
          return Future.wait(
            ids.map(_userService.getUserAvatarUrl),
          );
        }),
      );

      if (!mounted || version != _requestVersion) return;
      setState(() {
        _memberAvatars = {
          for (var i = 0; i < unique.length; i++) unique[i].id: groupResults[i],
        };
      });
    } on Object {
      // Non-critical; cards fall back to icon + count
    }
  }

  Future<void> _searchGroups() async {
    if (_searchController.text.trim().isEmpty) {
      await _loadGroups();
      return;
    }

    if (!mounted) return;
    final version = ++_requestVersion;
    setState(() {
      _isSearching = true;
      _loadError = null;
    });

    try {
      final searchResults = await _groupService.searchGroups(
        query: _searchController.text.trim(),
        type: _selectedType,
      );

      if (!mounted || version != _requestVersion) return;
      setState(() {
        _groups = searchResults;
        _isSearching = false;
        _loadError = null;
      });
    } on Object catch (e) {
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _isSearching = false;
        _loadError = 'Error searching groups. Please try again.';
      });
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

  Widget _buildCard(
    UnifiedGroup group, {
    bool showAdminBadge = false,
  }) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final member = group.isMember(uid);
    final admin = showAdminBadge && group.isAdmin(uid);
    final isFeatured = group.memberCount > 20 ||
        DateTime.now().difference(group.lastActivityAt).inHours < 1;
    final isNew = DateTime.now().difference(group.createdAt).inDays <= 7;
    final recentActivity =
        DateTime.now().difference(group.lastActivityAt).inHours < 24;
    final isTrending = !isNew && recentActivity && group.memberCount >= 5;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: UnifiedGroupCard(
        group: group,
        isMember: member,
        isAdmin: admin,
        featured: isFeatured,
        hasUnread: member && (_unreadCounts[group.id] ?? 0) > 0,
        memberAvatars: _memberAvatars[group.id] ?? const [],
        badge: isNew
            ? GroupBadge.isNew
            : isTrending
                ? GroupBadge.trending
                : null,
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
        body: _loadError != null &&
                !_isLoading &&
                !_isSearching &&
                _groups.isEmpty &&
                _userGroups.isEmpty
            ? AppErrorView(
                title: 'Unable to load communities',
                message: _loadError!,
                onRetry: _loadGroups,
              )
            : Column(
                children: [
                  // Search Bar
                  _buildSearchBar(),

                  // Type Filter
                  _buildTypeFilter(),

                  const SizedBox(height: 12),

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
          onSubmitted: (_) {
            _searchDebounce?.cancel();
            unawaited(_searchGroups());
          },
          decoration: InputDecoration(
            hintText: 'Search communities, topics, or people',
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
                    onPressed: _searchController.clear,
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

  Widget _buildTypeFilter() => SizedBox(
        height: 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: GroupType.values.length + 1,
          itemBuilder: (context, index) {
            final type = index == 0 ? null : GroupType.values[index - 1];
            final isSelected = _selectedType == type;
            final label = type == null ? 'All' : _getTypeLabel(type);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
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
                  color: isSelected
                      ? AppColors.primaryGreen
                      : Colors.grey.shade300,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                visualDensity: VisualDensity.compact,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            );
          },
        ),
      );

  Widget _buildTabBar() => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(
              color: AppColors.primaryGreen,
              width: 2,
            ),
            insets: EdgeInsets.symmetric(horizontal: 20),
          ),
          indicatorSize: TabBarIndicatorSize.label,
          dividerHeight: 0.5,
          dividerColor: Colors.grey.shade200,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
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

  Widget _buildLoadingSkeleton() => const AppLoadingView(
        message: 'Loading communities...',
      );

  Widget _buildDiscoverTab() {
    if (_isLoading) {
      return _buildLoadingSkeleton();
    }

    if (_groups.isEmpty) {
      return _buildEmptyState(
        icon: Icons.group_outlined,
        title: 'No Communities Found',
        subtitle: _isSearching
            ? 'Try adjusting your search terms to find communities that match your interests.'
            : 'Be the first to create a community and start building your network!',
        actionLabel: _isSearching ? null : 'Create Community',
        onAction: _isSearching ? null : _navigateToCreateGroup,
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
      return _buildLoadingSkeleton();
    }

    if (_userGroups.isEmpty) {
      return _buildEmptyState(
        icon: Icons.group_outlined,
        title: 'No Groups Joined',
        subtitle: 'Discover and join communities that match your interests!',
        actionLabel: 'Discover Groups',
        onAction: () => _tabController.animateTo(0),
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
          return _buildCard(group);
        },
      ),
    );
  }

  Widget _buildCreatedTab() {
    if (_isLoading) {
      return _buildLoadingSkeleton();
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
        icon: Icons.group_outlined,
        title: 'No Groups Created',
        subtitle:
            'Create your first community and start building your network!',
        actionLabel: 'Create Community',
        onAction: _navigateToCreateGroup,
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

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      AppEmptyView(
        title: title,
        subtitle: subtitle,
        icon: icon,
        actionLabel: actionLabel,
        onAction: onAction,
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
