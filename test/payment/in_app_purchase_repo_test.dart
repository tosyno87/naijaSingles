import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naijasingles/common/data/repo/in_app_purchase_repo.dart';

// Mocks for iOS StoreKit types
class MockAppStoreProductDetails extends Mock
    implements AppStoreProductDetails {}

class MockSKProductWrapper extends Mock implements SKProductWrapper {}

// Mocks for Android Google Play Billing types
class MockGooglePlayProductDetails extends Mock
    implements GooglePlayProductDetails {}

class MockProductDetailsWrapper extends Mock implements ProductDetailsWrapper {}

class MockSubscriptionOfferDetailsWrapper extends Mock
    implements SubscriptionOfferDetailsWrapper {}

class MockPricingPhaseWrapper extends Mock implements PricingPhaseWrapper {}

PurchaseDetails _makePurchase(String productId) => PurchaseDetails(
      productID: productId,
      purchaseID: productId,
      verificationData: PurchaseVerificationData(
        localVerificationData: 'local',
        serverVerificationData: 'server',
        source: 'test',
      ),
      transactionDate: '0',
      status: PurchaseStatus.purchased,
    );

void main() {
  // ---------------------------------------------------------------------------
  // hasPurchased
  // ---------------------------------------------------------------------------
  group('InAppPurchaseRepoImpl.hasPurchased', () {
    test('returns the matching purchase', () {
      final purchase1 = _makePurchase('id1');
      final purchase2 = _makePurchase('id2');

      final result =
          InAppPurchaseRepoImpl.hasPurchased('id2', [purchase1, purchase2]);

      expect(result.productID, 'id2');
    });

    test('returns the first match when duplicates exist', () {
      final p1 = _makePurchase('dup');
      final p2 = _makePurchase('dup');

      final result = InAppPurchaseRepoImpl.hasPurchased('dup', [p1, p2]);

      expect(identical(result, p1), isTrue);
    });

    test('throws StateError when product is not in the list', () {
      final purchase = _makePurchase('id1');

      expect(
        () => InAppPurchaseRepoImpl.hasPurchased('missing', [purchase]),
        throwsStateError,
      );
    });

    test('throws StateError when purchases list is empty', () {
      expect(
        () => InAppPurchaseRepoImpl.hasPurchased('any', []),
        throwsStateError,
      );
    });

    test('returns the only purchase when list has a single matching item', () {
      final purchase = _makePurchase('solo');

      final result = InAppPurchaseRepoImpl.hasPurchased('solo', [purchase]);

      expect(identical(result, purchase), isTrue);
      expect(result.productID, 'solo');
    });

    test('returned purchase preserves its original status', () {
      final purchase = _makePurchase('premium');

      final result = InAppPurchaseRepoImpl.hasPurchased('premium', [purchase]);

      expect(result.status, PurchaseStatus.purchased);
    });

    test('throws StateError with descriptive message for missing product', () {
      final purchases = [_makePurchase('id1'), _makePurchase('id2')];

      expect(
        () => InAppPurchaseRepoImpl.hasPurchased('nonexistent', purchases),
        throwsA(isA<StateError>()),
      );
    });

    test('product ID matching is case-sensitive', () {
      final purchase = _makePurchase('Premium_Monthly');

      expect(
        () => InAppPurchaseRepoImpl.hasPurchased('premium_monthly', [purchase]),
        throwsStateError,
      );
    });

    test('finds match at the end of a large list', () {
      final purchases = [
        _makePurchase('a'),
        _makePurchase('b'),
        _makePurchase('c'),
        _makePurchase('d'),
        _makePurchase('target'),
      ];

      final result = InAppPurchaseRepoImpl.hasPurchased('target', purchases);

      expect(result.productID, 'target');
      expect(identical(result, purchases.last), isTrue);
    });

    test('finds match at the beginning of a large list', () {
      final purchases = [
        _makePurchase('first'),
        _makePurchase('b'),
        _makePurchase('c'),
        _makePurchase('d'),
        _makePurchase('e'),
      ];

      final result = InAppPurchaseRepoImpl.hasPurchased('first', purchases);

      expect(result.productID, 'first');
      expect(identical(result, purchases.first), isTrue);
    });

    test('returned purchase preserves pending status', () {
      final purchase = PurchaseDetails(
        productID: 'pending_item',
        purchaseID: 'pending_item',
        verificationData: PurchaseVerificationData(
          localVerificationData: 'local',
          serverVerificationData: 'server',
          source: 'test',
        ),
        transactionDate: '0',
        status: PurchaseStatus.pending,
      );

      final result =
          InAppPurchaseRepoImpl.hasPurchased('pending_item', [purchase]);

      expect(result.status, PurchaseStatus.pending);
    });

    test('returned purchase preserves error status', () {
      final purchase = PurchaseDetails(
        productID: 'error_item',
        purchaseID: 'error_item',
        verificationData: PurchaseVerificationData(
          localVerificationData: 'local',
          serverVerificationData: 'server',
          source: 'test',
        ),
        transactionDate: '0',
        status: PurchaseStatus.error,
      );

      final result =
          InAppPurchaseRepoImpl.hasPurchased('error_item', [purchase]);

      expect(result.status, PurchaseStatus.error);
    });

    test('returned purchase preserves restored status', () {
      final purchase = PurchaseDetails(
        productID: 'restored_item',
        purchaseID: 'restored_item',
        verificationData: PurchaseVerificationData(
          localVerificationData: 'local',
          serverVerificationData: 'server',
          source: 'test',
        ),
        transactionDate: '0',
        status: PurchaseStatus.restored,
      );

      final result =
          InAppPurchaseRepoImpl.hasPurchased('restored_item', [purchase]);

      expect(result.status, PurchaseStatus.restored);
    });
  });

  // ---------------------------------------------------------------------------
  // getInterval (iOS / StoreKit)
  // ---------------------------------------------------------------------------
  group('InAppPurchaseRepoImpl.getInterval', () {
    late InAppPurchaseRepoImpl repo;
    late MockAppStoreProductDetails mockProduct;
    late MockSKProductWrapper mockSKProduct;

    setUp(() {
      repo = InAppPurchaseRepoImpl();
      mockProduct = MockAppStoreProductDetails();
      mockSKProduct = MockSKProductWrapper();
      when(() => mockProduct.skProduct).thenReturn(mockSKProduct);
    });

    test('returns "Month(s)" for monthly subscription', () {
      when(() => mockSKProduct.subscriptionPeriod).thenReturn(
        SKProductSubscriptionPeriodWrapper(
          numberOfUnits: 1,
          unit: SKSubscriptionPeriodUnit.month,
        ),
      );

      expect(repo.getInterval(mockProduct), 'Month(s)');
    });

    test('returns "Week(s)" for weekly subscription', () {
      when(() => mockSKProduct.subscriptionPeriod).thenReturn(
        SKProductSubscriptionPeriodWrapper(
          numberOfUnits: 1,
          unit: SKSubscriptionPeriodUnit.week,
        ),
      );

      expect(repo.getInterval(mockProduct), 'Week(s)');
    });

    test('returns "Year" for yearly subscription', () {
      when(() => mockSKProduct.subscriptionPeriod).thenReturn(
        SKProductSubscriptionPeriodWrapper(
          numberOfUnits: 1,
          unit: SKSubscriptionPeriodUnit.year,
        ),
      );

      expect(repo.getInterval(mockProduct), 'Year');
    });

    test('returns "Year" for day period (falls into else branch)', () {
      when(() => mockSKProduct.subscriptionPeriod).thenReturn(
        SKProductSubscriptionPeriodWrapper(
          numberOfUnits: 1,
          unit: SKSubscriptionPeriodUnit.day,
        ),
      );

      expect(repo.getInterval(mockProduct), 'Year');
    });

    test('returns correct interval regardless of numberOfUnits value', () {
      when(() => mockSKProduct.subscriptionPeriod).thenReturn(
        SKProductSubscriptionPeriodWrapper(
          numberOfUnits: 6,
          unit: SKSubscriptionPeriodUnit.month,
        ),
      );

      expect(repo.getInterval(mockProduct), 'Month(s)');
    });

    test('throws when subscriptionPeriod is null', () {
      when(() => mockSKProduct.subscriptionPeriod).thenReturn(null);

      expect(
        () => repo.getInterval(mockProduct),
        throwsA(isA<TypeError>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // getIntervalAndroid (Google Play Billing)
  // ---------------------------------------------------------------------------
  group('InAppPurchaseRepoImpl.getIntervalAndroid', () {
    late InAppPurchaseRepoImpl repo;
    late MockGooglePlayProductDetails mockProduct;
    late MockProductDetailsWrapper mockPDW;
    late MockSubscriptionOfferDetailsWrapper mockSODW;
    late MockPricingPhaseWrapper mockPPW;

    setUp(() {
      repo = InAppPurchaseRepoImpl();
      mockProduct = MockGooglePlayProductDetails();
      mockPDW = MockProductDetailsWrapper();
      mockSODW = MockSubscriptionOfferDetailsWrapper();
      mockPPW = MockPricingPhaseWrapper();

      when(() => mockProduct.productDetails).thenReturn(mockPDW);
      when(() => mockPDW.subscriptionOfferDetails).thenReturn([mockSODW]);
      when(() => mockSODW.pricingPhases).thenReturn([mockPPW]);
    });

    test('returns "Month(s)" for billing period "M"', () {
      when(() => mockPPW.billingPeriod).thenReturn('M');

      expect(repo.getIntervalAndroid(mockProduct), 'Month(s)');
    });

    test('returns "Month(s)" for billing period "m"', () {
      when(() => mockPPW.billingPeriod).thenReturn('m');

      expect(repo.getIntervalAndroid(mockProduct), 'Month(s)');
    });

    test('returns "Year" for billing period "Y"', () {
      when(() => mockPPW.billingPeriod).thenReturn('Y');

      expect(repo.getIntervalAndroid(mockProduct), 'Year');
    });

    test('returns "Year" for billing period "y"', () {
      when(() => mockPPW.billingPeriod).thenReturn('y');

      expect(repo.getIntervalAndroid(mockProduct), 'Year');
    });

    test('returns "Week(s)" for unrecognised billing period', () {
      when(() => mockPPW.billingPeriod).thenReturn('W');

      expect(repo.getIntervalAndroid(mockProduct), 'Week(s)');
    });

    test('returns "Week(s)" when subscriptionOfferDetails is null', () {
      when(() => mockPDW.subscriptionOfferDetails).thenReturn(null);

      expect(repo.getIntervalAndroid(mockProduct), 'Week(s)');
    });

    test('returns "Week(s)" for empty billingPeriod string', () {
      when(() => mockPPW.billingPeriod).thenReturn('');

      expect(repo.getIntervalAndroid(mockProduct), 'Week(s)');
    });

    test('returns "Week(s)" for unrecognised period string "D"', () {
      when(() => mockPPW.billingPeriod).thenReturn('D');

      expect(repo.getIntervalAndroid(mockProduct), 'Week(s)');
    });

    test('returns "Month(s)" for period "M" regardless of case', () {
      for (final period in ['M', 'm']) {
        when(() => mockPPW.billingPeriod).thenReturn(period);
        expect(repo.getIntervalAndroid(mockProduct), 'Month(s)');
      }
    });

    test('returns "Year" for period "Y" regardless of case', () {
      for (final period in ['Y', 'y']) {
        when(() => mockPPW.billingPeriod).thenReturn(period);
        expect(repo.getIntervalAndroid(mockProduct), 'Year');
      }
    });

    test('returns "Week(s)" for ISO 8601 duration "P1M" (not single char)', () {
      when(() => mockPPW.billingPeriod).thenReturn('P1M');

      expect(repo.getIntervalAndroid(mockProduct), 'Week(s)');
    });

    test('returns "Week(s)" for ISO 8601 duration "P1Y"', () {
      when(() => mockPPW.billingPeriod).thenReturn('P1Y');

      expect(repo.getIntervalAndroid(mockProduct), 'Week(s)');
    });

    test('returns "Week(s)" for whitespace-only billingPeriod', () {
      when(() => mockPPW.billingPeriod).thenReturn(' ');

      expect(repo.getIntervalAndroid(mockProduct), 'Week(s)');
    });
  });

  // ---------------------------------------------------------------------------
  // Repo instantiation
  // ---------------------------------------------------------------------------
  group('InAppPurchaseRepoImpl instantiation', () {
    test('can be instantiated', () {
      expect(InAppPurchaseRepoImpl(), isA<InAppPurchaseRepoImpl>());
    });

    test('implements InAppPurchaseRepo', () {
      expect(InAppPurchaseRepoImpl(), isA<InAppPurchaseRepo>());
    });
  });
}
