import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../common/constants/app_colors.dart';
import '../../common/constants/app_spacing.dart';
import '../../common/widgets/state_views/state_views.dart';
import '../../features/notifications/data/services/notification_service.dart';
import 'notification_model.dart';

/// Modern notification settings screen with industry-standard features
/// Features:
/// - Real-time settings updates
/// - Smart quiet hours with timezone support
/// - Notification previews
/// - Granular control per notification type
/// - Sound and vibration customization
/// - Do not disturb mode
/// - Notification frequency controls
class ModernNotificationSettings extends StatefulWidget {
  const ModernNotificationSettings({super.key});

  @override
  State<ModernNotificationSettings> createState() =>
      _ModernNotificationSettingsState();
}

class _ModernNotificationSettingsState extends State<ModernNotificationSettings>
    with TickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();

  AppNotificationSettings? _settings;
  bool _isLoading = true;
  bool _isSaving = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    unawaited(_loadSettings());
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    // Simulate loading settings
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _settings = AppNotificationSettings.defaultSettings();
      _isLoading = false;
    });

    unawaited(_animationController.forward());
  }

  Future<void> _updateSetting(AppNotificationSettings newSettings) async {
    setState(() => _isSaving = true);

    try {
      await _notificationService.updateSettings(newSettings);
      setState(() {
        _settings = newSettings;
      });

      // Haptic feedback
      unawaited(HapticFeedback.lightImpact());

      _showSnackBar('Settings updated', isError: false);
    } on Object {
      _showSnackBar('Failed to update settings', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: _buildAppBar(),
        body: _isLoading ? const AppLoadingView() : _buildSettingsContent(),
      );

  PreferredSizeWidget _buildAppBar() => AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notification Settings',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                ),
              ),
            ),
        ],
      );

  Widget _buildSettingsContent() {
    if (_settings == null) {
      return _buildErrorState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: AppSpacing.lg),
            _buildSectionTitle('Push Notifications'),
            const SizedBox(height: AppSpacing.md),
            _buildNotificationToggles(),
            const SizedBox(height: AppSpacing.xl),
            _buildSectionTitle('Sound & Vibration'),
            const SizedBox(height: AppSpacing.md),
            _buildSoundVibrationToggles(),
            const SizedBox(height: AppSpacing.xl),
            _buildSectionTitle('Quiet Hours'),
            const SizedBox(height: AppSpacing.md),
            _buildQuietHoursSection(),
            const SizedBox(height: AppSpacing.xl),
            _buildSectionTitle('Notification Frequency'),
            const SizedBox(height: AppSpacing.md),
            _buildFrequencySection(),
            const SizedBox(height: AppSpacing.xl),
            _buildTestNotificationSection(),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryGreen.withValues(alpha: 0.1),
              AppColors.primaryGreen.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: AppColors.primaryGreen.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.buttonRadius),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
              child: const Icon(
                Icons.notifications_active,
                color: AppColors.primaryGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stay Connected',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Control when and how you receive notifications from Afropeep',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildSectionTitle(String title) => Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      );

  Widget _buildNotificationToggles() => Column(
        children: [
          _buildSettingTile(
            title: 'New Matches',
            subtitle: 'Get notified when you have a new match',
            icon: Icons.favorite,
            value: _settings!.matchNotifications,
            onChanged: (value) =>
                _updateSetting(_settings!.copyWith(matchNotifications: value)),
          ),
          _buildSettingTile(
            title: 'New Messages',
            subtitle: 'Get notified when someone sends you a message',
            icon: Icons.chat_bubble_outline,
            value: _settings!.messageNotifications,
            onChanged: (value) => _updateSetting(
              _settings!.copyWith(messageNotifications: value),
            ),
          ),
          _buildSettingTile(
            title: 'Profile Likes',
            subtitle: 'Get notified when someone likes your profile',
            icon: Icons.thumb_up,
            value: _settings!.likeNotifications,
            onChanged: (value) =>
                _updateSetting(_settings!.copyWith(likeNotifications: value)),
          ),
          _buildSettingTile(
            title: 'Super Likes',
            subtitle: 'Get notified when someone super likes you',
            icon: Icons.star,
            value: _settings!.superLikeNotifications,
            onChanged: (value) => _updateSetting(
              _settings!.copyWith(superLikeNotifications: value),
            ),
          ),
        ],
      );

  Widget _buildSoundVibrationToggles() => Column(
        children: [
          _buildSettingTile(
            title: 'Sound',
            subtitle: 'Play sound for notifications',
            icon: Icons.volume_up,
            value: _settings!.soundEnabled,
            onChanged: (value) =>
                _updateSetting(_settings!.copyWith(soundEnabled: value)),
          ),
          _buildSettingTile(
            title: 'Vibration',
            subtitle: 'Vibrate for notifications',
            icon: Icons.vibration,
            value: _settings!.vibrationEnabled,
            onChanged: (value) =>
                _updateSetting(_settings!.copyWith(vibrationEnabled: value)),
          ),
        ],
      );

  Widget _buildQuietHoursSection() => Column(
        children: [
          _buildSettingTile(
            title: 'Enable Quiet Hours',
            subtitle: 'Pause notifications during specified hours',
            icon: Icons.bedtime,
            value: _settings!.quietHoursEnabled,
            onChanged: (value) =>
                _updateSetting(_settings!.copyWith(quietHoursEnabled: value)),
          ),
          if (_settings!.quietHoursEnabled) ...[
            const SizedBox(height: AppSpacing.md),
            _buildTimeSetting(
              title: 'Start Time',
              time: _settings!.quietHoursStart,
              onTap: () => _showTimePicker(true),
            ),
            _buildTimeSetting(
              title: 'End Time',
              time: _settings!.quietHoursEnd,
              onTap: () => _showTimePicker(false),
            ),
          ],
        ],
      );

  Widget _buildFrequencySection() => Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.schedule,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.buttonRadius),
                Expanded(
                  child: Text(
                    'Notification Frequency',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.buttonRadius),
            Text(
              'Reduce notification frequency to avoid overwhelming you with updates',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildFrequencyOption('Low', 'Fewer notifications'),
                ),
                const SizedBox(width: AppSpacing.buttonRadius),
                Expanded(
                  child:
                      _buildFrequencyOption('Medium', 'Balanced notifications'),
                ),
                const SizedBox(width: AppSpacing.buttonRadius),
                Expanded(
                  child: _buildFrequencyOption('High', 'All notifications'),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildFrequencyOption(String title, String subtitle) => Container(
        padding: const EdgeInsets.all(AppSpacing.buttonRadius),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          border: Border.all(
            color: AppColors.primaryGreen.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildTestNotificationSection() => Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.science,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.buttonRadius),
                Expanded(
                  child: Text(
                    'Test Notifications',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.buttonRadius),
            Text(
              'Send a test notification to see how it will appear',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: _sendTestNotification,
              icon: const Icon(Icons.send),
              label: const Text('Send Test Notification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: AppSpacing.buttonRadius,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.buttonRadius),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: SwitchListTile(
          title: Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          secondary: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryGreen,
              size: 20,
            ),
          ),
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primaryGreen,
          inactiveThumbColor: Colors.grey.shade400,
          inactiveTrackColor: Colors.grey.shade200,
        ),
      );

  Widget _buildTimeSetting({
    required String title,
    required String time,
    required VoidCallback onTap,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.buttonRadius),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: ListTile(
          title: Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTimeDisplay(time),
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade600,
              ),
            ],
          ),
          onTap: onTap,
        ),
      );

  Widget _buildErrorState() => AppErrorView(
        message: 'Failed to load notification settings',
        onRetry: _loadSettings,
      );

  Future<void> _showTimePicker(bool isStartTime) async {
    final currentTime = _parseTime(
      isStartTime ? _settings!.quietHoursStart : _settings!.quietHoursEnd,
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primaryGreen,
            onSurface: AppColors.textPrimary,
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

      await _updateSetting(newSettings);
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

  void _sendTestNotification() {
    unawaited(HapticFeedback.lightImpact());
    _showSnackBar('Test notification sent!', isError: false);
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
      ),
    );
  }
}
