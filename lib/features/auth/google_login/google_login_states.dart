import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class GoogleLoginStates extends Equatable {
  const GoogleLoginStates();

  @override
  List<Object?> get props => [];
}

class GoogleLoginInitial extends GoogleLoginStates {}

class GoogleLoginLoading extends GoogleLoginStates {}

class GoogleLoginSuccess extends GoogleLoginStates {
  const GoogleLoginSuccess({required this.user});
  final User? user;

  @override
  List<Object?> get props => [user];
}

class GoogleLoginFailed extends GoogleLoginStates {
  const GoogleLoginFailed({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}
