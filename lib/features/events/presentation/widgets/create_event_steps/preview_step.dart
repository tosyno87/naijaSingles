import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../data/models/enhanced_event_model.dart';

class PreviewStep extends StatelessWidget {

  const PreviewStep({
    required this.eventData, super.key,
  });
  final EventCreationData eventData;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Preview Your Event'),
          const SizedBox(height: 8),
          Text(
            'Review your event details before publishing',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: const Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 32),
          _buildEventPreviewCard(context),
          const SizedBox(height: 32),
          _buildSubmissionNote(),
          const SizedBox(height: 40),
        ],
      ),
    );

  Widget _buildSectionTitle(String title) => Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF333333),
      ),
    );

  Widget _buildEventPreviewCard(BuildContext context) => DecoratedBox(
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEventHeader(),
                const SizedBox(height: 16),
                _buildEventDateTime(),
                const SizedBox(height: 16),
                _buildEventLocation(),
                const SizedBox(height: 16),
                _buildEventDescription(),
                const SizedBox(height: 16),
                _buildEventTags(),
                const SizedBox(height: 16),
                _buildEventPricing(),
              ],
            ),
          ),
        ],
      ),
    );

  Widget _buildEventImage() => Container(
      height: 200,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: eventData.imageUrls.isNotEmpty
          ? ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  // Display the actual image
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: const Color(0xFFF0F0F0),
                    child: eventData.imageUrls.first.startsWith('http')
                        ? Image.network(
                            eventData.imageUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 48,
                                  color: Color(0xFF999999),
                                ),
                              ),
                          )
                        : Image.file(
                            File(eventData.imageUrls.first),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 48,
                                  color: Color(0xFF999999),
                                ),
                              ),
                          ),
                  ),
                  // Show count badge if multiple images
                  if (eventData.imageUrls.length > 1)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4,),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '+${eventData.imageUrls.length - 1}',
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
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.image_outlined,
                    size: 48,
                    color: Color(0xFF999999),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No images added',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: const Color(0xFF999999),
                    ),
                  ),
                ],
              ),
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
                eventData.category,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF008037),
                ),
              ),
            ),
            const Spacer(),
            if (!eventData.isFree)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '₦${eventData.ticketPrice?.toStringAsFixed(0) ?? '0'}',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'FREE',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          eventData.name,
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF333333),
          ),
        ),
      ],
    );

  Widget _buildEventDateTime() {
    if (eventData.startDate == null || eventData.endDate == null) {
      return const SizedBox.shrink();
    }

    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Row(
      children: [
        const Icon(
          Icons.schedule,
          size: 20,
          color: Color(0xFF666666),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${dateFormat.format(eventData.startDate!)} • ${timeFormat.format(eventData.startDate!)}',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                ),
              ),
              Text(
                'Ends ${dateFormat.format(eventData.endDate!)} • ${timeFormat.format(eventData.endDate!)}',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: const Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventLocation() {
    if (eventData.location == null) {
      return const SizedBox.shrink();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.location_on,
          size: 20,
          color: Color(0xFF666666),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            eventData.location!.displayAddress,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: const Color(0xFF666666),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventDescription() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About this event',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          eventData.description,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: const Color(0xFF666666),
            height: 1.5,
          ),
        ),
      ],
    );

  Widget _buildEventTags() {
    if (eventData.tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: eventData.tags.map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF008037).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF008037).withOpacity(0.3),
                ),
              ),
              child: Text(
                tag,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: const Color(0xFF008037),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),).toList(),
        ),
      ],
    );
  }

  Widget _buildEventPricing() => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Icon(
            eventData.isFree ? Icons.event_available : Icons.monetization_on,
            color: const Color(0xFF008037),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eventData.isFree ? 'Free Event' : 'Paid Event',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
                Text(
                  eventData.isFree
                      ? 'No charge for attendees'
                      : '₦${eventData.ticketPrice?.toStringAsFixed(2) ?? '0.00'} per ticket',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: const Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${eventData.maxAttendees} max',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );

  Widget _buildSubmissionNote() => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Before You Submit',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Your event will be reviewed by our team before being published\n'
            '• Review typically takes 24-48 hours\n'
            '• You\'ll receive a notification once your event is approved\n'
            '• Make sure all information is accurate as changes after approval require re-review',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.blue,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
}
