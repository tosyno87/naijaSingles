import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../../common/routes/route_name.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/events_repository.dart';
import '../../data/services/events_firestore_service.dart';
import '../../data/services/location_service.dart';
import '../bloc/events_bloc.dart';
import '../bloc/rsvp_bloc.dart';
import '../widgets/advanced_search_dialog.dart';
import '../widgets/event_card.dart';
import '../widgets/events_empty_state.dart';
import '../widgets/events_error_state.dart';
import '../widgets/events_loading_shimmer.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final RefreshController _refreshController = RefreshController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSearching = false;
  EventFilter _currentFilter = const EventFilter();
  EventsBloc? _eventsBloc;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom && _eventsBloc != null && !_isLoadingMore) {
      _isLoadingMore = true;
      _eventsBloc!.add(LoadMoreEventsEvent());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.95);
  }

  void _onRefresh() {
    if (_eventsBloc != null) {
      _eventsBloc!.add(RefreshEventsEvent());
    }
  }

  void _onLoading() {
    if (_eventsBloc != null) {
      _eventsBloc!.add(LoadMoreEventsEvent());
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        if (_eventsBloc != null) {
          _eventsBloc!.add(ClearSearchEvent());
        }
      }
    });
  }

  void _onSearchChanged(String query) {
    if (_eventsBloc != null) {
      if (query.trim().isNotEmpty) {
        _eventsBloc!.add(SearchEventsEvent(query.trim()));
      } else {
        _eventsBloc!.add(ClearSearchEvent());
      }
    }
  }

  void _onFilterChanged(EventFilter filter) {
    setState(() {
      _currentFilter = filter;
    });
    if (_eventsBloc != null) {
      _eventsBloc!.add(FilterEventsEvent(filter));
    }
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) {
              _eventsBloc = EventsBloc(
                repository: EventsRepositoryImpl(
                  firestoreService: EventsFirestoreService(),
                  locationService: LocationService(),
                ),
              )..add(const LoadEventsEvent());
              return _eventsBloc!;
            },
          ),
          BlocProvider(
            create: (context) => RSVPBloc(
              firestoreService: EventsFirestoreService(),
              currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
            ),
          ),
        ],
        child: Builder(
          builder: (context) => Scaffold(
            backgroundColor: Colors.white,
            appBar: _buildAppBar(),
            body: SafeArea(
              child: Column(
                children: [
                  _buildSubtitle(),
                  _buildFilters(),
                  Expanded(child: _buildEventsList()),
                ],
              ),
            ),
            floatingActionButton: Semantics(
              button: true,
              label: 'Create Event'.tr(),
              child: FloatingActionButton(
                heroTag: 'events_screen_fab',
                onPressed: () {
                  unawaited(Navigator.pushNamed(context, RouteName.eventTemplateSelection));
                },
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                child: const Icon(Icons.add),
              ),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          ),
        ),
      );

  PreferredSizeWidget _buildAppBar() => AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Semantics(
          button: true,
          label: 'Go back'.tr(),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back,
              color: Color(0xFF3E1F0D),
            ),
          ),
        ),
        title: Semantics(
          header: true,
          child: Text(
            'Events'.tr(),
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3E1F0D),
            ),
          ),
        ),
        actions: [
          Semantics(
            button: true,
            label: 'My Events'.tr(),
            child: IconButton(
              onPressed: () {
                unawaited(Navigator.pushNamed(context, RouteName.myEvents));
              },
              icon: const Icon(
                Icons.calendar_today,
                color: AppColors.primaryGreen,
                size: 24,
              ),
              tooltip: 'My Events'.tr(),
            ),
          ),
          Semantics(
            button: true,
            label: _isSearching ? 'Close Search'.tr() : 'Search Events'.tr(),
            child: IconButton(
              onPressed: _toggleSearch,
              icon: Icon(
                _isSearching ? Icons.close : Icons.search,
                color: AppColors.primaryGreen,
                size: 24,
              ),
              tooltip: _isSearching ? 'Close Search'.tr() : 'Search Events'.tr(),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildSubtitle() => Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Text(
          'Discover upcoming events, parties, and community gatherings'.tr(),
          style: GoogleFonts.montserrat(
            fontSize: 16,
            color: const Color(0xFF666666),
          ),
        ),
      );

  Widget _buildFilters() => Column(
        children: [
          if (_isSearching) _buildSearchBar(),
          _buildCategoryFilters(),
          _buildDateAndAdvancedFilters(),
        ],
      );

  Widget _buildSearchBar() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Semantics(
          textField: true,
          label: 'Search events, categories, locations...'.tr(),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: const Color(0xFF333333),
            ),
            decoration: InputDecoration(
              hintText: 'Search events, categories, locations...'.tr(),
              hintStyle: GoogleFonts.montserrat(
                fontSize: 16,
                color: const Color(0xFF999999),
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.primaryGreen,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      );

  Widget _buildCategoryFilters() {
    final categories = ['All', 'Music', 'Business', 'Community', 'Social', 'Cultural'];

    return Container(
      height: 40,
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == 'All'
              ? _currentFilter.category == null
              : _currentFilter.category == category;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: Semantics(
              button: true,
              selected: isSelected,
              label: '{} category filter'.tr(args: [category.tr()]),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    final newFilter = _currentFilter.copyWith(
                      category: category == 'All' ? null : category,
                    );
                    _onFilterChanged(newFilter);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryGreen : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryGreen
                            : const Color(0xFFE0E0E0),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      category.tr(),
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color:
                            isSelected ? Colors.white : AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateAndAdvancedFilters() => Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Row(
          children: [
            Expanded(child: _buildDateRangeDropdown()),
            const SizedBox(width: 12),
            _buildAdvancedFilterLink(),
          ],
        ),
      );

  Widget _buildDateRangeDropdown() {
    final dateRanges = ['All Time', 'Today', 'This Week', 'This Month'];
    String selectedDateRange = 'All Time';

    if (_currentFilter.startDate != null || _currentFilter.endDate != null) {
      if (_isDateRangeSelected('Today')) {
        selectedDateRange = 'Today';
      } else if (_isDateRangeSelected('This Week')) {
        selectedDateRange = 'This Week';
      } else if (_isDateRangeSelected('This Month')) {
        selectedDateRange = 'This Month';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: DropdownButton<String>(
        value: selectedDateRange,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        icon: const Icon(
          Icons.arrow_drop_down,
          color: AppColors.primaryGreen,
        ),
        style: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF333333),
        ),
        items: dateRanges.map((String range) => DropdownMenuItem<String>(
            value: range,
            child: Text(range.tr()),
          ),).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            final newFilter = _getDateRangeFilter(newValue, true);
            _onFilterChanged(newFilter);
          }
        },
      ),
    );
  }

  bool _isDateRangeSelected(String dateRange) {
    if (dateRange == 'All Time') {
      return _currentFilter.startDate == null &&
          _currentFilter.endDate == null;
    }

    final now = DateTime.now();
    switch (dateRange) {
      case 'Today':
        return _currentFilter.startDate?.day == now.day &&
            _currentFilter.startDate?.month == now.month &&
            _currentFilter.startDate?.year == now.year;
      case 'This Week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final startDate = _currentFilter.startDate;
        return (startDate
                    ?.isAfter(weekStart.subtract(const Duration(days: 1))) ??
                false) &&
            (startDate?.isBefore(weekStart.add(const Duration(days: 7))) ??
                false);
      case 'This Month':
        return _currentFilter.startDate?.month == now.month &&
            _currentFilter.startDate?.year == now.year;
      default:
        return false;
    }
  }

  EventFilter _getDateRangeFilter(String dateRange, bool selected) {
    if (!selected || dateRange == 'All Time') {
      return _currentFilter.copyWith();
    }

    final now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate;

    switch (dateRange) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'This Week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        endDate = startDate.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
    }

    return _currentFilter.copyWith(startDate: startDate, endDate: endDate);
  }

  Widget _buildAdvancedFilterLink() => Semantics(
        button: true,
        label: 'Advanced Filters'.tr(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final newFilter = await showDialog<EventFilter>(
                context: context,
                builder: (context) => AdvancedSearchDialog(
                  currentFilter: _currentFilter,
                  onFilterApplied: _onFilterChanged,
                ),
              );
              if (newFilter != null) {
                _onFilterChanged(newFilter);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.tune,
                    color: AppColors.primaryGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Advanced Filters'.tr(),
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  void _navigateToEventDetails(EventModel event) {
    unawaited(Navigator.pushNamed(context, RouteName.eventDetails, arguments: event));
  }

  Widget _buildEventsList() => BlocConsumer<EventsBloc, EventsState>(
        listener: (context, state) {
          if (state is EventsLoaded) {
            _refreshController.refreshCompleted();
            _refreshController.loadComplete();
            _isLoadingMore = false;
          } else if (state is EventsError) {
            _refreshController.refreshFailed();
            _refreshController.loadFailed();
            _isLoadingMore = false;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: GoogleFonts.montserrat(color: Colors.white),
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is EventsLoading) {
            return const EventsLoadingShimmer();
          }

          if (state is EventsError && state.isNetworkError) {
            return EventsErrorState(
              title: 'Connection Error'.tr(),
              message: state.message,
              icon: Icons.wifi_off,
              onRetry: () {
                _eventsBloc?.add(const LoadEventsEvent(forceRefresh: true));
              },
            );
          }

          if (state is EventsError) {
            return EventsErrorState(
              title: 'Something went wrong'.tr(),
              message: state.message,
              icon: Icons.error_outline,
              onRetry: () {
                _eventsBloc?.add(const LoadEventsEvent(forceRefresh: true));
              },
            );
          }

          if (state is EventsSearching) {
            return _buildSearchingState(state.query);
          }

          if (state is EventsLoaded) {
            if (state.events.isEmpty) {
              return EventsEmptyState(
                hasActiveFilters: _currentFilter.hasActiveFilters ||
                    _searchController.text.isNotEmpty,
                onClearFilters: () {
                  setState(() {
                    _currentFilter = const EventFilter();
                    _searchController.clear();
                  });
                  _eventsBloc?.add(ClearSearchEvent());
                },
                onCreateEvent: () {
                  unawaited(Navigator.pushNamed(
                    context,
                    RouteName.eventTemplateSelection,
                  ));
                },
              );
            }

            return SmartRefresher(
              controller: _refreshController,
              enablePullUp: !state.hasReachedMax,
              onRefresh: _onRefresh,
              onLoading: _onLoading,
              header: const WaterDropMaterialHeader(
                backgroundColor: AppColors.primaryGreen,
              ),
              footer: CustomFooter(
                builder: (context, mode) {
                  Widget body;
                  if (mode == LoadStatus.idle) {
                    body = Text(
                      'Pull up to load more'.tr(),
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF666666),
                      ),
                    );
                  } else if (mode == LoadStatus.loading) {
                    body = const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation(AppColors.primaryGreen),
                    );
                  } else if (mode == LoadStatus.failed) {
                    body = Text(
                      'Load Failed! Click retry!'.tr(),
                      style: GoogleFonts.montserrat(color: Colors.red),
                    );
                  } else if (mode == LoadStatus.canLoading) {
                    body = Text(
                      'Release to load more'.tr(),
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF666666),
                      ),
                    );
                  } else {
                    body = Text(
                      'No more events'.tr(),
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF666666),
                      ),
                    );
                  }
                  return SizedBox(
                    height: 55,
                    child: Center(child: body),
                  );
                },
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                itemCount: state.events.length + (state.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= state.events.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation(AppColors.primaryGreen),
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: EventCard(
                      event: state.events[index],
                      onTap: () =>
                          _navigateToEventDetails(state.events[index]),
                    ),
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      );

  Widget _buildSearchingState(String query) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.primaryGreen),
              ),
              const SizedBox(height: 24),
              Text(
                'Searching for "{}"'.tr(args: [query]),
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Finding the best Afrocentric events for you...'.tr(),
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: const Color(0xFF666666),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}
