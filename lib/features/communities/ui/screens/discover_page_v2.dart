import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../common/bloc/user/user_bloc.dart';
import '../../../../common/constants/app_colors.dart';
import '../../../../common/routes/route_name.dart';
import '../../../../models/user_model.dart';
import '../../../discovery/data/services/discovery_service.dart';
import '../../../events/data/models/event_model.dart';
import '../../../events/data/services/events_firestore_service.dart';
import '../../../groups/data/services/unified_group_service.dart';
import '../../../groups/screens/unified_groups_screen.dart';
import '../widgets/discover_section_header.dart';
import '../widgets/discover_skeleton_card.dart';
import '../widgets/event_card_overlay.dart';
import '../widgets/horizontal_snap_list.dart';
import '../widgets/people_card.dart';

enum _DiscoverBlock {
  trendingEvent,
  peopleYouMayLike,
  communities,
  happeningThisWeek,
  stats,
}

class DiscoverPageV2 extends StatefulWidget {
  const DiscoverPageV2({
    this.onSeeAllPeopleTap,
    super.key,
  });

  final VoidCallback? onSeeAllPeopleTap;

  @override
  State<DiscoverPageV2> createState() => _DiscoverPageV2State();
}

class _DiscoverPageV2State extends State<DiscoverPageV2> {
  static const String _communityPlaceholderAsset =
      'assets/images/placeholders/discover_community_placeholder.png';

  final EventsFirestoreService _eventsService = EventsFirestoreService();
  final UnifiedGroupService _groupService = UnifiedGroupService();

  UserModel? _currentUser;

  List<UserModel> _people = [];
  bool _peopleLoading = true;
  String? _peopleError;

  List<EventModel> _events = [];
  bool _eventsLoading = true;
  String? _eventsError;
  bool _usingGlobalEventsFallback = false;

  List<UnifiedGroup> _communities = [];
  bool _communitiesLoading = true;
  String? _communitiesError;

  int _eventCount = 0;
  int _communityCount = 0;
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    _currentUser = context.read<UserBloc>().currentUser;
    unawaited(_loadAll());
  }

  Future<void> _loadAll() => Future.wait([
        _loadPeople(),
        _loadEvents(),
        _loadCommunities(),
        _loadStats(),
      ]);

  // ---------------------------------------------------------------------------
  // Data loaders
  // ---------------------------------------------------------------------------

  Future<void> _loadPeople() async {
    if (!mounted) return;
    setState(() {
      _peopleLoading = true;
      _peopleError = null;
    });

    try {
      final user = _currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _people = [];
          _peopleLoading = false;
        });
        return;
      }

      final results = await DiscoveryService.getUsersForDiscovery(
        user,
        forceRefresh: true,
      );

      if (!mounted) return;
      setState(() {
        _people = results.take(10).toList();
        _peopleLoading = false;
      });
    } on Object catch (e) {
      log('Error loading people: $e');
      if (!mounted) return;
      setState(() {
        _peopleError = 'Could not load people';
        _peopleLoading = false;
      });
    }
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;
    setState(() {
      _eventsLoading = true;
      _eventsError = null;
      _usingGlobalEventsFallback = false;
    });

    try {
      // Over-fetch so we can client-side filter by location
      final results = await _eventsService.fetchEvents(
        limit: 30,
        startDate: DateTime.now(),
      );

      final rawLocation = _currentUser?.living_in?.toLowerCase().trim() ?? '';
      // Extract tokens from formats like "San Francisco, CA" or "Lagos, Nigeria"
      final locationTokens = rawLocation
          .split(RegExp(r'[,\s]+'))
          .where((t) => t.length > 2)
          .toList();

      List<EventModel> filtered;
      var usingGlobalFallback = false;

      if (locationTokens.isNotEmpty) {
        filtered = results.where((e) {
          final haystack = [
            e.location.city,
            e.location.state,
            e.location.country,
            e.location.name,
          ].where((s) => s != null).join(' ').toLowerCase();

          return locationTokens.any((token) => haystack.contains(token));
        }).toList();

        if (filtered.isEmpty) {
          filtered = results.take(6).toList();
          usingGlobalFallback = true;
        }
      } else {
        filtered = results;
      }

      if (!mounted) return;
      setState(() {
        _events = filtered.take(6).toList();
        _eventsLoading = false;
        _usingGlobalEventsFallback = usingGlobalFallback;
      });
    } on Object catch (e) {
      log('Error loading events: $e');
      if (!mounted) return;
      setState(() {
        _eventsError = 'Could not load events';
        _eventsLoading = false;
      });
    }
  }

  Future<void> _loadCommunities() async {
    if (!mounted) return;
    setState(() {
      _communitiesLoading = true;
      _communitiesError = null;
    });

    try {
      final userLocation = _currentUser?.living_in;
      final stream = _groupService.getPublicGroups(
        location: (userLocation != null && userLocation.isNotEmpty)
            ? userLocation
            : null,
      );
      final snapshot = await stream.first;
      if (!mounted) return;
      setState(() {
        _communities = snapshot.take(10).toList();
        _communitiesLoading = false;
      });
    } on Object catch (e) {
      log('Error loading communities: $e');
      if (!mounted) return;
      setState(() {
        _communitiesError = 'Could not load communities';
        _communitiesLoading = false;
      });
    }
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _statsLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final now = DateTime.now();
      // Dart weekday: 1=Mon..7=Sun. Days remaining until end of Sunday.
      final daysUntilSunday = DateTime.daysPerWeek - now.weekday;
      final endOfWeek = DateTime(
        now.year,
        now.month,
        now.day + daysUntilSunday,
        23,
        59,
        59,
      );

      final eventsQuery = await firestore
          .collection('events')
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .where(
            'startDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfWeek),
          )
          .count()
          .get();

      final groupsQuery = await firestore
          .collection('unifiedGroups')
          .where('isPublic', isEqualTo: true)
          .count()
          .get();

      if (!mounted) return;
      setState(() {
        _eventCount = eventsQuery.count ?? 0;
        _communityCount = groupsQuery.count ?? 0;
        _statsLoading = false;
      });
    } on Object catch (e) {
      log('Error loading stats: $e');
      if (!mounted) return;
      setState(() => _statsLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  void _onSeeAllPeople() {
    final onSeeAllPeopleTap = widget.onSeeAllPeopleTap;
    if (onSeeAllPeopleTap != null) {
      onSeeAllPeopleTap();
      return;
    }

    final nav = DefaultTabController.maybeOf(context);
    if (nav != null && nav.length > 0) {
      nav.animateTo(0);
    }
  }

  void _onSeeAllEvents() {
    unawaited(Navigator.pushNamed(context, RouteName.eventsScreen));
  }

  void _onBrowseCommunities() {
    unawaited(
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UnifiedGroupsScreen()),
      ),
    );
  }

  void _onTapPerson(UserModel user) {
    unawaited(
      Navigator.pushNamed(
        context,
        RouteName.userDetailScreen,
        arguments: user,
      ),
    );
  }

  void _onTapEvent(EventModel event) {
    unawaited(
      Navigator.pushNamed(
        context,
        RouteName.eventDetails,
        arguments: event,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Filter sheet
  // ---------------------------------------------------------------------------

  void _showFilterSheet() {
    final user = _currentUser;
    if (user == null) return;

    unawaited(
      showModalBottomSheet<void>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => _DiscoverFilterSheet(
          currentUser: user,
          onApply: (selectedFilter) async {
            _currentUser?.lookingFor = selectedFilter;
            await _loadAll();
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

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
          child: RefreshIndicator(
            color: AppColors.primaryGreen,
            onRefresh: _loadAll,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  _buildSubtitleRow(),
                  ..._buildMixedDiscoverFeed(),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      );

  // ---------------------------------------------------------------------------
  // Subtitle + filter
  // ---------------------------------------------------------------------------

  String get _subtitleText {
    final city = _currentUser?.living_in;
    if (city != null && city.isNotEmpty) {
      return 'Discover people, events, and communities in $city';
    }
    return 'Discover people, events, and communities near you';
  }

  Widget _buildSubtitleRow() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _subtitleText,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Material(
              color: AppColors.primaryGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _showFilterSheet,
                borderRadius: BorderRadius.circular(12),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  List<_DiscoverBlock> _composeBlocks() {
    return const <_DiscoverBlock>[
      _DiscoverBlock.trendingEvent,
      _DiscoverBlock.peopleYouMayLike,
      _DiscoverBlock.communities,
      _DiscoverBlock.happeningThisWeek,
      _DiscoverBlock.stats,
    ];
  }

  List<Widget> _buildMixedDiscoverFeed() {
    final blocks = _composeBlocks();
    final widgets = <Widget>[const SizedBox(height: 24)];

    for (final block in blocks) {
      switch (block) {
        case _DiscoverBlock.trendingEvent:
          widgets.add(_buildTrendingEventBlock());
        case _DiscoverBlock.peopleYouMayLike:
          widgets.add(_buildPeopleYouMayLikeBlock());
        case _DiscoverBlock.communities:
          widgets.add(_buildCommunitiesBlock());
        case _DiscoverBlock.happeningThisWeek:
          widgets.add(_buildHappeningThisWeekBlock());
        case _DiscoverBlock.stats:
          widgets.add(_buildStatsBlock());
      }
      widgets.add(const SizedBox(height: 24));
    }

    return widgets;
  }

  Widget _buildTrendingEventBlock() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DiscoverSectionHeader(
            title: 'Trending Near You',
            actionLabel: 'See all nearby',
            onAction: _onSeeAllEvents,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildTrendingEventCard(),
          ),
          if (_usingGlobalEventsFallback) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Showing popular events outside your area',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      );

  Widget _buildTrendingEventCard() {
    if (_eventsLoading) {
      return const DiscoverSkeletonCard(height: 260);
    }
    if (_eventsError != null) {
      return _buildInlineError(_eventsError!, _loadEvents,
          horizontalPadding: 0);
    }
    if (_events.isEmpty) {
      return _buildImageEmpty(
        assetPath: 'assets/images/placeholders/discover_event_placeholder.png',
        message: 'No trending events nearby',
        actionLabel: 'Browse all events',
        onAction: _onSeeAllEvents,
      );
    }
    return EventCardOverlay(
      event: _events.first,
      onTap: () => _onTapEvent(_events.first),
    );
  }

  Widget _buildPeopleYouMayLikeBlock() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DiscoverSectionHeader(
            title: 'People Near You',
            actionLabel: 'See all',
            onAction: _onSeeAllPeople,
          ),
          const SizedBox(height: 12),
          _buildPeopleSection(),
        ],
      );

  Widget _buildCommunitiesBlock() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DiscoverSectionHeader(
            title: 'Explore Communities',
            actionLabel: 'Browse all',
            onAction: _onBrowseCommunities,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildCommunitiesHeroCard(),
          ),
        ],
      );

  Widget _buildHappeningThisWeekBlock() {
    final upcomingEvents =
        _events.length > 1 ? _events.skip(1).toList() : _events;

    final showNonDuplicateEmpty = !_eventsLoading &&
        _eventsError == null &&
        upcomingEvents.isEmpty &&
        _events.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DiscoverSectionHeader(
          title: 'Happening This Week',
          actionLabel: 'See all nearby',
          onAction: _onSeeAllEvents,
        ),
        const SizedBox(height: 12),
        if (showNonDuplicateEmpty)
          _buildActionableEmpty(
            icon: Icons.event_note_outlined,
            message: 'No additional events this week',
            actionLabel: 'Browse all events',
            onAction: _onSeeAllEvents,
          )
        else
          _buildEventsSection(
            events: upcomingEvents,
          ),
      ],
    );
  }

  Widget _buildStatsBlock() => _buildStatsRow();

  // ---------------------------------------------------------------------------
  // People section
  // ---------------------------------------------------------------------------

  Widget _buildPeopleSection({List<UserModel>? people}) {
    final sectionPeople = people ?? _people;

    if (_peopleLoading) {
      return _buildSkeletonRow(width: 160, height: 220, count: 3);
    }
    if (_peopleError != null) {
      return _buildInlineError(_peopleError!, _loadPeople);
    }
    if (sectionPeople.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _buildImageEmpty(
          assetPath:
              'assets/images/placeholders/discover_people_placeholder.png',
          message: 'No people found nearby',
          actionLabel: 'Refresh',
          onAction: _loadPeople,
          height: 220,
        ),
      );
    }
    return HorizontalSnapList(
      itemWidth: 160,
      itemHeight: 220,
      itemCount: sectionPeople.length,
      itemBuilder: (_, i) => PeopleCard(
        user: sectionPeople[i],
        onTap: () => _onTapPerson(sectionPeople[i]),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Events section
  // ---------------------------------------------------------------------------

  Widget _buildEventsSection({
    List<EventModel>? events,
  }) {
    final sectionEvents = events ?? _events;

    if (_eventsLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Expanded(child: DiscoverSkeletonCard(height: 200)),
            const SizedBox(width: 12),
            Expanded(child: DiscoverSkeletonCard(height: 200)),
          ],
        ),
      );
    }
    if (_eventsError != null) {
      return _buildInlineError(_eventsError!, _loadEvents);
    }
    if (sectionEvents.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _buildImageEmpty(
          assetPath:
              'assets/images/placeholders/discover_happeningthisweek_placeholder.png',
          message: 'No upcoming events nearby',
          actionLabel: 'Browse all events',
          onAction: _onSeeAllEvents,
        ),
      );
    }

    final pairs = <List<EventModel>>[];
    for (var i = 0; i < sectionEvents.length; i += 2) {
      pairs.add(
          sectionEvents.sublist(i, (i + 2).clamp(0, sectionEvents.length)));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          for (var p = 0; p < pairs.length; p++) ...[
            if (p > 0) const SizedBox(height: 12),
            Row(
              children: [
                for (var c = 0; c < pairs[p].length; c++) ...[
                  if (c > 0) const SizedBox(width: 12),
                  Expanded(
                    child: EventCardOverlay(
                      event: pairs[p][c],
                      onTap: () => _onTapEvent(pairs[p][c]),
                    ),
                  ),
                ],
                if (pairs[p].length == 1) ...[
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox()),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stats row
  // ---------------------------------------------------------------------------

  Widget _buildStatsRow() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _statsLoading
            ? const SizedBox.shrink()
            : Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildStatChip(
                          Icons.event_rounded,
                          '$_eventCount events this week',
                        ),
                        const SizedBox(width: 16),
                        _buildStatChip(
                          Icons.groups_rounded,
                          '$_communityCount communities',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: _onSeeAllEvents,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'See all nearby',
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: AppColors.primaryGreen,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      );

  Widget _buildStatChip(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryGreen),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      );

  // ---------------------------------------------------------------------------
  // Communities section
  // ---------------------------------------------------------------------------

  Widget _buildCommunitiesHeroCard() {
    if (_communitiesLoading) {
      return const DiscoverSkeletonCard(height: 200);
    }
    if (_communitiesError != null) {
      return _buildInlineError(_communitiesError!, _loadCommunities,
          horizontalPadding: 0);
    }
    if (_communities.isEmpty) {
      return _buildImageEmpty(
        assetPath: _communityPlaceholderAsset,
        message: 'No communities yet',
        actionLabel: 'Browse all communities',
        onAction: _onBrowseCommunities,
        height: 200,
      );
    }

    final totalMembers =
        _communities.fold<int>(0, (sum, g) => sum + g.memberCount);

    return Semantics(
      button: true,
      label: 'Explore ${_communities.length} communities',
      child: Material(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _onBrowseCommunities,
          child: SizedBox(
            height: 240,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  _communityPlaceholderAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) => _communityFallbackBg(),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.3, 1.0],
                      colors: [
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.70),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_communities.length} communities near you',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalMembers members across all groups',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 36,
                        child: OutlinedButton(
                          onPressed: _onBrowseCommunities,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: Text(
                            'Browse all',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _communityFallbackBg() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryGreen.withValues(alpha: 0.6),
              AppColors.primaryGreen.withValues(alpha: 0.25),
            ],
          ),
        ),
        child: const Center(
          child: Icon(Icons.groups_rounded, size: 48, color: Colors.white38),
        ),
      );

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  Widget _buildSkeletonRow({
    required double width,
    required double height,
    required int count,
  }) =>
      HorizontalSnapList(
        itemWidth: width,
        itemHeight: height,
        itemCount: count,
        itemBuilder: (_, __) =>
            DiscoverSkeletonCard(width: width, height: height),
      );

  Widget _buildInlineError(
    String message,
    VoidCallback onRetry, {
    double horizontalPadding = 24,
  }) =>
      Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: Colors.grey.shade400,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: onRetry,
                child: Text(
                  'Retry',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildActionableEmpty({
    required IconData icon,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    double horizontalPadding = 24,
  }) =>
      Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              Icon(icon, size: 40, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                message,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 40,
                child: OutlinedButton(
                  onPressed: onAction,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                    side: const BorderSide(color: AppColors.primaryGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: Text(
                    actionLabel,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildImageEmpty({
    required String assetPath,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    double height = 260,
  }) =>
      Semantics(
        button: true,
        label: '$message — $actionLabel',
        child: Material(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onAction,
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    assetPath,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.primaryGreen.withValues(alpha: 0.15),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.10),
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 36,
                          child: OutlinedButton(
                            onPressed: onAction,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white70),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: Text(
                              actionLabel,
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

// -----------------------------------------------------------------------------
// Discover filter bottom sheet
// -----------------------------------------------------------------------------

class _DiscoverFilterSheet extends StatefulWidget {
  const _DiscoverFilterSheet({
    required this.currentUser,
    required this.onApply,
  });

  final UserModel currentUser;
  final Future<void> Function(String selectedFilter) onApply;

  @override
  State<_DiscoverFilterSheet> createState() => _DiscoverFilterSheetState();
}

class _DiscoverFilterSheetState extends State<_DiscoverFilterSheet> {
  static const _modes = <String, (String, IconData)>{
    'Dating': ('Dating & Romance', Icons.favorite_outline),
    'Friendship': ('Friendship & Social', Icons.people_outline),
    'Networking': ('Professional Networking', Icons.work_outline),
    'Mixed': ('All of the Above', Icons.explore_outlined),
  };

  late String _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentUser.lookingFor ?? 'Dating';
    if (!_modes.containsKey(_selected)) {
      _selected = 'Dating';
    }
  }

  Future<void> _applyFilters() async {
    final changed = _selected != (widget.currentUser.lookingFor ?? 'Dating');
    if (!changed) {
      Navigator.pop(context);
      return;
    }

    setState(() => _saving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'lookingFor': _selected});
      }
      if (!mounted) return;
      Navigator.pop(context);
      await widget.onApply(_selected);
    } on Object catch (e) {
      log('Error saving filter: $e');
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'What are you looking for?',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'This helps us show you the right people',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              ..._modes.entries.map((e) {
                final isSelected = e.key == _selected;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: isSelected
                        ? AppColors.primaryGreen.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () => setState(() => _selected = e.key),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryGreen
                                : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              e.value.$2,
                              size: 22,
                              color: isSelected
                                  ? AppColors.primaryGreen
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                e.value.$1,
                                style: GoogleFonts.montserrat(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primaryGreen
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                size: 22,
                                color: AppColors.primaryGreen,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Apply',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      );
}
