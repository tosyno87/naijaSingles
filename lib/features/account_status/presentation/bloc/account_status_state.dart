import 'package:flutter/foundation.dart';

@immutable
abstract class AccountStatusState {
  const AccountStatusState();
}

class AccountStatusInitial extends AccountStatusState {
  const AccountStatusInitial();
}

class AccountStatusLoading extends AccountStatusState {
  const AccountStatusLoading();
}

/// The account status was loaded successfully.
class AccountStatusLoaded extends AccountStatusState {
  const AccountStatusLoaded(this.status);

  /// One of: 'active', 'paused', 'incognito', 'deleted', 'banned'.
  final String status;

  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';
  bool get isIncognito => status == 'incognito';
  bool get isDeactivated => status == 'paused' || status == 'incognito';
}

class AccountStatusError extends AccountStatusState {
  const AccountStatusError(this.message);
  final String message;
}
