import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../common/bloc/theme/theme_bloc.dart';
import '../../common/bloc/user/user_bloc.dart';
import '../../common/constants/app_colors.dart';
import '../../common/constants/app_spacing.dart';
import '../../common/routes/route_name.dart';
import '../../common/utils/privacy_policy_screen.dart';
import '../../common/utils/terms_of_service_screen.dart';
import '../../common/widgets/delete_account_themed_dialog.dart';
import '../../config/app_config.dart';
import '../../features/payment/presentation/bloc/subscription_bloc.dart';
import '../../features/payment/ui/in_app_purchase/buy_products/buyproducts_bloc.dart';
import '../../features/payment/ui/in_app_purchase/get_products/getproducts_bloc.dart';
import '../../features/payment/ui/products.dart';
import '../../models/user_model.dart';
import '../account_status/presentation/bloc/account_status_bloc.dart';
import '../account_status/presentation/screens/account_status_screen.dart';
import '../profile/privacy_settings_screen.dart';
import 'account_deletion_screen.dart';
import 'help_center_screen.dart';
import 'password_settings_screen.dart';
import 'safety_center_screen.dart';
import 'widgets/settings_list/settings_list.dart';

/// Single hub for account, notifications, subscription, legal, safety, and support.
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _restoreDialogVisible = false;

  static const Color primaryColor = AppColors.primaryGreen;
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;

  bool get _isPasswordProviderUser =>
      _auth.currentUser?.providerData.any((p) => p.providerId == 'password') ??
      false;
  bool get _hasAccountEmail =>
      _auth.currentUser?.email?.trim().isNotEmpty ?? false;
  bool get _canManagePassword => _isPasswordProviderUser || _hasAccountEmail;

  Widget _divider(BuildContext context) => Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context).dividerColor,
      );

  Widget _sectionGap() => const SizedBox(height: 18);

  Future<void> _openUrlWithFallback(
    String url, {
    required String copyLabel,
  }) async {
    final uri = Uri.parse(url);
    var opened = false;
    if (await canLaunchUrl(uri)) {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (!opened && await canLaunchUrl(uri)) {
      opened = await launchUrl(uri);
    }
    if (opened) return;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Could not open link',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
        content: SelectableText(url),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$copyLabel link copied to clipboard.'),
                ),
              );
            },
            child: const Text('Copy link'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _openCommunityGuidelines() async {
    await _openUrlWithFallback(
      AppConfig.communityGuidelinesUrl,
      copyLabel: 'Community guidelines',
    );
  }

  Future<void> _openManageSubscription() async {
    final url = Platform.isIOS
        ? 'https://apps.apple.com/account/subscriptions'
        : 'https://play.google.com/store/account/subscriptions';
    await _openUrlWithFallback(url, copyLabel: 'Manage subscription');
  }

  Future<void> _openUpgradePaywall() async {
    final user = context.read<UserBloc>().currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to manage subscription.')),
        );
      }
      return;
    }
    if (!mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (ctx) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => GetInAppProductsBloc()),
            BlocProvider(create: (_) => BuyConsumableInAppProductsBloc()),
          ],
          child: Products(user, null, const <String, dynamic>{}),
        ),
      ),
    );
  }

  void _restorePurchases() {
    context.read<SubscriptionBloc>().add(const SubscriptionRestoreRequested());
  }

  String _subscriptionConsequenceText(UserModel? user) {
    const base =
        'Manage your plan or restore purchases from the App Store or Google Play.';
    if (user == null) return base;
    if (user.hasPremiumAccess) {
      final String plan = user.subscriptionPlanId ?? 'Premium';
      final DateTime? exp = user.subscriptionExpiresAt;
      final String expPhrase = exp != null
          ? 'Renews or expires on ${exp.year}-${exp.month.toString().padLeft(2, '0')}-${exp.day.toString().padLeft(2, '0')}.'
          : 'Active subscription.';
      return '$plan · $expPhrase $base';
    }
    return 'You are on the free plan. $base';
  }

  void _openLicenses() {
    showLicensePage(
      context: context,
      applicationName: AppConfig.appName,
      applicationVersion: AppConfig.appVersion,
    );
  }

  void _showSignOutDialog() {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Sign out?',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'You will need to sign in again to use your account.',
            style: GoogleFonts.montserrat(color: textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                unawaited(_performSignOut());
              },
              child: Text(
                'Sign out',
                style: GoogleFonts.montserrat(color: Colors.red.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    unawaited(
      showAccountDeletionThemedDialog<void>(
        context,
        (dialogContext) => AlertDialog(
          backgroundColor: deleteAccountDialogBackgroundColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          title: Text(
            'Delete account',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade700,
            ),
          ),
          content: Text(
            'This permanently removes your profile, messages, and matches.',
            style: GoogleFonts.montserrat(color: textSecondary, height: 1.35),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                unawaited(
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const AccountDeletionScreen(),
                    ),
                  ),
                );
              },
              child: Text(
                'Continue',
                style: GoogleFonts.montserrat(color: Colors.red.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performSignOut() async {
    final userBloc = context.read<UserBloc>();
    final navigator = Navigator.of(context);

    final loadingRoute = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => const Center(child: CircularProgressIndicator()),
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
      await Future<void>.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;
      if (loadingRoute.isActive) {
        navigator.removeRoute(loadingRoute);
      }

      await navigator.pushNamedAndRemoveUntil(
        RouteName.welcomeScreen,
        (route) => false,
      );
    } on Object catch (e) {
      log('Error signing out: $e');
      if (!mounted) return;
      if (loadingRoute.isActive) {
        navigator.removeRoute(loadingRoute);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sign out: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  void _showChangePassword() {
    unawaited(
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => const PasswordSettingsScreen(),
        ),
      ),
    );
  }

  Future<void> _showSetPassword() async {
    final email = _auth.currentUser?.email;
    if (email == null || email.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No email found for this account.')),
        );
      }
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password setup link sent to $email'),
            backgroundColor: primaryColor,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Unable to send email'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  void _showAboutDialog() {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'About ${AppConfig.appName}',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Version ${AppConfig.appVersion}\n\n'
            '${AppConfig.appName} connects Africans in the diaspora.',
            style: GoogleFonts.montserrat(color: textSecondary, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.montserrat(color: primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _languageSubtitle(BuildContext context) {
    try {
      final locale = context.locale;
      return '${locale.languageCode}-${locale.countryCode ?? ''}'.trim();
    } on Object {
      return 'en-US';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeBloc>().isDarkMode;
    final bg = isDark ? Colors.black : AppColors.backgroundColor;
    final onSurface = isDark ? Colors.white : textPrimary;

    return MultiBlocListener(
      listeners: [
        BlocListener<SubscriptionBloc, SubscriptionState>(
          listenWhen: (previous, current) =>
              previous.restoreInProgress != current.restoreInProgress,
          listener: (context, state) {
            if (state.restoreInProgress) {
              if (_restoreDialogVisible) return;
              _restoreDialogVisible = true;
              unawaited(
                showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => PopScope(
                    canPop: false,
                    child: AlertDialog(
                      content: Row(
                        children: [
                          const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Restoring purchases…',
                              style: GoogleFonts.montserrat(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).whenComplete(() {
                  _restoreDialogVisible = false;
                }),
              );
              return;
            }
            final NavigatorState nav = Navigator.of(context);
            if (_restoreDialogVisible && nav.canPop()) {
              nav.pop();
            }
          },
        ),
        BlocListener<SubscriptionBloc, SubscriptionState>(
          listenWhen: (previous, current) =>
              current.userMessage != null &&
              current.userMessage != previous.userMessage,
          listener: (context, state) {
            final String? message = state.userMessage;
            if (message == null) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message, style: GoogleFonts.montserrat()),
                behavior: SnackBarBehavior.floating,
              ),
            );
            context
                .read<SubscriptionBloc>()
                .add(const SubscriptionConsumeUserMessage());
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: onSurface, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Account Settings',
            style: GoogleFonts.montserrat(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 32),
          children: [
            SettingsSection(
              title: 'Account',
              children: [
                SettingsRow(
                  title: 'Edit profile',
                  subtitle: 'Photos and info',
                  onTap: () => unawaited(
                    Navigator.pushNamed(context, RouteName.editProfileScreen),
                  ),
                ),
                _divider(context),
                SettingsRow(
                  title: 'Phone & email',
                  subtitle: 'Sign-in contact details',
                  onTap: () => unawaited(
                    Navigator.pushNamed(context, RouteName.phoneEmailSettings),
                  ),
                ),
                _divider(context),
                SettingsRow(
                  title: 'Connected accounts',
                  subtitle: 'Google, Apple, and more',
                  onTap: () => unawaited(
                    Navigator.pushNamed(
                      context,
                      RouteName.connectedAccountsSettings,
                    ),
                  ),
                ),
                if (_canManagePassword) ...[
                  _divider(context),
                  SettingsRow(
                    title: _isPasswordProviderUser
                        ? 'Change password'
                        : 'Set password',
                    subtitle: _isPasswordProviderUser
                        ? 'Update your password'
                        : 'Create a password',
                    onTap: _isPasswordProviderUser
                        ? _showChangePassword
                        : () => unawaited(_showSetPassword()),
                  ),
                ],
              ],
            ),
            _sectionGap(),
            SettingsSection(
              title: 'Notifications',
              children: [
                SettingsRow(
                  title: 'Push notifications',
                  subtitle: 'Matches, messages, likes',
                  onTap: () => unawaited(
                    Navigator.pushNamed(
                      context,
                      RouteName.notificationSettings,
                    ),
                  ),
                ),
                _divider(context),
                SettingsRow(
                  title: 'Email notifications',
                  subtitle: 'Product updates and tips',
                  onTap: () => unawaited(
                    Navigator.pushNamed(
                      context,
                      RouteName.emailNotificationsSettings,
                    ),
                  ),
                ),
              ],
            ),
            _sectionGap(),
            BlocBuilder<UserBloc, UserState>(
              builder: (context, userState) {
                final UserModel? user = context.read<UserBloc>().currentUser;
                final bool premium = user?.hasPremiumAccess ?? false;
                return SettingsSection(
                  title: 'Subscription',
                  consequence: _subscriptionConsequenceText(user),
                  children: [
                    SettingsRow(
                      title: premium ? 'Change plan' : 'Upgrade',
                      subtitle: premium
                          ? 'Switch billing period or plan'
                          : 'See plans and benefits',
                      onTap: () => unawaited(_openUpgradePaywall()),
                    ),
                    _divider(context),
                    SettingsRow(
                      title: 'Manage subscription',
                      subtitle: 'Open store subscriptions',
                      onTap: () => unawaited(_openManageSubscription()),
                    ),
                    _divider(context),
                    SettingsRow(
                      title: 'Restore purchases',
                      subtitle: 'Recover an existing subscription',
                      onTap: _restorePurchases,
                    ),
                  ],
                );
              },
            ),
            _sectionGap(),
            SettingsSection(
              title: 'Legal',
              children: [
                SettingsRow(
                  title: 'Privacy policy',
                  onTap: () => unawaited(
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    ),
                  ),
                ),
                _divider(context),
                SettingsRow(
                  title: 'Terms',
                  onTap: () => unawaited(
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const TermsOfServiceScreen(),
                      ),
                    ),
                  ),
                ),
                _divider(context),
                SettingsRow(
                  title: 'Licenses',
                  onTap: _openLicenses,
                ),
                _divider(context),
                SettingsRow(
                  title: 'Download my data',
                  subtitle: 'Request a copy of your data',
                  onTap: () => unawaited(
                    Navigator.pushNamed(context, RouteName.downloadMyData),
                  ),
                ),
              ],
            ),
            _sectionGap(),
            SettingsSection(
              title: 'Safety & community',
              children: [
                SettingsRow(
                  title: 'Blocked users',
                  onTap: () => unawaited(
                    Navigator.pushNamed(context, RouteName.blockedUsers),
                  ),
                ),
                _divider(context),
                SettingsRow(
                  title: 'Safety center',
                  onTap: () => unawaited(
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const SafetyCenterScreen(),
                      ),
                    ),
                  ),
                ),
                _divider(context),
                SettingsRow(
                  title: 'Community guidelines',
                  onTap: () => unawaited(_openCommunityGuidelines()),
                ),
              ],
            ),
            _sectionGap(),
            SettingsSection(
              title: 'Privacy',
              children: [
                SettingsRow(
                  title: 'Profile privacy',
                  subtitle: 'Who can see you',
                  onTap: () => unawaited(
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const PrivacySettingsScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            _sectionGap(),
            SettingsSection(
              title: 'Preferences',
              children: [
                SettingsRow(
                  title: 'Language',
                  subtitle: _languageSubtitle(context),
                  onTap: () => unawaited(
                    Navigator.pushNamed(context, RouteName.languageSettings),
                  ),
                ),
              ],
            ),
            _sectionGap(),
            SettingsSection(
              title: 'Support',
              children: [
                SettingsRow(
                  title: 'Help center',
                  onTap: () => unawaited(
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const HelpCenterScreen(),
                      ),
                    ),
                  ),
                ),
                _divider(context),
                SettingsRow(
                  title: 'Send feedback',
                  onTap: () => unawaited(
                    Navigator.pushNamed(context, RouteName.feedbackScreen),
                  ),
                ),
                _divider(context),
                SettingsRow(
                  title: 'About',
                  onTap: _showAboutDialog,
                ),
              ],
            ),
            _sectionGap(),
            SettingsSection(
              title: 'Account status',
              consequence:
                  'Taking a break hides your profile from discovery until you return.',
              children: [
                SettingsRow(
                  title: 'Take a break',
                  onTap: () => unawaited(
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => BlocProvider<AccountStatusBloc>(
                          create: (_) => AccountStatusBloc(),
                          child: const AccountStatusScreen(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SettingsSection(
              title: 'Session',
              children: [
                SettingsRow(
                  title: 'Log out',
                  destructive: true,
                  showChevron: false,
                  onTap: _showSignOutDialog,
                ),
                _divider(context),
                SettingsRow(
                  title: 'Delete account',
                  subtitle: 'Permanent — cannot be undone',
                  destructive: true,
                  onTap: _showDeleteAccountDialog,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
