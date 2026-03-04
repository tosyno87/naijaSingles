import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../../common/routes/route_name.dart';
import '../../../../common/widgets/custom_3d_icons.dart';
import '../../../events/data/models/event_model.dart';
import '../../../events/data/services/events_firestore_service.dart';
import '../../../groups/data/services/unified_group_service.dart';
import '../../../groups/screens/group_details_screen.dart';
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

  final EventsFirestoreService _eventsService = EventsFirestoreService();
  final UnifiedGroupService _groupService = UnifiedGroupService();

  List<_RecommendationItem> _recommendations = [];
  bool _isLoadingRecommendations = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadRecommendations());
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoadingRecommendations = true);

    try {
      // Fetch upcoming events (limit 2 for recommendations)
      final events = await _eventsService.fetchEvents(
        limit: 2,
        startDate: DateTime.now(),
      );

      // Fetch public groups (limit 2 for recommendations)
      final groupsStream = _groupService.getPublicGroups();
      final groupsSnapshot = await groupsStream.first;
      final groups = groupsSnapshot.take(2).toList();

      // Combine events and groups into recommendations
      final recommendations = <_RecommendationItem>[];

      // Add groups first (communities)
      for (final group in groups) {
        recommendations.add(
          _RecommendationItem(
            title: group.name,
            type: RecommendationType.community,
            group: group,
          ),
        );
      }

      // Add events
      for (final event in events) {
        // Format event title with date
        String title = event.name;
        final now = DateTime.now();
        final eventDate = event.startDate;
        final daysUntil = eventDate.difference(now).inDays;

        if (daysUntil == 0) {
          title = '$title – Today';
        } else if (daysUntil == 1) {
          title = '$title – Tomorrow';
        } else if (daysUntil <= 7) {
          title = '$title – This ${_getDayName(eventDate.weekday)}';
        }

        recommendations.add(
          _RecommendationItem(
            title: title,
            type: RecommendationType.event,
            event: event,
          ),
        );
      }

      // If we don't have enough recommendations, add placeholder items
      while (recommendations.length < 4) {
        if (recommendations.length % 2 == 0) {
          recommendations.add(
            _RecommendationItem(
              title: 'More events coming soon',
              type: RecommendationType.event,
            ),
          );
        } else {
          recommendations.add(
            _RecommendationItem(
              title: 'More communities coming soon',
              type: RecommendationType.community,
            ),
          );
        }
      }

      // Limit to 4 items
      setState(() {
        _recommendations = recommendations.take(4).toList();
        _isLoadingRecommendations = false;
      });
    } catch (e) {
      log('Error loading recommendations: $e');
      // Fallback to placeholder items on error
      setState(() {
        _recommendations = [
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
        _isLoadingRecommendations = false;
      });
    }
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
              _buildSectionHeader('Start Here', fontSize: 22),
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

  Widget _buildSubtitle() => Column(
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

  Widget _buildSectionHeader(String title, {double fontSize = 20}) => Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );

  Widget _buildStartHereCards(BuildContext context) => Row(
      children: [
        Expanded(
          child: _buildActionCard(
            context: context,
            title: 'Events',
            subtitle: "What's happening\nnear you",
            icon: Custom3DIcons.events(),
            color: const Color(0xFFFF9800), // Orange for events
            onTap: () {
              unawaited(Navigator.pushNamed(context, RouteName.eventsScreen));
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
              unawaited(Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UnifiedGroupsScreen(),
                ),
              ));
            },
          ),
        ),
      ],
    );

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Widget icon,
    required Color color,
    required VoidCallback onTap,
  }) => Material(
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
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: color.withValues(alpha: 0.1),
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
                      color.withValues(alpha: 0.1),
                      color.withValues(alpha: 0.05),
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

  Widget _buildRecommendedList(BuildContext context) {
    if (_isLoadingRecommendations) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.1),
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryGreen,
          ),
        ),
      );
    }

    if (_recommendations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.1),
          ),
        ),
        child: Center(
          child: Text(
            'No recommendations available',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: _recommendations.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              _buildListTile(
                context: context,
                title: item.title,
                type: item.type,
                onTap: () {
                  _handleRecommendationTap(context, item);
                },
              ),
              // Add divider between items (not after last item)
              if (index < _recommendations.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey.withValues(alpha: 0.1),
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _handleRecommendationTap(BuildContext context, _RecommendationItem item) {
    if (item.type == RecommendationType.event && item.event != null) {
      unawaited(Navigator.pushNamed(
        context,
        RouteName.eventDetails,
        arguments: item.event,
      ));
    } else if (item.type == RecommendationType.community && item.group != null) {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final isMember = item.group!.isMember(currentUserId);
      unawaited(Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GroupDetailsScreen(
            group: item.group!,
            isMember: isMember,
          ),
        ),
      ));
    } else {
      if (item.type == RecommendationType.event) {
        unawaited(Navigator.pushNamed(context, RouteName.eventsScreen));
      } else {
        unawaited(Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const UnifiedGroupsScreen(),
          ),
        ));
      }
    }
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: iconColor,
              ),
              const SizedBox(width: 12),
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

  Widget _buildHappeningNearYou(BuildContext context) => Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          unawaited(Navigator.pushNamed(context, RouteName.eventsScreen));
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
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
                  const Icon(
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

  Widget _buildStatRow(String text) => Row(
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 12),
          decoration: const BoxDecoration(
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

  Widget _buildExploreMore(BuildContext context) => Column(
      children: [
        _buildExploreRow(
          context: context,
          title: 'Browse all Events',
          onTap: () {
            unawaited(Navigator.pushNamed(context, RouteName.eventsScreen));
          },
        ),
        const SizedBox(height: 12),
        _buildExploreRow(
          context: context,
          title: 'Browse all Communities',
          onTap: () {
            unawaited(Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UnifiedGroupsScreen(),
              ),
            ));
          },
        ),
      ],
    );

  Widget _buildExploreRow({
    required BuildContext context,
    required String title,
    required VoidCallback onTap,
  }) => Material(
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
              color: Colors.grey.withValues(alpha: 0.1),
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
              const Icon(
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

/// Enum to distinguish between event and community recommendations
enum RecommendationType {
  event,
  community,
}

/// Helper class to represent recommendation items with their type
class _RecommendationItem {

  _RecommendationItem({
    required this.title,
    required this.type,
    this.event,
    this.group,
  });
  final String title;
  final RecommendationType type;
  final EventModel? event;
  final UnifiedGroup? group;
}

