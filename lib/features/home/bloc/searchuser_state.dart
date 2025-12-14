part of 'searchuser_bloc.dart';

abstract class SearchUserState extends Equatable {
  const SearchUserState();

  @override
  List<Object> get props => [];
}

class SearchuserInitial extends SearchUserState {}

class SearchUserLoadingState extends SearchUserState {}

class SearchUserLoadUserState extends SearchUserState {

  const SearchUserLoadUserState(this.users);
  final List<UserModel> users;

  @override
  List<Object> get props => [users];
}

class SearchUserFailedState extends SearchUserState {}

class MigrationStatusState extends SearchUserState {

  const MigrationStatusState({required this.shouldPromptForMigration});
  final bool shouldPromptForMigration;

  @override
  List<Object> get props => [shouldPromptForMigration];
}
