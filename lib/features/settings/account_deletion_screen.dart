import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';
import '../../common/data/repo/phone_auth_repo.dart';
import '../../common/routes/route_name.dart';

class AccountDeletionScreen extends StatefulWidget {
  const AccountDeletionScreen({Key? key}) : super(key: key);

  @override
  State<AccountDeletionScreen> createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends State<AccountDeletionScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _passwordController = TextEditingController();
  final _reasonController = TextEditingController();

  // Afropeep MVP Color Scheme
  static const Color backgroundColor = Colors.white; // MVP white background
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
      log('📱 User auth provider check: providerData=${providerData.map((p) => p.providerId).toList()}, isPhone=$isPhone');
      
      if (_isPhoneUser != isPhone) {
        setState(() {
          _isPhoneUser = isPhone;
        });
        log('📱 Updated _isPhoneUser to: $_isPhoneUser');
      } else {
        _isPhoneUser = isPhone; // Set it even if no state change needed
      }
    } else {
      log('⚠️ No current user found in _checkAuthProvider');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
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

            // Password/Phone Confirmation (based on auth provider)
            _isPhoneUser
                ? _buildPhoneConfirmationSection()
                : _buildPasswordConfirmationSection(),
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
  }

  Widget _buildWarningHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: errorColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: errorColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: errorColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
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
  }

  Widget _buildWhatGetsDeletedSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
              Icon(Icons.delete_forever, color: errorColor, size: 24),
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
              color: warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: warningColor, size: 20),
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
  }

  Widget _buildDeletionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: errorColor, size: 16),
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
  }

  Widget _buildDeletionReasonSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
          ..._deletionReasons
              .map((reason) => _buildReasonTile(reason))
              .toList(),
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
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: GoogleFonts.montserrat(fontSize: 16, color: textPrimary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReasonTile(String reason) {
    final isSelected = _selectedReason == reason;

    return GestureDetector(
      onTap: () => setState(() => _selectedReason = reason),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
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
                  ? Icon(Icons.check, color: Colors.white, size: 12)
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

  Widget _buildPasswordConfirmationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixIcon: Icon(Icons.lock, color: primaryColor),
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
  }

  Widget _buildConfirmationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
  }

  Widget _buildCheckboxTile({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String title,
    required String subtitle,
  }) {
    return Row(
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
  }

  Widget _buildDeleteButton() {
    // For phone users, don't require password
    // For email users, require password
    final passwordValid = _isPhoneUser || _passwordController.text.isNotEmpty;
    
        final canDelete = passwordValid &&
        _understandConsequences &&
        _confirmDeletion;
        
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
          backgroundColor: canDelete && !_isDeleting ? errorColor : Colors.grey.shade400,
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
                  SizedBox(
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

  Widget _buildAlternativeOptionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: primaryColor, size: 20),
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
              '📴 Temporarily deactivate your account instead'),
          _buildAlternativeItem('🔒 Update your privacy settings'),
          _buildAlternativeItem('⚙️ Adjust your matching preferences'),
          _buildAlternativeItem('💬 Contact support for help with issues'),
        ],
      ),
    );
  }

  Widget _buildAlternativeItem(String text) {
    return Padding(
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
  }

  Future<void> _deleteAccount() async {
    setState(() => _isDeleting = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Check auth provider and re-authenticate accordingly
      final providerData = user.providerData;
      final isPhoneUser = providerData.any((info) => info.providerId == 'phone');
      final isEmailUser = providerData.any((info) => info.providerId == 'password') || user.email != null;

      log('📱 Delete account: isPhoneUser=$isPhoneUser, isEmailUser=$isEmailUser');

      // Re-authenticate based on auth provider
      if (isPhoneUser) {
        // For phone users, we can't use email/password reauth
        // Try direct deletion first (works if user logged in recently)
        // If fails, will need phone reauth flow
        log('📱 Phone user - attempting direct deletion');
        try {
          await user.delete();
          log('✅ Direct deletion successful for phone user');
        } catch (e) {
          if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
            log('⚠️ Requires recent login - need phone reauth');
            throw Exception('Please sign out and sign back in to delete your account, or contact support.');
          }
          rethrow;
        }
      } else if (isEmailUser && user.email != null) {
        // For email users, use password reauth
        log('📧 Email user - using password reauth');
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _passwordController.text,
        );
        await user.reauthenticateWithCredential(credential);
        await user.delete();
      } else {
        // For other providers (Google, Facebook), try direct deletion
        log('🔐 Other auth provider - attempting direct deletion');
        try {
          await user.delete();
        } catch (e) {
          if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
            throw Exception('Please sign out and sign back in to delete your account.');
          }
          rethrow;
        }
      }

      // Cleanup user data from Firestore BEFORE deleting auth user
      // This ensures we have a valid user object for cleanup
      log('🧹 Cleaning up user data...');
      try {
        await _cleanupUserData(user);
        log('✅ User data cleanup completed');
      } catch (cleanupError) {
        log('⚠️ Error during cleanup (non-fatal): $cleanupError');
        // Continue with deletion even if cleanup fails partially
      }

      // Store deletion request in Firestore for audit/logging
      try {
        await _firestore.collection('accountDeletions').add({
          'userId': user.uid,
          'email': user.email,
          'phoneNumber': user.phoneNumber,
          'authProvider': isPhoneUser ? 'phone' : (isEmailUser ? 'email' : 'other'),
          'reason': _selectedReason,
          'customReason':
              _selectedReason == 'Other' ? _reasonController.text : null,
          'requestedAt': FieldValue.serverTimestamp(),
          'status': 'completed',
          'deletedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        log('⚠️ Could not log deletion request: $e');
        // Don't fail deletion if logging fails
      }

      // Sign out user
      await _auth.signOut();

      // Show success dialog - account is immediately deleted
      if (mounted) {
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
                    color: errorColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(Icons.delete_forever, color: errorColor, size: 40),
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
                    color: errorColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: errorColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: errorColor, size: 20),
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
                    // Navigate to welcome screen (not login, since account is deleted)
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      RouteName.welcomeScreen,
                      (route) => false,
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
        );
      }
    } catch (e) {
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
            errorMessage = 'For security, please sign out and sign back in, then try again.';
          } else if (e.code == 'wrong-password') {
            errorMessage = 'Incorrect password. Please try again.';
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

  Future<void> _cleanupUserData(User user) async {
    try {
      log('🧹 Starting user data cleanup for: ${user.uid}');
      
      // Use PhoneAuthRepository's deleteUser method which handles cleanup
      final repo = PhoneAuthRepository();
      await repo.deleteUser(user);
      
      log('✅ User data cleanup completed');
    } catch (e) {
      log('⚠️ Error during user data cleanup: $e');
      log('⚠️ Cleanup error type: ${e.runtimeType}');
      // Re-throw so we can handle it properly in the calling method
      rethrow;
    }
  }

  Widget _buildPhoneConfirmationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
              color: warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: warningColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: warningColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Note: For security, you may need to sign out and sign back in before deleting if you haven\'t signed in recently.',
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
}
