// ignore_for_file: sort_child_properties_last, depend_on_referenced_packages, avoid_positional_boolean_parameters

import 'dart:async';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import '../../../common/bloc/theme/theme_bloc.dart';
import '../../../common/constants/adds.dart';
import '../../../common/constants/app_colors.dart';
import '../../../common/constants/app_spacing.dart';
import '../../../common/data/repo/in_app_purchase_repo.dart';
import '../../../common/utils/crousle_slider.dart';
import '../../../common/utils/privacy_page.dart';
import '../../../common/widgets/custom_button.dart';
import '../../../common/widgets/custom_snackbar.dart';
import '../../../common/widgets/state_views/state_views.dart';
import '../../../config/app_config.dart';
import '../../../models/user_model.dart';
import '../../home/ui/tab/tabbar.dart';
import '../presentation/bloc/subscription_bloc.dart';
import 'in_app_purchase/buy_products/buyproducts_bloc.dart';
import 'in_app_purchase/buy_products/buyproducts_events.dart';
import 'in_app_purchase/buy_products/buyproducts_states.dart';
import 'in_app_purchase/get_products/getproducts_bloc.dart';
import 'in_app_purchase/get_products/getproducts_events.dart';
import 'in_app_purchase/get_products/getproducts_states.dart';

class Products extends StatefulWidget {
  const Products(
    this.currentUser,
    this.isPaymentSuccess,
    this.items, {
    super.key,
  });
  final bool? isPaymentSuccess;
  final UserModel? currentUser;
  final Map items;

  @override
  ProductsState createState() => ProductsState();
}

class ProductsState extends State<Products> {
  ProductDetails? electedPlan;
  ProductDetails? selectedProduct;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    context.read<GetInAppProductsBloc>().add(RequestInAppProducts());
    // Show payment failure alert.
    if (widget.isPaymentSuccess != null && !widget.isPaymentSuccess!) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(
          Alert(
            context: context,
            type: AlertType.error,
            title: 'Failed'.tr().toString(),
            desc: 'Oops !! something went wrong. Try Again'.tr().toString(),
            buttons: [
              DialogButton(
                child: Text(
                  'Retry'.tr().toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
                onPressed: () => Navigator.pop(context),
                width: 120,
              ),
            ],
          ).show(),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeBloc>().isDarkMode;
    return MultiBlocListener(
      listeners: [
        BlocListener<SubscriptionBloc, SubscriptionState>(
          listenWhen: (previous, current) =>
              current.shouldNavigateToSuccess &&
              !previous.shouldNavigateToSuccess,
          listener: (context, state) {
            final UserModel? user = widget.currentUser;
            final String? uid = user?.id;
            if (uid == null || uid.isEmpty) return;
            context
                .read<SubscriptionBloc>()
                .add(const SubscriptionConsumeNavigateSuccess());
            unawaited(
              Navigator.pushReplacement(
                context,
                CupertinoPageRoute<void>(
                  builder: (_) => Tabbar(
                    isPaymentSuccess: true,
                    currentUserId: uid,
                  ),
                ),
              ),
            );
          },
        ),
        BlocListener<SubscriptionBloc, SubscriptionState>(
          listenWhen: (previous, current) =>
              current.userMessage != null &&
              current.userMessage != previous.userMessage,
          listener: (context, state) {
            final String? message = state.userMessage;
            if (message == null) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
            context
                .read<SubscriptionBloc>()
                .add(const SubscriptionConsumeUserMessage());
          },
        ),
        BlocListener<BuyConsumableInAppProductsBloc, BuyConsumableStates>(
          listenWhen: (previous, current) =>
              current is BuyConsumableFailedState,
          listener: (context, state) {
            if (state is BuyConsumableFailedState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.msg ?? 'Purchase could not be started. Try again.',
                  ),
                ),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<GetInAppProductsBloc, GetInAppProductsStates>(
        builder: (context, state) {
          if (state is GetInAppProductsLoadingState) {
            return const AppLoadingView();
          }
          if (state is GetInAppProductsFailedState) {
            return Scaffold(
              body: AppErrorView(
                title: 'Plans temporarily unavailable',
                message: state.msg ?? 'Failed to load products',
                onRetry: () => context
                    .read<GetInAppProductsBloc>()
                    .add(RequestInAppProducts()),
              ),
            );
          }
          if (state is GetInAppProductsSuccessState) {
            return Scaffold(
              backgroundColor: Theme.of(context).primaryColor,
              appBar: AppBar(
                elevation: 0,
                backgroundColor:
                    isDarkMode ? const Color(0xff252020) : Colors.white,
                centerTitle: true,
                title: Text(
                  'Get our premium plans'.tr().toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    color: isDarkMode ? Colors.white : Colors.black,
                    icon: const Icon(
                      Icons.cancel,
                      size: 25,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(4),
                  child: BlocBuilder<SubscriptionBloc, SubscriptionState>(
                    buildWhen: (p, c) =>
                        p.purchaseInProgress != c.purchaseInProgress,
                    builder: (context, subState) {
                      if (!subState.purchaseInProgress) {
                        return const SizedBox.shrink();
                      }
                      return const LinearProgressIndicator(minHeight: 4);
                    },
                  ),
                ),
              ),
              key: _scaffoldKey,
              body: SingleChildScrollView(
                child: Column(
                  // mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.chipRadius),
                        ),
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
                                'Unlimited swipe.'.tr().toString(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.star,
                                color: Colors.green,
                              ),
                              title: Text(
                                'Search users around'.tr().toString(),
                                style: const TextStyle(
                                  // Color(0xFF1A1A1A),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ).tr(
                                args: ["${widget.items['paid_radius'] ?? ''}"],
                              ),
                            ),
                            CarouselSlider(
                              adds: adds,
                            ),
                            state.result.isNotEmpty
                                ? Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      Align(
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
                                                color: isDarkMode
                                                    ? const Color(
                                                        0x33FFFFFF,
                                                      )
                                                    : AppColors.primaryGreen,
                                              ),
                                            ),
                                            child: Center(
                                              child: CupertinoPicker(
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
                                                    FixedExtentScrollController(),
                                                itemExtent: 100,
                                                onSelectedItemChanged: (value) {
                                                  selectedProduct =
                                                      state.result[value];
                                                  setState(() {});
                                                },
                                                children:
                                                    state.result.map((product) {
                                                  final AppStoreProductDetails?
                                                      iosP =
                                                      product is AppStoreProductDetails
                                                          ? product
                                                          : null;
                                                  final GooglePlayProductDetails?
                                                      androidP =
                                                      product is GooglePlayProductDetails
                                                          ? product
                                                          : null;
                                                  final String interval = iosP !=
                                                          null
                                                      ? InAppPurchaseRepoImpl()
                                                          .getInterval(product)
                                                      : InAppPurchaseRepoImpl()
                                                          .getIntervalAndroid(
                                                          product,
                                                        );
                                                  final String intervalCount = iosP !=
                                                          null
                                                      ? iosP
                                                              .skProduct
                                                              .subscriptionPeriod
                                                              ?.numberOfUnits
                                                              .toString() ??
                                                          ''
                                                      : androidP
                                                              ?.productDetails
                                                              .subscriptionOfferDetails
                                                              ?.first
                                                              .pricingPhases
                                                              .first
                                                              .billingPeriod
                                                              .replaceAll(
                                                            RegExp(
                                                              r'[^0-9]',
                                                            ),
                                                            '',
                                                          ) ??
                                                          '';
                                                  return Transform.rotate(
                                                    angle: pi / 2,
                                                    child: Center(
                                                      child: Column(
                                                        children: [
                                                          productList(
                                                            context: context,
                                                            product: product,
                                                            interval: interval,
                                                            intervalCount:
                                                                intervalCount,
                                                            price:
                                                                product.price,
                                                            onTap: () {
                                                              null;
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (selectedProduct != null)
                                        Builder(
                                          builder: (context) {
                                            final product = selectedProduct;
                                            if (product == null) {
                                              return const SizedBox.shrink();
                                            }
                                            return Center(
                                              child: ListTile(
                                                title: Text(
                                                  product.title,
                                                  textAlign: TextAlign.center,
                                                ),
                                                subtitle: Text(
                                                  product.description,
                                                  textAlign: TextAlign.center,
                                                ),
                                                trailing: Text(
                                                  '${state.result.indexOf(product) + 1}/${state.result.length}',
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                      else
                                        Center(
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
                                              '1/${state.result.length}',
                                            ),
                                          ),
                                        ),
                                    ],
                                  )
                                : SizedBox(
                                    height:
                                        MediaQuery.of(context).size.width * .8,
                                    child: AppErrorView(
                                      title: 'Plans temporarily unavailable',
                                      message:
                                          'No plans were returned from the store. '
                                          'Check App Store Connect / Play Console IDs '
                                          'and try again.',
                                      icon: Icons.shopping_bag_outlined,
                                      onRetry: () => context
                                          .read<GetInAppProductsBloc>()
                                          .add(RequestInAppProducts()),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: selectedProduct != null
                          ? CustomButton(
                              text: 'CONTINUE'.tr().toString(),
                              onTap: () async {
                                final product = selectedProduct;
                                if (product == null) return;
                                BlocProvider.of<BuyConsumableInAppProductsBloc>(
                                  context,
                                ).add(
                                  RequestBuyConsumableProducts(
                                    productDetails: product,
                                  ),
                                );
                              },
                              color: AppColors.textPrimary,
                              active: true,
                            )
                          : Padding(
                              padding: const EdgeInsets.only(bottom: 40),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: InkWell(
                                  onTap: () {
                                    CustomSnackbar.showSnackBarSimple(
                                      'You must choose a subscription to continue.'
                                          .tr()
                                          .toString(),
                                      context,
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.secondaryColor.withValues(
                                        alpha: (.7 * 255).toDouble(),
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    height: MediaQuery.of(context).size.height *
                                        .065,
                                    width:
                                        MediaQuery.of(context).size.width * .75,
                                    child: Center(
                                      child: Text(
                                        'CONTINUE'.tr().toString(),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
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
                    //                       AppColors.primaryGreen.withValues(alpha: .5),
                    //                       AppColors.primaryGreen.withValues(alpha: .8),
                    //                       AppColors.primaryGreen,
                    //                       AppColors.primaryGreen
                    // ])),
                    //             height: MediaQuery.of(context).size.height * .055,
                    //             width: MediaQuery.of(context).size.width * .55,
                    //             child: Center(
                    //                 child: Text(
                    //               "RESTORE PURCHASE".tr().toString(),
                    //               style: TextStyle(
                    //                   fontSize: 15,
                    //                   color: AppColors.textPrimary,
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
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          GestureDetector(
                            child: Text(
                              'Privacy Policy'.tr().toString(),
                              style: const TextStyle(color: Colors.blue),
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PrivacyPolicyPage(
                                  url: privacyUrl,
                                  tittle: 'Privacy Policy',
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            child: Text(
                              'Terms & Conditions'.tr().toString(),
                              style: const TextStyle(color: Colors.blue),
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PrivacyPolicyPage(
                                  url: termConditionUrl,
                                  tittle: 'Terms & Conditions',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return Scaffold(
            body: AppErrorView(
              title: 'Plans temporarily unavailable',
              message: 'No product Found'.tr().toString(),
              icon: Icons.shopping_bag_outlined,
              onRetry: () => context
                  .read<GetInAppProductsBloc>()
                  .add(RequestInAppProducts()),
            ),
          );
        },
      ),
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
    final isDarkMode = context.watch<ThemeBloc>().isDarkMode;
    return AnimatedContainer(
      curve: Curves.easeIn,
      height: 100, //setting up dimention if product get selected
      width: selectedProduct !=
              product //setting up dimention if product get selected
          ? MediaQuery.of(context).size.width * .19
          : MediaQuery.of(context).size.width * .22,
      decoration: selectedProduct == product
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.primaryGreen
                  .withValues(alpha: (0.5 * 255).toDouble()),
              border: Border.all(width: 2, color: AppColors.primaryGreen),
            )
          : null,
      duration: const Duration(milliseconds: 500),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          SizedBox(height: MediaQuery.of(context).size.height * .02),
          Text(
            intervalCount,
            style: TextStyle(
              color: selectedProduct !=
                      product //setting up color if product get selected
                  ? isDarkMode
                      ? Colors.white
                      : Colors.black
                  : AppColors.primaryGreen,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            interval,
            style: TextStyle(
              color: selectedProduct !=
                      product //setting up color if product get selected
                  ? isDarkMode
                      ? Colors.white
                      : Colors.black
                  : AppColors.primaryGreen,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          Text(
            price,
            style: TextStyle(
              color: selectedProduct !=
                      product //setting up product if product get selected
                  ? isDarkMode
                      ? Colors.white
                      : Colors.black
                  : AppColors.primaryGreen,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
        //      )),
      ),
    );
  }
}
