import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../../common/routes/route_name.dart';
import '../bloc/event_creation_bloc.dart';
import '../widgets/my_event_card.dart';
import '../../data/models/enhanced_event_model.dart';
import '../../data/services/user_event_service.dart';
import 'create_event_screen.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({Key? key}) : super(key: key);

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _currentUserId;
  bool _isDeleting = false;
  String? _deletingEventId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    // Add listener for tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // Optional: Add haptic feedback
        // HapticFeedback.selectionClick();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return _buildAuthRequiredScreen();
    }

    return BlocProvider(
      create: (context) => EventCreationBloc(
        userEventService: UserEventService(),
      )..add(LoadUserEventsEvent(_currentUserId!)),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            BlocListener<EventCreationBloc, EventCreationState>(
              listener: (context, state) {
                print('🔄 EventCreationBloc State: ${state.runtimeType}');
                
                if (state is EventDeleted) {
                  print('✅ Event deleted successfully: ${state.eventId}');
                  // Only clear loading if this is the event we're deleting
                  if (_deletingEventId == state.eventId) {
                    setState(() {
                      _isDeleting = false;
                      _deletingEventId = null;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Event deleted successfully',
                          style: GoogleFonts.montserrat(color: Colors.white),
                        ),
                        backgroundColor: const Color(0xFF008037),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                    // Add a small delay before refreshing to ensure delete is processed
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) {
                        context.read<EventCreationBloc>().add(
                          LoadUserEventsEvent(_currentUserId!),
                        );
                      }
                    });
                  }
                } else if (state is EventPublished) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Event published successfully! It will be reviewed before going live.',
                    style: GoogleFonts.montserrat(color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFF008037),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
              // Refresh the events list
              context.read<EventCreationBloc>().add(
                LoadUserEventsEvent(_currentUserId!),
              );
            } else if (state is EventCreationError) {
              // Clear delete loading state on error
              if (_isDeleting) {
                setState(() {
                  _isDeleting = false;
                  _deletingEventId = null;
                });
              }
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
          child: Column(
            children: [
              _buildTabBar(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPublishedEventsTab(),
                      _buildDraftsTab(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Loading overlay during delete operations
        if (_isDeleting)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Color(0xFF008037)),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Deleting event...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildCreateEventFAB(),
    ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFFFF6E5),
      elevation: 0,
      iconTheme: const IconThemeData(
        color: Color(0xFF333333), // Dark color for back button
        size: 24,
      ),
      leading: IconButton(
        onPressed: () {
          // Safety check for navigation
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          } else {
            // If we can't pop, navigate to main navigation
            Navigator.pushNamedAndRemoveUntil(
              context,
              RouteName.mainNavigation,
              (route) => false,
            );
          }
        },
        icon: const Icon(
          Icons.arrow_back_ios,
          color: Color(0xFF333333),
          size: 24,
        ),
        tooltip: 'Back',
      ),
      title: Text(
        'My Events',
        style: GoogleFonts.montserrat(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF333333),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            context.read<EventCreationBloc>().add(
              LoadUserEventsEvent(_currentUserId!),
            );
          },
          icon: const Icon(
            Icons.refresh,
            color: Color(0xFF008037),
          ),
          tooltip: 'Refresh',
        ),
      ],
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFFF6E5),
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 50,
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
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF008037),
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF666666),
        labelStyle: GoogleFonts.montserrat(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.montserrat(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        dividerColor: Colors.transparent,
        overlayColor: MaterialStateProperty.all(Colors.transparent),
        tabs: [
          Tab(
            child: Container(
              alignment: Alignment.center,
              child: const Text('Published'),
            ),
          ),
          Tab(
            child: Container(
              alignment: Alignment.center,
              child: const Text('Drafts'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishedEventsTab() {
    return BlocBuilder<EventCreationBloc, EventCreationState>(
      builder: (context, state) {
        if (state is UserEventsLoading) {
          return _buildLoadingState();
        }

        if (state is UserEventsError) {
          return _buildErrorState(state.message);
        }

        if (state is UserEventsLoaded) {
          final publishedEvents = state.events.where((event) => 
            event.status == EventStatus.published || 
            event.status == EventStatus.underReview ||
            event.status == EventStatus.completed
          ).toList();

          if (publishedEvents.isEmpty) {
            // Don't show empty state if we're in the middle of a delete operation
            if (_isDeleting) {
              return _buildLoadingState();
            }
            return _buildEmptyState(
              title: 'No Published Events',
              message: 'You haven\'t published any events yet.\nCreate your first event to get started!',
              icon: Icons.event_busy,
              showCreateButton: true,
            );
          }

          return _buildEventsList(publishedEvents);
        }

        return _buildEmptyState(
          title: 'No Published Events',
          message: 'You haven\'t published any events yet.\nCreate your first event to get started!',
          icon: Icons.event_busy,
          showCreateButton: true,
        );
      },
    );
  }

  Widget _buildDraftsTab() {
    return BlocBuilder<EventCreationBloc, EventCreationState>(
      builder: (context, state) {
        if (state is UserEventsLoading) {
          return _buildLoadingState();
        }

        if (state is UserEventsError) {
          return _buildErrorState(state.message);
        }

        if (state is UserEventsLoaded) {
          final draftEvents = state.drafts.where((event) => 
            event.status == EventStatus.draft
          ).toList();

          if (draftEvents.isEmpty) {
            // Don't show empty state if we're in the middle of a delete operation
            if (_isDeleting) {
              return _buildLoadingState();
            }
            return _buildEmptyState(
              title: 'No Draft Events',
              message: 'You don\'t have any draft events.\nSave an event as draft while creating it.',
              icon: Icons.drafts,
              showCreateButton: true,
            );
          }

          return _buildEventsList(draftEvents, isDrafts: true);
        }

        return _buildEmptyState(
          title: 'No Draft Events',
          message: 'You don\'t have any draft events.\nSave an event as draft while creating it.',
          icon: Icons.drafts,
          showCreateButton: true,
        );
      },
    );
  }

  Widget _buildEventsList(List<EnhancedEventModel> events, {bool isDrafts = false}) {
    // Only apply optimistic update if there are multiple events to prevent empty state flash
    final filteredEvents = events.length > 1 && _deletingEventId != null
        ? events.where((event) => event.id != _deletingEventId).toList()
        : events;
    
    return RefreshIndicator(
      onRefresh: () async {
        if (_currentUserId != null) {
          context.read<EventCreationBloc>().add(
            LoadUserEventsEvent(_currentUserId!),
          );
          // Add a small delay to show the refresh indicator
          await Future.delayed(const Duration(milliseconds: 500));
        }
      },
      color: const Color(0xFF008037),
      backgroundColor: Colors.white,
      strokeWidth: 3,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filteredEvents.length,
        itemBuilder: (context, index) {
          final event = filteredEvents[index];
          final isBeingDeleted = event.id == _deletingEventId;
          
          return AnimatedContainer(
            duration: Duration(milliseconds: 200 + (index * 50)),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: isBeingDeleted ? 0.5 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: MyEventCard(
                  event: event,
                  isDraft: isDrafts,
                  onTap: isBeingDeleted ? null : () => _navigateToEventDetails(event),
                  onEdit: isBeingDeleted ? null : () => _editEvent(event),
                  onDelete: isBeingDeleted ? null : () => _deleteEvent(context, event),
                  onPublish: (isDrafts && !isBeingDeleted) ? () => _publishDraft(context, event) : null,
                  onShare: isBeingDeleted ? null : () => _shareEvent(event),
                  onAnalytics: isBeingDeleted ? null : () => _showAnalytics(event),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF008037).withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF008037)),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading your events...',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: const Color(0xFF999999),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
              ),
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
              onPressed: () {
                context.read<EventCreationBloc>().add(
                  LoadUserEventsEvent(_currentUserId!),
                );
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

  Widget _buildEmptyState({
    required String title,
    required String message,
    required IconData icon,
    bool showCreateButton = false,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF008037).withOpacity(0.1),
                    const Color(0xFF008037).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                icon,
                size: 60,
                color: const Color(0xFF008037),
              ),
            ),
            const SizedBox(height: 32),
            
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            Text(
              message,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: const Color(0xFF666666),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            if (showCreateButton) ...[
              const SizedBox(height: 40),
              
              // Feature highlights
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF008037).withOpacity(0.1),
                  ),
                ),
                child: Column(
                  children: [
                    _buildFeatureHighlight(
                      icon: Icons.people,
                      text: 'Connect with your community',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureHighlight(
                      icon: Icons.location_on,
                      text: 'Host events in your area',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureHighlight(
                      icon: Icons.favorite,
                      text: 'Meet like-minded people',
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              ElevatedButton.icon(
                onPressed: _createNewEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008037),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.add, size: 20),
                label: Text(
                  'Create Your First Event',
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

  Widget _buildFeatureHighlight({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF008037),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: const Color(0xFF666666),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthRequiredScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.login,
                size: 80,
                color: const Color(0xFF999999),
              ),
              const SizedBox(height: 24),
              Text(
                'Sign In Required',
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please sign in to view and manage your events.',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: const Color(0xFF666666),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateEventFAB() {
    return FloatingActionButton.extended(
      heroTag: "my_events_screen_fab",
      onPressed: _createNewEvent,
      backgroundColor: const Color(0xFF008037),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: Text(
        'Create Event',
        style: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _createNewEvent() {
    Navigator.pushNamed(context, RouteName.createEvent).then((_) {
      // Refresh events list when returning from create screen
      if (_currentUserId != null) {
        context.read<EventCreationBloc>().add(
          LoadUserEventsEvent(_currentUserId!),
        );
      }
    });
  }

  void _editEvent(EnhancedEventModel event) {
    Navigator.pushNamed(
      context, 
      RouteName.createEvent,
      arguments: {'existingEvent': event},
    ).then((_) {
      // Refresh events list when returning from edit screen
      if (_currentUserId != null) {
        context.read<EventCreationBloc>().add(
          LoadUserEventsEvent(_currentUserId!),
        );
      }
    });
  }

  void _deleteEvent(BuildContext screenContext, EnhancedEventModel event) {
    showDialog(
      context: screenContext,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Event',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${event.name}"? This action cannot be undone.',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: const Color(0xFF666666),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF666666),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              print('🗑️ Delete button pressed for event: ${event.id}');
              Navigator.of(dialogContext).pop();
              
              // Track which event is being deleted
              setState(() {
                _isDeleting = true;
                _deletingEventId = event.id;
              });
              
              // Add timeout mechanism
              Timer(const Duration(seconds: 10), () {
                if (_isDeleting && _deletingEventId == event.id) {
                  setState(() {
                    _isDeleting = false;
                    _deletingEventId = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Delete operation timed out. Please try again.',
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              });
              
              // Use the passed screen context that has access to EventCreationBloc
              print('📤 Dispatching DeleteEventEvent for: ${event.id}');
              screenContext.read<EventCreationBloc>().add(DeleteEventEvent(event.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _publishDraft(BuildContext screenContext, EnhancedEventModel event) {
    showDialog(
      context: screenContext,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF008037).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.publish,
                color: Color(0xFF008037),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Publish Draft',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to publish "${event.name}"? It will be submitted for review and become visible to other users once approved.',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: const Color(0xFF666666),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF666666),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Use the passed screen context that has access to EventCreationBloc
              screenContext.read<EventCreationBloc>().add(PublishDraftEventEvent(event.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008037),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Publish',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEventDetails(EnhancedEventModel event) {
    Navigator.pushNamed(
      context,
      RouteName.eventDetails,
      arguments: event,
    );
  }

  void _shareEvent(EnhancedEventModel event) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    
    final shareText = '''
🎉 ${event.name}

📅 ${dateFormat.format(event.startDate)} at ${timeFormat.format(event.startDate)}
📍 ${event.location.shortAddress}
${event.isFree ? '🆓 Free Event' : '💰 ₦${event.ticketPrice?.toStringAsFixed(0)}'}

${event.description.length > 100 ? '${event.description.substring(0, 100)}...' : event.description}

Join me at this amazing event! 🚀

#NaijaSingles #Events #${event.category.replaceAll(' ', '')}
    '''.trim();

    // For MVP, we'll use the clipboard and show a snackbar
    Clipboard.setData(ClipboardData(text: shareText));
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Event details copied to clipboard!',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF008037),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAnalytics(EnhancedEventModel event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF008037).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.analytics,
                      color: Color(0xFF008037),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Event Analytics',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF333333),
                          ),
                        ),
                        Text(
                          event.name,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: const Color(0xFF666666),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Analytics content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Stats grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildAnalyticsCard(
                            icon: Icons.visibility,
                            title: 'Views',
                            value: '${event.metadata['views'] ?? 0}',
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildAnalyticsCard(
                            icon: Icons.people,
                            title: 'Attendees',
                            value: '${event.attendeeCount}',
                            color: const Color(0xFF008037),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildAnalyticsCard(
                            icon: Icons.favorite,
                            title: 'Interested',
                            value: '${event.rsvpCount}',
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildAnalyticsCard(
                            icon: Icons.share,
                            title: 'Shares',
                            value: '${event.metadata['shares'] ?? 0}',
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Performance insights
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Performance Insights',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInsightRow(
                            icon: Icons.trending_up,
                            text: 'Event is performing well in your category',
                            color: Colors.green,
                          ),
                          const SizedBox(height: 8),
                          _buildInsightRow(
                            icon: Icons.location_on,
                            text: 'Popular in ${event.location.city}',
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 8),
                          _buildInsightRow(
                            icon: Icons.schedule,
                            text: 'Peak viewing time: 6-8 PM',
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: const Color(0xFF666666),
            ),
          ),
        ),
      ],
    );
  }
}
