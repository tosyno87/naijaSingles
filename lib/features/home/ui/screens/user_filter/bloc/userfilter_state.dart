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
  const UserFilterUpdationFailed({required this.message});
  final String message;

  @override
  List<Object> get props => [message];
}
