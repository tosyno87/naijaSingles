import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../common/constants/app_colors.dart';
import '../../data/models/event_model.dart';
import '../../data/services/events_firestore_service.dart';
import '../bloc/rsvp_bloc.dart';
import '../widgets/event_attendees_list.dart';
import '../widgets/event_description_section.dart';
import '../widgets/event_details_app_bar.dart';
import '../widgets/event_rsvp_bottom_bar.dart';

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
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            EventDetailsSliverAppBar(
              event: widget.event,
              onShare: _shareEvent,
            ),
            SliverToBoxAdapter(
              child: _buildEventDetails(),
            ),
          ],
        ),
        bottomNavigationBar: EventRsvpBottomBar(
          eventId: widget.event.id,
        ),
      ),
    );
  }

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
            EventDescriptionSection(description: widget.event.description),
            const SizedBox(height: 24),
            _buildEventAttendees(),
            const SizedBox(height: 100),
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
              label: 'Going'.tr(),
            ),
            _buildStatItem(
              icon: Icons.group,
              value: '${widget.event.attendeeCount}',
              label: 'Interested'.tr(),
            ),
          ],
        ),
      );

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) =>
      Semantics(
        label: '$value $label',
        child: Column(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF666666)),
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
        ),
      );

  Widget _buildDateTimeCard() => Semantics(
        label:
            '${'Date & Time'.tr()}: ${_formatEventDateTime().replaceAll('\n', ', ')}',
        child: Container(
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
                      'Date & Time'.tr(),
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
        ),
      );

  Widget _buildLocationCard() {
    final location = widget.event.location;
    final address = location.displayAddress.isNotEmpty
        ? location.displayAddress
        : 'Location TBA'.tr();

    return Semantics(
      button: location.latitude != null,
      label: '${'Location'.tr()}: $address',
      child: Container(
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
            onTap: location.latitude != null ? _openMaps : null,
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
                          'Location'.tr(),
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3E1F0D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          address,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: const Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (location.latitude != null)
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
                Semantics(
                  header: true,
                  child: Text(
                    "Who's Going".tr(),
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ),
                const Spacer(),
                Semantics(
                  button: true,
                  label: 'See All'.tr(),
                  child: TextButton(
                    onPressed: _showAllAttendees,
                    child: Text(
                      'See All'.tr(),
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
                      ),
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
                child: Semantics(
                  header: true,
                  child: Text(
                    'Event Attendees'.tr(),
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
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
