import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class FacebookLoginStates extends Equatable {
  const FacebookLoginStates();

  @override
  List<Object> get props => [];
}

class FacebookLoginInitial extends FacebookLoginStates {}

class FacebookLoginLoading extends FacebookLoginStates {}

class FacebookLoginSuccess extends FacebookLoginStates {
  final User? user;
  const FacebookLoginSuccess({required this.user});

  @override
  List<Object> get props => [user!];
}

class FacebookLoginFailed extends FacebookLoginStates {
  final String message;
  const FacebookLoginFailed({required this.message});

  @override
  List<Object> get props => [message];
}
