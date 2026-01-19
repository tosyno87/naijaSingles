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

/// Event when user data is updated
class UserDataUpdated extends UserEvent {
  final UserModel? user;

  const UserDataUpdated(this.user);

  @override
  List<Object?> get props => [user];
}

/// Event when authentication state changes
class UserAuthStateChanged extends UserEvent {
  final bool isAuthenticated;

  const UserAuthStateChanged(this.isAuthenticated);

  @override
  List<Object?> get props => [isAuthenticated];
}
