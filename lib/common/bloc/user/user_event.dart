part of 'user_bloc.dart';

/// Base class for user events
abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

/// Event to start listening to user details
class UserListenStarted extends UserEvent {
  const UserListenStarted();
}

/// Event to stop listening to user details
class UserListenStopped extends UserEvent {
  const UserListenStopped();
}

/// Event to refresh user details (auth logged in) - does NOT re-add auth listener
class UserRefreshUserDetails extends UserEvent {
  const UserRefreshUserDetails();
}

/// Event when user data is updated
class UserDataUpdated extends UserEvent {
  const UserDataUpdated(this.user);
  final UserModel? user;

  @override
  List<Object?> get props => [user];
}

/// Event when authentication state changes
class UserAuthStateChanged extends UserEvent {
  const UserAuthStateChanged(this.isAuthenticated);
  final bool isAuthenticated;

  @override
  List<Object?> get props => [isAuthenticated];
}
