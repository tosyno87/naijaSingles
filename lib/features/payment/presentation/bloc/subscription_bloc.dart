import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../../common/bloc/user/user_bloc.dart';
import '../../../../common/data/repo/in_app_purchase_repo.dart';
import '../../../../config/app_config.dart';
import '../../../../services/subscription_iap_analytics.dart';
import '../../data/subscription_functions_service.dart';
import '../../iap_user_facing_message.dart';

// --- Events ---

sealed class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();
  @override
  List<Object?> get props => [];
}

final class SubscriptionUserChanged extends SubscriptionEvent {
  const SubscriptionUserChanged(this.uid);
  final String? uid;
  @override
  List<Object?> get props => [uid];
}

final class SubscriptionPurchaseBatch extends SubscriptionEvent {
  const SubscriptionPurchaseBatch(this.purchases);
  final List<PurchaseDetails> purchases;
  @override
  List<Object?> get props => [purchases];
}

final class SubscriptionRestoreRequested extends SubscriptionEvent {
  const SubscriptionRestoreRequested();
}

final class SubscriptionConsumeUserMessage extends SubscriptionEvent {
  const SubscriptionConsumeUserMessage();
}

final class SubscriptionConsumeNavigateSuccess extends SubscriptionEvent {
  const SubscriptionConsumeNavigateSuccess();
}

final class SubscriptionRestoreTimedOut extends SubscriptionEvent {
  const SubscriptionRestoreTimedOut();
}

final class SubscriptionPurchaseStreamFailed extends SubscriptionEvent {
  const SubscriptionPurchaseStreamFailed(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// --- State ---

class SubscriptionState extends Equatable {
  const SubscriptionState({
    this.purchaseInProgress = false,
    this.restoreInProgress = false,
    this.userMessage,
    this.restoreSuccess,
    this.shouldNavigateToSuccess = false,
    this.lastError,
  });

  final bool purchaseInProgress;
  final bool restoreInProgress;
  final String? userMessage;
  final bool? restoreSuccess;
  final bool shouldNavigateToSuccess;
  final String? lastError;

  SubscriptionState copyWith({
    bool? purchaseInProgress,
    bool? restoreInProgress,
    String? userMessage,
    bool? restoreSuccess,
    bool? shouldNavigateToSuccess,
    String? lastError,
    bool clearUserMessage = false,
    bool clearRestoreSuccess = false,
    bool clearNavigate = false,
    bool clearError = false,
  }) =>
      SubscriptionState(
        purchaseInProgress: purchaseInProgress ?? this.purchaseInProgress,
        restoreInProgress: restoreInProgress ?? this.restoreInProgress,
        userMessage:
            clearUserMessage ? null : (userMessage ?? this.userMessage),
        restoreSuccess: clearRestoreSuccess
            ? null
            : (restoreSuccess ?? this.restoreSuccess),
        shouldNavigateToSuccess: clearNavigate
            ? false
            : (shouldNavigateToSuccess ?? this.shouldNavigateToSuccess),
        lastError: clearError ? null : (lastError ?? this.lastError),
      );

  @override
  List<Object?> get props => [
        purchaseInProgress,
        restoreInProgress,
        userMessage,
        restoreSuccess,
        shouldNavigateToSuccess,
        lastError,
      ];
}

/// Central IAP purchase stream + restore + server verification.
class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  SubscriptionBloc({
    required UserBloc userBloc,
    SubscriptionFunctionsService? functionsService,
    Future<bool> Function()? isStoreAvailable,
    Stream<List<PurchaseDetails>> Function()? purchaseUpdates,
  })  : _userBloc = userBloc,
        _functions = functionsService ?? SubscriptionFunctionsService(),
        _isStoreAvailable =
            isStoreAvailable ?? (() => InAppPurchase.instance.isAvailable()),
        _purchaseUpdates =
            purchaseUpdates ?? (() => InAppPurchase.instance.purchaseStream),
        super(const SubscriptionState()) {
    on<SubscriptionUserChanged>(_onUserChanged);
    on<SubscriptionPurchaseBatch>(_onPurchaseBatch);
    on<SubscriptionRestoreRequested>(_onRestore);
    on<SubscriptionConsumeUserMessage>(_onConsumeMessage);
    on<SubscriptionConsumeNavigateSuccess>(_onConsumeNavigate);
    on<SubscriptionRestoreTimedOut>(_onRestoreTimedOut);
    on<SubscriptionPurchaseStreamFailed>(_onPurchaseStreamFailed);

    _applyUserState(userBloc.state);
    _userSub = userBloc.stream.listen(_applyUserState);
  }

  final UserBloc _userBloc;
  final SubscriptionFunctionsService _functions;
  final Future<bool> Function() _isStoreAvailable;
  final Stream<List<PurchaseDetails>> Function() _purchaseUpdates;

  late final StreamSubscription<UserState> _userSub;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  String? _uid;
  final Set<String> _processedKeys = {};

  /// Store updates that arrived before [_uid] was known (cold start only).
  /// Cleared on logout / account switch. Never flushed after a signed-out period.
  final List<PurchaseDetails> _pendingPurchases = [];

  /// When true, unsigned store updates may be buffered for the first login
  /// (app cold start). After logout this is false so post-logout store events
  /// are dropped instead of applied to the next account.
  bool _bufferUnsignedPurchases = true;

  bool _awaitingRestore = false;
  Timer? _restoreTimer;

  static String _iapPlatformLabel() {
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    return 'other';
  }

  void _applyUserState(UserState state) {
    if (state is UserLoaded) {
      add(SubscriptionUserChanged(state.user?.id));
    } else if (state is UserInitial || state is UserError) {
      add(const SubscriptionUserChanged(null));
    }
  }

  /// Awaitable: set [uid] and ensure `purchaseStream` is attached before buy.
  ///
  /// Prefer this over fire-and-forget [SubscriptionUserChanged] right before
  /// starting a store purchase — [SubscriptionUserChanged] returns before the
  /// async listener setup finishes.
  Future<void> prepareForPurchase(String uid) async {
    if (uid.isEmpty) {
      throw ArgumentError.value(uid, 'uid', 'must be non-empty');
    }

    final String? previous = _uid;
    if (previous != null && previous.isNotEmpty && previous != uid) {
      _pendingPurchases.clear();
      _processedKeys.clear();
    }
    // Post-logout: never apply anything buffered while signed out.
    if (!_bufferUnsignedPurchases) {
      _pendingPurchases.clear();
    }
    _uid = uid;
    _bufferUnsignedPurchases = false;

    await _ensurePurchaseStreamListening();

    if (_pendingPurchases.isNotEmpty) {
      final List<PurchaseDetails> pending =
          List<PurchaseDetails>.from(_pendingPurchases);
      _pendingPurchases.clear();
      add(SubscriptionPurchaseBatch(pending));
    }
  }

  Future<void> _ensurePurchaseStreamListening() async {
    if (_purchaseSub != null) return;

    final bool available = await _isStoreAvailable();
    if (!available) return;

    await InAppPurchaseRepoImpl.ensureIosPaymentQueueDelegate();
    _purchaseSub = _purchaseUpdates().listen(
      (purchases) => add(SubscriptionPurchaseBatch(purchases)),
      onError: (Object e) =>
          add(SubscriptionPurchaseStreamFailed(e.toString())),
    );
  }

  Future<void> _onUserChanged(
    SubscriptionUserChanged event,
    Emitter<SubscriptionState> emit,
  ) async {
    final String? previousUid = _uid;
    final String? nextUid = event.uid;
    final bool uidChanged = nextUid != previousUid;

    // Logout / signed-out: drop pending. Only disable unsigned buffering after a
    // real logout (we previously had a uid) — not on cold-start UserInitial(null).
    if (nextUid == null || nextUid.isEmpty) {
      _pendingPurchases.clear();
      if (previousUid != null && previousUid.isNotEmpty) {
        _bufferUnsignedPurchases = false;
      }
      _uid = nextUid;
      if (uidChanged) {
        _processedKeys.clear();
      }
      await _ensurePurchaseStreamListening();
      return;
    }

    // Account switch: drop any buffered updates from the previous session.
    if (previousUid != null &&
        previousUid.isNotEmpty &&
        previousUid != nextUid) {
      _pendingPurchases.clear();
    }

    // Login after logout: unsigned batches must not be applied to the new user.
    if (!_bufferUnsignedPurchases) {
      _pendingPurchases.clear();
    }

    _uid = nextUid;
    _bufferUnsignedPurchases = false;
    if (uidChanged) {
      _processedKeys.clear();
    }

    await _ensurePurchaseStreamListening();

    // Cold-start only: uid arrived after store updates were buffered.
    if (_pendingPurchases.isNotEmpty) {
      final List<PurchaseDetails> pending =
          List<PurchaseDetails>.from(_pendingPurchases);
      _pendingPurchases.clear();
      await _processPurchaseBatch(pending, emit);
    }
  }

  void _onPurchaseStreamFailed(
    SubscriptionPurchaseStreamFailed event,
    Emitter<SubscriptionState> emit,
  ) {
    emit(state.copyWith(lastError: event.message));
    unawaited(
      SubscriptionIapAnalytics.logPurchaseStreamError(
        platform: _iapPlatformLabel(),
        message: event.message,
      ),
    );
  }

  void _onRestoreTimedOut(
    SubscriptionRestoreTimedOut event,
    Emitter<SubscriptionState> emit,
  ) {
    if (!state.restoreInProgress) return;
    _awaitingRestore = false;
    emit(state.copyWith(
      restoreInProgress: false,
      restoreSuccess: false,
      userMessage:
          'No active subscription was found. If you use a different Apple/Google account for billing, sign in with that account in the store settings.',
    ));
    unawaited(
      SubscriptionIapAnalytics.logRestoreOutcome(
        platform: _iapPlatformLabel(),
        outcome: 'timeout',
      ),
    );
  }

  Future<void> _onPurchaseBatch(
    SubscriptionPurchaseBatch event,
    Emitter<SubscriptionState> emit,
  ) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      // Cold start only. After logout, drop — do not hand to the next login.
      if (!_bufferUnsignedPurchases) {
        return;
      }
      _pendingPurchases.addAll(event.purchases);
      final bool showProgress = event.purchases.any(
        (p) =>
            p.status == PurchaseStatus.pending ||
            p.status == PurchaseStatus.purchased ||
            p.status == PurchaseStatus.restored,
      );
      if (showProgress) {
        emit(state.copyWith(purchaseInProgress: true));
      }
      return;
    }

    await _processPurchaseBatch(event.purchases, emit);
  }

  Future<void> _processPurchaseBatch(
    List<PurchaseDetails> purchases,
    Emitter<SubscriptionState> emit,
  ) async {
    for (final purchase in purchases) {
      final key =
          '${purchase.purchaseID ?? ""}|${purchase.productID}|${purchase.status.name}';
      if (_processedKeys.contains(key)) continue;

      if (purchase.status == PurchaseStatus.pending) {
        emit(state.copyWith(purchaseInProgress: true));
        continue;
      }

      if (purchase.status == PurchaseStatus.error) {
        emit(state.copyWith(
          purchaseInProgress: false,
          userMessage: userFacingIapStoreErrorMessage(purchase.error),
          lastError: purchase.error?.toString(),
        ));
        _processedKeys.add(key);
        unawaited(
          SubscriptionIapAnalytics.logPurchaseFailed(
            platform: _iapPlatformLabel(),
            productId: purchase.productID,
            message: purchase.error?.message,
          ),
        );
        continue;
      }

      if (purchase.status == PurchaseStatus.canceled) {
        emit(state.copyWith(purchaseInProgress: false));
        _processedKeys.add(key);
        continue;
      }

      if (purchase.status != PurchaseStatus.purchased &&
          purchase.status != PurchaseStatus.restored) {
        continue;
      }

      // Profile boost is a separate consumable — never treat it as Premium.
      if (InAppPurchaseRepoImpl.isBoostProductId(purchase.productID)) {
        _processedKeys.add(key);
        continue;
      }

      _processedKeys.add(key);
      emit(state.copyWith(purchaseInProgress: true));

      try {
        final bool verifyForRestore = _awaitingRestore;
        await _verifyWithServer(purchase);

        if (purchase.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchase);
        }

        unawaited(
          SubscriptionIapAnalytics.logVerifySucceeded(
            platform: _iapPlatformLabel(),
            productId: purchase.productID,
            isRestoreFlow: verifyForRestore,
          ),
        );

        _userBloc.add(const UserRefreshUserDetails());

        if (_awaitingRestore) {
          _restoreTimer?.cancel();
          _awaitingRestore = false;
          emit(state.copyWith(
            purchaseInProgress: false,
            restoreInProgress: false,
            restoreSuccess: true,
            shouldNavigateToSuccess: false,
            userMessage: 'Subscription restored',
          ));
          unawaited(
            SubscriptionIapAnalytics.logRestoreOutcome(
              platform: _iapPlatformLabel(),
              outcome: 'success',
              detail: purchase.productID,
            ),
          );
        } else {
          // Navigate only — do not also set userMessage. Paywall listeners
          // would show a SnackBar and pushReplacement in the same frame,
          // which asserts '_dependents.isEmpty' while ScaffoldMessenger
          // tears down. Tabbar shows "Payment Successful!" via isPaymentSuccess.
          emit(state.copyWith(
            purchaseInProgress: false,
            shouldNavigateToSuccess: true,
          ));
        }
      } on Object catch (e) {
        _restoreTimer?.cancel();
        final bool wasRestore = _awaitingRestore;
        _awaitingRestore = false;
        emit(state.copyWith(
          purchaseInProgress: false,
          restoreInProgress: false,
          lastError: e.toString(),
          userMessage: userFacingSubscriptionVerifyMessage(e),
          restoreSuccess: wasRestore ? false : state.restoreSuccess,
        ));
        unawaited(
          SubscriptionIapAnalytics.logVerifyFailed(
            platform: _iapPlatformLabel(),
            productId: purchase.productID,
            isRestoreFlow: wasRestore,
            error: e,
          ),
        );
        if (wasRestore) {
          unawaited(
            SubscriptionIapAnalytics.logRestoreOutcome(
              platform: _iapPlatformLabel(),
              outcome: 'verify_failed',
              detail: e.toString(),
            ),
          );
        }
      }
    }
  }

  Future<void> _verifyWithServer(PurchaseDetails purchase) async {
    if (!AppConfig.subscriptionVerifyRollout) {
      throw StateError(
        'SUBSCRIPTION_VERIFY_ROLLOUT=false: turn on the dart-define or deploy '
        'verifySubscriptionPurchase before shipping IAP.',
      );
    }
    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : defaultTargetPlatform == TargetPlatform.android
            ? 'android'
            : 'android';
    final token = purchase.verificationData.serverVerificationData;
    await _functions.verifySubscriptionPurchase(
      platform: platform,
      productId: purchase.productID,
      purchaseToken: platform == 'android' ? token : null,
      receiptData: platform == 'ios' ? token : null,
      packageName: AppConfig.androidApplicationId,
    );
  }

  Future<void> _onRestore(
    SubscriptionRestoreRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    final uid = _uid;
    if (uid == null) return;

    final iap = InAppPurchase.instance;
    if (!await iap.isAvailable()) {
      emit(state.copyWith(
        userMessage: 'Store not available.',
        restoreSuccess: false,
      ));
      unawaited(
        SubscriptionIapAnalytics.logRestoreOutcome(
          platform: _iapPlatformLabel(),
          outcome: 'store_unavailable',
        ),
      );
      return;
    }

    emit(state.copyWith(
      restoreInProgress: true,
      restoreSuccess: null,
      userMessage: null,
    ));
    _awaitingRestore = true;
    _restoreTimer?.cancel();
    _restoreTimer = Timer(const Duration(seconds: 14), () {
      if (_awaitingRestore) {
        _awaitingRestore = false;
        add(const SubscriptionRestoreTimedOut());
      }
    });

    try {
      await iap.restorePurchases();
    } on Object catch (e) {
      _restoreTimer?.cancel();
      _awaitingRestore = false;
      emit(state.copyWith(
        restoreInProgress: false,
        restoreSuccess: false,
        userMessage: userFacingPurchaseThrowableMessage(e),
      ));
      unawaited(
        SubscriptionIapAnalytics.logRestoreOutcome(
          platform: _iapPlatformLabel(),
          outcome: 'native_exception',
          detail: e.toString(),
        ),
      );
    }
  }

  void _onConsumeMessage(
    SubscriptionConsumeUserMessage event,
    Emitter<SubscriptionState> emit,
  ) {
    emit(state.copyWith(clearUserMessage: true, clearRestoreSuccess: true));
  }

  void _onConsumeNavigate(
    SubscriptionConsumeNavigateSuccess event,
    Emitter<SubscriptionState> emit,
  ) {
    emit(state.copyWith(clearNavigate: true));
  }

  @override
  Future<void> close() async {
    await _purchaseSub?.cancel();
    await _userSub.cancel();
    _restoreTimer?.cancel();
    return super.close();
  }
}
