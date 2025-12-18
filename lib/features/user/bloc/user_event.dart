import 'dart:io';

import 'package:equatable/equatable.dart';

import '../../../models/user_model.dart';

abstract class UserEvents extends Equatable {
  const UserEvents();

  @override
  List<Object> get props => [];
}

class UpdateUserRequest extends UserEvents {

  const UpdateUserRequest({
    required this.details,
  });
  final Map<String, dynamic> details;

  @override
  List<Object> get props => [details];
}

class UpdateUserProfilePictures extends UserEvents {
  const UpdateUserProfilePictures({
    required this.checktype,
    required this.photo,
    required this.currentUser,
  });
  final File photo;
  final UserModel currentUser;
  final String checktype;

  @override
  List<Object> get props => [photo, currentUser];
}
