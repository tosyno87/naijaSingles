import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../common/bloc/theme/theme_bloc.dart';
import '../../common/bloc/user/user_bloc.dart';
import '../../common/constants/app_colors.dart';
import '../../common/constants/app_spacing.dart';
import '../../common/widgets/state_views/state_views.dart';
import '../../services/settings_service.dart';
import 'widgets/notification_settings_panel.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  NotificationSettings? _draft;
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
      unawaited(_loadNotificationSettings());
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
          _draft = settings;
          _isLoading = false;
        });
      }
    } on Object {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Error loading notification settings', isError: true);
      }
    }
  }

  Future<void> _onDone() async {
    if (_currentUserId == null || _draft == null) return;

    setState(() => _isSaving = true);

    try {
      final success = await SettingsService.updateNotificationSettings(
        _currentUserId!,
        _draft!,
      );

      if (!mounted) return;

      setState(() => _isSaving = false);

      if (success) {
        Navigator.of(context).pop();
      } else {
        _showSnackBar('Failed to save settings', isError: true);
      }
    } on Object {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnackBar('Error saving settings', isError: true);
      }
    }
  }

  void _updateDraft(NotificationSettings next) {
    setState(() {
      _draft = next;
    });
  }

  Future<void> _showTimePickerDialog(bool isStartTime) async {
    if (_draft == null) return;

    final currentTime = isStartTime
        ? _parseTime(_draft!.quietHoursStart)
        : _parseTime(_draft!.quietHoursEnd);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primaryGreen,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      final timeString = _formatTime(picked);
      final newSettings = isStartTime
          ? _draft!.copyWith(quietHoursStart: timeString)
          : _draft!.copyWith(quietHoursEnd: timeString);

      _updateDraft(newSettings);
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

  void _showSnackBar(String message, {required bool isError}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red : theme.colorScheme.surfaceContainerHighest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeBloc>().isDarkMode;
    final bg = isDarkMode ? Colors.black : Colors.white;
    final onSurface = isDarkMode ? Colors.white : Colors.black;

    return PopScope(
      canPop: !_isSaving,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: TextButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                color: onSurface.withValues(alpha: _isSaving ? 0.4 : 1),
              ),
            ),
          ),
          leadingWidth: 88,
          title: Text(
            'Push Notifications',
            style: GoogleFonts.montserrat(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
          centerTitle: true,
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              TextButton(
                onPressed: _onDone,
                child: Text(
                  'Done',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
          ],
        ),
        body: _isLoading
            ? const AppLoadingView(message: 'Loading settings...')
            : _draft == null
                ? _buildErrorState()
                : _buildBody(),
      ),
    );
  }

  Widget _buildErrorState() => AppErrorView(
        title: 'Failed to load settings',
        message: 'Please try again.',
        onRetry: _loadNotificationSettings,
      );

  Widget _buildBody() => NotificationSettingsPanel(
        draft: _draft!,
        onDraftChanged: _updateDraft,
        isSaving: _isSaving,
        bottomInset: MediaQuery.paddingOf(context).bottom,
        onQuietHoursStart: () => _showTimePickerDialog(true),
        onQuietHoursEnd: () => _showTimePickerDialog(false),
      );
}
