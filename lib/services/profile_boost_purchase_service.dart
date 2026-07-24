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
  })  : _iap = iap ?? InAppPurchase.instance,
        _boostService = boostService ?? ProfileBoostService(),
        _firestore = firestore ?? firebaseFireStoreInstance;

  final InAppPurchase _iap;
  final ProfileBoostService _boostService;
  final FirebaseFirestore _firestore;

  static const String _packageTypeBoost = 'boost';

  /// Store product IDs for boost packages (`Packages` docs with `packageType: boost`).
  Future<List<String>> fetchBoostProductIds() async {
    try {
      final snap = await _firestore
          .collection('Packages')
          .where('status', isEqualTo: true)
          .where('packageType', isEqualTo: _packageTypeBoost)
          .get();

      final ids = <String>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final legacy = data['id']?.toString();
        final ios = data['iosProductId']?.toString();
        final android = data['androidProductId']?.toString();
        if (defaultTargetPlatform == TargetPlatform.iOS && ios != null) {
          ids.add(ios);
        } else if (defaultTargetPlatform == TargetPlatform.android &&
            android != null) {
          ids.add(android);
        } else if (legacy != null && legacy.isNotEmpty) {
          ids.add(legacy);
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
    if (!available) return [];

    final ids = await fetchBoostProductIds();
    if (ids.isEmpty) return [];

    final response = await _iap.queryProductDetails(ids.toSet());
    return response.productDetails;
  }

  Future<void> buyBoost(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    await _iap.buyConsumable(purchaseParam: param);
  }

  /// Whether a store event should grant a new boost window.
  ///
  /// Consumable restores replay on every launch; only fresh `purchased`
  /// (or unfinished restores that still need `completePurchase`) should activate.
  @visibleForTesting
  static bool shouldActivateFromPurchase(PurchaseDetails purchase) {
    if (purchase.status == PurchaseStatus.purchased) return true;
    if (purchase.status == PurchaseStatus.restored &&
        purchase.pendingCompletePurchase) {
      return true;
    }
    return false;
  }

  /// Listens for a completed boost purchase and activates boost for [userId].
  StreamSubscription<List<PurchaseDetails>> listenForBoostActivation({
    required String userId,
    required void Function() onActivated,
    void Function(String message)? onError,
  }) {
    return _iap.purchaseStream.listen((purchases) async {
      for (final purchase in purchases) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          final boostIds = await fetchBoostProductIds();
          if (!boostIds.contains(purchase.productID)) continue;

          if (!shouldActivateFromPurchase(purchase)) {
            continue;
          }

          await _boostService.activateBoost(
            userId: userId,
            productId: purchase.productID,
          );

          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          onActivated();
        } else if (purchase.status == PurchaseStatus.error) {
          onError?.call(
            purchase.error?.message ?? 'Boost purchase failed',
          );
        }
      }
    });
  }
}
