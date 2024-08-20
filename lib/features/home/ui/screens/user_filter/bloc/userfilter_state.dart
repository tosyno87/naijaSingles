part of 'userfilter_bloc.dart';

abstract class UserfilterState extends Equatable {
  const UserfilterState();

  @override
  List<Object> get props => [];
}

class UserfilterInitial extends UserfilterState {}

class UpdatingUserFilter extends UserfilterState {}

class UserFilterUpdated extends UserfilterState {}

class UserFilterUpdationFailed extends UserfilterState {
  final String message;
  const UserFilterUpdationFailed({required this.message});

  @override
  List<Object> get props => [message];
}
