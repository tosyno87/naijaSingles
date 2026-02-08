part of 'bloc_user_list_bloc.dart';

abstract class BlocUserListState extends Equatable {
  const BlocUserListState();

  @override
  List<Object> get props => [];
}

class BlocUserListInitial extends BlocUserListState {}

class BlockUserLoadingState extends BlocUserListState {}

class BlockUserLoadedState extends BlocUserListState {
  const BlockUserLoadedState(this.users);
  final List<BlockUserModel> users;

  @override
  List<Object> get props => [users];
}

class BlockUserFailedState extends BlocUserListState {}
