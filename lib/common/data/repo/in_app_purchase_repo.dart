// ignore_for_file: depend_on_referenced_packages

import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:hookup4u2/models/user_model.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

import '../../../features/home/ui/tab/tabbar.dart';
import '../../../features/payment/ui/products.dart';
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
        throw 'Not available';
      }

      Set<String> kIds = Set.from(await _fetchPackageIds());
      final ProductDetailsResponse response =
          await InAppPurchase.instance.queryProductDetails(kIds);
      if (response.notFoundIDs.isNotEmpty) {
        log("Not found");
        throw 'No product found';
      }
      List<ProductDetails> products = response.productDetails;
      return products;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future buyConsumable({required ProductDetails productDetails}) async {
    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: productDetails);
    await inApp.buyNonConsumable(purchaseParam: purchaseParam);
    log("=============-----------isPurchaseSuccessfully");
  }

  Future<List<String>> _fetchPackageIds() async {
    List<String> packageId = [];

    await firebaseFireStoreInstance
        .collection("Packages")
        .where('status', isEqualTo: true)
        .get()
        .then((value) {
      packageId.addAll(value.docs.map((e) => e['id']));
    });

    return packageId;
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
      String productId, List<PurchaseDetails> purchases) {
    return purchases.firstWhere(
      (purchase) => purchase.productID == productId,
      //orElse: () => null
    );
  }

  ///verifying opurhcase of user
  static Future<void> verifyPuchase(String id, List<PurchaseDetails> purchases,
      UserModel currentUser, Map items, BuildContext context) async {
    PurchaseDetails purchase = hasPurchased(id, purchases);
    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      log('===***${purchase.productID}');

      // if (Platform.isIOS) {
      await inApp.completePurchase(purchase);
      //}
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(builder: (context) {
            return Tabbar(
              purchase.productID,
              true,
            );
          }),
        );
      }
    } else if (purchase.status == PurchaseStatus.error) {
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(
            builder: (context) => Products(currentUser, false, items)),
      );
    }
    return;
  }

  String getInterval(ProductDetails product) {
    product as AppStoreProductDetails;
    SKSubscriptionPeriodUnit periodUnit =
        product.skProduct.subscriptionPeriod!.unit;
    if (SKSubscriptionPeriodUnit.month == periodUnit) {
      return "Month(s)";
    } else if (SKSubscriptionPeriodUnit.week == periodUnit) {
      return "Week(s)";
    } else {
      return "Year";
    }
  }

  String getIntervalAndroid(ProductDetails product) {
    product as GooglePlayProductDetails;
    String? durCode = product.productDetails.subscriptionOfferDetails?.first
        .pricingPhases.first.billingPeriod;
    if (durCode == "M" || durCode == "m") {
      return "Month(s)";
    } else if (durCode == "Y" || durCode == "y") {
      return "Year";
    } else {
      return "Week(s)";
    }
  }
}
