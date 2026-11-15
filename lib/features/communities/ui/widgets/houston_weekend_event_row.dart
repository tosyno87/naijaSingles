import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../events/data/models/event_model.dart';
import '../../utils/houston_events_selection.dart';

/// Compact Figma weekend row: photo, date badge, title, place, optional host.
class HoustonWeekendEventRow extends StatelessWidget {
  const HoustonWeekendEventRow({
    required this.event,
    required this.onTap,
    this.hostName,
    super.key,
  });

  static const String eventPlaceholderAsset =
      'assets/images/placeholders/discover_event_placeholder.png';

  final EventModel event;
  final VoidCallback onTap;
  final String? hostName;

  @override
  Widget build(BuildContext context) {
    final int going = eventGoingCount(event);
    final String? host = hostName?.trim();
    final bool hasHost = host != null && host.isNotEmpty;
    final String place = eventPlaceLabel(event);

    return Semantics(
      button: true,
      label: event.name,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 106,
                  height: 78,
                  child: _EventPhoto(imageUrl: event.imageUrl),
                ),
              ),
              const SizedBox(width: 12),
              _DateBadge(date: event.startDate),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111111),
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (place.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        place,
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6A6A6A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (hasHost) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Host: $host',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF595959),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (going > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        '$going going',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Icon(
                  Icons.chevron_right,
                  color: Color(0xFF6B6B6B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) => Container(
        width: 48,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFF1EEE7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('MMM').format(date).toUpperCase(),
              style: GoogleFonts.montserrat(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
              ),
            ),
            Text(
              DateFormat('d').format(date),
              style: GoogleFonts.montserrat(
                fontSize: 23,
                fontWeight: FontWeight.w700,
                height: 1.1,
                color: const Color(0xFF111111),
              ),
            ),
            Text(
              DateFormat('E').format(date).toUpperCase(),
              style: GoogleFonts.montserrat(
                fontSize: 8,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B6B6B),
              ),
            ),
          ],
        ),
      );
}

class _EventPhoto extends StatelessWidget {
  const _EventPhoto({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final String? url = imageUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, __) => const ColoredBox(color: Color(0xFF714B34)),
        errorWidget: (_, __, ___) => Image.asset(
          HoustonWeekendEventRow.eventPlaceholderAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const ColoredBox(
            color: Color(0xFF714B34),
          ),
        ),
      );
    }
    return Image.asset(
      HoustonWeekendEventRow.eventPlaceholderAsset,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const ColoredBox(
        color: Color(0xFF714B34),
      ),
    );
  }
}
