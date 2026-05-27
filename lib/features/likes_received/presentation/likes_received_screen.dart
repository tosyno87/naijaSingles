import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/constants/app_colors.dart';
import '../../../common/constants/app_spacing.dart';
import '../../../common/widgets/image_widget.dart' show CustomCNImage;
import '../../../common/widgets/state_views/state_views.dart';
import '../../../models/user_model.dart';
import '../../dating/screens/user_detail_screen.dart';
import '../../payment/ui/in_app_purchase/buy_products/buyproducts_bloc.dart';
import '../../payment/ui/in_app_purchase/get_products/getproducts_bloc.dart';
import '../../payment/ui/products.dart';
import '../data/likes_received_repository.dart';
import '../likes_received_gating.dart';

/// Shows users who liked the current profile. Full list requires premium.
class LikesReceivedScreen extends StatefulWidget {
  const LikesReceivedScreen({
    required this.currentUser,
    super.key,
  });

  final UserModel currentUser;

  @override
  State<LikesReceivedScreen> createState() => _LikesReceivedScreenState();
}

class _LikesReceivedScreenState extends State<LikesReceivedScreen> {
  final LikesReceivedRepository _repository = LikesReceivedRepository();

  bool _loading = true;
  String? _error;
  List<UserModel> _likers = [];

  bool get _isPremium => widget.currentUser.hasPremiumAccess;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final likers = await _repository.fetchUsersWhoLikedMe();
      if (!mounted) return;
      setState(() {
        _likers = likers;
        _loading = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundColor,
          elevation: 0,
          title: Text(
            'Likes You',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
        ),
        body: _buildBody(),
      );

  Widget _buildBody() {
    if (_loading) {
      return const AppLoadingView(message: 'Loading likes...');
    }
    if (_error != null) {
      return AppErrorView(
        title: 'Could not load likes',
        message: _error!,
        onRetry: _load,
      );
    }
    if (_likers.isEmpty) {
      return const AppEmptyView(
        title: 'No likes yet',
        subtitle: 'Keep your profile fresh and stay active in Connect.',
        icon: Icons.favorite_border,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_isPremium) _buildPremiumBanner(),
        Expanded(
          child: GridView.builder(
            padding: AppSpacing.pagePadding,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: _likers.length,
            itemBuilder: (context, index) {
              final user = _likers[index];
              final locked = LikesReceivedGating.isCardLocked(
                hasPremiumAccess: _isPremium,
                index: index,
              );
              return _LikerCard(
                user: user,
                locked: locked,
                onTap: locked ? _openPremium : () => _openProfile(user),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumBanner() => Container(
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          0,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_open, color: AppColors.primaryGreen),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Upgrade to see everyone who likes you',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: _openPremium,
              child: const Text('Upgrade'),
            ),
          ],
        ),
      );

  void _openPremium() {
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

  void _openProfile(UserModel user) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => UserDetailScreen(user: user),
        ),
      ),
    );
  }
}

class _LikerCard extends StatelessWidget {
  const _LikerCard({
    required this.user,
    required this.locked,
    required this.onTap,
  });

  final UserModel user;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        user.imageUrl?.isNotEmpty ?? false ? user.imageUrl!.first : null;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              CustomCNImage(imageUrl: imageUrl, fit: BoxFit.cover)
            else
              Container(color: Colors.grey.shade300),
            if (locked)
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  alignment: Alignment.center,
                  child: const Icon(Icons.lock, color: Colors.white, size: 36),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  user.name ?? 'Member',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
