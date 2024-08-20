part of 'registration_bloc.dart';

abstract class RegistrationEvents extends Equatable {
  const RegistrationEvents();
  @override
  List<Object> get props => [];
}

class RegistrationRequest extends RegistrationEvents {
final Map<String ,dynamic> userdata;

  const RegistrationRequest({required this.userdata});

  @override
  List<Object> get props => [userdata];
}

class CheckRegistration extends RegistrationEvents {
  final String token;
  
  const CheckRegistration({required this.token});

  @override
  List<Object> get props => [token];
}
