import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../common/constants/app_colors.dart';
import '../../data/models/event_model.dart';

class EventSharingWidget extends StatelessWidget {
  const EventSharingWidget({
    required this.event,
    super.key,
  });
  final EventModel event;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share Event',
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Spread the word about this amazing event!',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: const Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildEventPreview(),
                  const SizedBox(height: 24),
                  _buildSharingOptions(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildEventPreview() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF008037).withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Color(0xFF666666),
                ),
                const SizedBox(width: 6),
                Text(
                  DateFormat('MMM d, yyyy • h:mm a').format(event.startDate),
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: const Color(0xFF666666),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: Color(0xFF666666),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    event.location.displayAddress.isNotEmpty
                        ? event.location.displayAddress
                        : 'Location TBA',
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
            if (event.isFree) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'FREE EVENT',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              ),
            ],
          ],
        ),
      );

  Widget _buildSharingOptions(BuildContext context) => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildShareOption(
                  icon: Icons.share,
                  title: 'Share Link',
                  subtitle: 'Share via any app',
                  onTap: () => _shareGeneral(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildShareOption(
                  icon: Icons.copy,
                  title: 'Copy Link',
                  subtitle: 'Copy to clipboard',
                  onTap: () => _copyLink(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildShareOption(
                  icon: Icons.message,
                  title: 'Share Text',
                  subtitle: 'Share event details',
                  onTap: () => _shareText(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildShareOption(
                  icon: Icons.image,
                  title: 'Share Image',
                  subtitle: 'Share with image',
                  onTap: () => _shareWithImage(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSocialMediaOptions(context),
        ],
      );

  Widget _buildShareOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE0E0E0),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF008037).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF008037),
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: const Color(0xFF666666),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  Widget _buildSocialMediaOptions(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Share on Social Media',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialButton(
                icon: Icons.facebook,
                color: const Color(0xFF1877F2),
                label: 'Facebook',
                onTap: () => _shareToFacebook(context),
              ),
              _buildSocialButton(
                icon: Icons.alternate_email,
                color: const Color(0xFF1DA1F2),
                label: 'Twitter',
                onTap: () => _shareToTwitter(context),
              ),
              _buildSocialButton(
                icon: Icons.camera_alt,
                color: const Color(0xFFE4405F),
                label: 'Instagram',
                onTap: () => _shareToInstagram(context),
              ),
              _buildSocialButton(
                icon: Icons.chat,
                color: const Color(0xFF25D366),
                label: 'WhatsApp',
                onTap: () => _shareToWhatsApp(context),
              ),
            ],
          ),
        ],
      );

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
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

  void _shareGeneral(BuildContext context) {
    final shareText = _buildShareText();
    Share.share(shareText);
    Navigator.pop(context);
  }

  void _copyLink(BuildContext context) {
    final link =
        event.ticketUrl ?? 'https://naijasingles.com/events/${event.id}';
    Clipboard.setData(ClipboardData(text: link));

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Event link copied to clipboard!',
          style: GoogleFonts.montserrat(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF008037),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _shareText(BuildContext context) {
    final shareText = _buildDetailedShareText();
    Share.share(shareText);
    Navigator.pop(context);
  }

  void _shareWithImage(BuildContext context) {
    if (event.imageUrl != null && event.imageUrl!.isNotEmpty) {
      Share.shareXFiles(
        [
          XFile.fromData(
            Uint8List(0), // Placeholder - would need to download image
            name: 'event_image.jpg',
            mimeType: 'image/jpeg',
          ),
        ],
        text: _buildShareText(),
      );
    } else {
      _shareText(context);
    }
    Navigator.pop(context);
  }

  void _shareToFacebook(BuildContext context) {
    final shareText = _buildSocialShareText();
    Share.share(shareText);
    Navigator.pop(context);
  }

  void _shareToTwitter(BuildContext context) {
    final shareText = _buildTwitterShareText();
    Share.share(shareText);
    Navigator.pop(context);
  }

  void _shareToInstagram(BuildContext context) {
    // Instagram sharing would typically require Instagram SDK
    // For now, we'll copy text and show instructions
    final shareText = _buildInstagramShareText();
    Clipboard.setData(ClipboardData(text: shareText));

    Navigator.pop(context);
    _showInstagramInstructions(context);
  }

  void _shareToWhatsApp(BuildContext context) {
    final shareText = _buildWhatsAppShareText();
    Share.share(shareText);
    Navigator.pop(context);
  }

  String _buildShareText() => '''
🎉 ${event.name}

📅 ${DateFormat('EEEE, MMMM d, yyyy at h:mm a').format(event.startDate)}
📍 ${event.location.displayAddress.isNotEmpty ? event.location.displayAddress : 'Location TBA'}
${event.isFree ? '🆓 FREE EVENT' : '🎫 Paid Event'}

${event.ticketUrl ?? 'Check out the Afropeep app for more details!'}

#Afropeep #AfrocentricEvents
''';

  String _buildDetailedShareText() => '''
🎉 Don't miss this amazing event!

${event.name}

📅 Date & Time: ${DateFormat('EEEE, MMMM d, yyyy at h:mm a').format(event.startDate)}
📍 Location: ${event.location.displayAddress.isNotEmpty ? event.location.displayAddress : 'Location TBA'}
🎭 Category: ${event.category}
${event.isFree ? '🆓 FREE EVENT' : '💰 Paid Event'}

${event.description.isNotEmpty ? '📝 About:\n${event.description.length > 200 ? '${event.description.substring(0, 200)}...' : event.description}\n\n' : ''}

${event.rsvpCount > 0 ? '👥 ${event.rsvpCount} people are already going!\n\n' : ''}

Get tickets: ${event.ticketUrl ?? 'Check the Afropeep app'}

#Afropeep #AfrocentricEvents #${event.category.replaceAll(' ', '')}
''';

  String _buildSocialShareText() => '''
🎉 Excited about this event: ${event.name}

📅 ${DateFormat('MMM d, h:mm a').format(event.startDate)}
📍 ${event.location.city ?? 'TBA'}
${event.isFree ? '🆓 FREE' : '🎫 Paid'}

#Afropeep #AfrocentricEvents #${event.category.replaceAll(' ', '')}

${event.ticketUrl ?? ''}
''';

  String _buildTwitterShareText() {
    final baseText = '''
🎉 ${event.name}

📅 ${DateFormat('MMM d, h:mm a').format(event.startDate)}
📍 ${event.location.city ?? 'TBA'}
${event.isFree ? '🆓 FREE' : '🎫 Paid'}

#Afropeep #AfrocentricEvents #${event.category.replaceAll(' ', '')}
''';

    // Twitter has character limit, so truncate if necessary
    if (baseText.length > 240) {
      return '''
🎉 ${event.name.length > 50 ? '${event.name.substring(0, 50)}...' : event.name}

📅 ${DateFormat('MMM d').format(event.startDate)}
${event.isFree ? '🆓 FREE' : '🎫 Paid'}

#Afropeep #AfrocentricEvents
''';
    }

    return baseText;
  }

  String _buildInstagramShareText() => '''
🎉 ${event.name}

📅 ${DateFormat('EEEE, MMMM d').format(event.startDate)}
📍 ${event.location.displayAddress}
${event.isFree ? '🆓 FREE EVENT' : '🎫 Paid Event'}

#Afropeep #AfrocentricEvents #${event.category.replaceAll(' ', '')} #Event #Culture #Community
''';

  String _buildWhatsAppShareText() => '''
🎉 *${event.name}*

📅 *Date:* ${DateFormat('EEEE, MMMM d, yyyy').format(event.startDate)}
⏰ *Time:* ${DateFormat('h:mm a').format(event.startDate)}
📍 *Location:* ${event.location.displayAddress.isNotEmpty ? event.location.displayAddress : 'Location TBA'}
${event.isFree ? '🆓 *FREE EVENT*' : '💰 *Paid Event*'}

${event.description.isNotEmpty ? '\n📝 *About:*\n${event.description.length > 150 ? '${event.description.substring(0, 150)}...' : event.description}\n' : ''}

${event.rsvpCount > 0 ? '👥 *${event.rsvpCount} people are going!*\n' : ''}

Get more details: ${event.ticketUrl ?? 'Afropeep app'}

#Afropeep #AfrocentricEvents
''';

  void _showInstagramInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Share to Instagram',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF333333),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event details have been copied to your clipboard!',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: const Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'To share on Instagram:',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '1. Open Instagram\n2. Create a new post or story\n3. Paste the copied text\n4. Add the event image if available',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: const Color(0xFF666666),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it!',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF008037),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
