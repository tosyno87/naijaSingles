part of 'authstatus_bloc.dart';

abstract class AuthstatusEvent extends Equatable {
  const AuthstatusEvent({List props = const []});

  @override
  List<Object> get props => [];
}


class AuthRequestEvent extends AuthstatusEvent {


}

class LogoutEvent extends AuthstatusEvent {}

