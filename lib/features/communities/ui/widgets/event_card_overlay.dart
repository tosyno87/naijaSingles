import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../events/data/models/event_model.dart';

class EventCardOverlay extends StatelessWidget {
  const EventCardOverlay({
    required this.event,
    required this.onTap,
    super.key,
  });

  final EventModel event;
  final VoidCallback onTap;

  String get _formattedDate {
    final now = DateTime.now();
    final diff = event.startDate.difference(now).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return DateFormat('EEEE, MMM d').format(event.startDate);
  }

  String get _locationLabel {
    final loc = event.location;
    final city = loc.city;
    final country = loc.country;
    if (city != null && city.isNotEmpty) {
      if (country != null && country.isNotEmpty) {
        return '$city, $country';
      }
      return city;
    }
    return loc.shortAddress;
  }

  IconData get _categoryIcon {
    switch (event.category.toLowerCase()) {
      case 'music':
        return Icons.music_note_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'sports':
        return Icons.sports_soccer_rounded;
      case 'networking':
        return Icons.business_center_rounded;
      case 'culture':
        return Icons.theater_comedy_rounded;
      case 'party':
        return Icons.celebration_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  Color get _categoryColor {
    switch (event.category.toLowerCase()) {
      case 'music':
        return const Color(0xFFFF9800);
      case 'food':
        return const Color(0xFFE8475F);
      case 'networking':
        return AppColors.primaryGreen;
      default:
        return const Color(0xFFFF9800);
    }
  }

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: event.name,
        child: SizedBox(
          height: 200,
          child: Material(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Stack(
            fit: StackFit.expand,
            children: [
              if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: event.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppColors.primaryGreen.withValues(alpha: 0.08),
                  ),
                  errorWidget: (_, __, ___) => _buildFallbackBg(),
                )
              else
                _buildFallbackBg(),

              // Dark gradient overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.35, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.80),
                      ],
                    ),
                  ),
                ),
              ),

              // Category icon badge
              Positioned(
                right: 12,
                bottom: 56,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _categoryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_categoryIcon, size: 20, color: Colors.white),
                ),
              ),

              // Bottom info
              Positioned(
                left: 14,
                right: 56,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      event.name,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formattedDate,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: Colors.white54),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            _locationLabel,
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (event.attendeeCount > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${event.attendeeCount} going',
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
        ),
      );

  Widget _buildFallbackBg() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _categoryColor.withValues(alpha: 0.6),
              _categoryColor.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: Center(
          child: Icon(_categoryIcon, size: 48, color: Colors.white38),
        ),
      );
}
