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
  final User? user;

  const GoogleLoginSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}

class GoogleLoginFailed extends GoogleLoginStates {
  final String message;

  const GoogleLoginFailed({required this.message});

  @override
  List<Object?> get props => [message];
}
