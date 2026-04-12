import 'package:flutter/material.dart';

import '../../../common/constants/app_colors.dart';
import '../../../services/settings_service.dart';
import 'settings_list/settings_list.dart';

/// Flat list of notification toggles (Hinge-style). Used by [NotificationSettingsScreen]
/// and widget tests.
class NotificationSettingsPanel extends StatelessWidget {
  const NotificationSettingsPanel({
    required this.draft,
    required this.onDraftChanged,
    required this.isSaving,
    required this.bottomInset,
    required this.onQuietHoursStart,
    required this.onQuietHoursEnd,
    super.key,
  });

  final NotificationSettings draft;
  final ValueChanged<NotificationSettings> onDraftChanged;
  final bool isSaving;
  final double bottomInset;
  final VoidCallback onQuietHoursStart;
  final VoidCallback onQuietHoursEnd;

  @override
  Widget build(BuildContext context) {
    final d = draft;
    final channelsLocked = !d.enableAllNotifications;

    return settingsSwitchTheme(
      context: context,
      child: ListView(
        children: [
          const SettingsSectionHeader('All notifications'),
          SettingsToggleRow(
            title: 'Enable All Notifications',
            subtitle: !d.enableAllNotifications
                ? 'You may miss a connection.'
                : null,
            value: d.enableAllNotifications,
            onChanged: isSaving
                ? null
                : (v) => onDraftChanged(d.copyWith(enableAllNotifications: v)),
          ),
          const Divider(height: 1),
          SettingsToggleRow(
            title: 'Mute All Notifications',
            value: d.muteAllNotifications,
            onChanged: isSaving
                ? null
                : (v) => onDraftChanged(d.copyWith(muteAllNotifications: v)),
          ),
          if (d.muteAllNotifications && d.enableAllNotifications)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Push alerts are muted. You can still see activity in the app.',
                style: SettingsTextStyles.consequence(context),
              ),
            ),
          const SizedBox(height: 16),
          const SettingsSectionHeader('Notifications'),
          Opacity(
            opacity: channelsLocked ? 0.45 : 1,
            child: Column(
              children: [
                SettingsToggleRow(
                  title: 'New Matches',
                  value: d.matchNotifications,
                  onChanged: channelsLocked || isSaving
                      ? null
                      : (v) =>
                          onDraftChanged(d.copyWith(matchNotifications: v)),
                ),
                const Divider(height: 1),
                SettingsToggleRow(
                  title: 'New Messages',
                  value: d.messageNotifications,
                  onChanged: channelsLocked || isSaving
                      ? null
                      : (v) =>
                          onDraftChanged(d.copyWith(messageNotifications: v)),
                ),
                const Divider(height: 1),
                SettingsToggleRow(
                  title: 'New Likes',
                  subtitle: 'Includes super likes',
                  value: d.likeNotifications,
                  onChanged: channelsLocked || isSaving
                      ? null
                      : (v) =>
                          onDraftChanged(d.copyWith(likeNotifications: v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SettingsSectionHeader('Sound'),
          SettingsToggleRow(
            title: 'Sound',
            value: d.soundEnabled,
            onChanged: isSaving
                ? null
                : (v) => onDraftChanged(d.copyWith(soundEnabled: v)),
          ),
          const Divider(height: 1),
          SettingsToggleRow(
            title: 'Vibration',
            value: d.vibrationEnabled,
            onChanged: isSaving
                ? null
                : (v) => onDraftChanged(d.copyWith(vibrationEnabled: v)),
          ),
          const SizedBox(height: 16),
          const SettingsSectionHeader('Quiet hours'),
          SettingsToggleRow(
            title: 'Enable Quiet Hours',
            value: d.quietHoursEnabled,
            onChanged: isSaving
                ? null
                : (v) => onDraftChanged(d.copyWith(quietHoursEnabled: v)),
          ),
          if (d.quietHoursEnabled) ...[
            const Divider(height: 1),
            _TimePickerRow(
              title: 'Start Time',
              time: d.quietHoursStart,
              onTap: isSaving ? null : onQuietHoursStart,
            ),
            const Divider(height: 1),
            _TimePickerRow(
              title: 'End Time',
              time: d.quietHoursEnd,
              onTap: isSaving ? null : onQuietHoursEnd,
            ),
          ],
          SizedBox(height: bottomInset + 24),
        ],
      ),
    );
  }
}

class _TimePickerRow extends StatelessWidget {
  const _TimePickerRow({
    required this.title,
    required this.time,
    required this.onTap,
  });

  final String title;
  final String time;
  final VoidCallback? onTap;

  String _formatTimeDisplay(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final tod = TimeOfDay(hour: hour, minute: minute);
    final h = tod.hourOfPeriod;
    final m = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '${h == 0 ? 12 : h}:$m $period';
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 54,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: SettingsTextStyles.rowTitle(context),
                      ),
                    ),
                  ),
                  Text(
                    _formatTimeDisplay(time),
                    style: SettingsTextStyles.rowTitle(context).copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade500
                        : Colors.grey.shade600,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
