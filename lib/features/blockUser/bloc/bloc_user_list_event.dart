part of 'bloc_user_list_bloc.dart';

abstract class BlocUserListEvent extends Equatable {
  const BlocUserListEvent();

  @override
  List<Object> get props => [];
}

class LoadBlockUserEvent extends BlocUserListEvent {
  final UserModel currentUser;

  const LoadBlockUserEvent({required this.currentUser});

  @override
  List<Object> get props => [currentUser];
}

class LoadMoreBlockUserEvent extends BlocUserListEvent {
  final UserModel currentUser;

  const LoadMoreBlockUserEvent({required this.currentUser});

  @override
  List<Object> get props => [currentUser];
}
