part of 'bloc_user_list_bloc.dart';

abstract class BlocUserListEvent extends Equatable {
  const BlocUserListEvent();

  @override
  List<Object> get props => [];
}

class LoadBlockUserEvent extends BlocUserListEvent {
  const LoadBlockUserEvent({required this.currentUser});
  final UserModel currentUser;

  @override
  List<Object> get props => [currentUser];
}

class LoadMoreBlockUserEvent extends BlocUserListEvent {
  const LoadMoreBlockUserEvent({required this.currentUser});
  final UserModel currentUser;

  @override
  List<Object> get props => [currentUser];
}
