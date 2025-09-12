import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../common/constants/app_colors.dart';
import '../../../../common/widgets/custom_3d_icons.dart';
import '../../../../models/group_model.dart';
import '../../../../services/group_service.dart';
import '../widgets/group_card.dart';
import 'create_group_screen.dart';
import 'group_details_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen>
    with TickerProviderStateMixin {
  final GroupService _groupService = GroupService();
  final TextEditingController _searchController = TextEditingController();
  
  List<GroupModel> _groups = [];
  List<GroupModel> _userGroups = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String _selectedCategory = 'All';
  
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
      final publicGroups = await _groupService.getPublicGroups(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
      );
      final userGroups = await _groupService.getUserGroups();
      
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
        category: _selectedCategory == 'All' ? null : _selectedCategory,
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

  Future<void> _joinGroup(GroupModel group) async {
    final success = await _groupService.joinGroup(group.id!);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully joined ${group.name}!'),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadGroups(); // Refresh the list
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to join group'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _navigateToGroupDetails(GroupModel group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupDetailsScreen(group: group),
      ),
    );
  }

  void _navigateToCreateGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateGroupScreen(),
      ),
    ).then((_) => _loadGroups()); // Refresh after creating
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Cultural Groups',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _navigateToCreateGroup,
            icon: Custom3DIcons.add(size: 24),
            tooltip: 'Create Group',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          
          // Create Group Button
          _buildCreateGroupButton(),
          
          // Category Filter
          _buildCategoryFilter(),
          
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
      margin: const EdgeInsets.all(16),
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
          hintText: 'Search groups...',
          hintStyle: GoogleFonts.poppins(
            color: AppColors.textSecondary,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.primaryGreen,
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
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCreateGroupButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: _navigateToCreateGroup,
          icon: Custom3DIcons.add(size: 20),
          label: Text(
            'Create Group',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: GroupCategories.categories.length + 1,
        itemBuilder: (context, index) {
          final category = index == 0 ? 'All' : GroupCategories.categories[index - 1];
          final isSelected = _selectedCategory == category;
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                category,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedCategory = category);
                _loadGroups();
              },
              backgroundColor: Colors.white,
              selectedColor: AppColors.primaryGreen,
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected ? AppColors.primaryGreen : AppColors.border,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
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
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w400,
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
        icon: Custom3DIcons.groups(size: 64),
        title: 'No Groups Found',
        subtitle: _isSearching
            ? 'Try adjusting your search terms'
            : 'Be the first to create a group in this category!',
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
          return GroupCard(
            group: group,
            onTap: () => _navigateToGroupDetails(group),
            onJoin: () => _joinGroup(group),
          );
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
        icon: Custom3DIcons.groups(size: 64),
        title: 'No Groups Joined',
        subtitle: 'Discover and join cultural groups that interest you!',
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
          return GroupCard(
            group: group,
            onTap: () => _navigateToGroupDetails(group),
            showJoinButton: false,
          );
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
      return group.isCreator(_groupService.currentUserId ?? '');
    }).toList();

    if (createdGroups.isEmpty) {
      return _buildEmptyState(
        icon: Custom3DIcons.add(size: 64),
        title: 'No Groups Created',
        subtitle: 'Create your first cultural group and start building your community!',
        actionButton: ElevatedButton.icon(
          onPressed: _navigateToCreateGroup,
          icon: Custom3DIcons.add(size: 20),
          label: const Text('Create Group'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
          ),
        ),
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
          return GroupCard(
            group: group,
            onTap: () => _navigateToGroupDetails(group),
            showJoinButton: false,
            showAdminBadge: true,
          );
        },
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
            icon,
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionButton != null) ...[
              const SizedBox(height: 24),
              actionButton,
            ],
          ],
        ),
      ),
    );
  }
}
