import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../data/models/enhanced_event_model.dart';
import '../../data/models/event_model.dart';
import 'rsvp_button.dart';

class EnhancedEventCard extends StatelessWidget {
  const EnhancedEventCard({
    required this.event,
    super.key,
    this.onTap,
    this.showRSVPButton = true,
    this.isCompact = false,
    this.showCreatorInfo = false,
  });
  final dynamic event; // Can be EventModel or EnhancedEventModel
  final VoidCallback? onTap;
  final bool showRSVPButton;
  final bool isCompact;
  final bool showCreatorInfo;

  // Helper getters to work with both event types
  String get eventId => event is EnhancedEventModel ? event.id : event.id;
  String get eventName => event is EnhancedEventModel ? event.name : event.name;
  String get eventDescription =>
      event is EnhancedEventModel ? event.description : event.description;
  DateTime get startDate =>
      event is EnhancedEventModel ? event.startDate : event.startDate;
  DateTime get endDate =>
      event is EnhancedEventModel ? event.endDate : event.endDate;
  String get category =>
      event is EnhancedEventModel ? event.category : event.category;
  bool get isFree => event is EnhancedEventModel ? event.isFree : event.isFree;
  int get attendeeCount =>
      event is EnhancedEventModel ? event.attendeeCount : event.attendeeCount;
  int get rsvpCount =>
      event is EnhancedEventModel ? event.rsvpCount : event.rsvpCount;

  String? get primaryImageUrl {
    if (event is EnhancedEventModel) {
      return event.primaryImageUrl.isNotEmpty ? event.primaryImageUrl : null;
    } else {
      return event.imageUrl;
    }
  }

  dynamic get location =>
      event is EnhancedEventModel ? event.location : event.location;

  bool get isUserGenerated =>
      event is EnhancedEventModel ? event.isUserGenerated : false;

  bool get isPromoted => event is EnhancedEventModel ? event.isPromoted : false;

  double? get ticketPrice =>
      event is EnhancedEventModel ? event.ticketPrice : null;

  String get currencySymbol =>
      event is EnhancedEventModel ? event.currencySymbol : r'$';

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEventImage(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEventHeader(),
                    const SizedBox(height: 12),
                    _buildEventDetails(),
                    if (!isCompact) ...[
                      const SizedBox(height: 12),
                      _buildEventStats(),
                      if (showRSVPButton) ...[
                        const SizedBox(height: 16),
                        _buildActionButton(),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildEventImage() => Container(
        height: isCompact ? 120 : 160,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Stack(
          children: [
            // Image
            if (primaryImageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: CachedNetworkImage(
                  imageUrl: primaryImageUrl!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const ColoredBox(
                    color: Color(0xFFF0F0F0),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Color(0xFF008037)),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => const ColoredBox(
                    color: Color(0xFFF0F0F0),
                    child: Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: Color(0xFF999999),
                    ),
                  ),
                ),
              )
            else
              Center(
                child: Icon(
                  Icons.event,
                  size: isCompact ? 32 : 48,
                  color: const Color(0xFF999999),
                ),
              ),

            // Badges
            Positioned(
              top: 12,
              left: 12,
              child: Row(
                children: [
                  if (isUserGenerated)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'COMMUNITY',
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (isPromoted) ...[
                    if (isUserGenerated) const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'PROMOTED',
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Price badge
            if (!isFree && ticketPrice != null)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$currencySymbol${ticketPrice!.toStringAsFixed(0)}',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            else if (isFree)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'FREE',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _buildEventHeader() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF008037).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF008037),
                  ),
                ),
              ),
              const Spacer(),
              if (showCreatorInfo && isUserGenerated)
                const Icon(
                  Icons.verified_user,
                  size: 16,
                  color: Color(0xFF008037),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            eventName,
            style: GoogleFonts.montserrat(
              fontSize: isCompact ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );

  Widget _buildEventDetails() {
    final dateFormat = DateFormat('MMM dd');
    final timeFormat = DateFormat('hh:mm a');

    return Column(
      children: [
        Row(
          children: [
            const Icon(
              Icons.schedule,
              size: 16,
              color: Color(0xFF666666),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${dateFormat.format(startDate)} • ${timeFormat.format(startDate)}',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: const Color(0xFF666666),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.location_on,
              size: 16,
              color: Color(0xFF666666),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                location?.displayAddress ??
                    location?.shortAddress ??
                    'Location TBA',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: const Color(0xFF666666),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventStats() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: Icons.people,
                label: 'Attending',
                value: attendeeCount.toString(),
              ),
            ),
            Container(
              width: 1,
              height: 24,
              color: const Color(0xFFE0E0E0),
            ),
            Expanded(
              child: _buildStatItem(
                icon: Icons.favorite,
                label: 'Interested',
                value: rsvpCount.toString(),
              ),
            ),
            if (event is EnhancedEventModel) ...[
              Container(
                width: 1,
                height: 24,
                color: const Color(0xFFE0E0E0),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.event_seat,
                  label: 'Capacity',
                  value: event.maxAttendees.toString(),
                ),
              ),
            ],
          ],
        ),
      );

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) =>
      Column(
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF008037),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 10,
              color: const Color(0xFF666666),
            ),
          ),
        ],
      );

  Widget _buildActionButton() {
    if (event is EventModel) {
      // Use event ID for RSVP button
      return RSVPButton(eventId: (event as EventModel).id);
    } else {
      // Simple button for user-generated events
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF008037),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'View Details',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
  }
}
