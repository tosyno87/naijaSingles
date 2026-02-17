import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/account_status_service.dart';
import 'account_status_event.dart';
import 'account_status_state.dart';

class AccountStatusBloc extends Bloc<AccountStatusEvent, AccountStatusState> {
  AccountStatusBloc({AccountStatusService? service})
      : _service = service ?? AccountStatusService(),
        super(const AccountStatusInitial()) {
    on<LoadAccountStatus>(_onLoad);
    on<PauseAccount>(_onPause);
    on<EnableIncognito>(_onIncognito);
    on<ReactivateAccount>(_onReactivate);
  }

  final AccountStatusService _service;
  StreamSubscription<String>? _statusSub;

  Future<void> _onLoad(
    LoadAccountStatus event,
    Emitter<AccountStatusState> emit,
  ) async {
    emit(const AccountStatusLoading());
    try {
      // Start a real-time stream so the UI stays in sync.
      await _statusSub?.cancel();
      await emit.forEach<String>(
        _service.watchAccountStatus(event.userId),
        onData: (status) => AccountStatusLoaded(status),
        onError: (error, _) =>
            AccountStatusError('Failed to load status: $error'),
      );
    } on Exception catch (e) {
      debugPrint('AccountStatusBloc load error: $e');
      emit(AccountStatusError(e.toString()));
    }
  }

  Future<void> _onPause(
    PauseAccount event,
    Emitter<AccountStatusState> emit,
  ) async {
    emit(const AccountStatusLoading());
    try {
      await _service.pauseAccount(
        userId: event.userId,
        reason: event.reason,
      );
      // Stream will emit the new status automatically.
    } on Exception catch (e) {
      debugPrint('AccountStatusBloc pause error: $e');
      emit(AccountStatusError('Failed to pause account: $e'));
    }
  }

  Future<void> _onIncognito(
    EnableIncognito event,
    Emitter<AccountStatusState> emit,
  ) async {
    emit(const AccountStatusLoading());
    try {
      await _service.enableIncognito(
        userId: event.userId,
        reason: event.reason,
      );
    } on Exception catch (e) {
      debugPrint('AccountStatusBloc incognito error: $e');
      emit(AccountStatusError('Failed to enable incognito: $e'));
    }
  }

  Future<void> _onReactivate(
    ReactivateAccount event,
    Emitter<AccountStatusState> emit,
  ) async {
    emit(const AccountStatusLoading());
    try {
      await _service.reactivateAccount(userId: event.userId);
    } on Exception catch (e) {
      debugPrint('AccountStatusBloc reactivate error: $e');
      emit(AccountStatusError('Failed to reactivate account: $e'));
    }
  }

  @override
  Future<void> close() async {
    await _statusSub?.cancel();
    return super.close();
  }
}
