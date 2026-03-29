import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../routes/route_name.dart';
import 'auth_flow_telemetry.dart';
import 'profile_completion_guard.dart';

/// Centralized post-auth navigation.
///
/// After any auth provider succeeds (Google, Email, Phone), call
/// [navigateAfterAuth] instead of hardcoding a destination. It checks the
/// user's Firestore profile and routes to onboarding or the main app.
class AuthRouter {
  AuthRouter._();

  /// Coalesces overlapping [navigateAfterAuth] calls (e.g. two mounted welcomes
  /// after a shared gate) so only one stack replacement runs.
  static Future<void>? _navigateAfterAuthInFlight;

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
    if (_navigateAfterAuthInFlight != null) {
      await _navigateAfterAuthInFlight;
      return;
    }
    final Future<void> run = _navigateAfterAuthImpl(context);
    _navigateAfterAuthInFlight = run;
    try {
      await run;
    } finally {
      if (identical(_navigateAfterAuthInFlight, run)) {
        _navigateAfterAuthInFlight = null;
      }
    }
  }

  static Future<void> _navigateAfterAuthImpl(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      log('AuthRouter: no authenticated user — returning to welcome');
      AuthFlowTelemetry.track('auth_router_no_user');
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
      AuthFlowTelemetry.track(
        'auth_router_invalid_session',
        data: {'uid': user.uid},
      );
      await _signOutAndGoWelcome(context);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 5));

      final profileData = doc.data();
      if (!doc.exists || profileData == null) {
        log(
          'AuthRouter: authenticated session has no user profile document '
          '— signing out and returning to welcome',
        );
        AuthFlowTelemetry.track(
          'auth_router_missing_profile',
          data: {'uid': user.uid},
        );
        if (!context.mounted) return;
        await _signOutAndGoWelcome(context);
        return;
      }

      final isComplete = ProfileCompletionGuard.isDocumentComplete(profileData);

      if (!isComplete && _isBlankProfile(profileData)) {
        log(
          'AuthRouter: blank/incomplete profile detected '
          '— routing to onboarding',
        );
        AuthFlowTelemetry.track(
          'auth_router_blank_profile_onboarding',
          data: {'uid': user.uid},
        );
      }

      if (!context.mounted) return;

      final destination =
          isComplete ? RouteName.mainNavigation : RouteName.onboarding;

      log('AuthRouter: profile ${isComplete ? "complete" : "incomplete"} '
          '→ navigating to $destination');
      AuthFlowTelemetry.track(
        'auth_router_navigate',
        data: {
          'uid': user.uid,
          'isComplete': isComplete,
          'destination': destination,
        },
      );

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
      AuthFlowTelemetry.track(
        'auth_router_firestore_lookup_failed',
        data: {
          'uid': user.uid,
          'error': e.runtimeType.toString(),
          'isLikelyNewUser': isLikelyNewUser,
          'fallbackDestination': fallbackDestination,
        },
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

  static bool _isBlankProfile(Map<String, dynamic> data) {
    bool isNonEmptyString(Object? value) =>
        value is String && value.trim().isNotEmpty;
    bool hasNonEmptyList(String key) =>
        data[key] is List && (data[key] as List).isNotEmpty;

    final hasName =
        isNonEmptyString(data['name']) || isNonEmptyString(data['userName']);
    final hasGender = isNonEmptyString(data['gender']) ||
        isNonEmptyString(data['userGender']);
    final hasBio = isNonEmptyString(data['bio']);
    final hasPhoto = hasNonEmptyList('photos') ||
        hasNonEmptyList('Pictures') ||
        hasNonEmptyList('imageUrl') ||
        isNonEmptyString(data['profilePicture']);
    final hasLocation = isNonEmptyString(data['locationName']) ||
        (data['location'] is Map &&
            isNonEmptyString((data['location'] as Map)['address']));

    return !(hasName || hasGender || hasPhoto || hasBio || hasLocation);
  }

  static Future<void> _signOutAndGoWelcome(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
    } on Object catch (e) {
      log('AuthRouter: signOut failed while clearing session: $e');
    }

    if (context.mounted) {
      await Navigator.of(context).pushNamedAndRemoveUntil(
        RouteName.welcomeScreen,
        (route) => false,
      );
    }
  }
}
