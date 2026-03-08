import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../common/constants/app_colors.dart';
import '../../common/data/repo/googlelogin_repo.dart';
import '../../common/data/repo/phone_auth_repo.dart';
import '../../common/routes/route_name.dart';
import '../../common/utils/account_deletion_scope.dart';

class AccountDeletionScreen extends StatefulWidget {
  const AccountDeletionScreen({super.key});

  @override
  State<AccountDeletionScreen> createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends State<AccountDeletionScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleLoginRepository _googleLoginRepository =
      GoogleLoginRepositoryImpl();
  final _passwordController = TextEditingController();
  final _reasonController = TextEditingController();

  // Afropeep MVP Color Scheme
  static const Color primaryColor = Color(0xFF008037); // Deep green
  static const Color cardColor = Color(0xFFFFFFFF); // White for cards
  static const Color errorColor = Color(0xFFFF5A5F); // Red for errors/danger
  static const Color warningColor = Color(0xFFFF9500); // Orange for warnings
  static final Color textPrimary = Colors.brown.shade800;
  static final Color textSecondary = Colors.brown.shade600;
  static final Color textLight = Colors.grey.shade600;

  bool _isDeleting = false;
  bool _passwordVisible = false;
  String _selectedReason = '';
  bool _confirmDeletion = false;
  bool _understandConsequences = false;
  bool _isPhoneUser = false;
  bool _isEmailUser = false;
  bool _isGoogleUser = false;

  // Phone re-auth for account deletion (when requires-recent-login)
  String? _verificationIdForReauth;
  final TextEditingController _reauthOtpController = TextEditingController();
  bool _isSendingReauthCode = false;

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
    _passwordController.dispose();
    _reasonController.dispose();
    _reauthOtpController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Check auth provider after the first frame to ensure state is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthProvider();
    });
  }

  void _checkAuthProvider() {
    final user = _auth.currentUser;
    if (user != null) {
      final providerData = user.providerData;
      final isPhone = providerData.any((info) => info.providerId == 'phone');
      final isEmail = providerData.any((info) => info.providerId == 'password');
      final isGoogle =
          providerData.any((info) => info.providerId == 'google.com');
      log(
        '📱 User auth provider check: providerData=${providerData.map((p) => p.providerId).toList()}, isPhone=$isPhone, isEmail=$isEmail, isGoogle=$isGoogle',
      );

      if (_isPhoneUser != isPhone ||
          _isEmailUser != isEmail ||
          _isGoogleUser != isGoogle) {
        setState(() {
          _isPhoneUser = isPhone;
          _isEmailUser = isEmail;
          _isGoogleUser = isGoogle;
        });
        log(
          '📱 Updated _isPhoneUser: $_isPhoneUser, _isEmailUser: $_isEmailUser, _isGoogleUser: $_isGoogleUser',
        );
      } else {
        _isPhoneUser = isPhone;
        _isEmailUser = isEmail;
        _isGoogleUser = isGoogle;
      }
    } else {
      log('⚠️ No current user found in _checkAuthProvider');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Delete Account',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning Header
              _buildWarningHeader(),
              const SizedBox(height: 24),

              // What Gets Deleted
              _buildWhatGetsDeletedSection(),
              const SizedBox(height: 24),

              // Deletion Reason
              _buildDeletionReasonSection(),
              const SizedBox(height: 24),

              // Password/Phone/Other Confirmation (based on auth provider)
              if (_isPhoneUser)
                _buildPhoneConfirmationSection()
              else if (_isEmailUser)
                _buildPasswordConfirmationSection()
              else
                _buildOtherProviderSection(),
              const SizedBox(height: 24),

              // Confirmation Checkboxes
              _buildConfirmationSection(),
              const SizedBox(height: 24),

              // Delete Button
              _buildDeleteButton(),
              const SizedBox(height: 16),

              // Alternative Options
              _buildAlternativeOptionsSection(),
            ],
          ),
        ),
      );

  Widget _buildWarningHeader() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: errorColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: errorColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning,
                size: 40,
                color: errorColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Delete Your Account?',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone. Once you delete your account, all your data will be permanently removed from our servers.',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildWhatGetsDeletedSection() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
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
            Row(
              children: [
                const Icon(Icons.delete_forever, color: errorColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  'What Gets Deleted',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDeletionItem('👤 Your profile and photos'),
            _buildDeletionItem('💬 All your messages and conversations'),
            _buildDeletionItem('❤️ Your matches and likes'),
            _buildDeletionItem('📍 Location and preference data'),
            _buildDeletionItem('📊 Activity history and analytics'),
            _buildDeletionItem('💳 Subscription and payment history'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: warningColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: warningColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This process may take up to 30 days to complete as we ensure all data is properly removed from our systems.',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildDeletionItem(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: errorColor, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildDeletionReasonSection() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
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
            const SizedBox(height: 8),
            Text(
              'Help us improve by telling us why you\'re deleting your account (optional)',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ..._deletionReasons.map(_buildReasonTile),
            if (_selectedReason == 'Other') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Please tell us more...',
                  hintStyle: GoogleFonts.montserrat(color: textLight),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: GoogleFonts.montserrat(fontSize: 16, color: textPrimary),
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
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
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
            const SizedBox(width: 12),
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

  Widget _buildPasswordConfirmationSection() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
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
              'Confirm Your Password',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your password to confirm account deletion',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: !_passwordVisible,
              decoration: InputDecoration(
                hintText: 'Enter your password',
                hintStyle: GoogleFonts.montserrat(color: textLight),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryColor, width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                prefixIcon: const Icon(Icons.lock, color: primaryColor),
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                    color: textLight,
                  ),
                  onPressed: () =>
                      setState(() => _passwordVisible = !_passwordVisible),
                ),
              ),
              style: GoogleFonts.montserrat(fontSize: 16, color: textPrimary),
            ),
          ],
        ),
      );

  Widget _buildOtherProviderSection() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.login, color: primaryColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Signed in with Google or another provider',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _isGoogleUser
                  ? 'If you signed in a while ago, we may ask you to confirm with Google before deleting.'
                  : 'For security, sign out and sign back in, then return to this screen to delete your account.',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await _auth.signOut();
                  if (mounted) {
                    await Navigator.of(context).pushNamedAndRemoveUntil(
                      RouteName.welcomeScreen,
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout, size: 20),
                label: Text(
                  _isGoogleUser
                      ? 'Sign out (fallback)'
                      : 'Sign out and return to sign-in',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: const BorderSide(color: primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildConfirmationSection() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
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
              'Final Confirmation',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildCheckboxTile(
              value: _understandConsequences,
              onChanged: (value) =>
                  setState(() => _understandConsequences = value ?? false),
              title: 'I understand that this action cannot be undone',
              subtitle: 'All my data will be permanently deleted',
            ),
            const SizedBox(height: 12),
            _buildCheckboxTile(
              value: _confirmDeletion,
              onChanged: (value) =>
                  setState(() => _confirmDeletion = value ?? false),
              title: 'I want to permanently delete my account',
              subtitle: 'I confirm that I want to proceed with deletion',
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
                const SizedBox(height: 4),
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

  Widget _buildDeleteButton() {
    // Phone and "other" (e.g. Google) users don't need password; email users do
    final isOtherProvider = !_isPhoneUser && !_isEmailUser;
    final passwordValid =
        _isPhoneUser || isOtherProvider || _passwordController.text.isNotEmpty;

    final canDelete =
        passwordValid && _understandConsequences && _confirmDeletion;

    log('🔘 Delete button state check:');
    log('   - isPhoneUser: $_isPhoneUser');
    log('   - passwordValid: $passwordValid (phoneUser=$_isPhoneUser || passwordNotEmpty=${_passwordController.text.isNotEmpty})');
    log('   - understandConsequences: $_understandConsequences');
    log('   - confirmDeletion: $_confirmDeletion');
    log('   - isDeleting: $_isDeleting');
    log('   - canDelete: $canDelete');
    log('   - buttonEnabled: ${canDelete && !_isDeleting}');

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canDelete && !_isDeleting ? _deleteAccount : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              canDelete && !_isDeleting ? errorColor : Colors.grey.shade400,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade400,
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: canDelete && !_isDeleting ? 2 : 0,
        ),
        child: _isDeleting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Deleting Account...',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                'Delete My Account Permanently',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildAlternativeOptionsSection() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Consider These Alternatives',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildAlternativeItem(
              '📴 Temporarily deactivate your account instead',
            ),
            _buildAlternativeItem('🔒 Update your privacy settings'),
            _buildAlternativeItem('⚙️ Adjust your matching preferences'),
            _buildAlternativeItem('💬 Contact support for help with issues'),
          ],
        ),
      );

  Widget _buildAlternativeItem(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: textSecondary,
            height: 1.4,
          ),
        ),
      );

  Future<void> _deleteAccount() async {
    setState(() => _isDeleting = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Check auth provider and re-authenticate accordingly.
      // Only treat as email user if they signed in with password; Google/OAuth users
      // must use the "other" flow (sign out and sign back in) for re-auth.
      final providerData = user.providerData;
      final isPhoneUser =
          providerData.any((info) => info.providerId == 'phone');
      final isEmailUser =
          providerData.any((info) => info.providerId == 'password');
      final isGoogleUser =
          providerData.any((info) => info.providerId == 'google.com');

      log(
        '📱 Delete account: isPhoneUser=$isPhoneUser, isEmailUser=$isEmailUser, isGoogleUser=$isGoogleUser',
      );

      // Re-authenticate based on auth provider. Order is critical: cleanup Firestore/Storage
      // while user is still authenticated, then delete Auth user, then sign out and show success.
      if (isPhoneUser) {
        log('📱 Phone user - cleanup then delete');
        AccountDeletionScope.inProgress = true;
        try {
          await _cleanupUserData(user);
          _logDeletionAndSignOut(user, authProvider: 'phone');
          await user.delete();
          await _auth.signOut();
          if (mounted) _showDeletionSuccessDialog();
          return;
        } on Object catch (e) {
          if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
            log('⚠️ Requires recent login - showing phone re-auth');
            AccountDeletionScope.inProgress = false;
            setState(() => _isDeleting = false);
            if (mounted) _showPhoneReauthDialog(user);
            return;
          }
          AccountDeletionScope.inProgress = false;
          rethrow;
        }
      } else if (isEmailUser && user.email != null) {
        log('📧 Email user - reauth, cleanup, then delete');
        AccountDeletionScope.inProgress = true;
        try {
          final credential = EmailAuthProvider.credential(
            email: user.email!,
            password: _passwordController.text,
          );
          await user.reauthenticateWithCredential(credential);
          await _cleanupUserData(user);
          _logDeletionAndSignOut(user, authProvider: 'email');
          await user.delete();
          await _auth.signOut();
          if (mounted) _showDeletionSuccessDialog();
          return;
        } on Object catch (_) {
          AccountDeletionScope.inProgress = false;
          rethrow;
        }
      } else {
        log('🔐 Other auth provider - cleanup then delete');
        AccountDeletionScope.inProgress = true;
        try {
          await _cleanupUserData(user);
          _logDeletionAndSignOut(user, authProvider: 'other');
          await user.delete();
          await _auth.signOut();
          if (mounted) _showDeletionSuccessDialog();
          return;
        } on Object catch (e) {
          if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
            if (isGoogleUser) {
              await _handleGoogleReauthAndRetryDelete(user);
              return;
            }

            AccountDeletionScope.inProgress = false;
            setState(() => _isDeleting = false);
            if (mounted) {
              _showSnackBar(
                'For security, please sign out and sign back in, then return to Delete Account to try again.',
              );
              await showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Re-authentication required'),
                  content: const Text(
                    'Sign out now, then sign back in and go to Delete Account to complete deletion.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _auth.signOut();
                        if (mounted) {
                          await Navigator.of(context).pushNamedAndRemoveUntil(
                            RouteName.welcomeScreen,
                            (route) => false,
                          );
                        }
                      },
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              );
            }
            return;
          }
          AccountDeletionScope.inProgress = false;
          rethrow;
        }
      }
    } on Object catch (e) {
      AccountDeletionScope.inProgress = false;
      log('❌ Error deleting account: $e');
      log('❌ Error type: ${e.runtimeType}');
      if (e is FirebaseAuthException) {
        log('❌ Firebase Auth Error: code=${e.code}, message=${e.message}');
      }
      setState(() => _isDeleting = false);

      if (mounted) {
        String errorMessage = 'Failed to delete account.';
        if (e is FirebaseAuthException) {
          if (e.code == 'requires-recent-login') {
            errorMessage =
                'For security, please sign out and sign back in, then try again.';
          } else if (e.code == 'wrong-password' ||
              e.code == 'invalid-credential') {
            errorMessage =
                'Incorrect password or expired session. Please try again.';
          } else {
            errorMessage = 'Error: ${e.message ?? e.code}';
          }
        } else {
          errorMessage = e.toString();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Shows dialog to re-authenticate phone user (send OTP then verify).
  void _showPhoneReauthDialog(User user) {
    final phone = user.phoneNumber ?? '';
    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Re-authentication required',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          content: Text(
            'For security, we need to verify your phone number before deleting your account. We\'ll send a code to $phone.',
            style: GoogleFonts.montserrat(color: textSecondary, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.montserrat(color: textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: _isSendingReauthCode
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      await _sendReauthCode(user);
                    },
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: _isSendingReauthCode
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Send code',
                      style: GoogleFonts.montserrat(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendReauthCode(User user) async {
    final phone = user.phoneNumber?.trim();
    if (phone == null || phone.isEmpty) {
      if (mounted) {
        _showSnackBar(
          'Phone number not found. Please sign out and sign back in.',
        );
      }
      return;
    }
    setState(() => _isSendingReauthCode = true);
    try {
      await PhoneAuthRepository().verifyPhone(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (!mounted) return;
          setState(() => _isSendingReauthCode = false);
          try {
            await user.reauthenticateWithCredential(credential);
            await _performDeletionAfterReauth(user);
          } on Object catch (e) {
            log('❌ Re-auth verificationCompleted error: $e');
            if (mounted) {
              _showSnackBar('Verification failed. Please try again.');
            }
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() {
            _isSendingReauthCode = false;
            _verificationIdForReauth = verificationId;
          });
          _showReauthOtpDialog(user);
        },
        verificationFailed: (FirebaseAuthException e) {
          log('❌ Re-auth verification failed: ${e.code} ${e.message}');
          if (mounted) {
            setState(() => _isSendingReauthCode = false);
            _showSnackBar('Failed to send code: ${e.message ?? e.code}');
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } on Object catch (e) {
      log('❌ Send reauth code error: $e');
      if (mounted) {
        setState(() => _isSendingReauthCode = false);
        _showSnackBar('Failed to send code. Please try again.');
      }
    }
  }

  void _showReauthOtpDialog(User user) {
    _reauthOtpController.clear();
    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Enter verification code',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter the 6-digit code sent to ${user.phoneNumber}',
                style:
                    GoogleFonts.montserrat(color: textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _reauthOtpController,
                keyboardType: TextInputType.number,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(8),
                  fieldHeight: 48,
                  fieldWidth: 36,
                  activeColor: primaryColor,
                  inactiveColor: textLight,
                  selectedColor: primaryColor,
                ),
                onChanged: (_) {},
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.montserrat(color: textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final code = _reauthOtpController.text.trim();
                final vid = _verificationIdForReauth;
                if (code.length != 6 || vid == null) {
                  if (mounted) _showSnackBar('Please enter the 6-digit code.');
                  return;
                }
                Navigator.pop(ctx);
                setState(() => _isDeleting = true);
                try {
                  final credential = PhoneAuthProvider.credential(
                    verificationId: vid,
                    smsCode: code,
                  );
                  await user.reauthenticateWithCredential(credential);
                  await _performDeletionAfterReauth(user);
                } on Object catch (e) {
                  log('❌ Re-auth OTP error: $e');
                  setState(() => _isDeleting = false);
                  if (mounted) {
                    _showSnackBar('Invalid or expired code. Please try again.');
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: Text(
                'Verify and delete',
                style: GoogleFonts.montserrat(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// After re-auth: cleanup Firestore/Storage, log, delete Auth user, sign out, show success.
  Future<void> _performDeletionAfterReauth(
    User user, {
    String authProvider = 'phone',
  }) async {
    AccountDeletionScope.inProgress = true;
    try {
      log('🧹 Cleaning up user data after re-auth...');
      await _cleanupUserData(user);
      _logDeletionAndSignOut(user, authProvider: authProvider);
      log('🔥 Deleting Firebase Auth user...');
      await user.delete();
      await _auth.signOut();
      if (mounted) _showDeletionSuccessDialog();
    } on Object catch (e) {
      log('❌ Error in _performDeletionAfterReauth: $e');
      AccountDeletionScope.inProgress = false;
      setState(() => _isDeleting = false);
      if (mounted) {
        _showSnackBar('Failed to complete deletion. Please try again.');
      }
    }
  }

  Future<void> _handleGoogleReauthAndRetryDelete(User user) async {
    try {
      if (mounted) {
        _showSnackBar('Re-verifying your account with Google...');
      }

      final credential =
          await _googleLoginRepository.getGoogleReauthCredential();
      if (credential == null) {
        AccountDeletionScope.inProgress = false;
        if (mounted) {
          setState(() => _isDeleting = false);
          _showSnackBar('Re-verification cancelled.');
        }
        return;
      }

      await user.reauthenticateWithCredential(credential);
      await _performDeletionAfterReauth(user, authProvider: 'google');
    } on Object catch (e) {
      AccountDeletionScope.inProgress = false;
      if (mounted) {
        setState(() => _isDeleting = false);
        _showSnackBar('Google re-verification failed. Please try again.');
      }
      log('❌ Google re-auth and retry failed: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: GoogleFonts.montserrat(color: Colors.white)),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _logDeletionAndSignOut(User user, {String? authProvider}) {
    try {
      unawaited(
        _firestore.collection('accountDeletions').add({
          'userId': user.uid,
          'email': user.email,
          'phoneNumber': user.phoneNumber,
          'authProvider': authProvider ?? 'unknown',
          'reason': _selectedReason,
          'customReason':
              _selectedReason == 'Other' ? _reasonController.text : null,
          'requestedAt': FieldValue.serverTimestamp(),
          'status': 'completed',
          'deletedAt': FieldValue.serverTimestamp(),
        }),
      );
    } on Object catch (e) {
      log('⚠️ Could not log deletion request: $e');
    }
  }

  void _showDeletionSuccessDialog() {
    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          contentPadding: const EdgeInsets.all(24),
          title: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: errorColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever,
                  color: errorColor,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Account Deleted',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your account has been permanently deleted. All your data, matches, messages, and photos have been removed from our servers.',
                style: GoogleFonts.montserrat(
                  color: textSecondary,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: errorColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: errorColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: errorColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action cannot be undone. You will need to create a new account to use the app again.',
                        style: GoogleFonts.montserrat(
                          color: textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  AccountDeletionScope.inProgress = false;
                  unawaited(
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      RouteName.welcomeScreen,
                      (route) => false,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Got it',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        ),
      ),
    );
  }

  Future<void> _cleanupUserData(User user) async {
    try {
      log('🧹 Starting user data cleanup for: ${user.uid}');

      // Use PhoneAuthRepository's deleteUser method which handles cleanup
      final repo = PhoneAuthRepository();
      await repo.deleteUser(user);

      log('✅ User data cleanup completed');
    } on Object catch (e) {
      log('⚠️ Error during user data cleanup: $e');
      log('⚠️ Cleanup error type: ${e.runtimeType}');
      // Re-throw so we can handle it properly in the calling method
      rethrow;
    }
  }

  Widget _buildPhoneConfirmationSection() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
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
              'Confirm Account Deletion',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Since you signed up with phone, your account will be deleted immediately after confirmation.',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: warningColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: warningColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: warningColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'If you signed in a while ago, we\'ll send a verification code to your phone before deleting.',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
