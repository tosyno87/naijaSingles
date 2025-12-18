part of 'userlocation_bloc.dart';

abstract class UserLocationStates extends Equatable {
  const UserLocationStates();

  @override
  List<Object> get props => [];
}

class UserLocationInitial extends UserLocationStates {}

class UserLocationLoading extends UserLocationStates {}

class UserLocationSuccess extends UserLocationStates {

  const UserLocationSuccess(
      {required this.latitude,
      required this.longitude,
      required this.formattedAddress,});
  final double latitude;
  final double longitude;
  final String formattedAddress;

  @override
  List<Object> get props => [latitude, longitude, formattedAddress];
}

class UserLocationFailed extends UserLocationStates {
  const UserLocationFailed({required this.message});
  final String message;

  @override
  List<Object> get props => [message];
}
