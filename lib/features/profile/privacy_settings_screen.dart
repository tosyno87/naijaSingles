import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../common/constants/app_colors.dart';
import '../../common/constants/app_spacing.dart';
import '../../common/widgets/state_views/state_views.dart';
import '../../services/user_privacy_service.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final UserPrivacyService _privacyService = UserPrivacyService();
  UserPrivacySettings _settings = const UserPrivacySettings();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPrivacySettings());
  }

  Future<void> _loadPrivacySettings() async {
    try {
      final settings = await _privacyService.getPrivacySettings();
      if (!mounted) {
        return;
      }
      setState(() {
        _settings = settings;
        _isLoading = false;
        _loadError = null;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadError = 'Failed to load privacy settings';
      });
    }
  }

  Future<void> _savePrivacySettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final success = await _privacyService.updatePrivacySettings(_settings);
      if (!mounted) {
        return;
      }
      if (success) {
        _showSuccessSnackBar('Privacy settings updated successfully');
      } else {
        _showErrorSnackBar('Failed to update privacy settings');
      }
    } on Object {
      if (!mounted) {
        return;
      }
      _showErrorSnackBar('Error updating privacy settings');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: GoogleFonts.montserrat(color: Colors.white)),
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: GoogleFonts.montserrat(color: Colors.white)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon:
                const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Privacy Settings',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: _isSaving
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
                      child: SizedBox(
                        width: AppSpacing.md + AppSpacing.xs,
                        height: AppSpacing.md + AppSpacing.xs,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    )
                  : FilledButton(
                      onPressed: _savePrivacySettings,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md + AppSpacing.xs,
                          vertical: AppSpacing.sm,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.chipRadius),
                        ),
                        textStyle: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      child: const Text('Save'),
                    ),
            ),
          ],
        ),
        body: _isLoading
            ? const AppLoadingView(message: 'Loading privacy settings...')
            : _loadError != null
                ? AppErrorView(
                    title: 'Couldn\'t load privacy settings',
                    message: _loadError!,
                    onRetry: _loadPrivacySettings,
                  )
                : _buildContent(),
      );

  Widget _buildContent() => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md + AppSpacing.xs,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              Icons.lock_outline_rounded,
              'Communication',
              'Control who can message you',
            ),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            _buildCommunicationSection(),
            const SizedBox(height: AppSpacing.lg + AppSpacing.xs),
            _buildSectionHeader(
              Icons.visibility_outlined,
              'Activity Status',
              'Manage your online presence visibility',
            ),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            _buildActivitySection(),
            const SizedBox(height: AppSpacing.lg + AppSpacing.xs),
            _buildSectionHeader(
              Icons.person_outline_rounded,
              'Profile Visibility',
              'Choose what information others can see',
            ),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            _buildProfileVisibilitySection(),
            const SizedBox(height: AppSpacing.lg + AppSpacing.xs),
            _buildSectionHeader(
              Icons.location_on_outlined,
              'Location Privacy',
              'Control how your location is shared',
            ),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            _buildLocationPrivacySection(),
            const SizedBox(height: AppSpacing.lg + AppSpacing.xs),
            _buildPrivacySummary(),
            const SizedBox(height: AppSpacing.xxl * 2),
          ],
        ),
      );

  Widget _buildSectionHeader(
    IconData icon,
    String title,
    String subtitle,
  ) =>
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
            child: Icon(
              icon,
              size: AppSpacing.iconSm,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs / 2),
                Text(
                  subtitle,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildProfileVisibilitySection() => _sectionCard(
        children: [
          _buildToggleItem(
            'Show Tribe',
            'Display your tribe or ethnicity',
            _settings.showTribe,
            (value) => setState(() {
              _settings = _settings.copyWith(showTribe: value);
            }),
          ),
          _buildToggleItem(
            'Show Orientation',
            'Display your sexual orientation',
            _settings.showOrientation,
            (value) => setState(() {
              _settings = _settings.copyWith(showOrientation: value);
            }),
          ),
          _buildToggleItem(
            'Show Age',
            'Display your age on your profile',
            _settings.showAge,
            (value) => setState(() {
              _settings = _settings.copyWith(showAge: value);
            }),
          ),
          _buildToggleItem(
            'Hide From Discovery',
            'Temporarily remove your profile from the swipe deck',
            _settings.hideFromDiscovery,
            (value) => setState(() {
              _settings = _settings.copyWith(hideFromDiscovery: value);
            }),
            isDestructive: true,
          ),
        ],
      );

  Widget _buildLocationPrivacySection() => _sectionCard(
        children: [
          _buildToggleItem(
            'Show Location',
            'Show city and state only',
            _settings.showLocation,
            (value) => setState(() {
              _settings = _settings.copyWith(showLocation: value);
            }),
          ),
          if (_settings.showLocation)
            _buildToggleItem(
              'Show Distance',
              'Show approximate distance (~5 mi / km)',
              _settings.showDistance,
              (value) => setState(() {
                _settings = _settings.copyWith(showDistance: value);
              }),
            ),
        ],
      );

  Widget _buildCommunicationSection() => _sectionCard(
        children: [
          _buildToggleItem(
            'Allow Messages from Matches',
            'Only matched users can message you',
            _settings.allowMessagesFromMatches,
            (value) => setState(() {
              _settings = _settings.copyWith(allowMessagesFromMatches: value);
            }),
          ),
        ],
      );

  Widget _buildActivitySection() => _sectionCard(
        children: [
          _buildToggleItem(
            'Show Online Status',
            'Show when you\'re currently online',
            _settings.showOnlineStatus,
            (value) => setState(() {
              _settings = _settings.copyWith(showOnlineStatus: value);
            }),
          ),
          _buildToggleItem(
            'Show Last Active',
            'Show when you were last online',
            _settings.showLastActive,
            (value) => setState(() {
              _settings = _settings.copyWith(showLastActive: value);
            }),
          ),
        ],
      );

  // ──────────────────────────────────────────────────────────────────────
  //  Shared helpers
  // ──────────────────────────────────────────────────────────────────────

  Widget _sectionCard({required List<Widget> children}) {
    final separated = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      separated.add(children[i]);
      if (i < children.length - 1) {
        separated.add(
          const Divider(
            height: 1,
            thickness: 0.5,
            color: AppColors.divider,
            indent: AppSpacing.md,
            endIndent: AppSpacing.md,
          ),
        );
      }
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Column(children: separated),
      ),
    );
  }

  Widget _buildToggleItem(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged, {
    bool isDestructive = false,
  }) {
    final Color activeColor =
        isDestructive ? Colors.red.shade600 : AppColors.primaryGreen;

    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm - AppSpacing.xs / 2,
      ),
      title: Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDestructive && value
              ? Colors.red.shade700
              : AppColors.textPrimary,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs / 2),
        child: Text(
          subtitle,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: isDestructive && value
                ? Colors.red.shade400
                : AppColors.textSecondary,
          ),
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: activeColor,
      activeTrackColor: activeColor.withValues(alpha: 0.35),
      inactiveThumbColor: Colors.grey.shade400,
      inactiveTrackColor: Colors.grey.shade200,
    );
  }

  Widget _buildPrivacySummary() {
    final summary = _privacyService.getPrivacySummary(_settings);

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen.withValues(alpha: 0.08),
            AppColors.primaryGreen.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.all(AppSpacing.sm - AppSpacing.xs / 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.primaryGreen,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs / 2),
              Text(
                'Privacy Summary',
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          Text(
            summary,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm - AppSpacing.xs / 2),
          Text(
            'You can update these settings at any time.',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
