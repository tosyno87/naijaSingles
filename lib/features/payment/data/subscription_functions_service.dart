import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Calls [verifySubscriptionPurchase] to sync entitlements server-side.
class SubscriptionFunctionsService {
  SubscriptionFunctionsService({
    FirebaseFunctions? functions,
  }) : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'us-central1');

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
    if (kDebugMode) {
      debugPrint('verifySubscriptionPurchase: $msg');
    }
    return msg;
  }
}
