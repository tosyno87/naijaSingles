part of 'authstatus_bloc.dart';

abstract class AuthstatusState extends Equatable {
  const AuthstatusState();
  
  @override
  List<Object> get props => [];
}
class AuthIntialState extends AuthstatusState {}

class AuthLoadingState extends AuthstatusState {}

class AuthFailed extends AuthstatusState {
  final String message;
  const AuthFailed({required this.message});
}

class AuthenticatedState extends AuthstatusState {
  final User user;
  const AuthenticatedState({required this.user});
}

class UnauthenticatedState extends AuthstatusState {}
