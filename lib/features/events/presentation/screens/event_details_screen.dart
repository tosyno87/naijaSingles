import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../bloc/events_bloc.dart';
import '../bloc/rsvp_bloc.dart';
import '../widgets/rsvp_button.dart';
import '../widgets/event_attendees_list.dart';
import '../../data/models/event_model.dart';
import '../../data/models/rsvp_model.dart';
import '../../data/services/events_firestore_service.dart';

class EventDetailsScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailsScreen({
    Key? key,
    required this.event,
  }) : super(key: key);

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  late Animation<double> _headerAnimation;
  
  bool _isHeaderCollapsed = false;
  bool _showFullDescription = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    const threshold = 200.0;
    final isCollapsed = _scrollController.offset > threshold;
    
    if (isCollapsed != _isHeaderCollapsed) {
      setState(() {
        _isHeaderCollapsed = isCollapsed;
      });
      
      if (isCollapsed) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RSVPBloc(
        firestoreService: EventsFirestoreService(),
        currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
      ),
      child: BlocBuilder<RSVPBloc, RSVPState>(
        builder: (context, state) {
          // Load event attendees when the bloc is first created
          if (state is RSVPInitial) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<RSVPBloc>().add(LoadEventAttendeesEvent(
                eventId: widget.event.id,
              ));
            });
          }
          
          return Scaffold(
            backgroundColor: Colors.white,
            body: CustomScrollView(
              controller: _scrollController,
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: _buildEventDetails(),
                ),
              ],
            ),
            bottomNavigationBar: _buildBottomActionBar(),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: const Color(0xFF008037),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _shareEvent,
          ),
        ),
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.white),
            onPressed: _toggleFavorite,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: AnimatedBuilder(
          animation: _headerAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _headerAnimation.value,
              child: Text(
                widget.event.name,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            widget.event.imageUrl != null && widget.event.imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: widget.event.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: const Color(0xFFF5F5F5),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Color(0xFF008037)),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => _buildPlaceholderImage(),
                  )
                : _buildPlaceholderImage(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: const Color(0xFF008037),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getCategoryIcon(),
            size: 80,
            color: Colors.white.withOpacity(0.8),
          ),
          const SizedBox(height: 16),
          Text(
            widget.event.category,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetails() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFF6E5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          _buildEventHeader(),
          const SizedBox(height: 24),
          _buildEventInfo(),
          const SizedBox(height: 24),
          _buildEventDescription(),
          const SizedBox(height: 24),
          _buildEventLocation(),
          const SizedBox(height: 24),
          _buildEventAttendees(),
          const SizedBox(height: 24),
          _buildSimilarEvents(),
          const SizedBox(height: 100), // Space for bottom bar
        ],
      ),
    );
  }

  Widget _buildEventHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.event.name,
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _buildPriceTag(),
            ],
          ),
          const SizedBox(height: 12),
          _buildCategoryChip(),
          const SizedBox(height: 16),
          _buildEventStats(),
        ],
      ),
    );
  }

  Widget _buildPriceTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: widget.event.isFree 
            ? const Color(0xFF4CAF50).withOpacity(0.1)
            : const Color(0xFFFF9800).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.event.isFree 
              ? const Color(0xFF4CAF50)
              : const Color(0xFFFF9800),
          width: 2,
        ),
      ),
      child: Text(
        widget.event.isFree ? 'FREE' : 'PAID',
        style: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: widget.event.isFree 
              ? const Color(0xFF4CAF50)
              : const Color(0xFFFF9800),
        ),
      ),
    );
  }

  Widget _buildCategoryChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF008037).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getCategoryIcon(),
            size: 16,
            color: const Color(0xFF008037),
          ),
          const SizedBox(width: 6),
          Text(
            widget.event.category,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF008037),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventStats() {
    return Row(
      children: [
        _buildStatItem(
          icon: Icons.people,
          value: '${widget.event.rsvpCount}',
          label: 'Going',
        ),
        const SizedBox(width: 24),
        _buildStatItem(
          icon: Icons.visibility,
          value: '${widget.event.attendeeCount + 50}', // Mock view count
          label: 'Views',
        ),
        const SizedBox(width: 24),
        _buildStatItem(
          icon: Icons.share,
          value: '${(widget.event.rsvpCount * 0.3).round()}', // Mock share count
          label: 'Shares',
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF008037),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: const Color(0xFF666666),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.calendar_today,
            title: 'Date & Time',
            subtitle: _formatEventDateTime(),
          ),
          const Divider(height: 32),
          _buildInfoRow(
            icon: Icons.location_on,
            title: 'Location',
            subtitle: widget.event.location.displayAddress.isNotEmpty 
                ? widget.event.location.displayAddress
                : 'Location TBA',
            onTap: widget.event.location.latitude != null 
                ? () => _openMaps()
                : null,
          ),
          if (widget.event.ticketUrl != null) ...[
            const Divider(height: 32),
            _buildInfoRow(
              icon: Icons.confirmation_number,
              title: 'Tickets',
              subtitle: widget.event.isFree ? 'Free Registration' : 'Purchase Required',
              onTap: () => _openTicketUrl(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF008037).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF008037),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: const Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: const Color(0xFF999999),
            ),
        ],
      ),
    );
  }

  Widget _buildEventDescription() {
    if (widget.event.description.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About This Event',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event.description,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: const Color(0xFF666666),
                    height: 1.6,
                  ),
                  maxLines: _showFullDescription ? null : 4,
                  overflow: _showFullDescription ? null : TextOverflow.ellipsis,
                ),
                if (widget.event.description.length > 200) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showFullDescription = !_showFullDescription;
                      });
                    },
                    child: Text(
                      _showFullDescription ? 'Show Less' : 'Read More',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF008037),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventLocation() {
    if (widget.event.location.displayAddress.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.event.location.name != null) ...[
                  Text(
                    widget.event.location.name!,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  widget.event.location.displayAddress,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: const Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openMaps,
                    icon: const Icon(Icons.directions),
                    label: Text(
                      'Get Directions',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF008037),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventAttendees() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Who\'s Going',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _showAllAttendees(),
                child: Text(
                  'See All',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF008037),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          EventAttendeesList(
            eventId: widget.event.id,
            maxVisible: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarEvents() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Similar Events',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5, // Mock similar events
              itemBuilder: (context, index) {
                return Container(
                  width: 200,
                  margin: EdgeInsets.only(right: index == 4 ? 0 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Similar Event ${index + 1}',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF333333),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tomorrow, 7:00 PM',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: const Color(0xFF666666),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'FREE',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: RSVPButton(
                eventId: widget.event.id,
                compact: false,
              ),
            ),
            const SizedBox(width: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF008037)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _shareEvent,
                icon: const Icon(
                  Icons.share,
                  color: Color(0xFF008037),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon() {
    switch (widget.event.category.toLowerCase()) {
      case 'music':
        return Icons.music_note;
      case 'business':
        return Icons.business;
      case 'community':
        return Icons.group;
      case 'food':
      case 'food & drink':
        return Icons.restaurant;
      case 'arts':
        return Icons.palette;
      case 'fashion':
        return Icons.checkroom;
      case 'sports':
      case 'fitness':
        return Icons.sports;
      case 'technology':
        return Icons.computer;
      default:
        return Icons.event;
    }
  }

  String _formatEventDateTime() {
    final startDate = DateFormat('EEEE, MMMM d, yyyy').format(widget.event.startDate);
    final startTime = DateFormat('h:mm a').format(widget.event.startDate);
    
    if (widget.event.startDate.day == widget.event.endDate.day) {
      final endTime = DateFormat('h:mm a').format(widget.event.endDate);
      return '$startDate\n$startTime - $endTime';
    } else {
      final endDate = DateFormat('EEEE, MMMM d, yyyy').format(widget.event.endDate);
      final endTime = DateFormat('h:mm a').format(widget.event.endDate);
      return '$startDate at $startTime\nto $endDate at $endTime';
    }
  }

  void _shareEvent() {
    final text = '''
🎉 Check out this amazing event!

${widget.event.name}
📅 ${DateFormat('EEEE, MMMM d at h:mm a').format(widget.event.startDate)}
📍 ${widget.event.location.displayAddress}
${widget.event.isFree ? '🆓 FREE' : '🎫 Paid Event'}

${widget.event.ticketUrl ?? 'More details in NaijaSingles app!'}

#NaijaSingles #AfrocentricEvents #${widget.event.category.replaceAll(' ', '')}
''';

    Share.share(text);
  }

  void _toggleFavorite() {
    // TODO: Implement favorite functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Favorite feature coming soon!',
          style: GoogleFonts.montserrat(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF008037),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _openMaps() async {
    if (widget.event.location.latitude != null && widget.event.location.longitude != null) {
      final url = 'https://www.google.com/maps/search/?api=1&query=${widget.event.location.latitude},${widget.event.location.longitude}';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    } else if (widget.event.location.displayAddress.isNotEmpty) {
      final encodedAddress = Uri.encodeComponent(widget.event.location.displayAddress);
      final url = 'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    }
  }

  void _openTicketUrl() async {
    if (widget.event.ticketUrl != null) {
      final url = Uri.parse(widget.event.ticketUrl!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    }
  }

  void _showAllAttendees() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Event Attendees',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: EventAttendeesList(
                    eventId: widget.event.id,
                    scrollController: scrollController,
                    showAll: true,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
