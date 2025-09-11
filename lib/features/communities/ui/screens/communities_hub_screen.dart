import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../common/routes/route_name.dart';
import '../../../../common/widgets/custom_3d_icons.dart';
import '../../../../common/constants/app_colors.dart';

class CommunitiesHubScreen extends StatefulWidget {
  const CommunitiesHubScreen({Key? key}) : super(key: key);

  @override
  State<CommunitiesHubScreen> createState() => _CommunitiesHubScreenState();
}

class _CommunitiesHubScreenState extends State<CommunitiesHubScreen> {
  String _selectedTab = 'discover';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "communities_hub_fab",
        onPressed: () {
          Navigator.pushNamed(context, RouteName.eventTemplateSelection);
        },
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
              icon: Custom3DIcons.createEvent(),
        label: Text(
          'Create Event',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cultural Communities',
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Connect, learn, and grow within African cultural communities',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: const Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, RouteName.culturalProfile);
            },
              icon: Custom3DIcons.profile(size: 28),
            tooltip: 'Your Cultural Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTab('discover', 'Discover', Custom3DIcons.discover()),
          _buildTab('groups', 'Groups', Custom3DIcons.groupsTab()),
          _buildTab('learning', 'Learning', Custom3DIcons.learningTab()),
          _buildTab('networking', 'Network', Custom3DIcons.networkingTab()),
        ],
      ),
    );
  }

  Widget _buildTab(String tabId, String label, Widget icon) {
    final isSelected = _selectedTab == tabId;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = tabId;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : const Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 'discover':
        return _buildDiscoverTab();
      case 'groups':
        return _buildGroupsTab();
      case 'learning':
        return _buildLearningTab();
      case 'networking':
        return _buildNetworkingTab();
      default:
        return _buildDiscoverTab();
    }
  }

  Widget _buildDiscoverTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0, // Further reduced to accommodate 3D icons
            children: [
                        _buildActionCard('Events', 'Cultural celebrations', Custom3DIcons.events(), AppColors.primaryGreen),
                        _buildActionCard('Groups', 'Join communities', Custom3DIcons.groups(), AppColors.culture),
                        _buildActionCard('Learning', 'Cultural stories', Custom3DIcons.learning(), AppColors.primaryGreenLight),
                        _buildActionCard('Network', 'Professional connections', Custom3DIcons.networking(), AppColors.business),
            ],
          ),
          const SizedBox(height: 20), // Add bottom padding
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, Widget icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: icon,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: const Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsTab() {
    return const Center(child: Text('Groups Tab - Coming Soon'));
  }

  Widget _buildLearningTab() {
    return const Center(child: Text('Learning Tab - Coming Soon'));
  }

  Widget _buildNetworkingTab() {
    return const Center(child: Text('Networking Tab - Coming Soon'));
  }
}