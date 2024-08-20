part of 'explore_map_bloc.dart';

abstract class SearchUserForMapEvent extends Equatable {
  const SearchUserForMapEvent();

  @override
  List<Object> get props => [];
}

class LoadUserForMapEvent extends SearchUserForMapEvent {
  final UserModel currentUser;
 

  const LoadUserForMapEvent({required this.currentUser});

  @override
  List<Object> get props => [currentUser];
}
