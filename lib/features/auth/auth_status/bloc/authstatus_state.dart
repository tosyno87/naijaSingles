part of 'authstatus_bloc.dart';

abstract class AuthstatusState extends Equatable {
  const AuthstatusState();

  @override
  List<Object> get props => [];
}

class AuthIntialState extends AuthstatusState {}

class AuthLoadingState extends AuthstatusState {}

class AuthFailed extends AuthstatusState {
  const AuthFailed({required this.message});
  final String message;
}

class AuthenticatedState extends AuthstatusState {
  const AuthenticatedState({required this.user});
  final User user;
}

class UnauthenticatedState extends AuthstatusState {}
