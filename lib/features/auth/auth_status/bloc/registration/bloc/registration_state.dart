part of 'registration_bloc.dart';

abstract class RegistrationStates extends Equatable {
  const RegistrationStates();
  @override
  List<Object> get props => [];
}

class RegistrationInitial extends RegistrationStates {}

class RegistrationLoading extends RegistrationStates {}

class RegistrationSuccess extends RegistrationStates {
  final UserModel user;
  const RegistrationSuccess({required this.user});

  @override
  List<Object> get props => [user];
}

class RegistrationFailed extends RegistrationStates {
  final String message;
  const RegistrationFailed({required this.message});

  @override
  List<Object> get props => [message];
}

class AlreadyRegistered extends RegistrationStates {
  final UserModel user;
  const AlreadyRegistered({required this.user});

  @override
  List<Object> get props => [user];
}

class NewRegistration extends RegistrationStates {
  final String token;
  final User user;

  const NewRegistration({
    required this.token,
    required this.user,
  });

  @override
  List<Object> get props => [token, user];
}
