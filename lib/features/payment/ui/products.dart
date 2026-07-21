import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import '../../../common/bloc/theme/theme_bloc.dart';
import '../../../common/constants/app_colors.dart';
import '../../../common/constants/app_spacing.dart';
import '../../../common/data/repo/in_app_purchase_repo.dart';
import '../../../common/utils/privacy_page.dart';
import '../../../common/widgets/afropeep_primary_button.dart';
import '../../../common/widgets/state_views/state_views.dart';
import '../../../config/app_config.dart';
import '../../../models/user_model.dart';
import '../../home/ui/tab/tabbar.dart';
import '../iap_user_facing_message.dart';
import '../presentation/bloc/subscription_bloc.dart';
import 'in_app_purchase/buy_products/buyproducts_bloc.dart';
import 'in_app_purchase/buy_products/buyproducts_events.dart';
import 'in_app_purchase/buy_products/buyproducts_states.dart';
import 'in_app_purchase/get_products/getproducts_bloc.dart';
import 'in_app_purchase/get_products/getproducts_events.dart';
import 'in_app_purchase/get_products/getproducts_states.dart';

class Products extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Call sites sometimes push [Products] without IAP blocs (e.g. location
    // upsell). Provide them here when missing so paywalls never red-screen.
    final bool hasGetBloc = _blocAvailable<GetInAppProductsBloc>(context);
    final bool hasBuyBloc =
        _blocAvailable<BuyConsumableInAppProductsBloc>(context);

    Widget child = _ProductsBody(
      currentUser: currentUser,
      isPaymentSuccess: isPaymentSuccess,
      items: items,
    );

    if (!hasGetBloc || !hasBuyBloc) {
      child = MultiBlocProvider(
        providers: [
          if (!hasGetBloc)
            BlocProvider<GetInAppProductsBloc>(
              create: (_) => GetInAppProductsBloc(),
            ),
          if (!hasBuyBloc)
            BlocProvider<BuyConsumableInAppProductsBloc>(
              create: (_) => BuyConsumableInAppProductsBloc(),
            ),
        ],
        child: child,
      );
    }
    return child;
  }

  static bool _blocAvailable<T extends StateStreamableSource<Object?>>(
    BuildContext context,
  ) {
    try {
      BlocProvider.of<T>(context, listen: false);
      return true;
    } on Object {
      return false;
    }
  }
}

class _ProductsBody extends StatefulWidget {
  const _ProductsBody({
    required this.currentUser,
    required this.isPaymentSuccess,
    required this.items,
  });

  final bool? isPaymentSuccess;
  final UserModel? currentUser;
  final Map items;

  @override
  State<_ProductsBody> createState() => _ProductsBodyState();
}

class _ProductsBodyState extends State<_ProductsBody> {
  ProductDetails? selectedProduct;
  bool _preparingPurchase = false;

  @override
  void initState() {
    super.initState();
    context.read<GetInAppProductsBloc>().add(RequestInAppProducts());
    // Keep SubscriptionBloc's purchaseStream listener in sync with the user
    // shown on this paywall (UserBloc can lag or be UserLoaded(null)).
    final String? paywallUid = widget.currentUser?.id;
    if (paywallUid != null && paywallUid.isNotEmpty) {
      context.read<SubscriptionBloc>().add(SubscriptionUserChanged(paywallUid));
    }
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

  String _intervalKey(ProductDetails product) {
    final repo = InAppPurchaseRepoImpl();
    final String interval = product is AppStoreProductDetails
        ? repo.getInterval(product)
        : repo.getIntervalAndroid(product);
    if (interval.isNotEmpty) return interval.toLowerCase();
    // Fallback: derive from product ID for resilience and testability.
    final id = product.id.toLowerCase();
    if (id.contains('yearly') || id.contains('annual') || id.contains('year')) {
      return 'year';
    }
    if (id.contains('monthly') || id.contains('month')) return 'month';
    if (id.contains('weekly') || id.contains('week')) return 'week';
    return '';
  }

  String _userFacingLabel(ProductDetails product) {
    final lower = _intervalKey(product);
    if (lower.contains('month')) return 'Monthly';
    if (lower.contains('year')) return 'Yearly';
    if (lower.contains('week')) return 'Weekly';
    return lower;
  }

  String _intervalSuffix(ProductDetails product) {
    final lower = _intervalKey(product);
    if (lower.contains('month')) return '/mo';
    if (lower.contains('year')) return '/yr';
    if (lower.contains('week')) return '/wk';
    return '';
  }

  int _billingMonths(ProductDetails product) {
    final lower = _intervalKey(product);
    if (lower.contains('year')) return 12;
    if (lower.contains('week')) return 1;
    return 1;
  }

  /// Returns savings percentage (0–100) for [candidate] vs [baseline], or null.
  int? _savingsPercent(ProductDetails candidate, ProductDetails? baseline) {
    if (baseline == null) return null;
    if (baseline.rawPrice <= 0) return null;
    final monthlyEquiv = candidate.rawPrice / _billingMonths(candidate);
    final baseMonthly = baseline.rawPrice / _billingMonths(baseline);
    if (monthlyEquiv >= baseMonthly) return null;
    return ((1 - monthlyEquiv / baseMonthly) * 100).round();
  }

  /// Finds the monthly plan from [products] (if any) for price comparison.
  ProductDetails? _monthlyPlan(List<ProductDetails> products) {
    for (final p in products) {
      if (_intervalKey(p).contains('month')) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeBloc>().isDarkMode;
    final cardBg = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final scaffoldBg =
        isDarkMode ? const Color(0xFF121212) : AppColors.backgroundColor;
    final subtitleColor =
        isDarkMode ? Colors.grey.shade400 : AppColors.textSecondary;

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
                    userFacingPurchaseSnackBarMessage(
                      state.msg,
                      fallback: 'Purchase could not be started. Try again.',
                    ),
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
            return const Scaffold(
              backgroundColor: AppColors.backgroundColor,
              body: AppLoadingView(),
            );
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
            if (selectedProduct == null && state.result.isNotEmpty) {
              selectedProduct = state.result.first;
            }

            final String selectedLabel = selectedProduct != null
                ? _userFacingLabel(selectedProduct!)
                : '';

            return Scaffold(
              backgroundColor: scaffoldBg,
              appBar: AppBar(
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: scaffoldBg,
                centerTitle: true,
                title: Text(
                  'Afropeep Premium',
                  style: GoogleFonts.montserrat(
                    color: AppColors.primaryGreen,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                    ),
                    onPressed: () => Navigator.pop(context),
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
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.contentInset,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: AppSpacing.md),

                              // --- Benefits ---
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.cardRadius,
                                  ),
                                  boxShadow: isDarkMode
                                      ? null
                                      : [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.05),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Unlock everything',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: isDarkMode
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    _buildBenefitRow(
                                      Icons.all_inclusive,
                                      'Unlimited swipes',
                                      isDarkMode,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    _buildBenefitRow(
                                      Icons.visibility_outlined,
                                      'See who likes you',
                                      isDarkMode,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    _buildBenefitRow(
                                      Icons.star_outline_rounded,
                                      'Priority visibility in discover',
                                      isDarkMode,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    _buildBenefitRow(
                                      Icons.tune_rounded,
                                      'Advanced search filters',
                                      isDarkMode,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: AppSpacing.lg),

                              // --- Choose plan label ---
                              Text(
                                'Choose your plan',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),

                              // --- Plan cards ---
                              if (state.result.isNotEmpty)
                                Builder(
                                  builder: (context) {
                                    final monthly = _monthlyPlan(state.result);
                                    return Row(
                                      children: state.result.map((product) {
                                        final bool isSelected =
                                            selectedProduct == product;
                                        final String label =
                                            _userFacingLabel(product);
                                        final String suffix =
                                            _intervalSuffix(product);

                                        final int? savings = product != monthly
                                            ? _savingsPercent(
                                                product,
                                                monthly,
                                              )
                                            : null;

                                        String? badge;
                                        String? monthlyEquiv;
                                        if (savings != null && savings > 0) {
                                          badge = 'Save $savings%';
                                          if (monthly != null) {
                                            monthlyEquiv =
                                                '${monthly.price}/mo';
                                          }
                                        }

                                        return Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.only(
                                              right:
                                                  product == state.result.last
                                                      ? 0
                                                      : AppSpacing.sm,
                                            ),
                                            child: _buildPlanCard(
                                              product: product,
                                              label: label,
                                              priceSuffix: suffix,
                                              badge: badge,
                                              monthlyEquiv: monthlyEquiv,
                                              isSelected: isSelected,
                                              isDarkMode: isDarkMode,
                                              cardBg: cardBg,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                )
                              else
                                SizedBox(
                                  height: 160,
                                  child: AppErrorView(
                                    title: 'No plans available',
                                    message:
                                        'No plans were returned from the store.',
                                    icon: Icons.shopping_bag_outlined,
                                    onRetry: () => context
                                        .read<GetInAppProductsBloc>()
                                        .add(RequestInAppProducts()),
                                  ),
                                ),

                              const SizedBox(height: AppSpacing.lg),
                            ],
                          ),
                        ),
                      ),

                      // --- CTA ---
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.sm,
                        ),
                        child: BlocBuilder<BuyConsumableInAppProductsBloc,
                            BuyConsumableStates>(
                          buildWhen: (previous, current) =>
                              previous.runtimeType != current.runtimeType,
                          builder: (context, buyState) {
                            final bool buying =
                                buyState is BuyConsumableLoadingState;
                            return BlocBuilder<SubscriptionBloc,
                                SubscriptionState>(
                              buildWhen: (p, c) =>
                                  p.purchaseInProgress != c.purchaseInProgress,
                              builder: (context, subState) {
                                final bool busy = buying ||
                                    subState.purchaseInProgress ||
                                    _preparingPurchase;
                                return AfropeepPrimaryButton(
                                  text: selectedProduct != null
                                      ? 'Continue with $selectedLabel'
                                      : 'Select a plan',
                                  isLoading: busy,
                                  onPressed: selectedProduct != null && !busy
                                      ? () => unawaited(_startPurchase(context))
                                      : null,
                                  borderRadius: AppSpacing.chipRadius,
                                );
                              },
                            );
                          },
                        ),
                      ),

                      // --- Legal links ---
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.md,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PrivacyPolicyPage(
                                    url: privacyUrl,
                                    tittle: 'Privacy Policy',
                                  ),
                                ),
                              ),
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(minHeight: 44),
                                child: Align(
                                  child: Text(
                                    'Privacy Policy'.tr().toString(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: subtitleColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                              ),
                              child: Text(
                                '|',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: subtitleColor,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PrivacyPolicyPage(
                                    url: termConditionUrl,
                                    tittle: 'Terms & Conditions',
                                  ),
                                ),
                              ),
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(minHeight: 44),
                                child: Align(
                                  child: Text(
                                    'Terms & Conditions'.tr().toString(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: subtitleColor,
                                    ),
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

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> _startPurchase(BuildContext context) async {
    final ProductDetails? product = selectedProduct;
    if (product == null) return;
    if (_preparingPurchase) return;

    final String? uid = widget.currentUser?.id;
    if (uid == null || uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please sign in again to subscribe.',
          ),
        ),
      );
      return;
    }

    setState(() => _preparingPurchase = true);
    try {
      // Await listener attach — fire-and-forget SubscriptionUserChanged can
      // still be mid-setup when buyNonConsumable presents the store sheet.
      await context.read<SubscriptionBloc>().prepareForPurchase(uid);
    } on Object catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFacingPurchaseThrowableMessage(e),
          ),
        ),
      );
      return;
    } finally {
      if (mounted) {
        setState(() => _preparingPurchase = false);
      }
    }

    if (!context.mounted) return;
    context.read<BuyConsumableInAppProductsBloc>().add(
          RequestBuyConsumableProducts(productDetails: product),
        );
  }

  Widget _buildBenefitRow(IconData icon, String text, bool isDarkMode) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Icon(icon, size: 20, color: AppColors.primaryGreen),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required ProductDetails product,
    required String label,
    required String priceSuffix,
    required bool isSelected,
    required bool isDarkMode,
    required Color cardBg,
    String? badge,
    String? monthlyEquiv,
  }) {
    final borderColor =
        isSelected ? AppColors.primaryGreen : Colors.transparent;
    final bgColor =
        isSelected ? AppColors.primaryGreen.withValues(alpha: 0.06) : cardBg;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label plan, ${product.price}$priceSuffix'
          '${badge != null ? ', $badge' : ''}',
      child: GestureDetector(
        onTap: () => setState(() => selectedProduct = product),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          constraints: const BoxConstraints(minHeight: 120),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: borderColor,
              width: 2,
            ),
            boxShadow: isDarkMode
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            children: [
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppColors.primaryGreen
                      : isDarkMode
                          ? Colors.white
                          : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${product.price}$priceSuffix',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColors.primaryGreen
                      : isDarkMode
                          ? Colors.grey.shade300
                          : AppColors.textSecondary,
                ),
              ),
              if (monthlyEquiv != null) ...[
                const SizedBox(height: 2),
                Text(
                  monthlyEquiv,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: isDarkMode
                        ? Colors.grey.shade500
                        : AppColors.textTertiary,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                size: 22,
                color: isSelected
                    ? AppColors.primaryGreen
                    : isDarkMode
                        ? Colors.grey.shade600
                        : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
