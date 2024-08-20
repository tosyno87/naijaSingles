// ignore_for_file: sort_child_properties_last, depend_on_referenced_packages, prefer_typing_uninitialized_variables, avoid_function_literals_in_foreach_calls

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookup4u2/common/widets/custom_button.dart';
import 'package:hookup4u2/config/app_config.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:provider/provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import '../../../common/constants/adds.dart';
import '../../../common/constants/colors.dart';
import '../../../common/constants/constants.dart';
import '../../../common/data/repo/in_app_purchase_repo.dart';
import '../../../common/providers/theme_provider.dart';
import '../../../common/utlis/crousle_slider.dart';
import '../../../common/utlis/privacy_page.dart';
import '../../../common/widets/custom_snackbar.dart';
import '../../../common/widets/hookup_circularbar.dart';
import '../../../models/user_model.dart';
import 'in-app purcahse/buy Products/buyproducts_bloc.dart';
import 'in-app purcahse/buy Products/buyproducts_events.dart';
import 'in-app purcahse/get Products/getproducts_bloc.dart';
import 'in-app purcahse/get Products/getproducts_events.dart';
import 'in-app purcahse/get Products/getproducts_states.dart';

class Products extends StatefulWidget {
  final bool? isPaymentSuccess;
  final UserModel? currentUser;
  final Map items;
  const Products(this.currentUser, this.isPaymentSuccess, this.items,
      {super.key});

  @override
  ProductsState createState() => ProductsState();
}

class ProductsState extends State<Products> {
  /// if the api is available or not.
  bool isAvailable = true;

  /// products for sale
  // List<ProductDetails> products = [];

  /// Past purchases
  List<PurchaseDetails> purchases = [];

  /// Update to purchases
  StreamSubscription? _streamSubscription;
  ProductDetails? electedPlan;
  ProductDetails? selectedProduct;

  var response;
  bool _isLoading = true;
  final InAppPurchase _iap = InAppPurchase.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    context.read<GetInAppProductsBloc>().add(RequestInAppProducts());
    _initialize();
    // Show payment failure alert.
    if (widget.isPaymentSuccess != null && !widget.isPaymentSuccess!) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Alert(
          context: context,
          type: AlertType.error,
          title: "Failed".tr().toString(),
          desc: "Oops !! something went wrong. Try Again".tr().toString(),
          buttons: [
            DialogButton(
              child: Text(
                "Retry".tr().toString(),
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
              onPressed: () => Navigator.pop(context),
              width: 120,
            )
          ],
        ).show();
      });
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  void _initialize() async {
    isAvailable = await _iap.isAvailable();
    debugPrint("available is $isAvailable");
    if (isAvailable) {
      /// removing all the pending puchases.
      if (Platform.isIOS) {
        var paymentWrapper = SKPaymentQueueWrapper();
        var transactions = await paymentWrapper.transactions();
        transactions.forEach((transaction) async {
          debugPrint(transaction.transactionState.toString());
          await paymentWrapper
              .finishTransaction(transaction)
              .catchError((onError) {
            debugPrint('finishTransaction Error $onError');
          });
        });
      }

      _streamSubscription = _iap.purchaseStream.listen((data) {
        setState(
          () {
            purchases.addAll(data);

            purchases.forEach(
              (purchase) async {
                await InAppPurchaseRepoImpl.verifyPuchase(purchase.productID,
                        purchases, widget.currentUser!, widget.items, context)
                    .whenComplete(() async {
                  await firebaseFireStoreInstance
                      .collection('Users')
                      .doc(widget.currentUser!.id)
                      .update({
                    'isPremium': true,
                    'subscriptionDate': FieldValue.serverTimestamp(),
                  });
                });
              },
            );
          },
        );
      });
      _streamSubscription!.onError(
        (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: error != null
                  ? Text('$error')
                  : Text("Oops !! something went wrong. Try Again"
                      .tr()
                      .toString()),
            ),
          );
        },
      );
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return BlocBuilder<GetInAppProductsBloc, GetInAppProductsStates>(
      builder: (context, state) {
        if (state is GetInAppProductsLoadingState) {
          return const Hookup4uBar();
        } else if (state is GetInAppProductsFailedState) {
          return Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Text(state.msg),
              ),
            ),
          );
        } else if (state is GetInAppProductsSuccessState) {
          return Scaffold(
            backgroundColor: Theme.of(context).primaryColor,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: themeProvider.isDarkMode
                  ? const Color(0xff252020)
                  : Colors.white,
              centerTitle: true,
              title: Text(
                "Get our premium plans".tr().toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: primaryColor,
                    fontSize: 25,
                    fontWeight: FontWeight.bold),
              ),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  icon: const Icon(
                    Icons.cancel,
                    size: 25,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            key: _scaffoldKey,
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                // mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.star,
                              color: Colors.blue,
                            ),
                            title: Text(
                              "Unlimited swipe.".tr().toString(),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                          ),
                          ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.star,
                              color: Colors.green,
                            ),
                            title: Text(
                              "Search users around".tr().toString(),
                              style: const TextStyle(

                                  // Color(0xFF1A1A1A),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400),
                            ).tr(
                                args: ["${widget.items['paid_radius'] ?? ''}"]),
                          ),
                          CarouselSlider(
                            adds: adds,
                          ),
                          _isLoading
                              ? SizedBox(
                                  height:
                                      MediaQuery.of(context).size.width * .8,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                primaryColor)),
                                  ),
                                )
                              : state.result.isNotEmpty
                                  ? Stack(
                                      alignment: Alignment.bottomCenter,
                                      children: [
                                        Align(
                                          alignment: Alignment.center,
                                          child: Transform.rotate(
                                            angle: -pi / 2,
                                            child: Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  .16,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  .8,
                                              decoration: BoxDecoration(
                                                  border: Border.all(
                                                      width: 2,
                                                      color: themeProvider
                                                              .isDarkMode
                                                          ? const Color(
                                                              0x33FFFFFF)
                                                          : primaryColor)),
                                              child: Center(
                                                child: (CupertinoPicker(
                                                    squeeze: 1.4,
                                                    selectionOverlay:
                                                        const CupertinoPickerDefaultSelectionOverlay(
                                                      background:
                                                          Colors.transparent,
                                                    ),
                                                    looping: true,
                                                    magnification: 1.08,
                                                    offAxisFraction: -.2,
                                                    scrollController:
                                                        FixedExtentScrollController(
                                                            initialItem: 0),
                                                    itemExtent: 100,
                                                    onSelectedItemChanged:
                                                        (value) {
                                                      selectedProduct =
                                                          state.result[value];
                                                      setState(() {});
                                                    },
                                                    children: state.result
                                                        .map((product) {
                                                      var iosP;
                                                      product
                                                          as GooglePlayProductDetails;
                                                      if (Platform.isIOS) {
                                                        iosP = product
                                                            as AppStoreProductDetails;
                                                      }
                                                      return Transform.rotate(
                                                        angle: pi / 2,
                                                        child: Center(
                                                          child: Column(
                                                            children: [
                                                              productList(
                                                                context:
                                                                    context,
                                                                product:
                                                                    product,
                                                                interval: Platform
                                                                        .isIOS
                                                                    ? InAppPurchaseRepoImpl()
                                                                        .getInterval(
                                                                            product)
                                                                    : InAppPurchaseRepoImpl()
                                                                        .getIntervalAndroid(
                                                                            product),
                                                                intervalCount: Platform
                                                                        .isIOS
                                                                    ? iosP
                                                                        .skProduct
                                                                        .subscriptionPeriod!
                                                                        .numberOfUnits
                                                                        .toString()
                                                                    : product
                                                                        .productDetails
                                                                        .subscriptionOfferDetails!
                                                                        .first
                                                                        .pricingPhases
                                                                        .first
                                                                        .billingPeriod
                                                                        .split(
                                                                            "")[1],
                                                                price: product
                                                                    .price,
                                                                onTap: () {
                                                                  null;
                                                                },
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    }).toList())),
                                              ),
                                            ),
                                          ),
                                        ),
                                        selectedProduct != null
                                            ? Center(
                                                child: ListTile(
                                                  title: Text(
                                                    selectedProduct!.title,
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  subtitle: Text(
                                                    selectedProduct!
                                                        .description,
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  trailing: Text(
                                                      "${state.result.indexOf(selectedProduct!) + 1}/${state.result.length}"),
                                                ),
                                              )
                                            : Center(
                                                child: ListTile(
                                                  title: Text(
                                                    state.result[0].title,
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  subtitle: Text(
                                                    state.result[0].description,
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  trailing: Text(
                                                      "1/${state.result.length}"),
                                                ),
                                              )
                                      ],
                                    )
                                  : SizedBox(
                                      height:
                                          MediaQuery.of(context).size.width *
                                              .8,
                                      child: Center(
                                        child: Text("No active product found!!"
                                            .tr()
                                            .toString()),
                                      ),
                                    )
                        ],
                      ),
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: selectedProduct != null
                          ? CustomButton(
                              text: "CONTINUE".tr().toString(),
                              onTap: () async {
                                BlocProvider.of<BuyConsumableInAppProductsBloc>(
                                        context)
                                    .add(RequestBuyConsumableProducts(
                                        productDetails: selectedProduct!));
                              },
                              color: textColor,
                              active: true)
                          : Padding(
                              padding: const EdgeInsets.only(bottom: 40),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: InkWell(
                                    onTap: () {
                                      CustomSnackbar.showSnackBarSimple(
                                          "You must choose a subscription to continue."
                                              .tr()
                                              .toString(),
                                          context);
                                    },
                                    child: Container(
                                        decoration: BoxDecoration(
                                          color: secondryColor.withOpacity(.7),
                                          shape: BoxShape.rectangle,
                                          borderRadius:
                                              BorderRadius.circular(25),
                                        ),
                                        height:
                                            MediaQuery.of(context).size.height *
                                                .065,
                                        width:
                                            MediaQuery.of(context).size.width *
                                                .75,
                                        child: Center(
                                            child: Text(
                                          "CONTINUE".tr().toString(),
                                          style: TextStyle(
                                              fontSize: 15,
                                              color: textColor,
                                              fontWeight: FontWeight.bold),
                                        )))),
                              ),
                            )),
                  // Platform.isIOS
                  //     ? InkWell(
                  //         child: Container(
                  //             decoration: BoxDecoration(
                  //                 shape: BoxShape.rectangle,
                  //                 borderRadius: BorderRadius.circular(25),
                  //                 gradient: LinearGradient(
                  //                     begin: Alignment.topRight,
                  //                     end: Alignment.bottomLeft,
                  //                     colors: [
                  //                       primaryColor.withOpacity(.5),
                  //                       primaryColor.withOpacity(.8),
                  //                       primaryColor,
                  //                       primaryColor
                  // ])),
                  //             height: MediaQuery.of(context).size.height * .055,
                  //             width: MediaQuery.of(context).size.width * .55,
                  //             child: Center(
                  //                 child: Text(
                  //               "RESTORE PURCHASE".tr().toString(),
                  //               style: TextStyle(
                  //                   fontSize: 15,
                  //                   color: textColor,
                  //                   fontWeight: FontWeight.bold),
                  //             ))),
                  //         onTap: () async {
                  //           // var result = await _getpastPurchases();
                  //           // if (result.length == 0) {
                  //           //   showDiadebugPrint(
                  //           //       context: context,
                  //           //       builder: (ctx) {
                  //           //         return AlertDiadebugPrint(
                  //           //           content:
                  //           //               Text("No purchase found".tr().toString()),
                  //           //           title: Text("Past Purchases".tr().toString()),
                  //           //         );
                  //           //       });
                  //           // }
                  //         },
                  //       )
                  //     : Container(),

                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        GestureDetector(
                            child: Text(
                              "Privacy Policy".tr().toString(),
                              style: const TextStyle(color: Colors.blue),
                            ),
                            onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PrivacyPolicyPage(
                                      url: privacyUrl,
                                      tittle: "Privacy Policy",
                                    ),
                                  ),
                                )),
                        GestureDetector(
                            child: Text(
                              "Terms & Conditions".tr().toString(),
                              style: const TextStyle(color: Colors.blue),
                            ),
                            onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PrivacyPolicyPage(
                                      url: termConditionUrl,
                                      tittle: "Terms & Conditions",
                                    ),
                                  ),
                                )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Scaffold(
          body: Center(
            child: Text("No product Found".tr().toString()),
          ),
        );
      },
    );
  }

  Widget productList({
    required BuildContext context,
    required String intervalCount,
    required String interval,
    required Function onTap,
    required ProductDetails product,
    required String price,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return AnimatedContainer(
      curve: Curves.easeIn,
      height: 100, //setting up dimention if product get selected
      width: selectedProduct !=
              product //setting up dimention if product get selected
          ? MediaQuery.of(context).size.width * .19
          : MediaQuery.of(context).size.width * .22,
      decoration: selectedProduct == product
          ? BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).primaryColor.withOpacity(0.5),
              border: Border.all(width: 2, color: primaryColor))
          : null,
      duration: const Duration(milliseconds: 500),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          SizedBox(height: MediaQuery.of(context).size.height * .02),
          Text(intervalCount,
              style: TextStyle(
                  color: selectedProduct !=
                          product //setting up color if product get selected
                      ? themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black
                      : primaryColor,
                  fontSize: 25,
                  fontWeight: FontWeight.bold)),
          Text(interval,
              style: TextStyle(
                  color: selectedProduct !=
                          product //setting up color if product get selected
                      ? themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black
                      : primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 15)),
          Text(price,
              style: TextStyle(
                  color: selectedProduct !=
                          product //setting up product if product get selected
                      ? themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black
                      : primaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ],
        //      )),
      ),
    );
  }
}
