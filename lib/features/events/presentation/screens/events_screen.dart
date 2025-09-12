import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../common/routes/route_name.dart';
import '../bloc/events_bloc.dart';
import '../bloc/rsvp_bloc.dart';
import '../widgets/event_card.dart';
import '../widgets/events_loading_shimmer.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/events_repository.dart';
import '../../data/services/events_firestore_service.dart';
import '../../data/services/location_service.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isSearching = false;
  EventFilter _currentFilter = const EventFilter();
  EventsBloc? _eventsBloc;
  bool _isLoadingMore = false; // Add loading state to prevent multiple calls

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
    // Only trigger when we're very close to the bottom (95% instead of 90%)
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
  Widget build(BuildContext context) {
    return MultiBlocProvider(
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
        builder: (context) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: _buildAppBar(),
            body: SafeArea(
              child: Column(
                children: [
                  _buildSubtitle(),
                  _buildFilters(),
                  Expanded(
                    child: _buildEventsListWithLocation(),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              heroTag: "events_screen_fab",
              onPressed: () {
                Navigator.pushNamed(context, RouteName.eventTemplateSelection);
              },
              backgroundColor: const Color(0xFF008037), // Deep green
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(
          Icons.arrow_back,
          color: Color(0xFF3E1F0D), // Deep brown
        ),
      ),
      title: Text(
        'Events',
        style: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF3E1F0D), // Deep brown
        ),
      ),
      actions: [
        // Calendar icon
        IconButton(
          onPressed: () {
            Navigator.pushNamed(context, RouteName.myEvents);
          },
          icon: const Icon(
            Icons.calendar_today,
            color: Color(0xFF008037), // Deep green
            size: 24,
          ),
          tooltip: 'My Events',
        ),
        // Search icon
        IconButton(
          onPressed: _toggleSearch,
          icon: Icon(
            _isSearching ? Icons.close : Icons.search,
            color: const Color(0xFF008037), // Deep green
            size: 24,
          ),
          tooltip: _isSearching ? 'Close Search' : 'Search Events',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Text(
        'Discover upcoming events, parties, and community gatherings',
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: const Color(0xFF666666), // Medium gray
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        // Search Bar (when searching)
        if (_isSearching) _buildSearchBar(),
        
        // Category Filters
        _buildCategoryFilters(),
        
        // Date Range Filters
        _buildDateRangeFilters(),
        
        // Advanced Filter Button
        _buildAdvancedFilterButton(),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: const Color(0xFF333333),
        ),
        decoration: InputDecoration(
          hintText: 'Search events, categories, locations...',
          hintStyle: GoogleFonts.poppins(
            fontSize: 16,
            color: const Color(0xFF999999),
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF008037),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

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
          final isSelected = _currentFilter.category == category || 
                            (_currentFilter.category == null && category == 'All');
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  final newFilter = _currentFilter.copyWith(
                    category: isSelected ? null : (category == 'All' ? null : category),
                  );
                  _onFilterChanged(newFilter);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF008037) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF008037) : const Color(0xFFE0E0E0),
                      width: 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Text(
                    category,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF008037),
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

  Widget _buildDateRangeFilters() {
    final dateRanges = ['All Time', 'Today', 'This Week', 'This Month'];
    
    return Container(
      height: 40,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dateRanges.length,
        itemBuilder: (context, index) {
          final dateRange = dateRanges[index];
          final isSelected = _isDateRangeSelected(dateRange);
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  final newFilter = _getDateRangeFilter(dateRange, !isSelected);
                  _onFilterChanged(newFilter);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF008037) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF008037) : const Color(0xFFE0E0E0),
                      width: 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Text(
                    dateRange,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF008037),
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

  bool _isDateRangeSelected(String dateRange) {
    if (dateRange == 'All Time') {
      return _currentFilter.startDate == null && _currentFilter.endDate == null;
    }
    
    final now = DateTime.now();
    switch (dateRange) {
      case 'Today':
        return _currentFilter.startDate?.day == now.day &&
               _currentFilter.startDate?.month == now.month &&
               _currentFilter.startDate?.year == now.year;
      case 'This Week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return _currentFilter.startDate?.isAfter(weekStart.subtract(const Duration(days: 1))) == true &&
               _currentFilter.startDate?.isBefore(weekStart.add(const Duration(days: 7))) == true;
      case 'This Month':
        return _currentFilter.startDate?.month == now.month &&
               _currentFilter.startDate?.year == now.year;
      default:
        return false;
    }
  }

  EventFilter _getDateRangeFilter(String dateRange, bool selected) {
    if (!selected || dateRange == 'All Time') {
      return _currentFilter.copyWith(startDate: null, endDate: null);
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
        endDate = startDate.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
    }
    
    return _currentFilter.copyWith(startDate: startDate, endDate: endDate);
  }

  Widget _buildAdvancedFilterButton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // TODO: Implement advanced filter dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Advanced filters coming soon!'),
                    backgroundColor: Color(0xFF008037),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF008037), // Deep green
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.tune,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Advanced',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildErrorState({
    required String title,
    required String message,
    required IconData icon,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: const Color(0xFF999999),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: const Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008037),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.event_available,
                size: 50,
                color: Color(0xFF999999),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Events Found',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3E1F0D), // Deep brown
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _currentFilter.hasActiveFilters || _searchController.text.isNotEmpty
                  ? 'Try adjusting your search or filters to find more events'
                  : 'Be the first to create an event and start bringing people together!',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xFF666666),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_currentFilter.hasActiveFilters || _searchController.text.isNotEmpty)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _currentFilter = const EventFilter();
                      _searchController.clear();
                    });
                    if (_eventsBloc != null) {
                      _eventsBloc!.add(ClearSearchEvent());
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF008037), // Deep green
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Clear Filters',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              )
            else
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, RouteName.eventTemplateSelection);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF008037), // Deep green
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Create Event',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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
  }

  Widget _buildSearchingState(String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Color(0xFF008037)),
            ),
            const SizedBox(height: 24),
            Text(
              'Searching for "$query"',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Finding the best Afrocentric events for you...',
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

  void _navigateToEventDetails(EventModel event) {
    Navigator.pushNamed(
      context,
      RouteName.eventDetails,
      arguments: event,
    );
  }

  Widget _buildEventsListWithLocation() {
    return BlocConsumer<EventsBloc, EventsState>(
      listener: (context, state) {
        if (state is EventsLoaded) {
          _refreshController.refreshCompleted();
          _refreshController.loadComplete();
          _isLoadingMore = false; // Reset loading state
        } else if (state is EventsError) {
          _refreshController.refreshFailed();
          _refreshController.loadFailed();
          _isLoadingMore = false; // Reset loading state on error
          
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
          return _buildErrorState(
            title: 'Connection Error',
            message: state.message,
            icon: Icons.wifi_off,
            onRetry: () {
              if (_eventsBloc != null) {
                _eventsBloc!.add(const LoadEventsEvent(forceRefresh: true));
              }
            },
          );
        }
        
        if (state is EventsError) {
          return _buildErrorState(
            title: 'Something went wrong',
            message: state.message,
            icon: Icons.error_outline,
            onRetry: () {
              if (_eventsBloc != null) {
                _eventsBloc!.add(const LoadEventsEvent(forceRefresh: true));
              }
            },
          );
        }
        
        if (state is EventsSearching) {
          return _buildSearchingState(state.query);
        }
        
        if (state is EventsLoaded) {
          if (state.events.isEmpty) {
            return _buildEmptyState();
          }
          
          return SmartRefresher(
            controller: _refreshController,
            enablePullDown: true,
            enablePullUp: !state.hasReachedMax,
            onRefresh: _onRefresh,
            onLoading: _onLoading,
            header: WaterDropMaterialHeader(
              backgroundColor: const Color(0xFF008037),
              color: Colors.white,
            ),
            footer: CustomFooter(
              builder: (context, mode) {
                Widget body;
                if (mode == LoadStatus.idle) {
                  body = Text(
                    "Pull up to load more",
                    style: GoogleFonts.montserrat(color: const Color(0xFF666666)),
                  );
                } else if (mode == LoadStatus.loading) {
                  body = const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Color(0xFF008037)),
                  );
                } else if (mode == LoadStatus.failed) {
                  body = Text(
                    "Load Failed! Click retry!",
                    style: GoogleFonts.montserrat(color: Colors.red),
                  );
                } else if (mode == LoadStatus.canLoading) {
                  body = Text(
                    "Release to load more",
                    style: GoogleFonts.montserrat(color: const Color(0xFF666666)),
                  );
                } else {
                  body = Text(
                    "No more events",
                    style: GoogleFonts.montserrat(color: const Color(0xFF666666)),
                  );
                }
                return Container(
                  height: 55.0,
                  child: Center(child: body),
                );
              },
            ),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 80), // Bottom padding for FAB
              itemCount: state.events.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.events.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Color(0xFF008037)),
                      ),
                    ),
                  );
                }
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: EventCard(
                    event: state.events[index],
                    onTap: () => _navigateToEventDetails(state.events[index]),
                  ),
                );
              },
            ),
          );
        }
        
        return const SizedBox.shrink();
      },
    );
  }
}
