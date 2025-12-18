import 'package:equatable/equatable.dart';

abstract class UserStates extends Equatable {
  const UserStates();

  @override
  List<Object> get props => [];
}

class UpdateUserInitial extends UserStates {}

class UpdatingUser extends UserStates {}

class UserUpdated extends UserStates {}

class UserUpdationFailed extends UserStates {
  const UserUpdationFailed({required this.message});
  final String message;

  @override
  List<Object> get props => [message];
}

class UpdatingUserProfilePicture extends UserStates {}

class UserProfilePictureUploaded extends UserStates {
  const UserProfilePictureUploaded({required this.url});
  final String? url;

  @override
  List<Object> get props => [url!];
}
