part of 'registration_bloc.dart';

abstract class RegistrationStates extends Equatable {
  const RegistrationStates();
  @override
  List<Object> get props => [];
}

class RegistrationInitial extends RegistrationStates {}

class RegistrationLoading extends RegistrationStates {}

class RegistrationSuccess extends RegistrationStates {
  const RegistrationSuccess({required this.user});
  final UserModel user;

  @override
  List<Object> get props => [user];
}

class RegistrationFailed extends RegistrationStates {
  const RegistrationFailed({required this.message});
  final String message;

  @override
  List<Object> get props => [message];
}

class AlreadyRegistered extends RegistrationStates {
  const AlreadyRegistered({required this.user});
  final UserModel user;

  @override
  List<Object> get props => [user];
}

class NewRegistration extends RegistrationStates {
  const NewRegistration({
    required this.token,
    required this.user,
  });
  final String token;
  final User user;

  @override
  List<Object> get props => [token, user];
}
