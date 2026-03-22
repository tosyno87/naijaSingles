import 'dart:async';

import '../../services/crashlytics_service.dart';
import 'app_logger.dart';

/// Lightweight telemetry for auth/onboarding routing and save outcomes.
/// Logs locally and forwards key breadcrumbs to Crashlytics when enabled.
class AuthFlowTelemetry {
  static void track(
    String event, {
    Map<String, Object?> data = const <String, Object?>{},
  }) {
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
