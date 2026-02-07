import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../common/bloc/theme/theme_bloc.dart';
import '../../common/constants/colors.dart';
import '../../common/bloc/user/user_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/settings_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  NotificationSettings? _settings;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _currentUserId = context.read<UserBloc>().currentUser?.id;
    if (_currentUserId != null) {
      _loadNotificationSettings();
    }
  }

  Future<void> _loadNotificationSettings() async {
    if (_currentUserId == null) return;

    setState(() => _isLoading = true);

    try {
      final settings =
          await SettingsService.getNotificationSettings(_currentUserId!);
      if (mounted) {
        setState(() {
          _settings = settings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Error loading notification settings', isError: true);
      }
    }
  }

  Future<void> _saveSettings() async {
    if (_currentUserId == null || _settings == null) return;

    setState(() => _isSaving = true);

    try {
      final success = await SettingsService.updateNotificationSettings(
        _currentUserId!,
        _settings!,
      );

      if (mounted) {
        setState(() => _isSaving = false);

        if (success) {
          _showSnackBar('Notification settings saved', isError: false);
        } else {
          _showSnackBar('Failed to save settings', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnackBar('Error saving settings', isError: true);
      }
    }
  }

  void _updateSetting(NotificationSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
    _saveSettings();
  }

  Future<void> _showTimePickerDialog(bool isStartTime) async {
    if (_settings == null) return;

    final currentTime = isStartTime
        ? _parseTime(_settings!.quietHoursStart)
        : _parseTime(_settings!.quietHoursEnd);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: primaryColor,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      final timeString = _formatTime(picked);
      final newSettings = isStartTime
          ? _settings!.copyWith(quietHoursStart: timeString)
          : _settings!.copyWith(quietHoursEnd: timeString);

      _updateSetting(newSettings);
    }
  }

  TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  String _formatTimeDisplay(String timeString) {
    final time = _parseTime(timeString);
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour == 0 ? 12 : hour}:$minute $period';
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeBloc>().isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notification Settings',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _settings == null
              ? _buildErrorState(isDarkMode)
              : _buildSettingsContent(isDarkMode),
    );
  }

  Widget _buildErrorState(bool isDarkMode) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load settings',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNotificationSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.montserrat(),
              ),
            ),
          ],
        ),
      );

  Widget _buildSettingsContent(bool isDarkMode) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_active,
                    color: primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Control when and how you receive notifications from Afropeep.',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Push Notifications Section
            _buildSectionHeader('Push Notifications', isDarkMode),
            const SizedBox(height: 12),

            _buildSettingTile(
              title: 'New Matches',
              subtitle: 'Get notified when you have a new match',
              icon: Icons.favorite,
              value: _settings!.matchNotifications,
              onChanged: (value) => _updateSetting(
                  _settings!.copyWith(matchNotifications: value)),
              isDarkMode: isDarkMode,
            ),

            _buildSettingTile(
              title: 'New Messages',
              subtitle: 'Get notified when someone sends you a message',
              icon: Icons.message,
              value: _settings!.messageNotifications,
              onChanged: (value) => _updateSetting(
                _settings!.copyWith(messageNotifications: value),
              ),
              isDarkMode: isDarkMode,
            ),

            _buildSettingTile(
              title: 'Likes',
              subtitle: 'Get notified when someone likes your profile',
              icon: Icons.thumb_up,
              value: _settings!.likeNotifications,
              onChanged: (value) =>
                  _updateSetting(_settings!.copyWith(likeNotifications: value)),
              isDarkMode: isDarkMode,
            ),

            _buildSettingTile(
              title: 'Super Likes',
              subtitle: 'Get notified when someone super likes you',
              icon: Icons.star,
              value: _settings!.superLikeNotifications,
              onChanged: (value) => _updateSetting(
                _settings!.copyWith(superLikeNotifications: value),
              ),
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 24),

            // Sound & Vibration Section
            _buildSectionHeader('Sound & Vibration', isDarkMode),
            const SizedBox(height: 12),

            _buildSettingTile(
              title: 'Sound',
              subtitle: 'Play sound for notifications',
              icon: Icons.volume_up,
              value: _settings!.soundEnabled,
              onChanged: (value) =>
                  _updateSetting(_settings!.copyWith(soundEnabled: value)),
              isDarkMode: isDarkMode,
            ),

            _buildSettingTile(
              title: 'Vibration',
              subtitle: 'Vibrate for notifications',
              icon: Icons.vibration,
              value: _settings!.vibrationEnabled,
              onChanged: (value) =>
                  _updateSetting(_settings!.copyWith(vibrationEnabled: value)),
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 24),

            // Quiet Hours Section
            _buildSectionHeader('Quiet Hours', isDarkMode),
            const SizedBox(height: 12),

            _buildSettingTile(
              title: 'Enable Quiet Hours',
              subtitle: 'Pause notifications during specified hours',
              icon: Icons.bedtime,
              value: _settings!.quietHoursEnabled,
              onChanged: (value) =>
                  _updateSetting(_settings!.copyWith(quietHoursEnabled: value)),
              isDarkMode: isDarkMode,
            ),

            if (_settings!.quietHoursEnabled) ...[
              const SizedBox(height: 12),
              _buildTimeSetting(
                title: 'Start Time',
                time: _settings!.quietHoursStart,
                onTap: () => _showTimePickerDialog(true),
                isDarkMode: isDarkMode,
              ),
              _buildTimeSetting(
                title: 'End Time',
                time: _settings!.quietHoursEnd,
                onTap: () => _showTimePickerDialog(false),
                isDarkMode: isDarkMode,
              ),
            ],

            const SizedBox(height: 32),

            // Save indicator
            if (_isSaving)
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Saving...',
                      style: GoogleFonts.montserrat(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );

  Widget _buildSectionHeader(String title, bool isDarkMode) => Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      );

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDarkMode,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: SwitchListTile(
          title: Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          secondary: Icon(
            icon,
            color: primaryColor,
          ),
          value: value,
          onChanged: onChanged,
          activeThumbColor: primaryColor,
        ),
      );

  Widget _buildTimeSetting({
    required String title,
    required String time,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          title: Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTimeDisplay(time),
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[600],
              ),
            ],
          ),
          onTap: onTap,
        ),
      );
}
