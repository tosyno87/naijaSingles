import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../common/constants/app_colors.dart';
import '../../../common/constants/app_spacing.dart';
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
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: active
              ? [AppColors.primaryGreen, AppColors.primaryGreenLight]
              : [const Color(0xFF1E3A5F), const Color(0xFF008037)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            active ? 'Boost active' : 'Boost your profile',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            active
                ? 'Time left: ${_formatRemaining(_remaining!)}'
                : 'Be seen by more people in Connect for 1 hour.',
            style: GoogleFonts.montserrat(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!active)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _purchasing ? null : _purchaseBoost,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                    child: _purchasing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Get boost'),
                  ),
                ),
              if (!active) const SizedBox(width: 8),
              TextButton(
                onPressed: _openProducts,
                child: Text(
                  'View plans',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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
