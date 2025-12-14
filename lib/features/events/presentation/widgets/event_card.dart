import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../data/models/event_model.dart';
import '../../data/models/rsvp_model.dart';
import '../../data/services/location_service.dart';
import '../bloc/rsvp_bloc.dart';
import 'rsvp_button.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;
  final bool showRSVPButton;
  final bool isCompact;

  const EventCard({
    Key? key,
    required this.event,
    this.onTap,
    this.showRSVPButton = true,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                    _buildEventDescription(),
                  ],
                  const SizedBox(height: 16),
                  _buildEventFooter(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: event.imageUrl != null && event.imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: event.imageUrl!,
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
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getCategoryIcon(),
            size: 48,
            color: const Color(0xFF008037),
          ),
          const SizedBox(height: 8),
          Text(
            event.category,
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

  Widget _buildEventHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.name,
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildCategoryChip(),
                  if (event.distanceFromUser != null) ...[
                    const SizedBox(width: 8),
                    _buildDistanceChip(),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildPriceTag(),
      ],
    );
  }

  Widget _buildCategoryChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF008037).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        event.category,
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF008037),
        ),
      ),
    );
  }

  Widget _buildDistanceChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF666666).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on,
            size: 12,
            color: const Color(0xFF666666),
          ),
          const SizedBox(width: 2),
          Text(
            LocationService.formatDistance(event.distanceFromUser!),
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: event.isFree
            ? const Color(0xFF4CAF50).withOpacity(0.1)
            : const Color(0xFFFF9800).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              event.isFree ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
          width: 1,
        ),
      ),
      child: Text(
        event.isFree ? 'FREE' : 'PAID',
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color:
              event.isFree ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
        ),
      ),
    );
  }

  Widget _buildEventDetails() {
    return Column(
      children: [
        _buildDetailRow(
          icon: Icons.calendar_today,
          text: _formatEventDate(),
        ),
        const SizedBox(height: 8),
        _buildDetailRow(
          icon: Icons.access_time,
          text: _formatEventTime(),
        ),
        const SizedBox(height: 8),
        _buildDetailRow(
          icon: Icons.location_on,
          text: event.location.displayAddress.isNotEmpty
              ? event.location.displayAddress
              : 'Location TBA',
        ),
      ],
    );
  }

  Widget _buildDetailRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF666666),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: const Color(0xFF666666),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEventDescription() {
    if (event.description.isEmpty) return const SizedBox.shrink();

    return Text(
      event.description,
      style: GoogleFonts.montserrat(
        fontSize: 14,
        color: const Color(0xFF666666),
        height: 1.4,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildEventFooter(BuildContext context) {
    return Row(
      children: [
        _buildAttendeeCount(),
        const Spacer(),
        if (showRSVPButton)
          RSVPButton(
            eventId: event.id,
            compact: true,
          ),
      ],
    );
  }

  Widget _buildAttendeeCount() {
    return Row(
      children: [
        Icon(
          Icons.people,
          size: 16,
          color: const Color(0xFF008037),
        ),
        const SizedBox(width: 4),
        Text(
          '${event.rsvpCount} going',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF008037),
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon() {
    switch (event.category.toLowerCase()) {
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

  String _formatEventDate() {
    final now = DateTime.now();
    final eventDate = event.startDate;

    if (eventDate.year == now.year &&
        eventDate.month == now.month &&
        eventDate.day == now.day) {
      return 'Today';
    }

    final tomorrow = now.add(const Duration(days: 1));
    if (eventDate.year == tomorrow.year &&
        eventDate.month == tomorrow.month &&
        eventDate.day == tomorrow.day) {
      return 'Tomorrow';
    }

    final difference = eventDate.difference(now).inDays;
    if (difference < 7) {
      return DateFormat('EEEE, MMM d').format(eventDate);
    }

    return DateFormat('MMM d, yyyy').format(eventDate);
  }

  String _formatEventTime() {
    final startTime = DateFormat('h:mm a').format(event.startDate);

    if (event.startDate.day == event.endDate.day) {
      final endTime = DateFormat('h:mm a').format(event.endDate);
      return '$startTime - $endTime';
    }

    return 'Starts at $startTime';
  }
}

// Compact version for lists
class CompactEventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;

  const CompactEventCard({
    Key? key,
    required this.event,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60,
                height: 60,
                child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: event.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: const Color(0xFFF5F5F5),
                          child: Icon(
                            Icons.event,
                            color: const Color(0xFF008037),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: const Color(0xFFF5F5F5),
                          child: Icon(
                            Icons.event,
                            color: const Color(0xFF008037),
                          ),
                        ),
                      )
                    : Container(
                        color: const Color(0xFFF5F5F5),
                        child: Icon(
                          Icons.event,
                          color: const Color(0xFF008037),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF333333),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, h:mm a').format(event.startDate),
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: const Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.location.displayAddress.isNotEmpty
                        ? event.location.displayAddress
                        : 'Location TBA',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: const Color(0xFF999999),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            RSVPButton(
              eventId: event.id,
              compact: true,
            ),
          ],
        ),
      ),
    );
  }
}
