part of 'user_bloc.dart';

/// Base class for user states
abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

/// Initial state - no user data loaded
class UserInitial extends UserState {
  const UserInitial();
}

/// User data is loading
class UserLoading extends UserState {
  const UserLoading();
}

/// User data loaded successfully
class UserLoaded extends UserState {

  const UserLoaded(this.user);
  final UserModel? user;

  @override
  List<Object?> get props => [user];
}

/// Error loading user data
class UserError extends UserState {

  const UserError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
