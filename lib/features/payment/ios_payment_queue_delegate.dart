import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

/// Minimal StoreKit payment-queue delegate (required on iOS 13+ for some flows).
class AfropeepPaymentQueueDelegate extends SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
    SKPaymentTransactionWrapper transaction,
    SKStorefrontWrapper storefront,
  ) =>
      true;

  @override
  bool shouldShowPriceConsent() => false;
}
