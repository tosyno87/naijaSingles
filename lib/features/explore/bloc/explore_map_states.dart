part of 'explore_map_bloc.dart';

abstract class SearchUserForMapState extends Equatable {
  const SearchUserForMapState();

  @override
  List<Object> get props => [];
}

class SearchuserForMapInitial extends SearchUserForMapState {}

class SearchUserLoadingForMapState extends SearchUserForMapState {}

class SearchUserLoadUserForMapState extends SearchUserForMapState {
  const SearchUserLoadUserForMapState(this.users);
  final List<UserModel> users;

  @override
  List<Object> get props => [users];
}

class SearchUserFailedForMapState extends SearchUserForMapState {}
