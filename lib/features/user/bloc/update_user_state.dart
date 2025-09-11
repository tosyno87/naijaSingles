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
  final String message;
  const UserUpdationFailed({required this.message});

  @override
  List<Object> get props => [message];
}

class UpdatingUserProfilePicture extends UserStates {}

class UserProfilePictureUploaded extends UserStates {
  final String? url;
  const UserProfilePictureUploaded({required this.url});

  @override
  List<Object> get props => [url!];
}
