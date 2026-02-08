part of 'registration_bloc.dart';

abstract class RegistrationEvents extends Equatable {
  const RegistrationEvents();
  @override
  List<Object> get props => [];
}

class RegistrationRequest extends RegistrationEvents {
  const RegistrationRequest({required this.userdata});
  final Map<String, dynamic> userdata;

  @override
  List<Object> get props => [userdata];
}

class CheckRegistration extends RegistrationEvents {
  const CheckRegistration({required this.token});
  final String token;

  @override
  List<Object> get props => [token];
}
