import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, visibleForTesting;
import 'package:in_app_purchase/in_app_purchase.dart';

import '../common/constants/constants.dart';
import 'profile_boost_service.dart';

/// Purchases profile boost consumables and activates boost on success.
class ProfileBoostPurchaseService {
  ProfileBoostPurchaseService({
    InAppPurchase? iap,
    ProfileBoostService? boostService,
    FirebaseFirestore? firestore,
    Future<List<String>> Function()? boostProductIds,
  })  : _iap = iap ?? InAppPurchase.instance,
        _boostService = boostService ?? ProfileBoostService(),
        _firestore = firestore ?? firebaseFireStoreInstance,
        _boostProductIdsOverride = boostProductIds;

  final InAppPurchase _iap;
  final ProfileBoostService _boostService;
  final FirebaseFirestore _firestore;
  final Future<List<String>> Function()? _boostProductIdsOverride;

  /// Product ID for an in-flight [buyBoost] call.
  ///
  /// StoreKit (esp. sandbox) often emits `restored` + `pendingComplete=false`
  /// for a user-initiated consumable buy. We only activate those while this is set,
  /// so cold-start restore replays still do not re-grant boost.
  String? _awaitingBoostProductId;

  static const String _packageTypeBoost = 'boost';

  /// Picks a non-empty store SKU from a Packages doc for [platform].
  ///
  /// Empty `iosProductId` / `androidProductId` must not block a valid legacy
  /// `id` — Firestore often stores `""` for the unused platform field.
  @visibleForTesting
  static String? resolveBoostProductId(
    Map<String, dynamic> data, {
    required TargetPlatform platform,
  }) {
    String? nonEmpty(Object? raw) {
      final value = raw?.toString().trim();
      if (value == null || value.isEmpty) return null;
      return value;
    }

    final legacy = nonEmpty(data['id']);
    final ios = nonEmpty(data['iosProductId']);
    final android = nonEmpty(data['androidProductId']);

    String? fromStoreIds;
    final storeIds = data['storeIds'];
    if (storeIds is Map) {
      if (platform == TargetPlatform.iOS) {
        fromStoreIds = nonEmpty(storeIds['ios']) ?? nonEmpty(storeIds['apple']);
      } else if (platform == TargetPlatform.android) {
        fromStoreIds =
            nonEmpty(storeIds['android']) ?? nonEmpty(storeIds['play']);
      }
    }

    if (platform == TargetPlatform.iOS) {
      return fromStoreIds ?? ios ?? legacy;
    }
    if (platform == TargetPlatform.android) {
      return fromStoreIds ?? android ?? legacy;
    }
    return legacy;
  }

  /// Store product IDs for boost packages (`Packages` docs with `packageType: boost`).
  Future<List<String>> fetchBoostProductIds() async {
    final override = _boostProductIdsOverride;
    if (override != null) return override();

    try {
      // Query by status only (same as Premium Packages fetch) so we do not
      // depend on a status+packageType composite index. Filter boost client-side.
      final snap = await _firestore
          .collection('Packages')
          .where('status', isEqualTo: true)
          .get();

      final ids = <String>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final packageType =
            data['packageType']?.toString().toLowerCase().trim() ?? '';
        if (packageType != _packageTypeBoost) continue;

        final id = resolveBoostProductId(
          data,
          platform: defaultTargetPlatform,
        );
        if (id != null) {
          ids.add(id);
        }
      }
      return ids.toList();
    } on Object catch (e) {
      log('ProfileBoostPurchaseService: failed to load boost IDs: $e');
      return [];
    }
  }

  Future<List<ProductDetails>> fetchBoostProducts() async {
    final available = await _iap.isAvailable();
    if (!available) {
      log('ProfileBoostPurchaseService: store not available');
      return [];
    }

    final ids = await fetchBoostProductIds();
    final queryIds = ids.where((id) => id.isNotEmpty).toSet();
    if (queryIds.isEmpty) {
      log(
        'ProfileBoostPurchaseService: no boost product IDs '
        '(Packages docs=${ids.length})',
      );
      return [];
    }

    final response = await _iap.queryProductDetails(queryIds);
    if (response.productDetails.isEmpty) {
      log(
        'ProfileBoostPurchaseService: store returned 0 products for $queryIds '
        '(notFound=${response.notFoundIDs})',
      );
    }
    return response.productDetails;
  }

  /// Whether the platform billing client is reachable.
  Future<bool> isStoreAvailable() => _iap.isAvailable();

  Future<void> buyBoost(ProductDetails product) async {
    _awaitingBoostProductId = product.id;
    final param = PurchaseParam(productDetails: product);
    await _iap.buyConsumable(purchaseParam: param);
  }

  /// Whether a store event should grant a new boost window.
  ///
  /// Consumable restores replay on every launch; only fresh `purchased`,
  /// unfinished restores that still need `completePurchase`, or a `restored`
  /// event that arrives while [awaitingUserPurchase] (in-flight [buyBoost])
  /// should activate.
  @visibleForTesting
  static bool shouldActivateFromPurchase(
    PurchaseDetails purchase, {
    bool awaitingUserPurchase = false,
  }) {
    if (purchase.status == PurchaseStatus.purchased) return true;
    if (purchase.status == PurchaseStatus.restored &&
        purchase.pendingCompletePurchase) {
      return true;
    }
    if (purchase.status == PurchaseStatus.restored && awaitingUserPurchase) {
      return true;
    }
    return false;
  }

  /// Handles one store update for boost (activation, cancel, or error).
  @visibleForTesting
  Future<void> handlePurchaseUpdate({
    required PurchaseDetails purchase,
    required String userId,
    required void Function() onActivated,
    void Function()? onCanceled,
    void Function(String message)? onError,
  }) async {
    try {
      final boostIds = await fetchBoostProductIds();
      final bool awaitingUserPurchase = _awaitingBoostProductId != null &&
          _awaitingBoostProductId == purchase.productID;
      if (!boostIds.contains(purchase.productID)) return;

      if (purchase.status == PurchaseStatus.canceled) {
        _awaitingBoostProductId = null;
        onCanceled?.call();
        return;
      }

      if (purchase.status == PurchaseStatus.error) {
        _awaitingBoostProductId = null;
        onError?.call(
          purchase.error?.message ?? 'Boost purchase failed',
        );
        return;
      }

      if (purchase.status != PurchaseStatus.purchased &&
          purchase.status != PurchaseStatus.restored) {
        return;
      }

      if (!shouldActivateFromPurchase(
        purchase,
        awaitingUserPurchase: awaitingUserPurchase,
      )) {
        return;
      }

      await _boostService.activateBoost(
        userId: userId,
        productId: purchase.productID,
      );

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
      _awaitingBoostProductId = null;
      onActivated();
    } on Object catch (e, st) {
      log(
        'ProfileBoostPurchaseService: boost purchase handling failed: $e',
        stackTrace: st,
      );
      _awaitingBoostProductId = null;
      onError?.call('Could not activate boost. Please try again.');
    }
  }

  /// Test-only: mark an in-flight boost buy (mirrors [buyBoost]).
  @visibleForTesting
  void debugSetAwaitingBoostProductId(String? productId) {
    _awaitingBoostProductId = productId;
  }

  /// Listens for a completed boost purchase and activates boost for [userId].
  ///
  /// [onCanceled] and [onError] are only invoked for boost product IDs so
  /// Premium/other IAP events do not clear the boost CTA spinner.
  StreamSubscription<List<PurchaseDetails>> listenForBoostActivation({
    required String userId,
    required void Function() onActivated,
    void Function()? onCanceled,
    void Function(String message)? onError,
  }) {
    return _iap.purchaseStream.listen((purchases) async {
      for (final purchase in purchases) {
        await handlePurchaseUpdate(
          purchase: purchase,
          userId: userId,
          onActivated: onActivated,
          onCanceled: onCanceled,
          onError: onError,
        );
      }
    });
  }
}
