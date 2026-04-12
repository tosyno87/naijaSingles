import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

import '../../../features/home/ui/tab/tabbar.dart';
import '../../../features/payment/ui/products.dart';
import '../../../models/user_model.dart';
import '../../constants/constants.dart';

abstract class InAppPurchaseRepo {
  Future<List<ProductDetails>> getProductsDetailsById();
  Future buyConsumable({required ProductDetails productDetails});
}

class InAppPurchaseRepoImpl extends InAppPurchaseRepo {
  static final InAppPurchase inApp = InAppPurchase.instance;
  // final bool _kAutoConsume = Platform.isAndroid || true;

  @override
  Future<List<ProductDetails>> getProductsDetailsById() async {
    try {
      final bool isAvailable = await inApp.isAvailable();

      if (!isAvailable) {
        throw Exception('Not available');
      }

      final Set<String> kIds = Set.from(await _fetchPackageIds());
      if (kIds.isEmpty) {
        log(
          '[IAP] No active product IDs from Firestore Packages. '
          'Add docs with status=true and iosProductId/androidProductId (or legacy id).',
        );
        throw Exception('No subscription products configured');
      }
      final ProductDetailsResponse response =
          await InAppPurchase.instance.queryProductDetails(kIds);
      if (response.productDetails.isEmpty) {
        log(
          '[IAP] Store returned no products. notFoundIDs=${response.notFoundIDs}',
        );
        throw Exception(
          'Plans temporarily unavailable. Missing IDs: ${response.notFoundIDs.join(", ")}',
        );
      }
      if (response.notFoundIDs.isNotEmpty) {
        log(
          '[IAP] Partial catalog: found ${response.productDetails.length} products; '
          'store missing: ${response.notFoundIDs}',
        );
      }
      return response.productDetails;
    } on Object {
      rethrow;
    }
  }

  @override
  Future buyConsumable({required ProductDetails productDetails}) async {
    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: productDetails);
    await inApp.buyNonConsumable(purchaseParam: purchaseParam);
    log('=============-----------isPurchaseSuccessfully');
  }

  /// Fetches store product IDs from `Packages` (platform-specific when set).
  Future<List<String>> _fetchPackageIds() async {
    final value = await firebaseFireStoreInstance
        .collection('Packages')
        .where('status', isEqualTo: true)
        .get();

    final ids = <String>{};
    for (final doc in value.docs) {
      final data = doc.data();
      final legacy = data['id']?.toString();
      final ios = data['iosProductId']?.toString();
      final android = data['androidProductId']?.toString();
      final storeIds = data['storeIds'];
      String? forPlatform;
      if (storeIds is Map) {
        if (_isIOS) {
          forPlatform =
              storeIds['ios']?.toString() ?? storeIds['apple']?.toString();
        } else if (_isAndroid) {
          forPlatform =
              storeIds['android']?.toString() ?? storeIds['play']?.toString();
        }
      }
      if (_isIOS) {
        final id = forPlatform ?? ios ?? legacy;
        if (id != null && id.isNotEmpty) ids.add(id);
      } else if (_isAndroid) {
        final id = forPlatform ?? android ?? legacy;
        if (id != null && id.isNotEmpty) ids.add(id);
      } else {
        if (legacy != null && legacy.isNotEmpty) ids.add(legacy);
      }
    }

    if (ids.isEmpty && kDebugMode) {
      log(
        '[IAP] Packages query returned ${value.docs.length} docs but no IDs '
        'for this platform. Check iosProductId / androidProductId / storeIds / id.',
      );
    }
    return ids.toList();
  }

  static bool get _isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Call once after Firebase init to surface misconfiguration in debug logs.
  static Future<void> logPackagesDiagnostics() async {
    try {
      final snap = await firebaseFireStoreInstance
          .collection('Packages')
          .where('status', isEqualTo: true)
          .get();
      if (snap.docs.isEmpty) {
        log(
          '[IAP:diagnostics] No Packages with status=true — paywall will fail until configured.',
        );
        return;
      }
      log(
        '[IAP:diagnostics] Active package docs: ${snap.docs.length} '
        '(platform=${kIsWeb ? "web" : defaultTargetPlatform.name})',
      );
    } on Object catch (e) {
      log('[IAP:diagnostics] Failed to read Packages: $e');
    }
  }

  ///fetch products
  Future<void> getProducts(List<String> productIds) async {
    log('----------${productIds.length}');
    if (productIds.isNotEmpty) {
      // Set<String> ids = Set.from(productIds);
    }
  }

  // static Future<void> _getpastPurchases() async {
  //   log('===past purchses----');
  //   bool isAvailable = await inApp.isAvailable();
  //   if (isAvailable) {
  //     await inApp.restorePurchases();
  //   }
  // }

  /// check if user has pruchased
  static PurchaseDetails hasPurchased(
    String productId,
    List<PurchaseDetails> purchases,
  ) =>
      purchases.firstWhere(
        (purchase) => purchase.productID == productId,
        //orElse: () => null
      );

  ///verifying opurhcase of user
  static Future<void> verifyPuchase(
    String id,
    List<PurchaseDetails> purchases,
    UserModel currentUser,
    Map items,
    BuildContext context,
  ) async {
    final PurchaseDetails purchase = hasPurchased(id, purchases);
    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      log('===***${purchase.productID}');

      // if (Platform.isIOS) {
      await inApp.completePurchase(purchase);
      //}
      if (context.mounted) {
        await Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
            builder: (context) => Tabbar(
              isPaymentSuccess: true,
              currentUserId: purchase.productID,
            ),
          ),
        );
      }
    } else if (purchase.status == PurchaseStatus.error) {
      await Navigator.pushReplacement(
        context,
        CupertinoPageRoute(
          builder: (context) => Products(currentUser, false, items),
        ),
      );
    }
    return;
  }

  String getInterval(ProductDetails product) {
    product as AppStoreProductDetails;
    final SKSubscriptionPeriodUnit periodUnit =
        product.skProduct.subscriptionPeriod!.unit;
    if (SKSubscriptionPeriodUnit.month == periodUnit) {
      return 'Month(s)';
    } else if (SKSubscriptionPeriodUnit.week == periodUnit) {
      return 'Week(s)';
    } else {
      return 'Year';
    }
  }

  String getIntervalAndroid(ProductDetails product) {
    product as GooglePlayProductDetails;
    final String? durCode = product.productDetails.subscriptionOfferDetails
        ?.first.pricingPhases.first.billingPeriod;
    if (durCode == 'M' || durCode == 'm') {
      return 'Month(s)';
    } else if (durCode == 'Y' || durCode == 'y') {
      return 'Year';
    } else {
      return 'Week(s)';
    }
  }
}
