part of 'searchuser_bloc.dart';

abstract class SearchUserEvent extends Equatable {
  const SearchUserEvent();

  @override
  List<Object> get props => [];
}

class LoadUserEvent extends SearchUserEvent {
  final UserModel currentUser;

  const LoadUserEvent({required this.currentUser});

  @override
  List<Object> get props => [currentUser];
}

class LoadNearbyUsersEvent extends SearchUserEvent {
  final UserModel currentUser;
  final double radiusMiles;

  const LoadNearbyUsersEvent({
    required this.currentUser,
    required this.radiusMiles,
  });

  @override
  List<Object> get props => [currentUser, radiusMiles];
}

class CheckMigrationStatusEvent extends SearchUserEvent {
  final String userId;

  const CheckMigrationStatusEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}
