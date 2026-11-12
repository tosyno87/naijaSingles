import 'dart:async';
import 'dart:developer';

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
import '../../../../services/profile_verification_service.dart';
import '../../../discovery/data/services/discovery_service.dart';
import '../../../events/data/models/event_model.dart';
import '../../../events/data/services/events_firestore_service.dart';
import '../../../groups/screens/unified_groups_screen.dart';
import '../../../home/main_nav_tabs.dart';
import '../../utils/discover_people_near_you_display.dart';
import '../../utils/houston_events_selection.dart';
import '../widgets/discover_skeleton_card.dart';
import '../widgets/explore_groups_link.dart';
import '../widgets/houston_home_hero.dart';
import '../widgets/houston_weekend_event_row.dart';
import '../widgets/soft_connect_module.dart';

class DiscoverPageV2 extends StatefulWidget {
  const DiscoverPageV2({super.key});

  @override
  State<DiscoverPageV2> createState() => _DiscoverPageV2State();
}

class _DiscoverPageV2State extends State<DiscoverPageV2> {
  static const Color _pageCream = Color(0xFFFFFCF7);
  static const EdgeInsets _discoverEmptyContentPadding =
      EdgeInsets.fromLTRB(AppSpacing.xl, 10, AppSpacing.xl, 10);

  final EventsFirestoreService _eventsService = EventsFirestoreService();
  final ProfileVerificationService _verificationService =
      ProfileVerificationService();
  final GlobalKey _weekendKey = GlobalKey();

  UserModel? _currentUser;

  List<UserModel> _people = [];

  List<EventModel> _events = [];
  bool _eventsLoading = true;
  String? _eventsError;
  final Map<String, VerificationStatus> _verificationCache =
      <String, VerificationStatus>{};
  bool _showVerifiedLocals = false;

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
      ]);

  void _applyPeopleNearYouList(List<UserModel> list) {
    if (!mounted) return;
    setState(() {
      _people = sortAndCapPeopleNearYou(list);
    });
    unawaited(_refreshVerifiedLocals());
  }

  Future<void> _loadPeople() async {
    if (!mounted) return;

    await _peopleSub?.cancel();
    _peopleSub = null;

    final UserModel? user = _currentUser;
    final String? uid = user?.id;
    if (user == null || uid == null || uid.isEmpty) {
      if (!mounted) return;
      setState(() {
        _people = [];
      });
      return;
    }

    try {
      final bool migrated = await PrivacyMigrationService().isUserMigrated(uid);

      if (!mounted) return;

      if (migrated) {
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
        },
      );
    } on Object catch (e) {
      log('Error loading people: $e');
    }
  }

  Future<void> _refreshVerifiedLocals() async {
    final List<String> ids = _people
        .map((UserModel u) => u.id)
        .whereType<String>()
        .where((String id) => id.isNotEmpty)
        .take(4)
        .toList();

    final List<String> missing =
        ids.where((String id) => !_verificationCache.containsKey(id)).toList();

    if (missing.isNotEmpty) {
      final List<MapEntry<String, VerificationStatus>> fetched =
          await Future.wait(
        missing.map((String id) async {
          try {
            final UserVerificationStatus status =
                await _verificationService.getUserVerificationStatus(id);
            return MapEntry<String, VerificationStatus>(
              id,
              status.overallStatus,
            );
          } on Object {
            return MapEntry<String, VerificationStatus>(
              id,
              VerificationStatus.pending,
            );
          }
        }),
      );
      for (final MapEntry<String, VerificationStatus> entry in fetched) {
        _verificationCache[entry.key] = entry.value;
      }
    }

    if (!mounted) return;

    final bool anyVerified = ids.any((String id) {
      final VerificationStatus? status = _verificationCache[id];
      return status == VerificationStatus.verified ||
          status == VerificationStatus.partial;
    });

    if (anyVerified == _showVerifiedLocals) return;
    setState(() {
      _showVerifiedLocals = anyVerified;
    });
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;
    setState(() {
      _eventsLoading = true;
      _eventsError = null;
    });

    try {
      final List<EventModel> results = await _eventsService.fetchEvents(
        limit: 30,
        startDate: DateTime.now(),
      );

      final HoustonEventsSelection selected =
          selectHoustonWeekendEvents(results);

      if (!mounted) return;
      setState(() {
        _events = selected.events;
        _eventsLoading = false;
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

  void _onSeeAllEvents() {
    unawaited(Navigator.pushNamed(context, RouteName.eventsScreen));
  }

  void _onSeeThisWeekend() {
    if (_events.isEmpty) {
      _onSeeAllEvents();
      return;
    }
    final BuildContext? weekendContext = _weekendKey.currentContext;
    if (weekendContext == null) {
      _onSeeAllEvents();
      return;
    }
    unawaited(
      Scrollable.ensureVisible(
        weekendContext,
        duration: const Duration(milliseconds: 280),
        alignment: 0.08,
      ),
    );
  }

  void _onBrowseCommunities() {
    unawaited(
      Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const UnifiedGroupsScreen()),
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

  void _switchShellTab(MainNavTabId id) {
    MainNavSwitcher.maybeOf(context)?.switchToTab(mainNavIndexFor(id));
  }

  String? _photoUrl(UserModel? user) {
    if (user == null) return null;
    final List<dynamic>? photos = user.imageUrl;
    if (photos == null || photos.isEmpty) return null;
    final Object? first = photos.first;
    if (first is String && first.isNotEmpty) return first;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final List<String> localPhotos =
        _people.map(_photoUrl).whereType<String>().take(4).toList();

    return Scaffold(
      backgroundColor: _pageCream,
      body: RefreshIndicator(
        color: AppColors.primaryGreen,
        onRefresh: _loadAll,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: HoustonHomeHero(
                localsLabel: _showVerifiedLocals
                    ? HoustonHomeHero.verifiedLocalsLabel
                    : HoustonHomeHero.honestLocalsLabel,
                showVerifiedMark: _showVerifiedLocals,
                onSeeThisWeekend: _onSeeThisWeekend,
                onProfileTap: () => _switchShellTab(MainNavTabId.profile),
                profilePhotoUrl: _photoUrl(_currentUser),
                localPhotoUrls: localPhotos,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KeyedSubtree(
                      key: _weekendKey,
                      child: _buildWeekendSection(),
                    ),
                    const SizedBox(height: 8),
                    ExploreGroupsLink(onTap: _onBrowseCommunities),
                    const SizedBox(height: 16),
                    SoftConnectModule(
                      onTap: () => _switchShellTab(MainNavTabId.connect),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekendSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'This weekend',
                  style: GoogleFonts.montserrat(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111111),
                  ),
                ),
              ),
              TextButton(
                onPressed: _onSeeAllEvents,
                child: Text(
                  'See all',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          if (_eventsLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  DiscoverSkeletonCard(height: 90, radius: 10),
                  SizedBox(height: 12),
                  DiscoverSkeletonCard(height: 90, radius: 10),
                ],
              ),
            )
          else if (_eventsError != null)
            AppErrorView(
              title: 'Could not load events',
              message: _eventsError!,
              onRetry: _loadEvents,
              icon: Icons.info_outline_rounded,
            )
          else if (_events.isEmpty)
            AppEmptyView(
              title: 'No events in Houston this week.',
              subtitle: 'See all events for listings outside Houston.',
              icon: Icons.calendar_today_outlined,
              actionLabel: 'See all events',
              onAction: _onSeeAllEvents,
              contentPadding: _discoverEmptyContentPadding,
            )
          else
            Column(
              children: [
                for (int i = 0; i < _events.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: Color(0xFFE7E0D6)),
                  HoustonWeekendEventRow(
                    event: _events[i],
                    onTap: () => _onTapEvent(_events[i]),
                  ),
                ],
              ],
            ),
        ],
      );
}
