import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../../common/constants/app_spacing.dart';
import '../../../../common/widgets/state_views/state_views.dart';
import '../../models/community_group_model.dart';
import '../widgets/community_group_card.dart';
import '../widgets/community_group_filter_bar.dart';

class CommunityGroupsScreen extends StatefulWidget {
  const CommunityGroupsScreen({super.key});

  @override
  State<CommunityGroupsScreen> createState() => _CommunityGroupsScreenState();
}

class _CommunityGroupsScreenState extends State<CommunityGroupsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _selectedCategory = 'All';
  String _selectedCountry = 'All';

  // Mock data for demonstration
  final List<CommunityGroup> _mockGroups = [
    CommunityGroup(
      id: '1',
      name: 'Nigerian Tech Professionals',
      description:
          'Connect with Nigerian tech professionals worldwide. Share opportunities, mentorship, and industry insights.',
      category: 'Professional',
      country: 'Nigeria',
      city: 'Lagos',
      creatorId: 'creator1',
      memberIds: ['user1', 'user2', 'user3'],
      adminIds: ['creator1'],
      imageUrl: '',
      isPublic: true,
      isVerified: true,
      rules: {'respect': 'Be respectful', 'spam': 'No spam'},
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
      memberCount: 1250,
      tags: ['Technology', 'Software', 'Engineering', 'Career'],
    ),
    CommunityGroup(
      id: '2',
      name: 'Ghanaian Food Culture',
      description:
          'Share traditional Ghanaian recipes, cooking techniques, and food stories. Celebrate our culinary heritage.',
      category: 'Cultural',
      country: 'Ghana',
      city: 'Accra',
      creatorId: 'creator2',
      memberIds: ['user4', 'user5', 'user6'],
      adminIds: ['creator2'],
      imageUrl: '',
      isPublic: true,
      isVerified: true,
      rules: {
        'authentic': 'Share authentic recipes',
        'respect': 'Respect traditions',
      },
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now(),
      memberCount: 890,
      tags: ['Food', 'Cooking', 'Culture', 'Traditions'],
    ),
    CommunityGroup(
      id: '3',
      name: 'Kenyan Music & Arts',
      description:
          'Discover Kenyan music, art, and cultural expressions. Support local artists and celebrate creativity.',
      category: 'Interest',
      country: 'Kenya',
      city: 'Nairobi',
      creatorId: 'creator3',
      memberIds: ['user7', 'user8', 'user9'],
      adminIds: ['creator3'],
      imageUrl: '',
      isPublic: true,
      isVerified: false,
      rules: {
        'support': 'Support local artists',
        'original': 'Share original content',
      },
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      updatedAt: DateTime.now(),
      memberCount: 456,
      tags: ['Music', 'Art', 'Culture', 'Entertainment'],
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              CommunityGroupFilterBar(
                selectedCategory: _selectedCategory,
                selectedCountry: _selectedCountry,
                onCategoryChanged: (category) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                onCountryChanged: (country) {
                  setState(() {
                    _selectedCountry = country;
                  });
                },
              ),
              Expanded(
                child: _buildGroupsList(),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'community_groups_fab',
          onPressed: () {
            // TODO(dev): Navigate to create group screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Create Group feature coming soon!'),
                backgroundColor: AppColors.primaryGreen,
              ),
            );
          },
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.group_add),
          label: Text(
            'Create Group',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Community Groups',
                    style: GoogleFonts.montserrat(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Join cultural, professional, and interest-based communities',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                  }
                });
              },
              icon: Icon(
                _isSearching ? Icons.close : Icons.search,
                color: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
      );

  Widget _buildSearchBar() {
    if (!_isSearching) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search groups...',
          hintStyle: GoogleFonts.montserrat(color: Colors.grey[500]),
          prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildGroupsList() {
    final filteredGroups = _mockGroups.where((group) {
      final matchesSearch = _searchController.text.isEmpty ||
          group.name
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()) ||
          group.description
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());

      final matchesCategory =
          _selectedCategory == 'All' || group.category == _selectedCategory;
      final matchesCountry =
          _selectedCountry == 'All' || group.country == _selectedCountry;

      return matchesSearch && matchesCategory && matchesCountry;
    }).toList();

    if (filteredGroups.isEmpty) {
      return const AppEmptyView(
        title: 'No groups found',
        subtitle: 'Try adjusting your filters or create a new group',
        icon: Icons.group_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filteredGroups.length,
      itemBuilder: (context, index) => CommunityGroupCard(
        group: filteredGroups[index],
        onJoin: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Joined ${filteredGroups[index].name}!'),
              backgroundColor: AppColors.primaryGreen,
            ),
          );
        },
      ),
    );
  }
}
