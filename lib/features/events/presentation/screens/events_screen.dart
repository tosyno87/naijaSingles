import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../common/routes/route_name.dart';
import '../bloc/events_bloc.dart';
import '../bloc/rsvp_bloc.dart';
import '../widgets/event_card.dart';
import '../widgets/event_filter_bar.dart';
import '../widgets/events_loading_shimmer.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/events_repository.dart';
import '../../data/services/events_firestore_service.dart';

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
    if (_isBottom && _eventsBloc != null) {
      _eventsBloc!.add(LoadMoreEventsEvent());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
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
            backgroundColor: const Color(0xFFFFF6E5), // NaijaSingles cream background
            body: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildSearchBar(),
                  EventFilterBar(
                    currentFilter: _currentFilter,
                    onFilterChanged: _onFilterChanged,
                  ),
                  Expanded(
                    child: _buildEventsList(),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              heroTag: "events_screen_fab",
              onPressed: () {
                Navigator.pushNamed(context, RouteName.eventTemplateSelection);
              },
              backgroundColor: const Color(0xFF008037), // NaijaSingles green
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text(
                'Create Event',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
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
                  'Discover Events',
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Find amazing Afrocentric events near you',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: const Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _toggleSearch,
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: const Color(0xFF008037), // NaijaSingles green
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    if (!_isSearching) return const SizedBox.shrink();
    
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
        style: GoogleFonts.montserrat(
          fontSize: 16,
          color: const Color(0xFF333333),
        ),
        decoration: InputDecoration(
          hintText: 'Search events, categories, locations...',
          hintStyle: GoogleFonts.montserrat(
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

  Widget _buildEventsList() {
    return BlocConsumer<EventsBloc, EventsState>(
      listener: (context, state) {
        if (state is EventsLoaded) {
          _refreshController.refreshCompleted();
          _refreshController.loadComplete();
        } else if (state is EventsError) {
          _refreshController.refreshFailed();
          _refreshController.loadFailed();
          
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
            Icon(
              Icons.event_busy,
              size: 80,
              color: const Color(0xFF999999),
            ),
            const SizedBox(height: 24),
            Text(
              'No Events Found',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _currentFilter.hasActiveFilters || _searchController.text.isNotEmpty
                  ? 'Try adjusting your search or filters'
                  : 'Check back later for new events',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: const Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
            if (_currentFilter.hasActiveFilters || _searchController.text.isNotEmpty) ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentFilter = const EventFilter();
                    _searchController.clear();
                  });
                  if (_eventsBloc != null) {
                    _eventsBloc!.add(ClearSearchEvent());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008037),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Clear Filters',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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
    // TODO: Navigate to event details screen
    Navigator.pushNamed(
      context,
      '/event-details',
      arguments: event,
    );
  }
}
