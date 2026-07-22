import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../debug_agent_log.dart';

/// Calls [verifySubscriptionPurchase] to sync entitlements server-side.
class SubscriptionFunctionsService {
  SubscriptionFunctionsService({
    FirebaseFunctions? functions,
  }) : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  /// Returns server message on success; throws [FirebaseFunctionsException] on failure.
  Future<String> verifySubscriptionPurchase({
    required String platform,
    required String productId,
    String? purchaseToken,
    String? receiptData,
    String? packageName,
  }) async {
    final callable = _functions.httpsCallable('verifySubscriptionPurchase');
    try {
      final HttpsCallableResult<dynamic> result = await callable.call({
        'platform': platform,
        'productId': productId,
        if (purchaseToken != null) 'purchaseToken': purchaseToken,
        if (receiptData != null) 'receiptData': receiptData,
        if (packageName != null) 'packageName': packageName,
      });
      final Object? raw = result.data;
      final Map<String, dynamic> data = raw is Map
          ? Map<String, dynamic>.from(raw as Map<Object?, Object?>)
          : <String, dynamic>{};
      final String msg = data['message']?.toString() ?? 'Subscription updated';
      // #region agent log
      agentDebugLog(
        hypothesisId: 'A,D',
        location: 'subscription_functions_service.dart:success',
        message: 'callable_ok',
        data: <String, Object?>{
          'platform': platform,
          'productId': productId,
          'hasMessage': data['message'] != null,
          'msgLen': msg.length,
        },
      );
      // #endregion
      if (kDebugMode) {
        debugPrint('verifySubscriptionPurchase: $msg');
      }
      return msg;
    } on FirebaseFunctionsException catch (e) {
      // #region agent log
      agentDebugLog(
        hypothesisId: 'A,D',
        location: 'subscription_functions_service.dart:firebase_error',
        message: 'callable_firebase_error',
        data: <String, Object?>{
          'code': e.code,
          'message': e.message,
          'details': () {
            final String? d = e.details?.toString();
            if (d == null) return null;
            return d.length > 200 ? d.substring(0, 200) : d;
          }(),
          'platform': platform,
          'productId': productId,
          'receiptLen': receiptData?.length ?? 0,
          'purchaseTokenLen': purchaseToken?.length ?? 0,
        },
      );
      // #endregion
      rethrow;
    } on Object catch (e) {
      // #region agent log
      agentDebugLog(
        hypothesisId: 'A',
        location: 'subscription_functions_service.dart:other_error',
        message: 'callable_other_error',
        data: <String, Object?>{
          'errorType': e.runtimeType.toString(),
          'error': e.toString().length > 300
              ? e.toString().substring(0, 300)
              : e.toString(),
          'platform': platform,
          'productId': productId,
        },
      );
      // #endregion
      rethrow;
    }
  }
}
