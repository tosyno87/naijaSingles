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
  const CheckRegistration({required this.token, this.isLogin = false});
  final String token;

  /// True when user is attempting login (not signup). If not registered we sign out and emit NotRegistered.
  final bool isLogin;

  @override
  List<Object> get props => [token, isLogin];
}
