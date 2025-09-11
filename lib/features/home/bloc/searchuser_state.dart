part of 'searchuser_bloc.dart';

abstract class SearchUserState extends Equatable {
  const SearchUserState();

  @override
  List<Object> get props => [];
}

class SearchuserInitial extends SearchUserState {}

class SearchUserLoadingState extends SearchUserState {}

class SearchUserLoadUserState extends SearchUserState {
  final List<UserModel> users;

  const SearchUserLoadUserState(this.users);

  @override
  List<Object> get props => [users];
}

class SearchUserFailedState extends SearchUserState {}

class MigrationStatusState extends SearchUserState {
  final bool shouldPromptForMigration;

  const MigrationStatusState({required this.shouldPromptForMigration});

  @override
  List<Object> get props => [shouldPromptForMigration];
}
