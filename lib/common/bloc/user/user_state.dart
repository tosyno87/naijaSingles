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
  final UserModel? user;

  const UserLoaded(this.user);

  @override
  List<Object?> get props => [user];
}

/// Error loading user data
class UserError extends UserState {
  final String message;

  const UserError(this.message);

  @override
  List<Object?> get props => [message];
}
