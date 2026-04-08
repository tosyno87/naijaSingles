import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../common/constants/app_colors.dart';
import '../../common/constants/app_spacing.dart';
import '../../common/widgets/state_views/state_views.dart';
import '../../services/privacy_migration_service.dart';
import 'privacy_settings_screen.dart';

class PrivacyMigrationScreen extends StatefulWidget {
  const PrivacyMigrationScreen({super.key});

  @override
  State<PrivacyMigrationScreen> createState() => _PrivacyMigrationScreenState();
}

class _PrivacyMigrationScreenState extends State<PrivacyMigrationScreen> {
  final PrivacyMigrationService _migrationService = PrivacyMigrationService();

  bool _isLoading = false;
  bool _isMigrating = false;
  String? _loadError;
  Map<String, dynamic>? _migrationStatus;

  @override
  void initState() {
    super.initState();
    unawaited(_checkMigrationStatus());
  }

  Future<void> _checkMigrationStatus() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final status = await _migrationService.getMigrationStatus();
      if (!mounted) return;
      setState(() {
        _migrationStatus = status;
        _isLoading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Failed to check migration status';
      });
    }
  }

  Future<void> _startMigration() async {
    setState(() {
      _isMigrating = true;
    });

    try {
      final success = await _migrationService.migrateCurrentUserData();

      if (success) {
        _showSuccessSnackBar('Privacy migration completed successfully!');
        await _checkMigrationStatus(); // Refresh status

        // Navigate to privacy settings
        if (mounted) {
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const PrivacySettingsScreen(),
            ),
          );
        }
      } else {
        _showErrorSnackBar('Migration failed. Please try again.');
      }
    } on Object {
      if (mounted) {
        _showErrorSnackBar('Migration failed. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isMigrating = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
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
    if (!mounted) return;
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy Update',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: _isLoading
          ? const AppLoadingView(message: 'Loading migration status...')
          : _loadError != null
              ? AppErrorView(
                  title: 'Unable to load privacy update',
                  message: _loadError!,
                  onRetry: _checkMigrationStatus,
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final isMigrated = _migrationStatus?['migrated'] ?? false;

    if (isMigrated) {
      return _buildAlreadyMigratedContent();
    } else {
      return _buildMigrationNeededContent();
    }
  }

  Widget _buildMigrationNeededContent() => SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xs),
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
                  color: AppColors.primaryGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.security_update_good,
                    size: 48,
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Enhanced Privacy Protection',
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'We\'ve upgraded our privacy system to give you better control over your personal information.',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // What's New Section
            _buildSectionHeader('What\'s New'),
            const SizedBox(height: AppSpacing.md),
            _buildFeatureCard(
              Icons.visibility_outlined,
              'Profile Visibility Controls',
              'Choose what information others can see about you — age, tribe, and more.',
            ),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            _buildFeatureCard(
              Icons.location_on_outlined,
              'Location Privacy',
              'Control how precise your location appears to others with high, medium, or low precision settings.',
            ),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            _buildFeatureCard(
              Icons.message_outlined,
              'Communication Controls',
              'Decide who can message you - matches only, or include users who liked you.',
            ),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            _buildFeatureCard(
              Icons.shield_outlined,
              'Enhanced Security',
              'Your sensitive data is now stored separately and protected with advanced security rules.',
            ),

            const SizedBox(height: AppSpacing.lg),

            // What Happens Section
            _buildSectionHeader('What Happens During Migration'),
            const SizedBox(height: AppSpacing.md),
            _buildInfoCard(
              'Your profile data will be reorganized for better privacy protection. This process:',
              [
                'Separates public and private information',
                'Applies default privacy settings (you can change these later)',
                'Protects sensitive data like phone number and exact location',
                'Maintains all your existing profile information',
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Migration Button
            SizedBox(
              width: double.infinity,
              height: AppSpacing.xxl + AppSpacing.sm,
              child: ElevatedButton(
                onPressed: _isMigrating ? null : _startMigration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  elevation: 3,
                ),
                child: _isMigrating
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: AppSpacing.md + AppSpacing.xs,
                            height: AppSpacing.md + AppSpacing.xs,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                          Text(
                            'Migrating...',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Update My Privacy Settings',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Skip Button
            TextButton(
              onPressed: _isMigrating ? null : () => Navigator.pop(context),
              child: Text(
                'Skip for Now',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      );

  Widget _buildAlreadyMigratedContent() => Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 80,
              color: AppColors.primaryGreen,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Privacy Settings Updated',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Your profile has been updated with enhanced privacy protection. You can now control what information others can see about you.',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: AppSpacing.xxl + AppSpacing.sm,
              child: ElevatedButton(
                onPressed: () {
                  unawaited(
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacySettingsScreen(),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  elevation: 3,
                ),
                child: Text(
                  'Manage Privacy Settings',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildSectionHeader(String title) => Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      );

  Widget _buildFeatureCard(IconData icon, String title, String description) =>
      Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: AppSpacing.sm + AppSpacing.xs / 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: Icon(
                icon,
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
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildInfoCard(String title, List<String> points) => Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: AppSpacing.sm + AppSpacing.xs / 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            ...points.map(
              (point) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(
                        top: AppSpacing.sm - AppSpacing.xs / 2,
                      ),
                      width: AppSpacing.sm - AppSpacing.xs / 2,
                      height: AppSpacing.sm - AppSpacing.xs / 2,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                    Expanded(
                      child: Text(
                        point,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
