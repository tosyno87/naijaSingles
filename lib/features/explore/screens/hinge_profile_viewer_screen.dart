import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/constants/app_colors.dart';
import '../../../common/data/repo/user_search_repo.dart';
import '../../../common/widgets/dating_feedback_snackbar.dart';
import '../../../models/user_model.dart';
import '../../../services/super_like_service.dart';
import '../../communities/models/discover_profile_dismiss_result.dart';
import '../../payment/ui/in_app_purchase/buy_products/buyproducts_bloc.dart';
import '../../payment/ui/in_app_purchase/get_products/getproducts_bloc.dart';
import '../../payment/ui/products.dart';
import '../widgets/hinge_profile_card.dart';
import '../widgets/match_confirmation_modal.dart';

/// Full-screen profile using the same [HingeProfileCard] UI as Connect
/// (Discover "People Near You" and other entry points can use this for
/// consistency instead of [UserDetailScreen]).
class HingeProfileViewerScreen extends StatefulWidget {
  const HingeProfileViewerScreen({
    required this.currentUser,
    required this.profileUser,
    super.key,
  });

  final UserModel currentUser;
  final UserModel profileUser;

  @override
  State<HingeProfileViewerScreen> createState() =>
      _HingeProfileViewerScreenState();
}

class _HingeProfileViewerScreenState extends State<HingeProfileViewerScreen> {
  final SuperLikeService _superLikeService = SuperLikeService();
  bool _actionBusy = false;

  UserModel get _profile => widget.profileUser;
  UserModel get _me => widget.currentUser;

  Future<void> _handleConnect() async {
    final UserModel user = _profile;
    final String? uid = user.id;
    if (uid == null || uid.isEmpty || _actionBusy) return;

    setState(() => _actionBusy = true);
    try {
      final String? matchId =
          await UserSearchRepo.rightSwipe(_me, user);
      if (!mounted) return;

      if (matchId != null) {
        unawaited(HapticFeedback.mediumImpact());
        await showDialog<void>(
          context: context,
          builder: (BuildContext dialogContext) => MatchConfirmationModal(
            currentUserImageUrl: _me.imageUrl?.isNotEmpty ?? false
                ? _me.imageUrl![0]
                : 'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg',
            matchedUserImageUrl:
                user.imageUrl?.isNotEmpty ?? false ? user.imageUrl![0] : '',
            matchedUserName: user.name ?? 'Unknown',
            matchedUserId: user.id!,
          ),
        );
        if (!mounted) return;
        Navigator.pop(
          context,
          DiscoverProfileDismissResult(
            userId: uid,
            removedFromQueue: true,
            wasMatch: true,
          ),
        );
        return;
      }

      unawaited(HapticFeedback.selectionClick());
      if (!mounted) return;
      Navigator.pop(
        context,
        DiscoverProfileDismissResult(
          userId: uid,
          removedFromQueue: true,
        ),
      );
    } on Object {
      if (mounted) {
        setState(() => _actionBusy = false);
        _showError('Failed to connect. Please try again.');
      }
    }
  }

  Future<void> _handlePass() async {
    final UserModel user = _profile;
    final String? uid = user.id;
    if (uid == null || uid.isEmpty || _actionBusy) return;

    setState(() => _actionBusy = true);
    try {
      await UserSearchRepo.leftSwipe(_me, user);
      if (!mounted) return;
      unawaited(HapticFeedback.lightImpact());
      Navigator.pop(
        context,
        DiscoverProfileDismissResult(
          userId: uid,
          removedFromQueue: true,
          wasPass: true,
        ),
      );
    } on Object {
      if (mounted) {
        setState(() => _actionBusy = false);
        _showError('Failed to pass. Please try again.');
      }
    }
  }

  Future<void> _handleSuperLike() async {
    final UserModel user = _profile;
    final String? uid = user.id;
    final String? currentUid = _me.id;
    if (uid == null ||
        uid.isEmpty ||
        currentUid == null ||
        currentUid.isEmpty ||
        _actionBusy) {
      return;
    }

    setState(() => _actionBusy = true);
    try {
      final UserModel fromUser = _me;
      final String? firstPhoto =
          (fromUser.imageUrl?.isNotEmpty ?? false) ? fromUser.imageUrl![0] : null;

      final result = await _superLikeService.sendSuperLike(
        fromUserId: currentUid,
        toUserId: uid,
        fromUserName: fromUser.name,
        fromUserImageUrl: firstPhoto,
        toUserName: user.name,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        if (result.isInstantMatch) {
          unawaited(HapticFeedback.mediumImpact());
          await showDialog<void>(
            context: context,
            builder: (BuildContext dialogContext) => MatchConfirmationModal(
              currentUserImageUrl: fromUser.imageUrl?.isNotEmpty ?? false
                  ? fromUser.imageUrl![0]
                  : 'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg',
              matchedUserImageUrl:
                  user.imageUrl?.isNotEmpty ?? false ? user.imageUrl![0] : '',
              matchedUserName: user.name ?? 'Unknown',
              matchedUserId: user.id!,
            ),
          );
          if (!mounted) return;
          Navigator.pop(
            context,
            DiscoverProfileDismissResult(
              userId: uid,
              removedFromQueue: true,
              wasMatch: true,
            ),
          );
        } else {
          unawaited(HapticFeedback.mediumImpact());
          Navigator.pop(
            context,
            DiscoverProfileDismissResult(
              userId: uid,
              removedFromQueue: true,
            ),
          );
        }
      } else {
        setState(() => _actionBusy = false);
        final String err = result.error ?? 'Could not send Super Like.';
        if (err == SuperLikeService.superLikeLimitReachedMessage) {
          await _showDailySuperLikeLimitSheet();
        } else {
          _showError(err);
        }
      }
    } on Object {
      if (mounted) {
        setState(() => _actionBusy = false);
        _showError('Failed to send Super Like. Please try again.');
      }
    }
  }

  Future<void> _showDailySuperLikeLimitSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: Material(
            color: AppColors.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            clipBehavior: Clip.antiAlias,
            elevation: 8,
            shadowColor: Colors.black26,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.star_rounded,
                    size: 48,
                    color: Color(0xFF2196F3),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Super Like limit reached',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    SuperLikeService.superLikeLimitReachedMessage,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      if (!mounted) return;
                      unawaited(
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => MultiBlocProvider(
                              providers: [
                                BlocProvider(
                                  create: (_) => GetInAppProductsBloc(),
                                ),
                                BlocProvider(
                                  create: (_) =>
                                      BuyConsumableInAppProductsBloc(),
                                ),
                              ],
                              child: Products(_me, null, const {}),
                            ),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Upgrade to Premium',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: Text(
                      'Not now',
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    DatingFeedbackSnackBar.show(
      context,
      message: message,
      backgroundColor: AppColors.error,
      bottomMarginAddition: DatingFeedbackSnackBar.marginAboveProfileActions,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> nameParts =
        (_profile.name ?? '').trim().split(RegExp(r'\s+'));
    final String title =
        nameParts.isEmpty ? 'Profile' : nameParts.first;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: _actionBusy ? null : () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _actionBusy,
          child: SingleChildScrollView(
            child: HingeProfileCard(
              user: _profile,
              onConnect: _handleConnect,
              onPass: _handlePass,
              onSuperLike: _handleSuperLike,
            ),
          ),
        ),
      ),
    );
  }
}
