import 'dart:async';

import '../../services/crashlytics_service.dart';
import 'app_logger.dart';

/// Lightweight telemetry for auth/onboarding routing and save outcomes.
/// Logs locally and forwards key breadcrumbs to Crashlytics when enabled.
class AuthFlowTelemetry {
  /// Welcome can mount twice in quick succession (e.g. sign-out redirect +
  /// router rebuild), which duplicated `welcome_check_started` /
  /// `welcome_shown_no_session`. Suppress repeats within this window.
  static const Duration _welcomeDedupeWindow = Duration(seconds: 5);
  static final Map<String, DateTime> _lastWelcomeEventAt = {};
  static const Set<String> _welcomeDedupeEvents = <String>{
    'welcome_check_started',
    'welcome_shown_no_session',
  };

  static void track(
    String event, {
    Map<String, Object?> data = const <String, Object?>{},
  }) {
    final DateTime now = DateTime.now();
    if (_welcomeDedupeEvents.contains(event)) {
      final DateTime? last = _lastWelcomeEventAt[event];
      if (last != null && now.difference(last) < _welcomeDedupeWindow) {
        return;
      }
      _lastWelcomeEventAt[event] = now;
    }

    final payload = <String, Object?>{
      'event': event,
      ...data,
    };
    final message = _toLine(payload);

    AppLogger.info('AUTH_FLOW $message');
    unawaited(CrashlyticsService().logMessage('AUTH_FLOW $message'));
  }

  static String _toLine(Map<String, Object?> payload) =>
      payload.entries.map((entry) => '${entry.key}=${entry.value}').join(' ');
}
