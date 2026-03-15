import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../common/bloc/user/user_bloc.dart';
import '../../common/constants/app_colors.dart';
import '../../common/constants/app_spacing.dart';
import '../../common/routes/route_name.dart';
import '../account_status/presentation/bloc/account_status_bloc.dart';
import '../account_status/presentation/screens/account_status_screen.dart';
import '../settings/account_deletion_screen.dart';
import '../settings/help_center_screen.dart';
import '../settings/language_settings_screen.dart';
import '../settings/location_settings_screen.dart';
import '../settings/password_settings_screen.dart';
import '../settings/safety_center_screen.dart';
import 'privacy_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const Color primaryColor = AppColors.primaryGreen;
  static const Color cardColor = AppColors.cardColor;
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;

  bool get _isPasswordProviderUser =>
      _auth.currentUser?.providerData.any((p) => p.providerId == 'password') ??
      false;
  bool get _hasAccountEmail =>
      _auth.currentUser?.email?.trim().isNotEmpty ?? false;
  bool get _canManagePassword => _isPasswordProviderUser || _hasAccountEmail;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Settings',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Section
              _buildSectionHeader('Account'),
              const SizedBox(height: AppSpacing.md),

              _buildSettingsCard([
                _buildSettingsItem(
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  subtitle: 'Update your photos and info',
                  onTap: () {
                    unawaited(
                      Navigator.pushNamed(
                        context,
                        RouteName.editProfileScreen,
                      ),
                    );
                  },
                ),
                if (_canManagePassword) ...[
                  _buildDivider(),
                  _buildSettingsItem(
                    icon: Icons.lock_outline,
                    title: _isPasswordProviderUser
                        ? 'Change Password'
                        : 'Set Password',
                    subtitle: _isPasswordProviderUser
                        ? 'Update your password'
                        : 'Create a password for your account',
                    onTap: _isPasswordProviderUser
                        ? _showChangePasswordDialog
                        : _showSetPasswordDialog,
                  ),
                ],
              ]),

              const SizedBox(height: AppSpacing.xl),

              _buildSectionHeader('Privacy & Safety'),
              const SizedBox(height: AppSpacing.md),

              _buildSettingsCard([
                _buildSettingsItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Settings',
                  subtitle: 'Control who can see your profile',
                  onTap: () {
                    unawaited(
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacySettingsScreen(),
                        ),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildSettingsItem(
                  icon: Icons.block_outlined,
                  title: 'Blocked Users',
                  subtitle: 'Manage blocked accounts',
                  onTap: () =>
                      Navigator.pushNamed(context, RouteName.blockedUsers),
                ),
                _buildDivider(),
                _buildSettingsItem(
                  icon: Icons.report_outlined,
                  title: 'Safety Center',
                  subtitle: 'Report issues and get help',
                  onTap: () {
                    unawaited(
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SafetyCenterScreen(),
                        ),
                      ),
                    );
                  },
                ),
              ]),

              const SizedBox(height: AppSpacing.xl),

              _buildSectionHeader('App Settings'),
              const SizedBox(height: AppSpacing.md),

              _buildSettingsCard([
                _buildSettingsItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Manage your notification preferences',
                  onTap: () => Navigator.pushNamed(
                    context,
                    RouteName.notificationSettings,
                  ),
                ),
                _buildDivider(),
                _buildSettingsItem(
                  icon: Icons.location_on_outlined,
                  title: 'Location',
                  subtitle: 'Update your location settings',
                  onTap: () {
                    unawaited(
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LocationSettingsScreen(),
                        ),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildSettingsItem(
                  icon: Icons.language_outlined,
                  title: 'Language',
                  subtitle: 'English (US)',
                  onTap: () {
                    unawaited(
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LanguageSettingsScreen(),
                        ),
                      ),
                    );
                  },
                ),
              ]),

              const SizedBox(height: AppSpacing.xl),

              _buildSectionHeader('Support'),
              const SizedBox(height: AppSpacing.md),

              _buildSettingsCard([
                _buildSettingsItem(
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  subtitle: 'Get help and support',
                  onTap: () {
                    unawaited(
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HelpCenterScreen(),
                        ),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildSettingsItem(
                  icon: Icons.feedback_outlined,
                  title: 'Send Feedback',
                  subtitle: 'Share your thoughts with us',
                  onTap: _showFeedbackDialog,
                ),
                _buildDivider(),
                _buildSettingsItem(
                  icon: Icons.info_outline,
                  title: 'About',
                  subtitle: 'App version and info',
                  onTap: _showAboutDialog,
                ),
              ]),

              const SizedBox(height: 40),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _showSignOutDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.chipRadius),
                        side: BorderSide(color: Colors.red.shade300, width: 2),
                      ),
                      elevation: 2,
                      shadowColor: Colors.black.withValues(alpha: 0.1),
                    ),
                    child: Text(
                      'Sign Out',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      unawaited(
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider(
                              create: (_) => AccountStatusBloc(),
                              child: const AccountStatusScreen(),
                            ),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.pause_circle_outline, size: 22),
                    label: Text(
                      'Take a Break',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.chipRadius),
                        side: const BorderSide(
                          color: AppColors.primaryGreen,
                          width: 2,
                        ),
                      ),
                      elevation: 2,
                      shadowColor: Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _showDeleteAccountDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.chipRadius),
                        side: BorderSide(color: Colors.red.shade300, width: 2),
                      ),
                      elevation: 2,
                      shadowColor: Colors.black.withValues(alpha: 0.1),
                    ),
                    child: Text(
                      'Delete Account',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      );

  Widget _buildSectionHeader(String title) => Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      );

  Widget _buildSettingsCard(List<Widget> children) => DecoratedBox(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(children: children),
      );

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (iconColor ?? primaryColor).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? primaryColor,
                    size: 20,
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
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildDivider() => Divider(
        height: 1,
        color: Colors.grey.shade200,
        indent: 72,
      );

  void _showSignOutDialog() {
    unawaited(
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_outlined,
                  color: Colors.red.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Sign Out',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to sign out of your account?',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            // Cancel button
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: textSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.buttonRadius,
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: ElevatedButton(
                onPressed: _performSignOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ), // Proper padding
                  minimumSize:
                      const Size(100, 44), // Minimum size to prevent cramping
                ),
                child: Text(
                  'Sign Out',
                  style: GoogleFonts.montserrat(
                    fontSize: 14, // Slightly smaller to fit better
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    unawaited(
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          title: Text(
            'Delete Account',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning text with high contrast against cardColor
              Text(
                'This action cannot be undone. Deleting your account will:',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color:
                      textPrimary, // Use textPrimary for high contrast against cardColor
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.buttonRadius),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  '• Remove all your photos and profile information\n'
                  '• Delete all your matches and conversations\n'
                  '• Cancel any active subscriptions\n'
                  '• Make your profile invisible to other users',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color:
                        Colors.red.shade800, // High contrast red for warnings
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: textSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.buttonRadius,
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: ElevatedButton(
                onPressed: _showDeleteConfirmation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                  elevation: 2,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  minimumSize: const Size(80, 44),
                ),
                child: Text(
                  'Delete',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    Navigator.pop(context);

    unawaited(
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          title: Text(
            'Final Confirmation',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          content: Text(
            'Are you sure? This cannot be undone. All your data will be permanently deleted.',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: textSecondary,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: TextButton.styleFrom(
                  foregroundColor: textSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.buttonRadius,
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  unawaited(
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AccountDeletionScreen(),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  minimumSize: const Size(120, 44),
                ),
                child: Text(
                  'Delete my account',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performSignOut() async {
    Navigator.pop(context);

    final userBloc = context.read<UserBloc>();
    final navigator = Navigator.of(context);

    final loadingRoute = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => Center(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: primaryColor,
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                'Signing out...',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    unawaited(navigator.push(loadingRoute));

    try {
      try {
        userBloc.add(const UserDataUpdated(null));
        userBloc.add(const UserListenStopped());
      } on Object catch (e) {
        log('Error clearing user provider: $e');
      }

      await _auth.signOut();

      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) {
        return;
      }
      if (loadingRoute.isActive) {
        navigator.removeRoute(loadingRoute);
      }

      if (mounted) {
        await navigator.pushNamedAndRemoveUntil(
          RouteName.welcomeScreen,
          (route) => false,
        );
      }
    } on Object catch (e) {
      log('Error signing out: $e');
      if (!mounted) {
        return;
      }
      if (loadingRoute.isActive) {
        navigator.removeRoute(loadingRoute);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to sign out. Please try again.',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          margin: AppSpacing.pagePadding,
        ),
      );
    }
  }

  void _showChangePasswordDialog() {
    unawaited(
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const PasswordSettingsScreen(),
        ),
      ),
    );
  }

  Future<void> _showSetPasswordDialog() async {
    final email = _auth.currentUser?.email;
    if (email == null || email.trim().isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No email found for this account.'),
        ),
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password setup link sent to $email',
            style: GoogleFonts.montserrat(color: Colors.white),
          ),
          backgroundColor: primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? 'Unable to send password setup email.',
            style: GoogleFonts.montserrat(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on Object catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to send password setup email.',
            style: GoogleFonts.montserrat(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showFeedbackDialog() {
    unawaited(Navigator.pushNamed(context, RouteName.feedbackScreen));
  }

  void _showAboutDialog() {
    unawaited(
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          title: Text(
            'About Afropeep',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Version 1.0.0',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: AppSpacing.buttonRadius),
              Text(
                'Afropeep is a community platform built for Africans in the diaspora. '
                'Connect with your people through friendships, shared culture, events, '
                'and meaningful relationships.',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '© 2025 Afropeep. All rights reserved.',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
