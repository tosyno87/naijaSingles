import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../common/utils/app_logger.dart';
import '../bloc/rsvp_bloc.dart';
import '../widgets/event_attendees_list.dart';
import '../../data/models/event_model.dart';
import '../../data/models/rsvp_model.dart';
import '../../data/services/events_firestore_service.dart';
import '../../../../common/constants/app_colors.dart';

class EventDetailsScreen extends StatefulWidget {
  const EventDetailsScreen({
    required this.event,
    super.key,
  });
  final EventModel event;

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late ScrollController _scrollController;
  bool _showFullDescription = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return BlocProvider(
        create: (context) => RSVPBloc(
          firestoreService: EventsFirestoreService(),
          currentUserId: userId,
        )
          ..add(LoadEventRSVPStatusEvent(
            userId: userId,
            eventId: widget.event.id,
          ))
          ..add(LoadEventAttendeesEvent(
            eventId: widget.event.id,
          )),
        child: BlocBuilder<RSVPBloc, RSVPState>(
          builder: (context, state) {
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

  Widget _buildSliverAppBar() => SliverAppBar(
        expandedHeight: 350,
        pinned: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
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
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.share_outlined,
                  color: Colors.white, size: 20),
              onPressed: _shareEvent,
            ),
          ),
        ],
        flexibleSpace: FlexibleSpaceBar(
          background: Stack(
            fit: StackFit.expand,
            children: [
              _buildEventHeaderImage(),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
              // Event title and chips overlaid on image
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.event.name,
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Category chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            widget.event.category,
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Paid/Free chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: widget.event.isFree
                                ? Colors.grey.withValues(alpha: 0.8)
                                : const Color(0xFFEF476F).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            widget.event.isFree ? 'FREE' : 'PAID',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  String? _getEventImageUrl() {
    // Check if imageUrl exists and is not empty
    final imageUrl = widget.event.imageUrl;
    AppLogger.debug(
        '🔍 EventDetails._getEventImageUrl - Event ID: ${widget.event.id}');
    AppLogger.debug(
        '🔍 EventDetails._getEventImageUrl - imageUrl type: ${imageUrl.runtimeType}');
    AppLogger.debug(
        '🔍 EventDetails._getEventImageUrl - imageUrl value: $imageUrl');

    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      AppLogger.debug('✅ EventDetails: Using imageUrl: $imageUrl');
      return imageUrl;
    }
    AppLogger.debug(
        '❌ EventDetails: imageUrl is null or empty. Event ID: ${widget.event.id}');
    return null;
  }

  Widget _buildEventHeaderImage() {
    final imageUrl = _getEventImageUrl();

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => const ColoredBox(
          color: Color(0xFFF5F5F5),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.primaryGreen),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildPlaceholderImage(),
      );
    }

    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() => ColoredBox(
        color: AppColors.primaryGreen,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getCategoryIcon(),
              size: 80,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 16),
            Text(
              widget.event.category,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      );

  Widget _buildEventDetails() => DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            _buildStatsRow(),
            const SizedBox(height: 24),
            _buildDateTimeCard(),
            const SizedBox(height: 16),
            _buildLocationCard(),
            const SizedBox(height: 24),
            _buildEventDescription(),
            const SizedBox(height: 24),
            _buildEventAttendees(),
            const SizedBox(height: 100), // Space for bottom bar
          ],
        ),
      );

  Widget _buildStatsRow() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(
              icon: Icons.people,
              value: '${widget.event.rsvpCount}',
              label: 'Going',
            ),
            _buildStatItem(
              icon: Icons.group,
              value: '${widget.event.attendeeCount}',
              label: 'Interested',
            ),
          ],
        ),
      );

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) =>
      Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF666666),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3E1F0D),
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
      );

  Widget _buildDateTimeCard() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_today,
                color: AppColors.primaryGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date & Time',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3E1F0D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatEventDateTime(),
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: const Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildLocationCard() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.event.location.latitude != null ? _openMaps : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.primaryGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3E1F0D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.event.location.displayAddress.isNotEmpty
                              ? widget.event.location.displayAddress
                              : 'Location TBA',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: const Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.event.location.latitude != null)
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFF999999),
                    ),
                ],
              ),
            ),
          ),
        ),
      );

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
              color: const Color(0xFF3E1F0D),
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
                  color: Colors.black.withValues(alpha: 0.05),
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
                    height: 1.5,
                  ),
                  maxLines: _showFullDescription ? null : 3,
                  overflow: _showFullDescription ? null : TextOverflow.ellipsis,
                ),
                if (widget.event.description.length > 150) ...[
                  const SizedBox(height: 12),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _showFullDescription = !_showFullDescription;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          _showFullDescription ? 'Show Less' : 'Read More',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
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

  Widget _buildEventAttendees() => Padding(
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
                  onPressed: _showAllAttendees,
                  child: Text(
                    'See All',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
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

  Widget _buildBottomActionBar() => BlocBuilder<RSVPBloc, RSVPState>(
        builder: (context, state) {
          bool isGoing = false;
          if (state is EventRSVPStatusLoaded) {
            isGoing = state.status == RSVPStatus.going;
          }

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // Trigger RSVP action
                        context.read<RSVPBloc>().add(
                              RSVPToEventEvent(
                                eventId: widget.event.id,
                                status: isGoing
                                    ? RSVPStatus.notGoing
                                    : RSVPStatus.going,
                              ),
                            );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isGoing ? Icons.check : Icons.add,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isGoing ? 'Going' : 'I\'m Going',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );

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
    final startDate =
        DateFormat('EEEE, MMMM d, yyyy').format(widget.event.startDate);
    final startTime = DateFormat('h:mm a').format(widget.event.startDate);

    if (widget.event.startDate.day == widget.event.endDate.day) {
      final endTime = DateFormat('h:mm a').format(widget.event.endDate);
      return '$startDate\n$startTime - $endTime';
    } else {
      final endDate =
          DateFormat('EEEE, MMMM d, yyyy').format(widget.event.endDate);
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

${widget.event.ticketUrl ?? 'More details in the Afropeep app!'}

#Afropeep #AfrocentricEvents #${widget.event.category.replaceAll(' ', '')}
''';

    SharePlus.instance.share(ShareParams(text: text));
  }

  Future<void> _openMaps() async {
    if (widget.event.location.latitude != null &&
        widget.event.location.longitude != null) {
      final url =
          'https://www.google.com/maps/search/?api=1&query=${widget.event.location.latitude},${widget.event.location.longitude}';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    } else if (widget.event.location.displayAddress.isNotEmpty) {
      final encodedAddress =
          Uri.encodeComponent(widget.event.location.displayAddress);
      final url =
          'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
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
        builder: (context, scrollController) => DecoratedBox(
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
        ),
      ),
    );
  }
}
