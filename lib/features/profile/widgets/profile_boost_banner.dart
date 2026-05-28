import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../common/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../services/profile_boost_purchase_service.dart';
import '../../../services/profile_boost_service.dart';
import '../../payment/ui/in_app_purchase/buy_products/buyproducts_bloc.dart';
import '../../payment/ui/in_app_purchase/get_products/getproducts_bloc.dart';
import '../../payment/ui/products.dart';

/// Profile boost CTA with IAP purchase and active timer when boost is running.
class ProfileBoostBanner extends StatefulWidget {
  const ProfileBoostBanner({
    required this.currentUser,
    super.key,
    ProfileBoostService? boostService,
    ProfileBoostPurchaseService? purchaseService,
  })  : _boostService = boostService,
        _purchaseService = purchaseService;

  final UserModel currentUser;
  final ProfileBoostService? _boostService;
  final ProfileBoostPurchaseService? _purchaseService;

  @override
  State<ProfileBoostBanner> createState() => _ProfileBoostBannerState();
}

class _ProfileBoostBannerState extends State<ProfileBoostBanner> {
  late final ProfileBoostService _boostService =
      widget._boostService ?? ProfileBoostService();
  late final ProfileBoostPurchaseService _purchaseService =
      widget._purchaseService ?? ProfileBoostPurchaseService();

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  Duration? _remaining;
  bool _loading = true;
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
    _listenForPurchases();
  }

  void _listenForPurchases() {
    final uid = widget.currentUser.id ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _purchaseSub = _purchaseService.listenForBoostActivation(
      userId: uid,
      onActivated: () {
        if (!mounted) return;
        setState(() => _purchasing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile boost is active!',
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        unawaited(_refresh());
      },
      onError: (message) {
        if (!mounted) return;
        setState(() => _purchasing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.error),
        );
      },
    );
  }

  @override
  void dispose() {
    unawaited(_purchaseSub?.cancel());
    super.dispose();
  }

  Future<void> _refresh() async {
    final uid = widget.currentUser.id ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    final remaining = await _boostService.boostTimeRemaining(uid);
    if (!mounted) return;
    setState(() {
      _remaining = remaining;
      _loading = false;
    });
  }

  Future<void> _purchaseBoost() async {
    final uid = widget.currentUser.id ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _purchasing) return;

    setState(() => _purchasing = true);
    try {
      final products = await _purchaseService.fetchBoostProducts();
      if (!mounted) return;

      if (products.isEmpty) {
        setState(() => _purchasing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Boost is not available right now. Configure a boost package in the store.',
            ),
          ),
        );
        return;
      }

      await _purchaseService.buyBoost(products.first);
    } on Object catch (e) {
      if (mounted) {
        setState(() => _purchasing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start purchase: $e')),
        );
      }
    }
  }

  void _openProducts() {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => GetInAppProductsBloc()),
              BlocProvider(create: (_) => BuyConsumableInAppProductsBloc()),
            ],
            child: Products(widget.currentUser, null, const {}),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    final active = _remaining != null;
    final title = active ? 'Boost active' : 'Boost profile';
    final subtitle = active
        ? '${_formatRemaining(_remaining!)} left in Connect'
        : 'Get seen more in Connect for 1 hour';

    return Container(
      margin: const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        12,
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active
              ? AppColors.primaryGreen.withValues(alpha: 0.28)
              : const Color(0x14000000),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: AppColors.primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (active)
            TextButton(
              onPressed: _openProducts,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Plans',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            FilledButton(
              onPressed: _purchasing ? null : _purchaseBoost,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                minimumSize: const Size(0, 38),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: _purchasing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Boost',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          if (!active)
            IconButton(
              onPressed: _openProducts,
              tooltip: 'View plans',
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.info_outline_rounded,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  String _formatRemaining(Duration d) {
    final minutes = d.inMinutes.remainder(60);
    final hours = d.inHours;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}
