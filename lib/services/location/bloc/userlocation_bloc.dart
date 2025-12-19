import 'dart:developer';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/data/repo/user_location_repo.dart';

part 'userlocation_event.dart';
part 'userlocation_state.dart';

class UserLocationBloc extends Bloc<UserLocationEvents, UserLocationStates> {
  UserLocationBloc({required this.userLocationReporistory})
      : super(UserLocationInitial()) {
    on<UserLocationRequest>((event, emit) async {
      emit(UserLocationLoading());
      try {
        log('Requesting location coordinates');
        Map? currentLocation;

        try {
          currentLocation =
              await userLocationReporistory.getLocationCoordinates();
        } catch (e) {
          log('Error getting location coordinates: ${e.toString()}');
          // Use default location as fallback
          currentLocation = await userLocationReporistory.getDefaultLocation();
        }

        if (currentLocation != null) {
          log('Location obtained: $currentLocation');
          emit(
            UserLocationSuccess(
              latitude: currentLocation['latitude'],
              longitude: currentLocation['longitude'],
              formattedAddress: currentLocation['PlaceName'],
            ),
          );
        } else {
          log('Failed to get location: returned null');
          // Use default location as fallback
          final defaultLocation =
              await userLocationReporistory.getDefaultLocation();
          log('Using default location: $defaultLocation');
          emit(
            UserLocationSuccess(
              latitude: defaultLocation['latitude'],
              longitude: defaultLocation['longitude'],
              formattedAddress: defaultLocation['PlaceName'],
            ),
          );
        }
      } on SocketException catch (e) {
        log('Socket exception: ${e.toString()}');
        // Use default location as fallback
        try {
          final defaultLocation =
              await userLocationReporistory.getDefaultLocation();
          log('Using default location after socket exception: $defaultLocation');
          emit(
            UserLocationSuccess(
              latitude: defaultLocation['latitude'],
              longitude: defaultLocation['longitude'],
              formattedAddress: defaultLocation['PlaceName'],
            ),
          );
        } catch (innerE) {
          emit(
            const UserLocationFailed(
              message:
                  'No internet connection. Please check your network and try again.',
            ),
          );
        }
      } catch (e) {
        log('General exception in location bloc: ${e.toString()}');
        // Use default location as fallback
        try {
          final defaultLocation =
              await userLocationReporistory.getDefaultLocation();
          log('Using default location after general exception: $defaultLocation');
          emit(
            UserLocationSuccess(
              latitude: defaultLocation['latitude'],
              longitude: defaultLocation['longitude'],
              formattedAddress: defaultLocation['PlaceName'],
            ),
          );
        } catch (innerE) {
          emit(
            UserLocationFailed(
              message: 'Could not access your location: ${e.toString()}',
            ),
          );
        }
      }
    });
  }
  final UserLocationReporistory userLocationReporistory;
}
