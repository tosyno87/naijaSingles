part of 'bloc_user_list_bloc.dart';

abstract class BlocUserListState extends Equatable {
  const BlocUserListState();

  @override
  List<Object> get props => [];
}

class BlocUserListInitial extends BlocUserListState {}

class BlockUserLoadingState extends BlocUserListState {}

class BlockUserLoadedState extends BlocUserListState {
  final List<BlockUserModel> users;

  const BlockUserLoadedState(this.users);

  @override
  List<Object> get props => [users];
}

class BlockUserFailedState extends BlocUserListState {}
