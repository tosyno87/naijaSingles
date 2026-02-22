import 'package:flutter/foundation.dart';

@immutable
abstract class AccountStatusEvent {
  const AccountStatusEvent();
}

/// Load / subscribe to the current user's account status.
class LoadAccountStatus extends AccountStatusEvent {
  const LoadAccountStatus(this.userId);
  final String userId;
}

/// Pause the account (hidden from discovery, chats/matches intact).
class PauseAccount extends AccountStatusEvent {
  const PauseAccount({required this.userId, this.reason});
  final String userId;
  final String? reason;
}

/// Enable incognito mode (hidden from discovery, chats/matches accessible).
class EnableIncognito extends AccountStatusEvent {
  const EnableIncognito({required this.userId, this.reason});
  final String userId;
  final String? reason;
}

/// Reactivate the account (fully discoverable again).
class ReactivateAccount extends AccountStatusEvent {
  const ReactivateAccount({required this.userId});
  final String userId;
}
