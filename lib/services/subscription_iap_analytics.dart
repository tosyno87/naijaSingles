import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/services.dart';

import '../common/utils/app_logger.dart';
import 'crashlytics_service.dart';

/// Subscription / IAP observability for support and debugging.
/// No PII; product ids only. Never throws.
class SubscriptionIapAnalytics {
  SubscriptionIapAnalytics._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static const int _maxParamLen = 100;

  static String _clip(String value) {
    if (value.length <= _maxParamLen) return value;
    return '${value.substring(0, _maxParamLen - 3)}...';
  }

  static Future<void> _safeLogEvent(
    String name,
    Map<String, Object> parameters,
  ) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } on Object catch (e, st) {
      if (e is PlatformException && e.code == 'channel-error') {
        AppLogger.debug(
          'SubscriptionIapAnalytics: $name skipped (analytics unavailable)',
        );
        return;
      }
      AppLogger.warning(
        'SubscriptionIapAnalytics: $name skipped',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Server verification failed after a purchased/restored transaction.
  static Future<void> logVerifyFailed({
    required String platform,
    required String productId,
    required bool isRestoreFlow,
    required Object error,
  }) async {
    final String reason = _clip(error.toString());
    AppLogger.warning(
      'iap_verify_failed platform=$platform productId=$productId '
      'isRestore=$isRestoreFlow reason=$reason',
      error: error,
    );
    await _safeLogEvent('iap_verify_failed', {
      'platform': _clip(platform),
      'product_id': _clip(productId),
      'is_restore': isRestoreFlow ? 'true' : 'false',
      'reason': reason,
    });
    unawaited(
      CrashlyticsService().logMessage(
        'iap_verify_failed platform=$platform productId=$productId '
        'restore=$isRestoreFlow: $reason',
      ),
    );
    unawaited(
      CrashlyticsService().logError(
        error,
        StackTrace.current,
        reason: 'iap_verify_failed',
      ),
    );
  }

  /// Server verification succeeded (optional funnel / support correlation).
  static Future<void> logVerifySucceeded({
    required String platform,
    required String productId,
    required bool isRestoreFlow,
  }) async {
    AppLogger.info(
      'iap_verify_succeeded platform=$platform productId=$productId '
      'isRestore=$isRestoreFlow',
    );
    await _safeLogEvent('iap_verify_succeeded', {
      'platform': _clip(platform),
      'product_id': _clip(productId),
      'is_restore': isRestoreFlow ? 'true' : 'false',
    });
  }

  /// Restore flow finished or failed from the user’s perspective.
  ///
  /// [outcome]: `success` | `timeout` | `failed` | `store_unavailable` |
  /// `native_exception` | `purchase_error` | `stream_error`
  static Future<void> logRestoreOutcome({
    required String platform,
    required String outcome,
    String? detail,
  }) async {
    final String d = detail != null ? _clip(detail) : '';
    AppLogger.info(
      'iap_restore_outcome platform=$platform outcome=$outcome${d.isEmpty ? '' : ' detail=$d'}',
    );
    final Map<String, Object> params = {
      'platform': _clip(platform),
      'outcome': _clip(outcome),
    };
    if (d.isNotEmpty) {
      params['detail'] = d;
    }
    await _safeLogEvent('iap_restore_outcome', params);
    unawaited(
      CrashlyticsService().logMessage(
        'iap_restore_outcome platform=$platform outcome=$outcome${d.isEmpty ? '' : ' $d'}',
      ),
    );
  }

  /// Purchase stream error from the store plugin.
  static Future<void> logPurchaseStreamError({
    required String platform,
    required String message,
  }) async {
    final String m = _clip(message);
    AppLogger.warning('iap_purchase_stream_error platform=$platform: $m');
    await _safeLogEvent('iap_purchase_stream_error', {
      'platform': _clip(platform),
      'message': m,
    });
    unawaited(
      CrashlyticsService().logMessage(
        'iap_purchase_stream_error platform=$platform: $m',
      ),
    );
  }

  /// Store reported [PurchaseStatus.error] for a product.
  static Future<void> logPurchaseFailed({
    required String platform,
    required String productId,
    String? message,
  }) async {
    final String m = message != null ? _clip(message) : '';
    AppLogger.warning(
      'iap_purchase_failed platform=$platform productId=$productId${m.isEmpty ? '' : ' $m'}',
    );
    final Map<String, Object> params = {
      'platform': _clip(platform),
      'product_id': _clip(productId),
    };
    if (m.isNotEmpty) {
      params['message'] = m;
    }
    await _safeLogEvent('iap_purchase_failed', params);
    unawaited(
      CrashlyticsService().logMessage(
        'iap_purchase_failed platform=$platform productId=$productId${m.isEmpty ? '' : ' $m'}',
      ),
    );
  }
}
