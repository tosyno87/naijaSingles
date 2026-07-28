import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naijasingles/services/profile_boost_purchase_service.dart';
import 'package:naijasingles/services/profile_boost_service.dart';

class _MockBoostService extends Mock implements ProfileBoostService {}

class _MockIap extends Mock implements InAppPurchase {}

class _MockFirestore extends Mock implements FirebaseFirestore {}

void main() {
  const boostId = 'com.afropeep.boost.1h';

  PurchaseDetails details({
    required PurchaseStatus status,
    String productId = boostId,
    bool pendingComplete = false,
  }) {
    return PurchaseDetails(
      productID: productId,
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

    test('activates restored while user buy is in flight', () {
      expect(
        ProfileBoostPurchaseService.shouldActivateFromPurchase(
          details(status: PurchaseStatus.restored),
          awaitingUserPurchase: true,
        ),
        isTrue,
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

  group('resolveBoostProductId', () {
    test('falls back to legacy id when iosProductId is empty', () {
      expect(
        ProfileBoostPurchaseService.resolveBoostProductId(
          {
            'id': boostId,
            'iosProductId': '',
            'androidProductId': '',
          },
          platform: TargetPlatform.iOS,
        ),
        boostId,
      );
    });

    test('prefers non-empty iosProductId over legacy id', () {
      expect(
        ProfileBoostPurchaseService.resolveBoostProductId(
          {
            'id': 'legacy.boost',
            'iosProductId': boostId,
          },
          platform: TargetPlatform.iOS,
        ),
        boostId,
      );
    });

    test('falls back to legacy id when androidProductId is empty', () {
      expect(
        ProfileBoostPurchaseService.resolveBoostProductId(
          {
            'id': boostId,
            'androidProductId': '   ',
          },
          platform: TargetPlatform.android,
        ),
        boostId,
      );
    });

    test('reads storeIds.ios when present', () {
      expect(
        ProfileBoostPurchaseService.resolveBoostProductId(
          {
            'id': 'legacy.boost',
            'iosProductId': '',
            'storeIds': {'ios': boostId},
          },
          platform: TargetPlatform.iOS,
        ),
        boostId,
      );
    });
  });

  group('handlePurchaseUpdate', () {
    late _MockBoostService boostService;
    late _MockIap iap;
    late ProfileBoostPurchaseService service;

    setUp(() {
      boostService = _MockBoostService();
      iap = _MockIap();
      service = ProfileBoostPurchaseService(
        iap: iap,
        boostService: boostService,
        firestore: _MockFirestore(),
        boostProductIds: () async => [boostId],
      );
      when(
        () => boostService.activateBoost(
          userId: any(named: 'userId'),
          productId: any(named: 'productId'),
        ),
      ).thenAnswer((_) async {});
      when(() => iap.completePurchase(any())).thenAnswer((_) async {});
    });

    setUpAll(() {
      registerFallbackValue(details(status: PurchaseStatus.purchased));
    });

    test('canceled boost clears purchasing via onCanceled', () async {
      var canceled = false;
      var activated = false;
      var errored = false;

      await service.handlePurchaseUpdate(
        purchase: details(status: PurchaseStatus.canceled),
        userId: 'user-1',
        onActivated: () => activated = true,
        onCanceled: () => canceled = true,
        onError: (_) => errored = true,
      );

      expect(canceled, isTrue);
      expect(activated, isFalse);
      expect(errored, isFalse);
      verifyNever(
        () => boostService.activateBoost(
          userId: any(named: 'userId'),
          productId: any(named: 'productId'),
        ),
      );
    });

    test('ignores canceled non-boost products', () async {
      var canceled = false;

      await service.handlePurchaseUpdate(
        purchase: details(
          status: PurchaseStatus.canceled,
          productId: 'com.afropeep.premium.monthly',
        ),
        userId: 'user-1',
        onActivated: () {},
        onCanceled: () => canceled = true,
      );

      expect(canceled, isFalse);
    });

    test('activation failure reports onError instead of hanging', () async {
      when(
        () => boostService.activateBoost(
          userId: any(named: 'userId'),
          productId: any(named: 'productId'),
        ),
      ).thenThrow(Exception('permission-denied'));

      String? error;
      await service.handlePurchaseUpdate(
        purchase: details(status: PurchaseStatus.purchased),
        userId: 'user-1',
        onActivated: () {},
        onError: (message) => error = message,
      );

      expect(error, 'Could not activate boost. Please try again.');
    });

    test('successful purchase activates boost', () async {
      var activated = false;

      await service.handlePurchaseUpdate(
        purchase: details(status: PurchaseStatus.purchased),
        userId: 'user-1',
        onActivated: () => activated = true,
      );

      expect(activated, isTrue);
      verify(
        () => boostService.activateBoost(
          userId: 'user-1',
          productId: boostId,
        ),
      ).called(1);
    });

    test('in-flight buy activates restored with pendingComplete false',
        () async {
      var activated = false;
      service.debugSetAwaitingBoostProductId(boostId);

      await service.handlePurchaseUpdate(
        purchase: details(status: PurchaseStatus.restored),
        userId: 'user-1',
        onActivated: () => activated = true,
      );

      expect(activated, isTrue);
      verify(
        () => boostService.activateBoost(
          userId: 'user-1',
          productId: boostId,
        ),
      ).called(1);
    });

    test('cold-start restored without in-flight buy does not activate',
        () async {
      var activated = false;

      await service.handlePurchaseUpdate(
        purchase: details(status: PurchaseStatus.restored),
        userId: 'user-1',
        onActivated: () => activated = true,
      );

      expect(activated, isFalse);
      verifyNever(
        () => boostService.activateBoost(
          userId: any(named: 'userId'),
          productId: any(named: 'productId'),
        ),
      );
    });
  });

  group('buyBoost awaiting marker', () {
    late _MockBoostService boostService;
    late _MockIap iap;
    late ProfileBoostPurchaseService service;

    ProductDetails product() => ProductDetails(
          id: boostId,
          title: 'Boost',
          description: '1 hour',
          price: '\$4.99',
          rawPrice: 4.99,
          currencyCode: 'USD',
        );

    setUpAll(() {
      registerFallbackValue(PurchaseParam(productDetails: product()));
      registerFallbackValue(details(status: PurchaseStatus.purchased));
    });

    setUp(() {
      boostService = _MockBoostService();
      iap = _MockIap();
      service = ProfileBoostPurchaseService(
        iap: iap,
        boostService: boostService,
        firestore: _MockFirestore(),
        boostProductIds: () async => [boostId],
      );
      when(
        () => boostService.activateBoost(
          userId: any(named: 'userId'),
          productId: any(named: 'productId'),
        ),
      ).thenAnswer((_) async {});
    });

    test('clears awaiting marker when buyConsumable returns false', () async {
      when(
        () => iap.buyConsumable(purchaseParam: any(named: 'purchaseParam')),
      ).thenAnswer((_) async => false);

      await expectLater(service.buyBoost(product()), throwsStateError);

      var activated = false;
      await service.handlePurchaseUpdate(
        purchase: details(status: PurchaseStatus.restored),
        userId: 'user-1',
        onActivated: () => activated = true,
      );
      expect(activated, isFalse);
    });

    test('clears awaiting marker when buyConsumable throws', () async {
      when(
        () => iap.buyConsumable(purchaseParam: any(named: 'purchaseParam')),
      ).thenThrow(Exception('store unavailable'));

      await expectLater(service.buyBoost(product()), throwsException);

      var activated = false;
      await service.handlePurchaseUpdate(
        purchase: details(status: PurchaseStatus.restored),
        userId: 'user-1',
        onActivated: () => activated = true,
      );
      expect(activated, isFalse);
    });

    test('clearAwaitingBoostPurchase blocks later restored activation',
        () async {
      service.debugSetAwaitingBoostProductId(boostId);
      service.clearAwaitingBoostPurchase();

      var activated = false;
      await service.handlePurchaseUpdate(
        purchase: details(status: PurchaseStatus.restored),
        userId: 'user-1',
        onActivated: () => activated = true,
      );
      expect(activated, isFalse);
    });

    test('expired awaiting marker does not activate restored purchase',
        () async {
      service.debugSetAwaitingBoostProductId(
        boostId,
        startedAt: DateTime.now().subtract(
          ProfileBoostPurchaseService.awaitingBoostTtl +
              const Duration(seconds: 1),
        ),
      );

      var activated = false;
      await service.handlePurchaseUpdate(
        purchase: details(status: PurchaseStatus.restored),
        userId: 'user-1',
        onActivated: () => activated = true,
      );
      expect(activated, isFalse);
    });
  });
}
