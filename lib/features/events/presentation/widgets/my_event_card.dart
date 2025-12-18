import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../../common/utils/app_logger.dart';
import '../../data/models/enhanced_event_model.dart';

class MyEventCard extends StatelessWidget {

  const MyEventCard({
    required this.event, super.key,
    this.isDraft = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onPublish,
    this.onShare,
    this.onAnalytics,
  });
  final EnhancedEventModel event;
  final bool isDraft;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onPublish;
  final VoidCallback? onShare;
  final VoidCallback? onAnalytics;

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
            _buildEventImage(context),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEventHeader(),
                  const SizedBox(height: 12),
                  _buildEventDetails(),
                  const SizedBox(height: 16),
                  _buildEventStats(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );

  Widget _buildEventImage(BuildContext context) {
    // Debug logging
    AppLogger.debug('🖼️ Event ${event.id} - hasImages: ${event.hasImages}');
    AppLogger.debug('🖼️ Event ${event.id} - imageUrls: ${event.imageUrls}');
    AppLogger.debug('🖼️ Event ${event.id} - primaryImageUrl: ${event.primaryImageUrl}');

    return Container(
      height: 200, // Increased height for better poster visibility
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
          // Image or placeholder
          if (event.hasImages)
            GestureDetector(
              onTap: () => _showFullScreenPoster(context),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Container(
                  color: Colors.grey.shade100, // Background for contained images
                  child: event.primaryImageUrl.startsWith('http')
                      ? Image.network(
                          event.primaryImageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          isAntiAlias: true,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: const Color(0xFFF8F8F8),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes !=
                                              null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF008037),
                                      ),
                                      strokeWidth: 3,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Loading poster...',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      color: const Color(0xFF666666),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          AppLogger.error(
                              '❌ Error loading image for event ${event.id}', error: error, stackTrace: stackTrace,);
                          AppLogger.debug('❌ Image URL: ${event.primaryImageUrl}');
                          return Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: const Color(0xFFF0F0F0),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.broken_image_outlined,
                                    size: 48,
                                    color: Color(0xFF999999),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Poster failed to load',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      color: const Color(0xFF666666),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap to retry',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      color: const Color(0xFF999999),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                      : Image.file(
                        File(event.primaryImageUrl),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (context, error, stackTrace) {
                          AppLogger.error(
                              '❌ Error loading local image for event ${event.id}', error: error, stackTrace: stackTrace,);
                          return Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: const Color(0xFFF0F0F0),
                            child: const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 48,
                                color: Color(0xFF999999),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ),
              ),
            )
          else
            // Enhanced placeholder for events without images
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF008037).withOpacity(0.1),
                    AppColors.backgroundColor,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_outlined,
                      size: 56,
                      color: const Color(0xFF008037).withOpacity(0.7),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No Poster',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: const Color(0xFF666666),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Event details below',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: const Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Gradient overlay for better text readability on posters
          if (event.hasImages)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
              ),
            ),

          // Status badge
          Positioned(
            top: 12,
            left: 12,
            child: _buildStatusBadge(),
          ),

          // Image count badge for multiple images
          if (event.imageUrls.length > 1)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${event.imageUrls.length} photos',
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
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    Color textColor;
    String text;
    IconData icon;

    switch (event.status) {
      case EventStatus.draft:
        backgroundColor = Colors.grey.withOpacity(0.9);
        textColor = Colors.white;
        text = 'DRAFT';
        icon = Icons.edit;
        break;
      case EventStatus.underReview:
        backgroundColor = Colors.orange.withOpacity(0.9);
        textColor = Colors.white;
        text = 'UNDER REVIEW';
        icon = Icons.schedule;
        break;
      case EventStatus.published:
        backgroundColor = const Color(0xFF008037).withOpacity(0.9);
        textColor = Colors.white;
        text = 'PUBLISHED';
        icon = Icons.check_circle;
        break;
      case EventStatus.cancelled:
        backgroundColor = Colors.red.withOpacity(0.9);
        textColor = Colors.white;
        text = 'CANCELLED';
        icon = Icons.cancel;
        break;
      case EventStatus.completed:
        backgroundColor = Colors.blue.withOpacity(0.9);
        textColor = Colors.white;
        text = 'COMPLETED';
        icon = Icons.event_available;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

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
                event.category,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF008037),
                ),
              ),
            ),
            const Spacer(),
            if (event.isPromoted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      size: 12,
                      color: Colors.purple,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'PROMOTED',
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          event.name,
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF333333),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

  Widget _buildEventDetails() {
    final dateFormat = DateFormat('MMM dd, yyyy');
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
                '${dateFormat.format(event.startDate)} • ${timeFormat.format(event.startDate)}',
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
                event.location.shortAddress,
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
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              event.isFree ? Icons.event_available : Icons.monetization_on,
              size: 16,
              color: const Color(0xFF666666),
            ),
            const SizedBox(width: 8),
            Text(
              event.isFree
                  ? 'Free Event'
                  : '${event.currencySymbol}${event.ticketPrice?.toStringAsFixed(0) ?? '0'}',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: event.isFree ? Colors.green : Colors.orange,
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
              label: 'Attendees',
              value: '${event.attendeeCount}/${event.maxAttendees}',
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: const Color(0xFFE0E0E0),
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.visibility,
              label: 'Views',
              value: '${event.metadata['views'] ?? 0}',
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
              value: '${event.rsvpCount}',
            ),
          ),
        ],
      ),
    );

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) => Column(
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

  Widget _buildActionButtons() => Row(
      children: [
        if (isDraft && onPublish != null)
          Expanded(
            child: ElevatedButton(
              onPressed: onPublish,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008037),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Publish',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        if (isDraft && onPublish != null) const SizedBox(width: 8),
        if (onEdit != null)
          Expanded(
            child: OutlinedButton(
              onPressed: onEdit,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF008037)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Edit',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF008037),
                ),
              ),
            ),
          ),
        if (onEdit != null) const SizedBox(width: 8),
        if (onDelete != null)
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.red,
            ),
            tooltip: 'Delete Event',
          ),
        const Spacer(),
        IconButton(
          onPressed: onShare,
          icon: const Icon(
            Icons.share_outlined,
            color: Color(0xFF666666),
          ),
          tooltip: 'Share Event',
        ),
        IconButton(
          onPressed: onAnalytics,
          icon: const Icon(
            Icons.analytics_outlined,
            color: Color(0xFF666666),
          ),
          tooltip: 'View Analytics',
        ),
      ],
    );

  void _showFullScreenPoster(BuildContext context) {
    if (!event.hasImages) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              'Event Poster',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  // Share poster functionality
                  // You can implement sharing here
                },
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(
                event.primaryImageUrl,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                isAntiAlias: true,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF008037),
                            ),
                            strokeWidth: 4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Loading full poster...',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.broken_image_outlined,
                          size: 80,
                          color: Colors.white54,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Failed to load poster',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check your internet connection',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.white54,
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
  }
}
