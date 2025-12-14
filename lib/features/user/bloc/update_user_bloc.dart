import 'dart:developer';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/data/repo/user_repo.dart';
import '../../../services/firestore_database.dart';
import 'update_user_state.dart';
import 'user_event.dart';

class UserBloc extends Bloc<UserEvents, UserStates> {
  UserBloc() : super(UpdateUserInitial()) {
    on<UpdateUserRequest>((event, emit) async {
      emit(UpdatingUser());
      try {
        await UserRepo.updateData(event.details);
        emit(UserUpdated());
      } on SocketException {
        emit(const UserUpdationFailed(message: 'No Internet Connection'));
      } catch (e) {
        emit(UserUpdationFailed(message: e.toString()));
        log('Error updating user: $e');
      }
    });
    on<UpdateUserProfilePictures>((event, emit) async {
      emit(UpdatingUser());
      try {
        log('file is in bloc ${event.photo}');
        final task = await FireStoreClass.uploadFile(
            currentUser: event.currentUser,
            checktype: event.checktype,
            file: event.photo,);
        final imageUrl = await task?.snapshot.ref.getDownloadURL();
        log('from bloc $imageUrl');

        emit(UserProfilePictureUploaded(url: imageUrl));
      } on SocketException {
        emit(const UserUpdationFailed(message: 'No Internet Connection'));
      } catch (e) {
        emit(UserUpdationFailed(message: e.toString()));
      }
    });
  }
}
