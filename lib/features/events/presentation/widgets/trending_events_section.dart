import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../common/constants/app_colors.dart';
import '../../data/models/event_model.dart';

class TrendingEventsSection extends StatelessWidget {
  const TrendingEventsSection({
    required this.trendingEvents,
    required this.onEventTap,
    super.key,
    this.onViewAllTap,
  });
  final List<EventModel> trendingEvents;
  final Function(EventModel) onEventTap;
  final VoidCallback? onViewAllTap;

  @override
  Widget build(BuildContext context) {
    if (trendingEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(),
          const SizedBox(height: 12),
          _buildTrendingEventsList(),
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
                  Icons.trending_up,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Trending Events',
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
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _buildTrendingEventsList() => SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: trendingEvents.length,
          itemBuilder: (context, index) {
            final event = trendingEvents[index];
            return _buildTrendingEventCard(event);
          },
        ),
      );

  Widget _buildTrendingEventCard(EventModel event) => Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        child: GestureDetector(
          onTap: () => onEventTap(event),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
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
                        _buildEventStats(event),
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
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                  size: 40,
                  color: Color(0xFF666666),
                ),
              )
            : null,
      );

  Widget _buildEventTitle(EventModel event) => Text(
        event.name,
        style: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF333333),
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );

  Widget _buildEventDate(EventModel event) {
    final date = event.startDate;
    final formattedDate = '${date.day}/${date.month}/${date.year}';
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
          '$formattedDate at $formattedTime',
          style: GoogleFonts.montserrat(
            fontSize: 12,
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
                fontSize: 12,
                color: const Color(0xFF666666),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

  Widget _buildEventStats(EventModel event) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.people,
                size: 12,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(width: 4),
              Text(
                '${event.rsvpCount} RSVPs',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
          if (event.isFree)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'FREE',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            )
          else if (event.ticketPrice != null)
            Text(
              '\$${event.ticketPrice!.toStringAsFixed(0)}',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
              ),
            ),
        ],
      );
}
