import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../routes/route_name.dart';
import 'profile_completion_guard.dart';

/// Centralized post-auth navigation.
///
/// After any auth provider succeeds (Google, Email, Phone), call
/// [navigateAfterAuth] instead of hardcoding a destination. It checks the
/// user's Firestore profile and routes to onboarding or the main app.
class AuthRouter {
  AuthRouter._();

  static const Duration _newAccountWindow = Duration(minutes: 2);
  static const Set<String> _supportedProviderIds = <String>{
    'phone',
    'google.com',
    'password',
    'apple.com',
  };

  /// Reads the current user's Firestore document and navigates to
  /// [RouteName.onboarding] (incomplete profile) or
  /// [RouteName.mainNavigation] (complete profile).
  ///
  /// Clears the entire back stack so the user cannot press Back into the
  /// auth flow.
  static Future<void> navigateAfterAuth(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      log('AuthRouter: no authenticated user — returning to welcome');
      if (context.mounted) {
        await Navigator.of(context).pushNamedAndRemoveUntil(
          RouteName.welcomeScreen,
          (route) => false,
        );
      }
      return;
    }

    if (_shouldTreatAsSignedOut(user)) {
      log(
        'AuthRouter: invalid/stale auth session detected '
        '(anonymous or unsupported provider) — signing out to welcome',
      );
      try {
        await FirebaseAuth.instance.signOut();
      } on Object catch (e) {
        log('AuthRouter: signOut failed while clearing stale session: $e');
      }
      if (context.mounted) {
        await Navigator.of(context).pushNamedAndRemoveUntil(
          RouteName.welcomeScreen,
          (route) => false,
        );
      }
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 5));

      final isComplete = doc.exists &&
          doc.data() != null &&
          ProfileCompletionGuard.isDocumentComplete(doc.data()!);

      if (!context.mounted) return;

      final destination =
          isComplete ? RouteName.mainNavigation : RouteName.onboarding;

      log('AuthRouter: profile ${isComplete ? "complete" : "incomplete"} '
          '→ navigating to $destination');

      await Navigator.of(context).pushNamedAndRemoveUntil(
        destination,
        (route) => false,
      );
    } on Object catch (e) {
      final creationTime = user.metadata.creationTime;
      final lastSignInTime = user.metadata.lastSignInTime;
      final isLikelyNewUser = creationTime != null &&
          lastSignInTime != null &&
          lastSignInTime.difference(creationTime).abs() <= _newAccountWindow;

      final fallbackDestination =
          isLikelyNewUser ? RouteName.onboarding : RouteName.mainNavigation;

      log(
        'AuthRouter: Firestore lookup failed ($e) — '
        'fallback to $fallbackDestination (isLikelyNewUser: $isLikelyNewUser)',
      );
      if (context.mounted) {
        await Navigator.of(context).pushNamedAndRemoveUntil(
          fallbackDestination,
          (route) => false,
        );
      }
    }
  }

  static bool _shouldTreatAsSignedOut(User user) {
    if (user.isAnonymous) return true;

    final providerIds = user.providerData
        .map((provider) => provider.providerId)
        .where((id) => id.trim().isNotEmpty)
        .toSet();
    if (providerIds.isEmpty) return true;

    return !providerIds.any(_supportedProviderIds.contains);
  }
}
