import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../common/constants/app_colors.dart';
import '../../common/constants/app_spacing.dart';
import '../../common/constants/theme.dart';
import '../../common/routes/route_name.dart';
import '../../common/utils/account_deletion_scope.dart';
import '../../common/utils/app_logger.dart';
import '../../config/app_config.dart';
import '../../services/account_deletion_analytics.dart';
import '../../services/crashlytics_service.dart';
import 'data/account_deletion_client_meta.dart';
import 'data/account_deletion_functions_error.dart';
import 'data/account_deletion_functions_service.dart';

/// Backend [deleteAccountDirect]: signed-in user + checkbox + fresh ID token only.
class AccountDeletionScreen extends StatefulWidget {
  const AccountDeletionScreen({super.key});

  @override
  State<AccountDeletionScreen> createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends State<AccountDeletionScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _reasonController = TextEditingController();

  static const Color primaryColor = AppColors.primaryGreen;
  static const Color cardColor = AppColors.cardColor;
  static const Color errorColor = Color(0xFFFF5A5F);
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
  static final Color textLight = Colors.grey.shade600;

  final AccountDeletionFunctionsService _deletionFunctions =
      AccountDeletionFunctionsService();

  String _selectedReason = '';
  bool _confirmedPermanentDelete = false;

  bool _isDeleting = false;
  String? _lastCallableErrorCode;

  final List<String> _deletionReasons = [
    'Found someone special',
    'Taking a break from dating',
    'Not getting quality matches',
    'Privacy concerns',
    'App is too complicated',
    'Technical issues',
    'Other',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(AccountDeletionAnalytics.logPhaseEntered('confirmDeletion'));
    });
  }

  String _providerSummary(User? user) {
    if (user == null) {
      return 'unknown';
    }
    final ids = user.providerData.map((p) => p.providerId).toList();
    return ids.isEmpty ? 'none' : ids.join(', ');
  }

  String _footerLabel() {
    if (_isDeleting) {
      return 'Deleting...';
    }
    return 'Delete account permanently';
  }

  bool get _footerEnabled => !_isDeleting && _confirmedPermanentDelete;

  Future<void> _onFooterPrimary() async {
    await _onBackendFinalDelete();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Theme(
      data: MyThemes.lightTheme,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Delete account',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: user == null
            ? const Center(child: Text('Not signed in'))
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.pagePadding.left,
                        AppSpacing.pagePadding.top,
                        AppSpacing.pagePadding.right,
                        AppSpacing.pagePadding.bottom + 96,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWarningHeader(),
                          const SizedBox(height: AppSpacing.md),
                          _buildWhatGetsRemovedCompact(),
                          const SizedBox(height: AppSpacing.lg),
                          _buildDeletionReasonSection(),
                          const SizedBox(height: AppSpacing.lg),
                          _buildConfirmationSection(),
                          const SizedBox(height: AppSpacing.lg),
                          _buildAlternativeOptionsSection(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
        bottomNavigationBar:
            user != null ? _buildStickyFooter() : null,
      ),
    );
  }

  Widget _buildStickyFooter() {
    final pad = MediaQuery.paddingOf(context).bottom;
    final enabled = _footerEnabled;
    final bg = !_isDeleting ? errorColor : primaryColor;
    final disabledBg = Colors.grey.shade400;

    return Material(
      elevation: 8,
      color: AppColors.backgroundColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pagePadding.left,
            12,
            AppSpacing.pagePadding.right,
            12 + pad,
          ),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: enabled
                  ? () => unawaited(_onFooterPrimary())
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: enabled ? bg : disabledBg,
                foregroundColor: Colors.white,
                disabledBackgroundColor: disabledBg,
                disabledForegroundColor: Colors.white,
                elevation: enabled ? 2 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.buttonRadius),
                ),
              ),
              child: _isDeleting
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _footerLabel(),
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      _footerLabel(),
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWarningHeader() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: errorColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: errorColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, color: errorColor, size: 28),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Permanent deletion',
                    style: GoogleFonts.montserrat(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'No recovery. You will be signed out and your account cannot be restored.',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildWhatGetsRemovedCompact() => Text(
        'We remove your profile, photos, messages, matches, and related activity from the app when you finish.',
        style: GoogleFonts.montserrat(
          fontSize: 13,
          color: textSecondary,
          height: 1.4,
        ),
      );

  Widget _buildDeletionReasonSection() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Why are you leaving?',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Optional feedback',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ..._deletionReasons.map(_buildReasonTile),
            if (_selectedReason == 'Other') ...[
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tell us more (optional detail)…',
                  hintStyle: GoogleFonts.montserrat(color: textLight),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.buttonRadius),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.buttonRadius),
                    borderSide:
                        const BorderSide(color: primaryColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(AppSpacing.md),
                ),
                style:
                    GoogleFonts.montserrat(fontSize: 16, color: textPrimary),
              ),
            ],
          ],
        ),
      );

  Widget _buildReasonTile(String reason) {
    final isSelected = _selectedReason == reason;
    return GestureDetector(
      onTap: () => setState(() => _selectedReason = reason),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.buttonRadius),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.grey.shade400,
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
            const SizedBox(width: AppSpacing.buttonRadius),
            Expanded(
              child: Text(
                reason,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationSection() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirm delete',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No grace period—you cannot restore the account after this.',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildCheckboxTile(
              value: _confirmedPermanentDelete,
              onChanged: (value) =>
                  setState(() => _confirmedPermanentDelete = value ?? false),
              title: 'I understand this permanently deletes my account',
              subtitle:
                  'I cannot recover my profile, messages, or matches after this.',
            ),
          ],
        ),
      );

  Widget _buildCheckboxTile({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String title,
    required String subtitle,
  }) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: errorColor,
            checkColor: Colors.white,
          ),
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
                const SizedBox(height: AppSpacing.xs),
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
        ],
      );

  Widget _buildAlternativeOptionsSection() => Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Other options',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Take a break or contact support if you need help.',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: textSecondary,
                height: 1.35,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => unawaited(_openSupportEmailGeneric()),
                child: Text(
                  'Contact support',
                  style: GoogleFonts.montserrat(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  bool get _canBackendDelete =>
      !_isDeleting && _confirmedPermanentDelete;

  Future<void> _openSupportEmailGeneric() async {
    await AccountDeletionAnalytics.logSupportTapped('generic');
    final User? u = _auth.currentUser;
    final subject = Uri.encodeComponent('Afropeep – account deletion help');
    final body = Uri.encodeComponent(
      'I need help with account deletion.\n'
      'UID: ${u?.uid ?? "unknown"}\n'
      'Sign-in methods: ${_providerSummary(u)}\n'
      'Last error code (if any): ${_lastCallableErrorCode ?? "none"}\n'
      'Platform: ${accountDeletionClientMeta()["platform"]}\n'
      'App version: ${accountDeletionClientMeta()["appVersion"]}\n',
    );
    await _launchMailto(subject: subject, body: body);
  }

  Future<void> _launchMailto({
    required String subject,
    required String body,
  }) async {
    final uri = Uri.parse(
      'mailto:${AppConfig.supportEmail}?subject=$subject&body=$body',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      _showSnackBar('Could not open email app.');
    }
  }

  String _mapFunctionsException(FirebaseFunctionsException e) {
    final AccountDeletionFunctionsDetails? d =
        AccountDeletionFunctionsDetails.fromException(e);
    final String? extra = d?.userMessageSuffix();

    if (e.code == 'not-found') {
      final String lower = (e.message ?? '').toLowerCase();
      if (lower.contains('verification') ||
          lower.contains('active') ||
          lower.contains('request a new')) {
        return 'No active verification. Request a new code from the previous step.';
      }
      return 'Deletion service is temporarily unavailable. Please try again shortly.';
    }

    String base = e.message ?? 'Something went wrong. Please try again.';
    switch (e.code) {
      case 'resource-exhausted':
        base = e.message ?? 'Too many requests. Please wait and try again.';
        break;
      case 'permission-denied':
        base = e.message ?? 'Session check failed. Please sign in again.';
        break;
      case 'failed-precondition':
        base = e.message ?? 'Request could not be completed.';
        break;
      case 'unauthenticated':
        base = _auth.currentUser == null
            ? 'Session expired. Please sign in again.'
            : 'Could not verify this request. If this keeps happening, '
                'ask your admin to set ACCOUNT_DELETION_ENFORCE_APPCHECK=false '
                'on non-prod functions or fix App Check.';
        break;
      default:
        break;
    }
    if (extra != null && extra.isNotEmpty) {
      return '$base $extra';
    }
    return base;
  }

  Future<void> _onBackendFinalDelete() async {
    if (!_canBackendDelete) {
      return;
    }
    setState(() {
      _isDeleting = true;
    });
    AccountDeletionScope.inProgress = true;
    await AccountDeletionAnalytics.logPhaseEntered('deleting');
    final bool hasSession = await _ensureDeletionAuthSession();
    if (!hasSession) {
      AccountDeletionScope.inProgress = false;
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
      return;
    }
    try {
      final String? customReason =
          _selectedReason == 'Other' ? _reasonController.text.trim() : null;
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw StateError('Not signed in');
      }
      final Map<String, String> meta = accountDeletionClientMeta();
      final String? idToken = await currentUser.getIdToken(true);
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Missing ID token');
      }
      await _deletionFunctions.deleteAccountDirect(
        idToken: idToken,
        reason: _selectedReason,
        customReason: customReason,
        clientMeta: meta,
      );
      await _auth.signOut();
      if (!mounted) {
        return;
      }
      AccountDeletionScope.inProgress = false;
      await AccountDeletionAnalytics.logCompleted('direct');
      await AccountDeletionAnalytics.logPhaseEntered('done');
      _navigateWelcomeAfterDeletion();
    } on FirebaseFunctionsException catch (e, st) {
      AccountDeletionScope.inProgress = false;
      _lastCallableErrorCode = e.code;
      const String callableName = 'deleteAccountDirect';
      AppLogger.warning(
        'Account deletion callable failed: $callableName '
        'region=${AccountDeletionFunctionsService.callableRegion} code=${e.code}',
        error: e,
        stackTrace: st,
      );
      await AccountDeletionAnalytics.logCallFailed(e.code);
      unawaited(
        CrashlyticsService().logError(
          e,
          st,
          reason: 'account_deletion_$callableName',
        ),
      );
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
        _showSnackBar(_mapFunctionsException(e));
      }
    } on Object catch (e) {
      AccountDeletionScope.inProgress = false;
      AppLogger.error('Backend account deletion failed', error: e);
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
        _showSnackBar('Could not complete deletion. Please try again.');
      }
    }
  }

  Future<bool> _ensureDeletionAuthSession() async {
    final User? signedInUser = _auth.currentUser;
    if (signedInUser == null) {
      if (mounted) {
        _showSnackBar('Please sign in again to continue account deletion.');
      }
      return false;
    }
    try {
      await signedInUser.reload();
    } on Object catch (_) {
      // Best-effort refresh: proceed to token refresh below.
    }

    final User? refreshedUser = _auth.currentUser;
    if (refreshedUser == null) {
      if (mounted) {
        _showSnackBar('Please sign in again to continue account deletion.');
      }
      return false;
    }
    try {
      final String? token = await refreshedUser.getIdToken(true);
      if (token == null || token.isEmpty) {
        throw StateError('Empty Firebase ID token');
      }
      return true;
    } on Object catch (e, st) {
      AppLogger.warning(
        'Could not refresh auth session before deletion callable',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        _showSnackBar(
          'Your session expired. Please sign in again and try once more.',
        );
      }
      return false;
    }
  }

  void _navigateWelcomeAfterDeletion() {
    if (!mounted) {
      return;
    }
    AccountDeletionScope.inProgress = false;
    unawaited(
      Navigator.of(context).pushNamedAndRemoveUntil(
        RouteName.welcomeScreen,
        (route) => false,
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: GoogleFonts.montserrat(color: Colors.white)),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
      ),
    );
  }
}
