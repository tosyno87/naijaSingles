import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../common/bloc/user/user_bloc.dart';
import '../../../../common/constants/app_colors.dart';
import '../../../../common/constants/app_spacing.dart';
import '../../../../common/routes/route_name.dart';
import '../../../../common/widgets/state_views/state_views.dart';
import '../../../../models/user_model.dart';
import '../../../../services/privacy_migration_service.dart';
import '../../../discovery/data/services/discovery_service.dart';
import '../../../discovery/presentation/screens/discovery_preferences_screen.dart';
import '../../../events/data/models/event_model.dart';
import '../../../events/data/services/events_firestore_service.dart';
import '../../../explore/screens/hinge_profile_viewer_screen.dart';
import '../../../groups/data/services/unified_group_service.dart';
import '../../../groups/screens/unified_groups_screen.dart';
import '../../../home/bloc/searchuser_bloc.dart';
import '../../../home/ui/screens/user_filter/bloc/userfilter_bloc.dart';
import '../../models/discover_profile_dismiss_result.dart';
import '../../utils/discover_people_near_you_display.dart';
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
  const DiscoverPageV2({super.key});

  @override
  State<DiscoverPageV2> createState() => _DiscoverPageV2State();
}

class _DiscoverPageV2State extends State<DiscoverPageV2> {
  /// Tighter than default [AppEmptyView] padding (~24px less vertical than all-xl).
  static const EdgeInsets _discoverEmptyContentPadding =
      EdgeInsets.fromLTRB(AppSpacing.xl, 10, AppSpacing.xl, 10);

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

  StreamSubscription<List<UserModel>>? _peopleSub;

  @override
  void initState() {
    super.initState();
    _currentUser = context.read<UserBloc>().currentUser;
    unawaited(_loadAll());
  }

  @override
  void dispose() {
    final StreamSubscription<List<UserModel>>? sub = _peopleSub;
    _peopleSub = null;
    if (sub != null) {
      unawaited(sub.cancel());
    }
    super.dispose();
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

  void _applyPeopleNearYouList(List<UserModel> list) {
    if (!mounted) return;
    setState(() {
      _people = sortAndCapPeopleNearYou(list);
      _peopleLoading = false;
      _peopleError = null;
    });
  }

  /// Live stream for non-migrated users; one-shot privacy path when migrated.
  Future<void> _loadPeople() async {
    if (!mounted) return;

    await _peopleSub?.cancel();
    _peopleSub = null;

    setState(() {
      _peopleLoading = true;
      _peopleError = null;
    });

    final UserModel? user = _currentUser;
    final String? uid = user?.id;
    if (user == null || uid == null || uid.isEmpty) {
      if (!mounted) return;
      setState(() {
        _people = [];
        _peopleLoading = false;
      });
      return;
    }

    try {
      final bool migrated =
          await PrivacyMigrationService().isUserMigrated(uid);

      if (!mounted) return;

      if (migrated) {
        // Raw `users` snapshots are not privacy-filtered; keep one-shot path.
        final List<UserModel> results =
            await DiscoveryService.getUsersForDiscovery(
          user,
          forceRefresh: true,
        );
        if (!mounted) return;
        _applyPeopleNearYouList(results);
        return;
      }

      final double radiusMiles = (user.maxDistance ?? 100).toDouble();
      _peopleSub = DiscoveryService.getNearbyUsersStream(
        user,
        radiusMiles,
        intentFilter: user.lookingFor,
      ).listen(
        _applyPeopleNearYouList,
        onError: (Object e, StackTrace stackTrace) {
          log('People stream error: $e', stackTrace: stackTrace);
          if (!mounted) return;
          setState(() {
            _peopleError = 'Could not load people';
            _peopleLoading = false;
          });
        },
      );
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

          return locationTokens.any(haystack.contains);
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

  Future<void> _openDiscoveryPreferences() async {
    final UserModel? user = _currentUser ?? context.read<UserBloc>().currentUser;
    if (user == null || !mounted) return;

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => BlocProvider<UserfilterBloc>(
          create: (_) => UserfilterBloc(),
          child: BlocProvider<SearchUserBloc>(
            create: (_) => SearchUserBloc(),
            child: DiscoveryPreferencesScreen(
              currentUser: user,
              isPurchased: user.hasPremiumAccess,
              items: const <String, dynamic>{},
            ),
          ),
        ),
      ),
    );
    if (!mounted) return;
    await _loadPeople();
  }

  Future<void> _onTapPerson(UserModel user) async {
    final UserModel? me = _currentUser;
    if (me == null) return;

    final DiscoverProfileDismissResult? result =
        await Navigator.push<DiscoverProfileDismissResult?>(
      context,
      MaterialPageRoute<DiscoverProfileDismissResult?>(
        builder: (BuildContext context) => HingeProfileViewerScreen(
          currentUser: me,
          profileUser: user,
        ),
      ),
    );
    if (!mounted) return;
    if (result != null && result.removedFromQueue) {
      final String id = result.userId;
      setState(() {
        _people.removeWhere((UserModel u) => u.id == id);
      });
      final String message = result.wasMatch
          ? 'It\'s a match! Say hi from your matches.'
          : result.wasPass
              ? 'Passed.'
              : 'Like sent!';
      final SnackBar snack = SnackBar(
        content: Text(
          message,
          style: GoogleFonts.montserrat(),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snack);
    }
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Text(
          _subtitleText,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      );

  /// Base order; [trendingEvent] is omitted when there are no events so
  /// [happeningThisWeek] alone shows the canonical empty state (no duplicate).
  List<_DiscoverBlock> _composeBlocks() {
    const List<_DiscoverBlock> withTrending = <_DiscoverBlock>[
      _DiscoverBlock.peopleYouMayLike,
      _DiscoverBlock.trendingEvent,
      _DiscoverBlock.communities,
      _DiscoverBlock.happeningThisWeek,
      _DiscoverBlock.stats,
    ];
    final bool hideTrendingBecauseEventsEmpty = !_eventsLoading &&
        _eventsError == null &&
        _events.isEmpty;
    if (!hideTrendingBecauseEventsEmpty) {
      return withTrending;
    }
    return const <_DiscoverBlock>[
      _DiscoverBlock.peopleYouMayLike,
      _DiscoverBlock.communities,
      _DiscoverBlock.happeningThisWeek,
      _DiscoverBlock.stats,
    ];
  }

  List<Widget> _buildMixedDiscoverFeed() {
    final blocks = _composeBlocks();
    final widgets = <Widget>[const SizedBox(height: 16)];

    for (var i = 0; i < blocks.length; i++) {
      final _DiscoverBlock block = blocks[i];
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
      if (i < blocks.length - 1) {
        final _DiscoverBlock next = blocks[i + 1];
        final double gap =
            next == _DiscoverBlock.stats ? 6 : 12;
        widgets.add(SizedBox(height: gap));
      }
    }

    return widgets;
  }

  Widget _buildTrendingEventBlock() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DiscoverSectionHeader(
            title: 'Trending Near You',
            actionLabel: 'Browse events',
            onAction: _onSeeAllEvents,
          ),
          const SizedBox(height: 8),
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
      return _buildInlineError(
        _eventsError!,
        _loadEvents,
        horizontalPadding: 0,
      );
    }
    if (_events.isEmpty) {
      // Feed omits the trending block when empty; this is a layout fallback only.
      return const SizedBox.shrink();
    }
    return EventCardOverlay(
      event: _events.first,
      onTap: () => _onTapEvent(_events.first),
    );
  }

  Widget _buildPeopleYouMayLikeBlock() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DiscoverSectionHeader(
            title: 'People Near You',
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
            actionLabel: 'Browse groups',
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
          actionLabel: 'View all events',
          onAction: _onSeeAllEvents,
        ),
        const SizedBox(height: 12),
        if (showNonDuplicateEmpty)
          _buildActionableEmpty(
            icon: Icons.event_note_outlined,
            message: 'No other events near you this week',
            subtitle: 'Check all events to find something you like.',
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
          message: 'No people nearby',
          subtitle: 'Pull to refresh or check back later.',
          icon: Icons.people_outline,
          actionLabel: 'Refresh',
          onAction: _loadPeople,
          footerLinkHint:
              'Who you see depends on your discovery settings.',
          footerLinkLabel: 'Adjust preferences',
          onFooterLink: _openDiscoveryPreferences,
          minHeight: 220,
          compact: true,
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
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Expanded(child: DiscoverSkeletonCard(height: 200)),
            SizedBox(width: 12),
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
          message: 'No events near you this week.',
          subtitle: 'Check all events to find something you like.',
          icon: Icons.calendar_today_outlined,
          minHeight: 200,
        ),
      );
    }

    final pairs = <List<EventModel>>[];
    for (var i = 0; i < sectionEvents.length; i += 2) {
      pairs.add(
        sectionEvents.sublist(i, (i + 2).clamp(0, sectionEvents.length)),
      );
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
      return _buildInlineError(
        _communitiesError!,
        _loadCommunities,
        horizontalPadding: 0,
      );
    }
    if (_communities.isEmpty) {
      return _buildImageEmpty(
        assetPath: _communityPlaceholderAsset,
        message: 'No communities yet',
        subtitle: 'Browse groups to join conversations near you.',
        icon: Icons.groups_outlined,
        actionLabel: 'Browse all communities',
        onAction: _onBrowseCommunities,
        minHeight: 200,
      );
    }

    final totalMembers =
        _communities.fold<int>(0, (acc, g) => acc + g.memberCount);

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
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: Text(
                            'View community',
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

  Widget _communityFallbackBg() => DecoratedBox(
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
        child: AppErrorView(
          title: 'Could not load section',
          message: message,
          onRetry: onRetry,
          icon: Icons.info_outline_rounded,
        ),
      );

  Widget _buildActionableEmpty({
    required IconData icon,
    required String message,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
    String? secondaryActionLabel,
    VoidCallback? onSecondaryAction,
    double horizontalPadding = 24,
    double liftContentBy = 0,
  }) {
    assert(
      (actionLabel == null && onAction == null) ||
          (actionLabel != null && onAction != null),
      'actionLabel and onAction must both be null or both non-null',
    );
    Widget child = AppEmptyView(
      title: message,
      subtitle: subtitle,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
      secondaryActionLabel: secondaryActionLabel,
      onSecondaryAction: onSecondaryAction,
      contentPadding: _discoverEmptyContentPadding,
    );
    if (liftContentBy != 0) {
      child = Transform.translate(
        offset: Offset(0, -liftContentBy),
        child: child,
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: child,
    );
  }

  Widget _buildImageEmpty({
    required String assetPath,
    required String message,
    required IconData icon,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
    String? secondaryActionLabel,
    VoidCallback? onSecondaryAction,
    String? footerLinkLabel,
    VoidCallback? onFooterLink,
    String? footerLinkHint,
    double minHeight = 240,
    double liftContentBy = 0,
    bool compact = false,
  }) {
    assert(
      (actionLabel == null && onAction == null) ||
          (actionLabel != null && onAction != null),
      'actionLabel and onAction must both be null or both non-null',
    );
    assert(
      (secondaryActionLabel == null && onSecondaryAction == null) ||
          (secondaryActionLabel != null && onSecondaryAction != null),
      'secondaryActionLabel and onSecondaryAction must both be null or both non-null',
    );
    assert(
      (footerLinkLabel == null && onFooterLink == null) ||
          (footerLinkLabel != null && onFooterLink != null),
      'footerLinkLabel and onFooterLink must both be null or both non-null',
    );
    assert(
      footerLinkHint == null ||
          (footerLinkLabel != null && onFooterLink != null),
      'footerLinkHint requires footerLinkLabel and onFooterLink',
    );
    final bool hasPrimary = actionLabel != null && onAction != null;
    final bool hasFooter = footerLinkLabel != null && onFooterLink != null;
    final String footerSemantics;
    if (hasFooter) {
      final String label = footerLinkLabel;
      footerSemantics =
          footerLinkHint != null ? '$footerLinkHint $label' : label;
    } else {
      footerSemantics = '';
    }
    Widget child = Semantics(
      button: hasPrimary,
      label: hasPrimary
          ? '$message — $actionLabel${hasFooter ? ' — $footerSemantics' : ''}'
          : '$message${subtitle != null ? ' — $subtitle' : ''}',
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: AppEmptyView(
          title: message,
          subtitle: subtitle,
          icon: icon,
          compactSpacing: compact,
          actionLabel: actionLabel,
          onAction: onAction,
          secondaryActionLabel: secondaryActionLabel,
          onSecondaryAction: onSecondaryAction,
          footerLinkLabel: footerLinkLabel,
          onFooterLink: onFooterLink,
          footerLinkHint: footerLinkHint,
          contentPadding: compact
              ? const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.sm,
                  AppSpacing.xl,
                  AppSpacing.sm,
                )
              : _discoverEmptyContentPadding,
        ),
      ),
    );
    if (liftContentBy != 0) {
      child = Transform.translate(
        offset: Offset(0, -liftContentBy),
        child: child,
      );
    }
    return child;
  }
}
