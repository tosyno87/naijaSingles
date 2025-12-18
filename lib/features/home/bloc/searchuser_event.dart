part of 'searchuser_bloc.dart';

abstract class SearchUserEvent extends Equatable {
  const SearchUserEvent();

  @override
  List<Object> get props => [];
}

class LoadUserEvent extends SearchUserEvent {

  const LoadUserEvent({required this.currentUser});
  final UserModel currentUser;

  @override
  List<Object> get props => [currentUser];
}

class LoadNearbyUsersEvent extends SearchUserEvent {

  const LoadNearbyUsersEvent({
    required this.currentUser,
    required this.radiusMiles,
  });
  final UserModel currentUser;
  final double radiusMiles;

  @override
  List<Object> get props => [currentUser, radiusMiles];
}

class CheckMigrationStatusEvent extends SearchUserEvent {

  const CheckMigrationStatusEvent({required this.userId});
  final String userId;

  @override
  List<Object> get props => [userId];
}
