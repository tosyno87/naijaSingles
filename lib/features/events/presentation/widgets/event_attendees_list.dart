import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/rsvp_model.dart';
import '../bloc/rsvp_bloc.dart';

class EventAttendeesList extends StatefulWidget {
  const EventAttendeesList({
    required this.eventId,
    super.key,
    this.maxVisible,
    this.scrollController,
    this.showAll = false,
  });
  final String eventId;
  final int? maxVisible;
  final ScrollController? scrollController;
  final bool showAll;

  @override
  State<EventAttendeesList> createState() => _EventAttendeesListState();
}

class _EventAttendeesListState extends State<EventAttendeesList> {
  @override
  void initState() {
    super.initState();
    // Load attendees when widget is created
    context.read<RSVPBloc>().add(
          LoadEventAttendeesEvent(
            eventId: widget.eventId,
            statusFilter: RSVPStatus.going,
          ),
        );
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<RSVPBloc, RSVPState>(
        builder: (context, state) {
          if (state is RSVPLoading) {
            return _buildLoadingState();
          }

          if (state is EventAttendeesLoaded &&
              state.eventId == widget.eventId) {
            final goingAttendees = state.attendees
                .where((attendee) => attendee.status == RSVPStatus.going)
                .toList();

            if (goingAttendees.isEmpty) {
              return _buildEmptyState();
            }

            return widget.showAll
                ? _buildFullList(goingAttendees)
                : _buildPreviewList(goingAttendees, state.statusCounts);
          }

          return _buildEmptyState();
        },
      );

  Widget _buildLoadingState() => SizedBox(
        height: widget.showAll ? 200 : 80,
        child: widget.showAll
            ? ListView.builder(
                controller: widget.scrollController,
                itemCount: 5,
                itemBuilder: (context, index) => _buildAttendeeShimmer(),
              )
            : Row(
                children: List.generate(
                  4,
                  (index) => Padding(
                    padding: EdgeInsets.only(right: index == 3 ? 0 : 8),
                    child: _buildAvatarShimmer(),
                  ),
                ),
              ),
      );

  Widget _buildEmptyState() => Container(
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
            Icon(
              Icons.people_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No attendees yet',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Be the first to RSVP!',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: const Color(0xFF999999),
              ),
            ),
          ],
        ),
      );

  Widget _buildPreviewList(
    List<EventAttendeeModel> attendees,
    Map<RSVPStatus, int> statusCounts,
  ) {
    final displayCount = widget.maxVisible ?? 6;
    final visibleAttendees = attendees.take(displayCount).toList();
    final remainingCount = attendees.length - visibleAttendees.length;

    return Container(
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
          _buildStatusCounts(statusCounts),
          const SizedBox(height: 16),
          Row(
            children: [
              ...visibleAttendees.asMap().entries.map((entry) {
                final index = entry.key;
                final attendee = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == visibleAttendees.length - 1 ? 0 : 8,
                  ),
                  child: _buildAttendeeAvatar(attendee),
                );
              }),
              if (remainingCount > 0) ...[
                const SizedBox(width: 8),
                _buildMoreIndicator(remainingCount),
              ],
            ],
          ),
          if (visibleAttendees.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _buildAttendeesText(visibleAttendees, remainingCount),
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: const Color(0xFF666666),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFullList(List<EventAttendeeModel> attendees) => ListView.builder(
        controller: widget.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: attendees.length,
        itemBuilder: (context, index) =>
            _buildAttendeeListItem(attendees[index]),
      );

  Widget _buildStatusCounts(Map<RSVPStatus, int> statusCounts) => Row(
        children: [
          _buildStatusCount(
            icon: Icons.check_circle,
            count: statusCounts[RSVPStatus.going] ?? 0,
            label: 'Going',
            color: const Color(0xFF4CAF50),
          ),
          const SizedBox(width: 20),
          _buildStatusCount(
            icon: Icons.star,
            count: statusCounts[RSVPStatus.interested] ?? 0,
            label: 'Interested',
            color: const Color(0xFFFF9800),
          ),
        ],
      );

  Widget _buildStatusCount({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) =>
      Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: const Color(0xFF666666),
            ),
          ),
        ],
      );

  Widget _buildAttendeeAvatar(EventAttendeeModel attendee) => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF008037),
            width: 2,
          ),
        ),
        child: ClipOval(
          child: attendee.userAvatar != null && attendee.userAvatar!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: attendee.userAvatar!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      _buildAvatarPlaceholder(attendee.userName),
                  errorWidget: (context, url, error) =>
                      _buildAvatarPlaceholder(attendee.userName),
                )
              : _buildAvatarPlaceholder(attendee.userName),
        ),
      );

  Widget _buildAvatarPlaceholder(String name) {
    final initials = name
        .split(' ')
        .take(2)
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .join();

    return ColoredBox(
      color: const Color(0xFF008037).withOpacity(0.1),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF008037),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreIndicator(int count) => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF008037).withOpacity(0.1),
          border: Border.all(
            color: const Color(0xFF008037),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            '+$count',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF008037),
            ),
          ),
        ),
      );

  Widget _buildAttendeeListItem(EventAttendeeModel attendee) => Container(
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
            _buildAttendeeAvatar(attendee),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attendee.userName,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  if (attendee.userLocation != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Color(0xFF666666),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          attendee.userLocation!,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: const Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            _buildStatusBadge(attendee.status),
          ],
        ),
      );

  Widget _buildStatusBadge(RSVPStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case RSVPStatus.going:
        color = const Color(0xFF4CAF50);
        icon = Icons.check_circle;
        break;
      case RSVPStatus.interested:
        color = const Color(0xFFFF9800);
        icon = Icons.star;
        break;
      case RSVPStatus.notGoing:
        color = const Color(0xFFF44336);
        icon = Icons.cancel;
        break;
      case RSVPStatus.none:
        color = const Color(0xFF999999);
        icon = Icons.help_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendeeShimmer() => Container(
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
            _buildAvatarShimmer(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 24,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      );

  Widget _buildAvatarShimmer() => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[300],
        ),
      );

  String _buildAttendeesText(
    List<EventAttendeeModel> visibleAttendees,
    int remainingCount,
  ) {
    if (visibleAttendees.isEmpty) return '';

    if (visibleAttendees.length == 1 && remainingCount == 0) {
      return '${visibleAttendees.first.userName} is going';
    }

    if (visibleAttendees.length == 1 && remainingCount > 0) {
      return '${visibleAttendees.first.userName} and $remainingCount ${remainingCount == 1 ? 'other' : 'others'} are going';
    }

    if (visibleAttendees.length == 2 && remainingCount == 0) {
      return '${visibleAttendees.first.userName} and ${visibleAttendees.last.userName} are going';
    }

    if (remainingCount == 0) {
      final names = visibleAttendees.take(2).map((a) => a.userName).join(', ');
      final remaining = visibleAttendees.length - 2;
      return '$names and $remaining ${remaining == 1 ? 'other' : 'others'} are going';
    }

    final names = visibleAttendees.take(2).map((a) => a.userName).join(', ');
    final total = remainingCount + (visibleAttendees.length - 2);
    return '$names and $total ${total == 1 ? 'other' : 'others'} are going';
  }
}
