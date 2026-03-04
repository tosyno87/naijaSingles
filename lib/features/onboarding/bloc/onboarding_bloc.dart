import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../common/bloc/user/user_bloc.dart';
import '../../../common/widgets/loading_transition_screen.dart';
import '../../../services/bulk_photo_picker_service.dart';
import '../../../services/profile_image_cropper_service.dart';
import '../data/repositories/onboarding_repository.dart';
import 'onboarding_data.dart';

part 'onboarding_event.dart';
part 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc({
    required this.repository,
    required this.userBloc,
  }) : super(OnboardingLoaded(OnboardingData())) {
    on<OnboardingFullNameUpdated>(_onFullNameUpdated);
    on<OnboardingDateOfBirthUpdated>(_onDateOfBirthUpdated);
    on<OnboardingGenderUpdated>(_onGenderUpdated);
    on<OnboardingTribeUpdated>(_onTribeUpdated);
    on<OnboardingBioUpdated>(_onBioUpdated);
    on<OnboardingInterestAdded>(_onInterestAdded);
    on<OnboardingInterestRemoved>(_onInterestRemoved);
    on<OnboardingGenresUpdated>(_onGenresUpdated);
    on<OnboardingLanguagesUpdated>(_onLanguagesUpdated);
    on<OnboardingNationalityUpdated>(_onNationalityUpdated);
    on<OnboardingIntentUpdated>(_onIntentUpdated);
    on<OnboardingFashionStyleUpdated>(_onFashionStyleUpdated);
    on<OnboardingWeekendVibeUpdated>(_onWeekendVibeUpdated);
    on<OnboardingValuesUpdated>(_onValuesUpdated);
    on<OnboardingDealbreakersUpdated>(_onDealbreakersUpdated);
    on<OnboardingInterestedInUpdated>(_onInterestedInUpdated);
    on<OnboardingAgeRangeUpdated>(_onAgeRangeUpdated);
    on<OnboardingMaxDistanceUpdated>(_onMaxDistanceUpdated);
    on<OnboardingHeightUpdated>(_onHeightUpdated);
    on<OnboardingHeightFromDropdownUpdated>(_onHeightFromDropdownUpdated);
    on<OnboardingLookingForUpdated>(_onLookingForUpdated);
    on<OnboardingRelationshipIntentUpdated>(_onRelationshipIntentUpdated);
    on<OnboardingEducationUpdated>(_onEducationUpdated);
    on<OnboardingReligionUpdated>(_onReligionUpdated);
    on<OnboardingOccupationUpdated>(_onOccupationUpdated);
    on<OnboardingDrinkingPreferenceUpdated>(_onDrinkingPreferenceUpdated);
    on<OnboardingSmokingPreferenceUpdated>(_onSmokingPreferenceUpdated);
    on<OnboardingLocationUpdated>(_onLocationUpdated);
    on<OnboardingProfilePhotoPicked>(_onProfilePhotoPicked);
    on<OnboardingProfilePhotosPickedBulk>(_onProfilePhotosPickedBulk);
    on<OnboardingProfilePhotoRemoved>(_onProfilePhotoRemoved);
    on<OnboardingProfilePhotosReordered>(_onProfilePhotosReordered);
    on<OnboardingSaveUserData>(_onSaveUserData);
  }

  final OnboardingRepository repository;
  final UserBloc userBloc;
  static const int _maxProfilePhotos = 9;

  List<File?> _compactPhotos(List<File?> photos) {
    final nonNull = photos.whereType<File>().toList();
    if (nonNull.length >= _maxProfilePhotos) {
      return nonNull.take(_maxProfilePhotos).toList();
    }
    return [
      ...nonNull,
      ...List<File?>.filled(_maxProfilePhotos - nonNull.length, null),
    ];
  }

  void _onFullNameUpdated(
    OnboardingFullNameUpdated e,
    Emitter<OnboardingState> emit,
  ) {
    final data = _data(emit);
    if (data == null) return;
    emit(OnboardingLoaded(
        data.copyWith(fullName: e.fullName, userName: e.fullName),),);
  }

  void _onDateOfBirthUpdated(
    OnboardingDateOfBirthUpdated e,
    Emitter<OnboardingState> emit,
  ) {
    final data = _data(emit);
    if (data == null) return;
    emit(OnboardingLoaded(data.copyWith(dateOfBirth: e.dateOfBirth)));
  }

  void _onGenderUpdated(
      OnboardingGenderUpdated e, Emitter<OnboardingState> emit,) {
    final data = _data(emit);
    if (data == null) return;
    emit(OnboardingLoaded(data.copyWith(gender: e.gender)));
  }

  void _onTribeUpdated(
      OnboardingTribeUpdated e, Emitter<OnboardingState> emit,) {
    final data = _data(emit);
    if (data == null) return;
    emit(OnboardingLoaded(data.copyWith(tribe: e.tribe)));
  }

  void _onBioUpdated(OnboardingBioUpdated e, Emitter<OnboardingState> emit) {
    final data = _data(emit);
    if (data == null) return;
    emit(OnboardingLoaded(data.copyWith(bio: e.bio)));
  }

  void _onInterestAdded(
    OnboardingInterestAdded e,
    Emitter<OnboardingState> emit,
  ) {
    final data = _data(emit);
    if (data == null) return;
    if (data.interests.contains(e.interest)) return;
    final interests = [...data.interests, e.interest];
    final genres = data.genres.contains(e.interest)
        ? data.genres
        : [...data.genres, e.interest];
    emit(OnboardingLoaded(data.copyWith(interests: interests, genres: genres)));
  }

  void _onInterestRemoved(
    OnboardingInterestRemoved e,
    Emitter<OnboardingState> emit,
  ) {
    final data = _data(emit);
    if (data == null) return;
    final interests = data.interests.where((i) => i != e.interest).toList();
    final genres = data.genres.where((g) => g != e.interest).toList();
    emit(OnboardingLoaded(data.copyWith(interests: interests, genres: genres)));
  }

  void _onGenresUpdated(
    OnboardingGenresUpdated e,
    Emitter<OnboardingState> emit,
  ) {
    final data = _data(emit);
    if (data == null) return;
    emit(
        OnboardingLoaded(data.copyWith(genres: e.genres, interests: e.genres)),);
  }

  void _onLanguagesUpdated(
    OnboardingLanguagesUpdated e,
    Emitter<OnboardingState> emit,
  ) {
    final data = _data(emit);
    if (data == null) return;
    emit(OnboardingLoaded(data.copyWith(languages: e.languages)));
  }

  void _onNationalityUpdated(
    OnboardingNationalityUpdated e,
    Emitter<OnboardingState> emit,
  ) {
    final data = _data(emit);
    if (data == null) return;
    emit(OnboardingLoaded(data.copyWith(nationality: e.nationality)));
  }

  void _onIntentUpdated(
    OnboardingIntentUpdated e,
    Emitter<OnboardingState> emit,
  ) {
    final data = _data(emit);
    if (data == null) return;
    emit(OnboardingLoaded(data.copyWith(intent: e.intent)));
  }

  void _onFashionStyleUpdated(
    OnboardingFashionStyleUpdated e,
    Emitter<OnboardingState> emit,
  ) {
    final data = _data(emit);
    if (data == null) return;
    emit(OnboardingLoaded(data.copyWith(fashionStyle: e.fashionStyle)));
  }

  void _onWeekendVibeUpdated(
    OnboardingWeekendVibeUpdated e,
    Emitter<OnboardingState> emit,
  ) {
    final data = _data(emit);
    if (data == null) return;
    emit(OnboardingLoaded(data.copyWith(weekendVibe: e.weekendVibe)));
  }

  void _onValuesUpdated(
    OnboardingValuesUpdated e,
    Emitter<OnboardingState> emit,
  ) {
    final data = _data(emit);
    if (data == null) return;
    emit(OnboardingLoaded(data.copyWith(values: e.values)));
  }

  void _onDealbreakersUpdated(
    OnboardingDealbreakersUpdated e,
    Emitter<OnboardingState> emit,
  ) {
    final data = _data(emit);
    if (data == null) return;
    emit(OnboardingLoaded(data.copyWith(dealbreakers: e.dealbreakers)));
  }

  void _onInterestedInUpdated(
    OnboardingInterestedInUpdated e,
    Emitter<OnboardingState> emit,
  ) {
    final data = _data(emit);
    if (data == null) return;
    emit(OnboardingLoaded(data.copyWith(interestedIn: e.interestedIn)));
  }

  void _onAgeRangeUpdated(
    OnboardingAgeRangeUpdated e,
    Emitter<OnboardingState> emit,
  ) {
    final data = _data(emit);
    if (data == null) return;
    emit(OnboardingLoaded(data.copyWith(ageRange: e.ageRange)));
  }

  void _onMaxDistanceUpdated(
    OnboardingMaxDistanceUpdated e,
    Emitter<OnboardingState> emit,
  ) {
    final data = _data(emit);
    if (data == null) return;
    emit(OnboardingLoaded(data.copyWith(maxDistance: e.maxDistance)));
  }

  void _onHeightUpdated(
    OnboardingHeightUpdated e,
    Emitter<OnboardingState> emit,
  ) {
    final data = _data(emit);
    if (data == null) return;
    emit(OnboardingLoaded(data.copyWith(height: e.height, heightUnit: e.unit)));
  }

  void _onHeightFromDropdownUpdated(
    OnboardingHeightFromDropdownUpdated e,
    Emitter<OnboardingState> emit,
  ) {
    final data = _data(emit);
    if (data == null) return;
    emit(OnboardingLoaded(
        data.copyWith(height: e.heightCm.toDouble(), heightUnit: 'cm'),),);
  }

  void _onLookingForUpdated(
    OnboardingLookingForUpdated e,
    Emitter<OnboardingState> emit,
  ) {
    final data = _data(emit);
    if (data == null) return;
    emit(OnboardingLoaded(data.copyWith(lookingFor: e.lookingFor)));
  }

  void _onRelationshipIntentUpdated(
    OnboardingRelationshipIntentUpdated e,
    Emitter<OnboardingState> emit,
  ) {
    final data = _data(emit);
    if (data == null) return;
    emit(OnboardingLoaded(
        data.copyWith(relationshipIntent: e.relationshipIntent),),);
  }

  void _onEducationUpdated(
    OnboardingEducationUpdated e,
    Emitter<OnboardingState> emit,
  ) {
    final data = _data(emit);
    if (data == null) return;
    emit(OnboardingLoaded(data.copyWith(education: e.education)));
  }

  void _onReligionUpdated(
    OnboardingReligionUpdated e,
    Emitter<OnboardingState> emit,
  ) {
    final data = _data(emit);
    if (data == null) return;
    emit(OnboardingLoaded(data.copyWith(religion: e.religion)));
  }

  void _onOccupationUpdated(
    OnboardingOccupationUpdated e,
    Emitter<OnboardingState> emit,
  ) {
    final data = _data(emit);
    if (data == null) return;
    emit(OnboardingLoaded(data.copyWith(occupation: e.occupation)));
  }

  void _onDrinkingPreferenceUpdated(
    OnboardingDrinkingPreferenceUpdated e,
    Emitter<OnboardingState> emit,
  ) {
    final data = _data(emit);
    if (data == null) return;
    emit(OnboardingLoaded(data.copyWith(drinkingPreference: e.preference)));
  }

  void _onSmokingPreferenceUpdated(
    OnboardingSmokingPreferenceUpdated e,
    Emitter<OnboardingState> emit,
  ) {
    final data = _data(emit);
    if (data == null) return;
    emit(OnboardingLoaded(data.copyWith(smokingPreference: e.preference)));
  }

  void _onLocationUpdated(
    OnboardingLocationUpdated e,
    Emitter<OnboardingState> emit,
  ) {
    final data = _data(emit);
    if (data == null) return;
    emit(OnboardingLoaded(data.copyWith(
      latitude: e.latitude,
      longitude: e.longitude,
      locationName: e.name,
    ),),);
  }

  OnboardingData? _data(Emitter<OnboardingState> emit) {
    final current = state.data;
    if (current == null) return null;
    return current;
  }

  Future<void> _onProfilePhotoPicked(
    OnboardingProfilePhotoPicked e,
    Emitter<OnboardingState> emit,
  ) async {
    final data = _data(emit);
    if (data == null) return;

    try {
      final source = e.source as ImageSource;
      final context = e.context as BuildContext?;
      const cropType = CropType.square;
      final title =
          e.index == 0 ? 'Crop Main Photo' : 'Crop Photo ${e.index + 1}';

      final croppedImage = await ProfileImageCropperService.pickAndCropImage(
        source: source,
        cropType: cropType,
        title: title,
        context: context,
      );

      if (croppedImage != null) {
        final photos = _compactPhotos(List<File?>.from(data.profilePhotos));
        final canReplaceAtIndex =
            e.index >= 0 && e.index < photos.length && photos[e.index] != null;

        if (canReplaceAtIndex) {
          photos[e.index] = croppedImage;
        } else {
          final firstEmpty = photos.indexWhere((photo) => photo == null);
          if (firstEmpty != -1) {
            photos[firstEmpty] = croppedImage;
          } else {
            photos[photos.length - 1] = croppedImage;
          }
        }

        emit(OnboardingLoaded(data.copyWith(profilePhotos: photos)));
      }
    } on Object catch (err) {
      log('❌ Error picking photo: $err', error: err);
      if (e.context is BuildContext && (e.context as BuildContext).mounted) {
        ScaffoldMessenger.of(e.context as BuildContext).showSnackBar(
          const SnackBar(
            content: Text('Failed to select photo. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onProfilePhotosPickedBulk(
    OnboardingProfilePhotosPickedBulk e,
    Emitter<OnboardingState> emit,
  ) async {
    final data = _data(emit);
    if (data == null) return;

    try {
      final context = e.context as BuildContext;
      final selected =
          await BulkPhotoPickerService.pickMultiplePhotos(context: context);
      if (selected.isEmpty) return;

      final cropped = await BulkPhotoPickerService.cropSelectedPhotos(
        selectedPhotos: selected,
        context: context,
      );

      if (!context.mounted) return;

      final photos = _compactPhotos(List<File?>.from(data.profilePhotos));
      for (final image in cropped) {
        final firstEmpty = photos.indexWhere((photo) => photo == null);
        if (firstEmpty == -1) break;
        photos[firstEmpty] = image;
      }
      emit(OnboardingLoaded(
          data.copyWith(profilePhotos: _compactPhotos(photos)),),);
    } on Object catch (err) {
      log('❌ Bulk photo selection: $err');
    }
  }

  void _onProfilePhotoRemoved(
    OnboardingProfilePhotoRemoved e,
    Emitter<OnboardingState> emit,
  ) {
    final data = _data(emit);
    if (data == null) return;
    final photos = _compactPhotos(List<File?>.from(data.profilePhotos));
    if (e.index < 0 || e.index >= photos.length || photos[e.index] == null) {
      return;
    }

    photos.removeAt(e.index);
    photos.add(null);
    emit(
        OnboardingLoaded(data.copyWith(profilePhotos: _compactPhotos(photos))),);
  }

  void _onProfilePhotosReordered(
    OnboardingProfilePhotosReordered e,
    Emitter<OnboardingState> emit,
  ) {
    final data = _data(emit);
    if (data == null) return;

    final photos = _compactPhotos(List<File?>.from(data.profilePhotos));
    if (e.fromIndex < 0 ||
        e.fromIndex >= photos.length ||
        e.toIndex < 0 ||
        e.toIndex >= photos.length) {
      return;
    }

    final photo = photos.removeAt(e.fromIndex);
    photos.insert(e.toIndex, photo);
    emit(
        OnboardingLoaded(data.copyWith(profilePhotos: _compactPhotos(photos))),);
  }

  Future<void> _onSaveUserData(
    OnboardingSaveUserData e,
    Emitter<OnboardingState> emit,
  ) async {
    final data = _data(emit);
    if (data == null) return;

    final context = e.context as BuildContext?;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      emit(const OnboardingSaveFailure('User not authenticated'));
      return;
    }

    emit(OnboardingLoading(data));

    if (context != null && context.mounted) {
      unawaited(
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const LoadingTransitionScreen(),
          ),
        ),
      );
    }

    try {
      await repository.saveUserData(data: data, userId: user.uid);
      try {
        await repository.uploadProfilePictures(data: data, userId: user.uid);
      } on Object catch (uploadErr) {
        log('⚠️ Photo upload failed (non-critical): $uploadErr');
      }

      emit(const OnboardingSaveSuccess());

      userBloc.add(const UserRefreshUserDetails());
      await Future.delayed(const Duration(milliseconds: 300));

      if (context != null && context.mounted) {
        await Navigator.of(context).pushNamedAndRemoveUntil(
          '/main_navigation',
          (route) => false,
        );
      }
    } on Object catch (err) {
      log('Error saving user data: $err');
      emit(OnboardingSaveFailure(err.toString()));
      if (context != null && context.mounted) {
        await Navigator.of(context).pushNamedAndRemoveUntil(
          '/main_navigation',
          (route) => false,
        );
      }
    }
  }
}
