import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/services.dart';

import '../common/utils/app_logger.dart';

/// Funnel events for account deletion (no PII). Never throws: some platforms or
/// builds lose the Analytics Pigeon channel (e.g. macOS/desktop); deletion must still work.
class AccountDeletionAnalytics {
  AccountDeletionAnalytics._();

  static final FirebaseAnalytics _a = FirebaseAnalytics.instance;

  static Future<void> _safeLog(
    String name,
    Map<String, Object> parameters,
  ) async {
    try {
      await _a.logEvent(name: name, parameters: parameters);
    } on Object catch (e, st) {
      // macOS/desktop and some embedders have no Analytics Pigeon channel —
      // expected; avoid noisy WARNING stacks in normal dev runs.
      if (e is PlatformException && e.code == 'channel-error') {
        AppLogger.debug(
          'AccountDeletionAnalytics: $name skipped (analytics unavailable)',
        );
        return;
      }
      AppLogger.warning(
        'AccountDeletionAnalytics: $name skipped',
        error: e,
        stackTrace: st,
      );
    }
  }

  static Future<void> logPhaseEntered(String phase) => _safeLog(
        'deletion_phase_entered',
        {'phase': phase},
      );

  static Future<void> logOtpSent(String channel) => _safeLog(
        'deletion_otp_sent',
        {'channel': channel},
      );

  static Future<void> logCallFailed(String reason) => _safeLog(
        'deletion_call_failed',
        {'reason': reason},
      );

  static Future<void> logCompleted(String method) => _safeLog(
        'deletion_completed',
        {'method': method},
      );

  static Future<void> logSupportTapped(String lane) => _safeLog(
        'deletion_support_tapped',
        {'lane': lane},
      );
}
