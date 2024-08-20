import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/data/repo/user_location_repo.dart';

part 'userlocation_event.dart';
part 'userlocation_state.dart';

class UserLocationBloc extends Bloc<UserLocationEvents, UserLocationStates> {
  final UserLocationReporistory userLocationReporistory;
  UserLocationBloc({required this.userLocationReporistory})
      : super(UserLocationInitial()) {
    on<UserLocationRequest>((event, emit) async {
      emit(UserLocationLoading());
      try {
        final currentLocation =
            await userLocationReporistory.getLocationCoordinates();
        if (currentLocation != null) {
          emit(UserLocationSuccess(
              latitude: currentLocation['latitude'],
              longitude: currentLocation['longitude'],
              formattedAddress: currentLocation["PlaceName"]));
        } else {
          emit(const UserLocationFailed(message: "Can not get location"));
        }
      } on SocketException {
        emit(const UserLocationFailed(message: "NO INTERNET "));
      } catch (e) {
        emit(UserLocationFailed(message: e.toString()));
      }
    });
  }
}
