import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../common/constants/app_colors.dart';
import '../../common/constants/app_spacing.dart';
import '../../common/widgets/state_views/state_views.dart';
import '../../services/user_privacy_service.dart';
import '../settings/widgets/settings_list/settings_list.dart';

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
          centerTitle: true,
          title: Text(
            'Privacy Settings',
            style: GoogleFonts.montserrat(
              fontSize: 17,
              fontWeight: FontWeight.w600,
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
              Icons.person_outline_rounded,
              'Profile Visibility',
              'Age, neighborhood, and approximate distance are always visible, like Hinge — your exact address is never shown',
            ),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            _buildProfileVisibilitySection(),
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

  Widget _buildProfileVisibilitySection() => settingsSwitchTheme(
        context: context,
        child: _sectionCard(
          children: [
            SettingsToggleRow(
              title: 'Show Tribe',
              subtitle: 'Display your tribe or ethnicity',
              value: _settings.showTribe,
              onChanged: (value) => setState(() {
                _settings = _settings.copyWith(showTribe: value);
              }),
            ),
            _buildLockedProfileField(
              'Age',
              'Always shown on your profile. This helps keep the experience fair and safe for everyone.',
            ),
            _buildLockedProfileField(
              'Neighborhood & distance',
              'Your area and approximate distance to others are always used for matching. Your exact address is never shared.',
            ),
            SettingsToggleRow(
              title: 'Hide From Discovery',
              subtitle: 'Temporarily remove your profile from the swipe deck',
              value: _settings.hideFromDiscovery,
              isDestructive: true,
              onChanged: (value) => setState(() {
                _settings = _settings.copyWith(hideFromDiscovery: value);
              }),
            ),
          ],
        ),
      );

  Widget _buildLockedProfileField(String title, String subtitle) => ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm - AppSpacing.xs / 2,
        ),
        leading: Icon(
          Icons.lock_outline_rounded,
          color: AppColors.textSecondary.withValues(alpha: 0.85),
          size: 22,
        ),
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs / 2),
          child: Text(
            subtitle,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
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
