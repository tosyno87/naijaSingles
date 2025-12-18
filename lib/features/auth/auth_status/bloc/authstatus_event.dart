part of 'authstatus_bloc.dart';

abstract class AuthstatusEvent extends Equatable {
  const AuthstatusEvent();

  @override
  List<Object> get props => [];
}

class AuthRequestEvent extends AuthstatusEvent {}

class LogoutEvent extends AuthstatusEvent {}
