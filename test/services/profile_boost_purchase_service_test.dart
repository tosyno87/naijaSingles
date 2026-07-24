import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:naijasingles/services/profile_boost_purchase_service.dart';

void main() {
  PurchaseDetails details({
    required PurchaseStatus status,
    bool pendingComplete = false,
  }) {
    return PurchaseDetails(
      productID: 'com.afropeep.boost.1h',
      purchaseID: 'test',
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: '',
        source: 'test',
      ),
      transactionDate: null,
      status: status,
    )..pendingCompletePurchase = pendingComplete;
  }

  group('shouldActivateFromPurchase', () {
    test('activates on purchased', () {
      expect(
        ProfileBoostPurchaseService.shouldActivateFromPurchase(
          details(status: PurchaseStatus.purchased),
        ),
        isTrue,
      );
    });

    test('skips completed restored consumables (no free re-boost)', () {
      expect(
        ProfileBoostPurchaseService.shouldActivateFromPurchase(
          details(status: PurchaseStatus.restored),
        ),
        isFalse,
      );
    });

    test('activates unfinished restored that still need completePurchase', () {
      expect(
        ProfileBoostPurchaseService.shouldActivateFromPurchase(
          details(
            status: PurchaseStatus.restored,
            pendingComplete: true,
          ),
        ),
        isTrue,
      );
    });
  });
}
