import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:naijasingles/common/data/repo/in_app_purchase_repo.dart';

void main() {
  group('InAppPurchaseRepoImpl.hasPurchased', () {
    test('returns the matching purchase', () {
      final purchase1 = PurchaseDetails(
        productID: 'id1',
        purchaseID: '1',
        verificationData: PurchaseVerificationData(
          localVerificationData: 'local',
          serverVerificationData: 'server',
          source: 'test',
        ),
        transactionDate: '0',
        status: PurchaseStatus.purchased,
      );
      final purchase2 = PurchaseDetails(
        productID: 'id2',
        purchaseID: '2',
        verificationData: PurchaseVerificationData(
          localVerificationData: 'local',
          serverVerificationData: 'server',
          source: 'test',
        ),
        transactionDate: '0',
        status: PurchaseStatus.purchased,
      );

      final result = InAppPurchaseRepoImpl.hasPurchased('id2', [purchase1, purchase2]);

      expect(result.productID, 'id2');
    });
  });
}
