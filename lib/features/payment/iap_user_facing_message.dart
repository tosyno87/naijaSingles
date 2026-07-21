import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Short copy for [SnackBar]s; avoids exposing raw [PlatformException] strings.
String userFacingIapStoreErrorMessage(IAPError? error) {
  if (error == null) {
    return 'Purchase could not be completed. Please try again.';
  }
  if (_isUserCanceled(error.code, error.message)) {
    return 'Purchase canceled. No charge was made.';
  }
  return 'Purchase could not be completed. Please try again.';
}

/// Maps any throwable from buy/restore/verify flows to a safe user string.
String userFacingPurchaseThrowableMessage(Object error) {
  if (error is IAPError) {
    return userFacingIapStoreErrorMessage(error);
  }
  if (error is PlatformException) {
    if (_isUserCanceled(error.code, error.message)) {
      return 'Purchase canceled. No charge was made.';
    }
    return 'Purchase could not be completed. Please try again.';
  }
  return userFacingPurchaseFromRawString(error.toString());
}

/// After server verification fails — no raw exception text in UI.
String userFacingSubscriptionVerifyMessage(Object error) {
  final lower = error.toString().toLowerCase();
  if (_rawLooksCanceled(lower)) {
    return 'Purchase canceled. No charge was made.';
  }
  if (error is PlatformException &&
      _isUserCanceled(error.code, error.message)) {
    return 'Purchase canceled. No charge was made.';
  }
  return 'We could not confirm your subscription. Please try again.';
}

String userFacingPurchaseFromRawString(String raw) {
  final lower = raw.toLowerCase();
  if (_rawLooksCanceled(lower)) {
    return 'Purchase canceled. No charge was made.';
  }
  if (lower.contains('could not be started') ||
      lower.contains('store is not available')) {
    return 'Purchase could not be started. Please try again in a moment.';
  }
  if (lower.contains('platformexception')) {
    return 'Purchase could not be completed. Please try again.';
  }
  return 'Purchase could not be completed. Please try again.';
}

bool _isUserCanceled(String code, String? message) {
  final c = code.toLowerCase();
  final m = (message ?? '').toLowerCase();
  if (c.contains('user_cancel') || c.contains('e_user_cancel')) {
    return true;
  }
  // StoreKit 2 plugin (e.g. code `storekit2_purchase_cancelled`).
  if (c.contains('purchase_cancel') ||
      c.contains('storekit2_purchase_cancel')) {
    return true;
  }
  if (m.contains('user canceled') ||
      m.contains('user cancelled') ||
      m.contains('canceled by user') ||
      m.contains('cancelled by user')) {
    return true;
  }
  return false;
}

bool _rawLooksCanceled(String lower) =>
    lower.contains('user_canceled') ||
    lower.contains('user_cancelled') ||
    lower.contains('user canceled') ||
    lower.contains('purchase_canceled') ||
    lower.contains('purchase canceled') ||
    lower.contains('purchase_cancelled') ||
    lower.contains('storekit2_purchase_cancel') ||
    (lower.contains('billingresponse') && lower.contains('canceled')) ||
    (lower.contains('skerror') && lower.contains('cancel'));

/// When [msg] may still be a raw plugin string, map to safe copy; otherwise return [msg].
String userFacingPurchaseSnackBarMessage(
  String? msg, {
  required String fallback,
}) {
  final String? t = msg?.trim();
  if (t == null || t.isEmpty) return fallback;
  final String lower = t.toLowerCase();
  if (_rawLooksCanceled(lower) ||
      lower.contains('platformexception') ||
      lower.contains('fluttermethodchannel') ||
      lower.contains('storekit2_purchase')) {
    return userFacingPurchaseFromRawString(t);
  }
  return t;
}
