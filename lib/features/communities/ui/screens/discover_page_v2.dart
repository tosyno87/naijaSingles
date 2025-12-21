import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../../common/routes/route_name.dart';
import '../../../../common/widgets/custom_3d_icons.dart';
import '../../../groups/screens/unified_groups_screen.dart';

/// DiscoverPageV2 - A comprehensive discover screen matching the wireframe
/// Features:
/// - Start Here section with Events and Communities cards
/// - Recommended for You section
/// - Happening Near You section with location-based stats
/// - Explore More section with navigation options
class DiscoverPageV2 extends StatefulWidget {
  const DiscoverPageV2({super.key});

  @override
  State<DiscoverPageV2> createState() => _DiscoverPageV2State();
}

class _DiscoverPageV2State extends State<DiscoverPageV2> {
  // Hardcoded constants (can be replaced with Firestore data later)
  static const int eventsThisWeek = 3;
  static const int activeCommunities = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Discover',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subtitle
              _buildSubtitle(),
              const SizedBox(height: 32),

              // Start Here Section
              _buildSectionHeader('Start Here'),
              const SizedBox(height: 16),
              _buildStartHereCards(context),
              const SizedBox(height: 32),

              // Recommended for You Section
              _buildSectionHeader('Recommended for You'),
              const SizedBox(height: 16),
              _buildRecommendedList(context),
              const SizedBox(height: 32),

              // Happening Near You Section
              _buildSectionHeader('Happening Near You'),
              const SizedBox(height: 16),
              _buildHappeningNearYou(context),
              const SizedBox(height: 32),

              // Explore More Section
              _buildSectionHeader('Explore More'),
              const SizedBox(height: 16),
              _buildExploreMore(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Discover people, events, and',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        Text(
          'communities near you',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildStartHereCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            context: context,
            title: 'Events',
            subtitle: "What's happening\nnear you",
            icon: Custom3DIcons.events(),
            color: const Color(0xFFFF9800), // Orange for events
            onTap: () {
              Navigator.pushNamed(context, RouteName.eventsScreen);
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard(
            context: context,
            title: 'Communities',
            subtitle: 'Find your people\nby interest',
            icon: Custom3DIcons.groups(),
            color: const Color(0xFF6B46C1), // Purple for communities
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UnifiedGroupsScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Widget icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: color.withOpacity(0.1),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.1),
                      color.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: icon,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D2D2D),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: const Color(0xFF666666),
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendedList(BuildContext context) {
    final recommendations = [
      _RecommendationItem(
        title: 'Lagos Diaspora Professionals',
        type: RecommendationType.community,
      ),
      _RecommendationItem(
        title: 'Afro Tech Meetup – This Saturday',
        type: RecommendationType.event,
      ),
      _RecommendationItem(
        title: 'Singles Game Night (5 miles away)',
        type: RecommendationType.event,
      ),
      _RecommendationItem(
        title: 'New Community: Book Lovers 🇳🇬',
        type: RecommendationType.community,
      ),
    ];

    return Column(
      children: recommendations.map((item) {
        return _buildListTile(
          context: context,
          title: item.title,
          type: item.type,
          onTap: () {
            _showComingSoonSnackBar(context);
          },
        );
      }).toList(),
    );
  }

  Widget _buildListTile({
    required BuildContext context,
    required String title,
    required RecommendationType type,
    required VoidCallback onTap,
  }) {
    final isEvent = type == RecommendationType.event;
    final icon = isEvent ? Icons.celebration_rounded : Icons.groups_rounded;
    final label = isEvent ? 'Event' : 'Community';
    final iconColor = isEvent ? const Color(0xFFFF9800) : const Color(0xFF6B46C1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                icon,
                size: 18,
                color: iconColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHappeningNearYou(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Navigate to Events screen (can be filtered by location later)
          Navigator.pushNamed(context, RouteName.eventsScreen);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: AppColors.primaryGreen.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location hint
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 18,
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Based on your location',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Stats rows
              _buildStatRow('$eventsThisWeek events this week'),
              const SizedBox(height: 10),
              _buildStatRow('$activeCommunities active communities'),
              const SizedBox(height: 12),
              // CTA line
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'See what\'s nearby',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.primaryGreen,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String text) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            shape: BoxShape.circle,
          ),
        ),
        Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: 15,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildExploreMore(BuildContext context) {
    return Column(
      children: [
        _buildExploreRow(
          context: context,
          title: 'Browse all Events',
          onTap: () {
            Navigator.pushNamed(context, RouteName.eventsScreen);
          },
        ),
        const SizedBox(height: 12),
        _buildExploreRow(
          context: context,
          title: 'Browse all Communities',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UnifiedGroupsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildExploreRow({
    required BuildContext context,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoonSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Coming soon',
          style: GoogleFonts.montserrat(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Enum to distinguish between event and community recommendations
enum RecommendationType {
  event,
  community,
}

/// Helper class to represent recommendation items with their type
class _RecommendationItem {
  final String title;
  final RecommendationType type;

  _RecommendationItem({
    required this.title,
    required this.type,
  });
}

