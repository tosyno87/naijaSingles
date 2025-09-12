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
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: FloatingActionButton(
              onPressed: _navigateToCreateGroup,
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              mini: true,
              child: const Icon(Icons.add, size: 20),
            ),
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
          hintText: 'Search groups...',
          hintStyle: GoogleFonts.poppins(
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

  Widget _buildCreateGroupButton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppColors.buttonShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _navigateToCreateGroup,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Custom3DIcons.add(size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Create Group',
                    style: GoogleFonts.poppins(
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
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: GroupCategories.categories.length + 1,
        itemBuilder: (context, index) {
          final category = index == 0 ? 'All' : GroupCategories.categories[index - 1];
          final isSelected = _selectedCategory == category;
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                category,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
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
        icon: Custom3DIcons.community(size: 64),
        title: 'No Groups Found',
        subtitle: _isSearching
            ? 'Try adjusting your search terms to find cultural groups that match your interests.'
            : 'Be the first to create a cultural group in this category and start building your community!',
        actionButton: _isSearching ? null : ElevatedButton.icon(
          onPressed: _navigateToCreateGroup,
          icon: Custom3DIcons.add(size: 18),
          label: const Text('Create Group'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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
        icon: Custom3DIcons.community(size: 64),
        title: 'No Groups Joined',
        subtitle: 'Discover and join cultural groups that match your heritage and interests!',
        actionButton: ElevatedButton.icon(
          onPressed: () {
            _tabController.animateTo(0); // Switch to Discover tab
          },
          icon: Custom3DIcons.discover(size: 18),
          label: const Text('Discover Groups'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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
        icon: Custom3DIcons.community(size: 64),
        title: 'No Groups Created',
        subtitle: 'Create your first cultural group and start building your community! Share your heritage and connect with others.',
        actionButton: ElevatedButton.icon(
          onPressed: _navigateToCreateGroup,
          icon: Custom3DIcons.add(size: 20),
          label: const Text('Create Group'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.culture.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.culture.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: icon,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.4,
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
}
