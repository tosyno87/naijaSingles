import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/user_privacy_service.dart';
import '../../common/constants/app_colors.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({Key? key}) : super(key: key);

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final UserPrivacyService _privacyService = UserPrivacyService();
  UserPrivacySettings _settings = const UserPrivacySettings();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    try {
      final settings = await _privacyService.getPrivacySettings();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load privacy settings');
    }
  }

  Future<void> _savePrivacySettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final success = await _privacyService.updatePrivacySettings(_settings);
      if (success) {
        _showSuccessSnackBar('Privacy settings updated successfully');
      } else {
        _showErrorSnackBar('Failed to update privacy settings');
      }
    } catch (e) {
      _showErrorSnackBar('Error updating privacy settings');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: GoogleFonts.montserrat(color: Colors.white)),
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
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
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _savePrivacySettings,
              child: Text(
                'Save',
                style: GoogleFonts.montserrat(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Communication Section
          _buildSectionHeader(
            '🔐 COMMUNICATION',
            'Control who can message you and message settings',
          ),
          const SizedBox(height: 16),
          _buildCommunicationSection(),

          const SizedBox(height: 32),

          // Activity Status Section
          _buildSectionHeader(
            '👀 ACTIVITY STATUS',
            'Manage your online presence visibility',
          ),
          const SizedBox(height: 16),
          _buildActivitySection(),

          const SizedBox(height: 32),

          // Profile Visibility Section
          _buildSectionHeader(
            '🧬 PROFILE VISIBILITY',
            'Choose what information others can see',
          ),
          const SizedBox(height: 16),
          _buildProfileVisibilitySection(),

          const SizedBox(height: 32),

          // Location Privacy Section
          _buildSectionHeader(
            '📍 LOCATION PRIVACY',
            'Control how your location is shared',
          ),
          const SizedBox(height: 16),
          _buildLocationPrivacySection(),

          const SizedBox(height: 32),
          _buildPrivacySummary(),

          const SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileVisibilitySection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildToggleItem(
            'Show Tribe',
            'Display your tribe or ethnicity',
            _settings.showTribe,
            (value) => setState(() {
              _settings = _settings.copyWith(showTribe: value);
            }),
          ),
          _buildDivider(),
          _buildToggleItem(
            'Show Orientation',
            'Display your sexual orientation',
            _settings.showOrientation,
            (value) => setState(() {
              _settings = _settings.copyWith(showOrientation: value);
            }),
          ),
          _buildDivider(),
          _buildToggleItem(
            'Show Age',
            'Let users hide their age from profile',
            _settings.showAge,
            (value) => setState(() {
              _settings = _settings.copyWith(showAge: value);
            }),
          ),
          _buildDivider(),
          _buildToggleItem(
            'Hide My Profile From Discovery',
            'Temporarily remove your profile from swipe deck',
            _settings.hideFromDiscovery,
            (value) => setState(() {
              _settings = _settings.copyWith(hideFromDiscovery: value);
            }),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPrivacySection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildToggleItem(
            'Show Location',
            'Show city and state only',
            _settings.showLocation,
            (value) => setState(() {
              _settings = _settings.copyWith(showLocation: value);
            }),
          ),
          if (_settings.showLocation) ...[
            _buildDivider(),
            _buildToggleItem(
              'Show Distance',
              'Show approximate distance (~5 miles/km)',
              _settings.showDistance,
              (value) => setState(() {
                _settings = _settings.copyWith(showDistance: value);
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommunicationSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildToggleItem(
            'Allow Messages from Matches',
            'Only matched users can message you',
            _settings.allowMessagesFromMatches,
            (value) => setState(() {
              _settings = _settings.copyWith(allowMessagesFromMatches: value);
            }),
          ),
          _buildDivider(),
        ],
      ),
    );
  }

  Widget _buildActivitySection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildToggleItem(
            'Show Online Status',
            'Show when you\'re currently online',
            _settings.showOnlineStatus,
            (value) => setState(() {
              _settings = _settings.copyWith(showOnlineStatus: value);
            }),
          ),
          _buildDivider(),
          _buildToggleItem(
            'Show Last Active',
            'Show when you were last online',
            _settings.showLastActive,
            (value) => setState(() {
              _settings = _settings.copyWith(showLastActive: value);
            }),
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDestructive && value
                        ? Colors.red.shade700
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: isDestructive && value
                        ? Colors.red.shade500
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor:
                isDestructive ? Colors.red.shade600 : AppColors.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.grey[200],
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildPrivacySummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.privacy_tip, color: AppColors.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Privacy Summary',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _privacyService.getPrivacySummary(_settings),
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your privacy settings help control what information others can see about you. You can change these settings anytime.',
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
