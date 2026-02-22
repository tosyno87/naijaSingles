import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/event_model.dart';

class WeekendEventsSection extends StatelessWidget {
  const WeekendEventsSection({
    required this.weekendEvents,
    required this.onEventTap,
    super.key,
    this.onViewAllTap,
  });
  final List<EventModel> weekendEvents;
  final Function(EventModel) onEventTap;
  final VoidCallback? onViewAllTap;

  @override
  Widget build(BuildContext context) {
    if (weekendEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(),
          const SizedBox(height: 12),
          _buildWeekendEventsList(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.weekend,
                  color: Color(0xFF008037),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'This Weekend',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
              ],
            ),
            if (onViewAllTap != null)
              GestureDetector(
                onTap: onViewAllTap,
                child: Text(
                  'View All',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF008037),
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _buildWeekendEventsList() => SizedBox(
        height: 160,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: weekendEvents.length,
          itemBuilder: (context, index) {
            final event = weekendEvents[index];
            return _buildWeekendEventCard(event);
          },
        ),
      );

  Widget _buildWeekendEventCard(EventModel event) => Container(
        width: 240,
        margin: const EdgeInsets.only(right: 16),
        child: GestureDetector(
          onTap: () => onEventTap(event),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEventImage(event),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildEventTitle(event),
                        const SizedBox(height: 4),
                        _buildEventDate(event),
                        const SizedBox(height: 4),
                        _buildEventLocation(event),
                        const Spacer(),
                        _buildEventPrice(event),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildEventImage(EventModel event) => Container(
        height: 80,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          image: event.imageUrl != null
              ? DecorationImage(
                  image: NetworkImage(event.imageUrl!),
                  fit: BoxFit.cover,
                )
              : null,
          color: event.imageUrl == null ? const Color(0xFFE0E0E0) : null,
        ),
        child: event.imageUrl == null
            ? const Center(
                child: Icon(
                  Icons.event,
                  size: 30,
                  color: Color(0xFF666666),
                ),
              )
            : null,
      );

  Widget _buildEventTitle(EventModel event) => Text(
        event.name,
        style: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF333333),
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );

  Widget _buildEventDate(EventModel event) {
    final date = event.startDate;
    final weekday = _getWeekdayName(date.weekday);
    final formattedTime =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Row(
      children: [
        const Icon(
          Icons.calendar_today,
          size: 12,
          color: Color(0xFF666666),
        ),
        const SizedBox(width: 4),
        Text(
          '$weekday at $formattedTime',
          style: GoogleFonts.montserrat(
            fontSize: 11,
            color: const Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  Widget _buildEventLocation(EventModel event) => Row(
        children: [
          const Icon(
            Icons.location_on,
            size: 12,
            color: Color(0xFF666666),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              event.location.displayAddress,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: const Color(0xFF666666),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

  Widget _buildEventPrice(EventModel event) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (event.isFree)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF008037).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'FREE',
                style: GoogleFonts.montserrat(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF008037),
                ),
              ),
            )
          else if (event.ticketPrice != null)
            Text(
              '\$${event.ticketPrice!.toStringAsFixed(0)}',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF008037),
              ),
            )
          else
            const SizedBox.shrink(),
          Row(
            children: [
              const Icon(
                Icons.people,
                size: 12,
                color: Color(0xFF666666),
              ),
              const SizedBox(width: 2),
              Text(
                '${event.rsvpCount}',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  color: const Color(0xFF666666),
                ),
              ),
            ],
          ),
        ],
      );

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return 'Weekend';
    }
  }
}
