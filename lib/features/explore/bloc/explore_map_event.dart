part of 'explore_map_bloc.dart';

abstract class SearchUserForMapEvent extends Equatable {
  const SearchUserForMapEvent();

  @override
  List<Object> get props => [];
}

class LoadUserForMapEvent extends SearchUserForMapEvent {
  const LoadUserForMapEvent({required this.currentUser});
  final UserModel currentUser;

  @override
  List<Object> get props => [currentUser];
}
