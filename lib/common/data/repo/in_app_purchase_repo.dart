import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

import '../../../features/home/ui/tab/tabbar.dart';
import '../../../features/payment/ios_payment_queue_delegate.dart';
import '../../../features/payment/ui/products.dart';
import '../../../models/user_model.dart';
import '../../constants/constants.dart';

abstract class InAppPurchaseRepo {
  Future<List<ProductDetails>> getProductsDetailsById();
  Future<void> buyConsumable({required ProductDetails productDetails});
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
      // Paywall must only show distinct subscription periods (not boost
      // consumables or duplicate monthly SKUs that share the same price).
      final List<ProductDetails> plans =
          selectSubscriptionPlans(response.productDetails);
      if (plans.isEmpty) {
        log(
          '[IAP] Store returned ${response.productDetails.length} product(s) '
          'but none looked like subscription plans. ids='
          '${response.productDetails.map((p) => p.id).join(", ")}',
        );
        throw Exception('No subscription plans available');
      }
      return plans;
    } on Object {
      rethrow;
    }
  }

  /// Keeps one product per billing period (week / month / year), drops boost
  /// consumables and unlabeled SKUs, and sorts week → month → year.
  ///
  /// Exposed for unit tests; [intervalOf] defaults to store period with
  /// product-id fallback.
  static List<ProductDetails> selectSubscriptionPlans(
    List<ProductDetails> products, {
    String Function(ProductDetails product)? intervalOf,
  }) {
    final String Function(ProductDetails) resolve =
        intervalOf ?? _defaultIntervalKey;
    final Map<String, ProductDetails> byInterval = <String, ProductDetails>{};

    for (final ProductDetails product in products) {
      if (isBoostProductId(product.id)) {
        log('[IAP] Skipping boost product on paywall: ${product.id}');
        continue;
      }
      final String interval = resolve(product);
      if (interval.isEmpty) {
        log(
          '[IAP] Skipping unlabeled / non-subscription product: ${product.id}',
        );
        continue;
      }
      final ProductDetails? existing = byInterval[interval];
      if (existing == null || _preferSubscriptionSku(product, existing)) {
        if (existing != null) {
          log(
            '[IAP] Duplicate $interval plan; keeping ${product.id} '
            'over ${existing.id}',
          );
        }
        byInterval[interval] = product;
      }
    }

    const List<String> order = <String>['week', 'month', 'year'];
    return <ProductDetails>[
      for (final String key in order)
        if (byInterval.containsKey(key)) byInterval[key]!,
    ];
  }

  /// True for profile-boost consumable product IDs.
  static bool isBoostProductId(String productId) =>
      productId.toLowerCase().contains('boost');

  /// Prefer canonical `*.premium.{period}` IDs over legacy / ambiguous ones.
  static bool _preferSubscriptionSku(
    ProductDetails candidate,
    ProductDetails incumbent,
  ) {
    final int candidateScore = _subscriptionSkuScore(candidate.id);
    final int incumbentScore = _subscriptionSkuScore(incumbent.id);
    if (candidateScore != incumbentScore) {
      return candidateScore > incumbentScore;
    }
    // Stable tie-break: shorter / lexicographically smaller id.
    return candidate.id.compareTo(incumbent.id) < 0;
  }

  static int _subscriptionSkuScore(String productId) {
    final String id = productId.toLowerCase();
    int score = 0;
    if (id.contains('premium')) score += 2;
    if (id.contains('afropeep')) score += 1;
    if (id.contains('monthly') ||
        id.contains('yearly') ||
        id.contains('weekly') ||
        id.contains('annual')) {
      score += 2;
    }
    return score;
  }

  static String _defaultIntervalKey(ProductDetails product) {
    try {
      final InAppPurchaseRepoImpl repo = InAppPurchaseRepoImpl();
      final String fromStore = product is AppStoreProductDetails
          ? repo.getInterval(product)
          : product is GooglePlayProductDetails
              ? repo.getIntervalAndroid(product)
              : '';
      final String normalized = normalizeBillingInterval(fromStore);
      if (normalized.isNotEmpty) return normalized;
    } on Object catch (e) {
      log('[IAP] Could not read store billing period for ${product.id}: $e');
    }
    return intervalKeyFromProductId(product.id);
  }

  /// Maps store / id strings to `week` | `month` | `year` | ``.
  static String normalizeBillingInterval(String raw) {
    final String lower = raw.toLowerCase();
    if (lower.contains('year') || lower.contains('annual')) return 'year';
    if (lower.contains('month')) return 'month';
    if (lower.contains('week')) return 'week';
    return '';
  }

  static String intervalKeyFromProductId(String productId) =>
      normalizeBillingInterval(productId);

  static bool _iosPaymentQueueDelegateSet = false;

  /// Ensures the iOS payment-queue delegate is registered once per process.
  static Future<void> ensureIosPaymentQueueDelegate() async {
    if (!_isIOS || _iosPaymentQueueDelegateSet) return;
    try {
      final InAppPurchaseStoreKitPlatformAddition iosAddition =
          inApp.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosAddition.setDelegate(AfropeepPaymentQueueDelegate());
      _iosPaymentQueueDelegateSet = true;
    } on Object catch (e) {
      log('[IAP] Failed to set StoreKit payment queue delegate: $e');
    }
  }

  PurchaseParam _purchaseParamFor(ProductDetails productDetails) {
    if (productDetails is GooglePlayProductDetails) {
      final String? offerToken = productDetails.offerToken;
      // Billing 5+ requires an offer token for subscriptions.
      return GooglePlayPurchaseParam(
        productDetails: productDetails,
        offerToken: offerToken,
      );
    }
    return PurchaseParam(productDetails: productDetails);
  }

  @override
  Future<void> buyConsumable({required ProductDetails productDetails}) async {
    final bool available = await inApp.isAvailable();
    if (!available) {
      throw StateError('Store is not available on this device.');
    }

    await ensureIosPaymentQueueDelegate();

    final PurchaseParam purchaseParam = _purchaseParamFor(productDetails);
    log('[IAP] Starting purchase for ${productDetails.id}');

    final bool started = await inApp.buyNonConsumable(
      purchaseParam: purchaseParam,
    );
    if (!started) {
      // Plugin returns false when another purchase is pending / sheet not shown.
      throw StateError(
        'Purchase could not be started. Wait a moment and try again, '
        'or restore purchases from Account Settings.',
      );
    }
    log('[IAP] Purchase sheet presented for ${productDetails.id}');
  }

  /// Fetches store product IDs from `Packages` (platform-specific when set).
  ///
  /// Excludes `packageType: boost` consumables — those belong on the profile
  /// boost flow, not the Premium subscription paywall.
  Future<List<String>> _fetchPackageIds() async {
    final value = await firebaseFireStoreInstance
        .collection('Packages')
        .where('status', isEqualTo: true)
        .get();

    final ids = <String>{};
    for (final doc in value.docs) {
      final data = doc.data();
      final packageType =
          data['packageType']?.toString().toLowerCase().trim() ?? '';
      if (packageType == 'boost') {
        continue;
      }
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
        if (id != null && id.isNotEmpty && !isBoostProductId(id)) {
          ids.add(id);
        }
      } else if (_isAndroid) {
        final id = forPlatform ?? android ?? legacy;
        if (id != null && id.isNotEmpty && !isBoostProductId(id)) {
          ids.add(id);
        }
      } else {
        if (legacy != null && legacy.isNotEmpty && !isBoostProductId(legacy)) {
          ids.add(legacy);
        }
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
    if (product is! AppStoreProductDetails) {
      return '';
    }
    final SKProductSubscriptionPeriodWrapper? period =
        product.skProduct.subscriptionPeriod;
    if (period == null) {
      // Consumables (e.g. boost) have no subscription period.
      return '';
    }
    final SKSubscriptionPeriodUnit periodUnit = period.unit;
    if (SKSubscriptionPeriodUnit.month == periodUnit) {
      return 'Month(s)';
    } else if (SKSubscriptionPeriodUnit.week == periodUnit) {
      return 'Week(s)';
    } else {
      return 'Year';
    }
  }

  String getIntervalAndroid(ProductDetails product) {
    if (product is! GooglePlayProductDetails) {
      return '';
    }
    final String? billingPeriod = product.productDetails
        .subscriptionOfferDetails?.first.pricingPhases.first.billingPeriod;
    if (billingPeriod == null) {
      return '';
    }
    final String period = billingPeriod.trim();
    if (period.isEmpty) {
      return '';
    }
    // ISO-8601 style: P1M / P1Y / P1W (and legacy single-letter tokens).
    if (period.contains('M')) {
      return 'Month(s)';
    }
    if (period.contains('Y')) {
      return 'Year';
    }
    if (period.contains('W')) {
      return 'Week(s)';
    }
    return '';
  }
}
