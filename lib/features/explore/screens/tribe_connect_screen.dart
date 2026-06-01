import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../discovery/presentation/screens/discovery_preferences_screen.dart';
import '../../home/bloc/searchuser_bloc.dart';
import '../../home/ui/screens/user_filter/bloc/userfilter_bloc.dart';
import '../../payment/ui/in_app_purchase/buy_products/buyproducts_bloc.dart';
import '../../payment/ui/in_app_purchase/get_products/getproducts_bloc.dart';
import '../../payment/ui/products.dart';
import '../../../common/constants/app_colors.dart';
import '../../../common/data/repo/user_search_repo.dart';
import '../../../common/widgets/dating_feedback_snackbar.dart';
import '../../../common/widgets/state_views/state_views.dart';
import '../../../models/user_model.dart';
import '../../../common/routes/route_name.dart';
import '../../../services/super_like_service.dart';
import '../../../services/undo_service.dart';
import '../widgets/hinge_profile_card.dart';
import '../widgets/match_confirmation_modal.dart';

class TribeConnectScreen extends StatefulWidget {
  const TribeConnectScreen({
    required this.currentUser,
    required this.users,
    this.onFiltersApplied,
    super.key,
  });
  final UserModel currentUser;
  final List<UserModel> users;
  final Future<void> Function()? onFiltersApplied;

  @override
  State<TribeConnectScreen> createState() => _TribeConnectScreenState();
}

class _TribeConnectScreenState extends State<TribeConnectScreen>
    with TickerProviderStateMixin {
  final Set<String> _processedUserIds = <String>{};
  final SuperLikeService _superLikeService = SuperLikeService();
  final UndoService _undoService = UndoService();
  UserModel? _lastPassedUser;
  bool _isRefreshing = false;
  bool _deckBusy = false;
  String? _pendingExitUid;

  /// While a dismiss animation runs: `false` = like (up-right), `true` = pass (left).
  bool _exitTowardsLeft = false;

  late final AnimationController _likeExitController;
  late final AnimationController _likeEnterController;
  late final CurvedAnimation _likeExitCurved;
  late final CurvedAnimation _likeEnterCurved;

  @override
  void initState() {
    super.initState();
    _likeExitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _likeEnterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1,
    );
    _likeExitCurved = CurvedAnimation(
      parent: _likeExitController,
      curve: Curves.easeInCubic,
    );
    _likeEnterCurved = CurvedAnimation(
      parent: _likeEnterController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _resetDeckAnimations();
    _likeExitCurved.dispose();
    _likeEnterCurved.dispose();
    _likeExitController.dispose();
    _likeEnterController.dispose();
    super.dispose();
  }

  void _resetDeckAnimations() {
    _likeExitController.removeStatusListener(_onCardExitStatus);
    _likeExitController.stop();
    _likeExitController.reset();
    _likeEnterController.value = 1;
    _pendingExitUid = null;
    _deckBusy = false;
    _exitTowardsLeft = false;
  }

  void _onCardExitStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _likeExitController.removeStatusListener(_onCardExitStatus);
    final String? uid = _pendingExitUid;
    _pendingExitUid = null;
    if (uid == null || !mounted) return;
    final bool wasPass = _exitTowardsLeft;
    setState(() {
      _processedUserIds.add(uid);
      _deckBusy = false;
      _exitTowardsLeft = false;
      _likeExitController.reset();
      _likeEnterController.value = 0;
    });
    unawaited(
      wasPass ? HapticFeedback.lightImpact() : HapticFeedback.selectionClick(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_likeEnterController.forward());
      }
    });
    if (wasPass) {
      unawaited(_offerUndoPass());
    }
    _advanceProfile();
  }

  List<UserModel> get _availableUsers => widget.users
      .where(
        (user) =>
            user.id != null &&
            user.id!.isNotEmpty &&
            !_processedUserIds.contains(user.id),
      )
      .toList();

  UserModel? get _currentProfile =>
      _availableUsers.isNotEmpty ? _availableUsers.first : null;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: _buildAppBar(),
        body: _buildBody(),
      );

  PreferredSizeWidget _buildAppBar() => AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: Text(
          'Connect',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed(
              RouteName.likesReceived,
              arguments: widget.currentUser,
            ),
            tooltip: 'Likes You',
            icon: const Icon(
              Icons.favorite_border,
              color: AppColors.textPrimary,
            ),
          ),
          IconButton(
            onPressed: () => unawaited(_openDiscoveryPreferences()),
            tooltip: 'Filters',
            icon: const FaIcon(
              FontAwesomeIcons.sliders,
              size: 20,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      );

  Widget _buildBody() {
    if (widget.users.isEmpty) {
      return _buildEmptyState();
    }

    final currentProfile = _currentProfile;

    if (currentProfile == null || _availableUsers.isEmpty) {
      return _buildEmptyState();
    }

    // One profile at a time; scroll vertically for full card details.
    // Like / pass: directional exit motion + next profile enters from below.
    return SingleChildScrollView(
      child: _wrapDeckMotion(
        child: AbsorbPointer(
          absorbing: _deckBusy || _likeExitController.isAnimating,
          child: HingeProfileCard(
            user: currentProfile,
            onConnect: () => _handleConnect(currentProfile),
            onPass: () => _handlePass(currentProfile),
            onSuperLike: () => _handleSuperLike(currentProfile),
          ),
        ),
      ),
    );
  }

  Widget _wrapDeckMotion({required Widget child}) => AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[
          _likeExitCurved,
          _likeEnterCurved,
        ]),
        builder: (BuildContext context, Widget? _) => _buildDeckMotionLayer(
          exitT: _likeExitCurved.value,
          enterT: _likeEnterCurved.value,
          child: child,
        ),
      );

  /// Next card stays opaque while sliding up (avoids a one-frame flash).
  Widget _buildDeckMotionLayer({
    required double exitT,
    required double enterT,
    required Widget child,
  }) {
    final bool exiting = exitT > 0;
    final double opacity = exiting ? (1.0 - exitT).clamp(0.0, 1.0) : 1.0;
    final double scale =
        exiting ? (1.0 - 0.06 * exitT) : (0.96 + 0.04 * enterT);
    final Offset offset = exiting
        ? (_exitTowardsLeft
            ? Offset(-96 * exitT, -32 * exitT)
            : Offset(88 * exitT, -72 * exitT))
        : Offset(0, 28 * (1 - enterT));
    return Transform.translate(
      offset: offset,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: child,
        ),
      ),
    );
  }

  Widget _buildEmptyState() => AppEmptyView(
        title: 'No More Profiles',
        subtitle:
            'You\'ve seen everyone for now. Pull to refresh later or tap Refresh to reload.',
        icon: Icons.explore_off,
        actionLabel: 'Refresh',
        onAction: _isRefreshing ? null : _refreshUsers,
      );

  Future<void> _refreshUsers() async {
    setState(() {
      _isRefreshing = true;
      _processedUserIds.clear();
    });
    _resetDeckAnimations();
    try {
      await widget.onFiltersApplied?.call();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _openDiscoveryPreferences() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => BlocProvider<UserfilterBloc>(
          create: (_) => UserfilterBloc(),
          child: BlocProvider<SearchUserBloc>(
            create: (_) => SearchUserBloc(),
            child: DiscoveryPreferencesScreen(
              currentUser: widget.currentUser,
              isPurchased: widget.currentUser.hasPremiumAccess,
              items: const <String, dynamic>{},
            ),
          ),
        ),
      ),
    );
    if (!mounted) return;
    setState(_processedUserIds.clear);
    _resetDeckAnimations();
    await widget.onFiltersApplied?.call();
  }

  Future<void> _handleConnect(UserModel user) async {
    final uid = user.id;
    if (uid == null || uid.isEmpty) return;
    if (_deckBusy || _likeExitController.isAnimating) return;

    setState(() => _deckBusy = true);
    try {
      final String? matchId =
          await UserSearchRepo.rightSwipe(widget.currentUser, user);

      if (!mounted) return;

      if (matchId != null) {
        setState(() {
          _processedUserIds.add(uid);
          _deckBusy = false;
        });
        unawaited(HapticFeedback.mediumImpact());
        _showMatchConfirmation(user);
        _advanceProfile();
        return;
      }

      _exitTowardsLeft = false;
      _pendingExitUid = uid;
      _likeExitController.addStatusListener(_onCardExitStatus);
      unawaited(_likeExitController.forward());
    } on Object {
      if (mounted) {
        setState(() => _deckBusy = false);
        _showError('Failed to connect. Please try again.');
      }
    }
  }

  Future<void> _handlePass(UserModel user) async {
    final uid = user.id;
    if (uid == null || uid.isEmpty) return;
    if (_deckBusy || _likeExitController.isAnimating) return;

    setState(() => _deckBusy = true);
    try {
      await UserSearchRepo.leftSwipe(widget.currentUser, user);

      final currentUid = widget.currentUser.id;
      if (currentUid != null && currentUid.isNotEmpty) {
        await _undoService.recordSwipeAction(
          userId: currentUid,
          targetUserId: uid,
          direction: SwipeDirection.left,
        );
        _lastPassedUser = user;
      }

      if (!mounted) return;

      _exitTowardsLeft = true;
      _pendingExitUid = uid;
      _likeExitController.addStatusListener(_onCardExitStatus);
      unawaited(_likeExitController.forward());
    } on Object {
      if (mounted) {
        setState(() => _deckBusy = false);
        _showError('Failed to pass. Please try again.');
      }
    }
  }

  Future<void> _handleSuperLike(UserModel user) async {
    final uid = user.id;
    final currentUid = widget.currentUser.id;
    if (uid == null ||
        uid.isEmpty ||
        currentUid == null ||
        currentUid.isEmpty) {
      return;
    }
    if (_deckBusy || _likeExitController.isAnimating) return;

    try {
      setState(() => _processedUserIds.add(uid));

      final fromUser = widget.currentUser;
      final firstPhoto = (fromUser.imageUrl?.isNotEmpty ?? false)
          ? fromUser.imageUrl![0]
          : null;

      final result = await _superLikeService.sendSuperLike(
        fromUserId: currentUid,
        toUserId: uid,
        fromUserName: fromUser.name,
        fromUserImageUrl: firstPhoto,
        toUserName: user.name,
      );

      if (!mounted) {
        return;
      }

      if (result.isSuccess) {
        if (result.isInstantMatch) {
          _showMatchConfirmation(user);
        } else {
          unawaited(HapticFeedback.mediumImpact());
        }
      } else {
        setState(() => _processedUserIds.remove(uid));
        final err = result.error ?? 'Could not send Super Like.';
        if (err == SuperLikeService.superLikeLimitReachedMessage) {
          if (!mounted) {
            return;
          }
          await _showDailySuperLikeLimitSheet();
        } else {
          _showError(err);
        }
        return;
      }

      _advanceProfile();
    } on Object {
      setState(() => _processedUserIds.remove(uid));
      _showError('Failed to send Super Like. Please try again.');
    }
  }

  void _advanceProfile() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() {});
    });
  }

  void _showMatchConfirmation(UserModel user) {
    unawaited(
      showDialog(
        context: context,
        builder: (context) => MatchConfirmationModal(
          currentUserImageUrl: widget.currentUser.imageUrl?.isNotEmpty ?? false
              ? widget.currentUser.imageUrl![0]
              : 'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg',
          matchedUserImageUrl:
              user.imageUrl?.isNotEmpty ?? false ? user.imageUrl![0] : '',
          matchedUserName: user.name ?? 'Unknown',
          matchedUserId: user.id!,
        ),
      ),
    );
  }

  /// Weekly Super Like quota exhausted: compact sheet with upgrade path.
  Future<void> _showDailySuperLikeLimitSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
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
                children: [
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
                      if (!mounted) {
                        return;
                      }
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
                              child:
                                  Products(widget.currentUser, null, const {}),
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

  Future<void> _offerUndoPass() async {
    final currentUid = widget.currentUser.id;
    final passedUser = _lastPassedUser;
    if (currentUid == null || passedUser?.id == null || !mounted) return;

    final canUndo = await _undoService.canUndoLastSwipe(currentUid);
    if (!canUndo || !mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Passed on ${passedUser!.name ?? 'this profile'}',
          style: GoogleFonts.montserrat(color: Colors.white),
        ),
        duration: UndoService.undoWindow,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.amberAccent,
          onPressed: () => unawaited(_undoLastPass(passedUser)),
        ),
      ),
    );
  }

  Future<void> _undoLastPass(UserModel passedUser) async {
    final currentUid = widget.currentUser.id;
    final passedUid = passedUser.id;
    if (currentUid == null || passedUid == null || !mounted) return;

    final result = await _undoService.undoLastSwipe(currentUid);
    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _processedUserIds.remove(passedUid);
        _lastPassedUser = null;
        _deckBusy = false;
      });
      _resetDeckAnimations();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pass undone',
            style: GoogleFonts.montserrat(color: Colors.white),
          ),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
      return;
    }

    _showError(result.error ?? 'Could not undo pass');
  }
}
