import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../common/constants/app_colors.dart';
import '../services/group_notification_service.dart';

/// Widget for toggling group notification settings
class GroupNotificationToggle extends StatefulWidget {
  const GroupNotificationToggle({
    required this.groupId,
    required this.groupName,
    super.key,
  });
  final String groupId;
  final String groupName;

  @override
  State<GroupNotificationToggle> createState() =>
      _GroupNotificationToggleState();
}

class _GroupNotificationToggleState extends State<GroupNotificationToggle> {
  final GroupNotificationService _notificationService =
      GroupNotificationService();
  bool _isMuted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMuteStatus();
  }

  Future<void> _loadMuteStatus() async {
    try {
      final isMuted = await _notificationService.isGroupMuted(widget.groupId);
      if (mounted) {
        setState(() {
          _isMuted = isMuted;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading notification settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleMute() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _notificationService.toggleGroupMute(widget.groupId, !_isMuted);
      if (mounted) {
        setState(() {
          _isMuted = !_isMuted;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isMuted
                  ? 'Notifications muted for ${widget.groupName}'
                  : 'Notifications enabled for ${widget.groupName}',
            ),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update notification settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isMuted ? Icons.notifications_off : Icons.notifications,
                    color: AppColors.primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notification Settings',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.groupName,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Toggle Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isMuted
                              ? 'Notifications Muted'
                              : 'Notifications Enabled',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isMuted
                              ? 'You won\'t receive push notifications for this group'
                              : 'You\'ll receive push notifications for new messages',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (_isLoading)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Switch(
                      value: !_isMuted, // Switch shows "enabled" state
                      onChanged: (_) => _toggleMute(),
                      activeThumbColor: AppColors.primaryGreen,
                      activeTrackColor: AppColors.primaryGreen.withOpacity(0.3),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}
