import 'dart:io';

import 'package:equatable/equatable.dart';

/// Immutable onboarding form data for onboarding flow state
class OnboardingData extends Equatable {
  OnboardingData({
    this.fullName = '',
    this.dateOfBirth,
    this.gender = '',
    this.tribe = '',
    this.race = '',
    this.bio = '',
    this.interests = const [],
    List<File?>? profilePhotos,
    this.userName,
    this.locationName,
    this.intent,
    this.nationality,
    this.education,
    this.occupation,
    this.fashionStyle,
    this.weekendVibe,
    this.religion = '',
    this.languages = const [],
    this.genres = const [],
    this.values = const [],
    this.photos = const [],
    this.dealbreakers = const [],
    this.interestedIn = '',
    this.ageRange = const [18, 50],
    this.maxDistance = 50,
    this.height = 170,
    this.heightUnit = 'cm',
    this.lookingFor = '',
    this.relationshipIntent = '',
    this.latitude,
    this.longitude,
    this.drinkingPreference = '',
    this.smokingPreference = '',
  }) : profilePhotos = profilePhotos ?? List<File?>.filled(9, null);

  final List<File?> profilePhotos;

  final String fullName;
  final DateTime? dateOfBirth;
  final String gender;
  final String tribe;
  final String race;
  final String bio;
  final List<String> interests;
  final String? userName;
  final String? locationName;
  final String? intent;
  final String? nationality;
  final String? education;
  final String? occupation;
  final String? fashionStyle;
  final String? weekendVibe;
  final String religion;
  final List<String> languages;
  final List<String> genres;
  final List<String> values;
  final List<String> photos;
  final List<String> dealbreakers;
  final String interestedIn;
  final List<int> ageRange;
  final int maxDistance;
  final double height;
  final String heightUnit;
  final String lookingFor;
  final String relationshipIntent;
  final double? latitude;
  final double? longitude;
  final String drinkingPreference;
  final String smokingPreference;

  int get age {
    if (dateOfBirth == null) return 0;
    final today = DateTime.now();
    int a = today.year - dateOfBirth!.year;
    if (today.month < dateOfBirth!.month ||
        (today.month == dateOfBirth!.month && today.day < dateOfBirth!.day)) {
      a--;
    }
    return a;
  }

  String get heightDisplay {
    if (heightUnit == 'cm') {
      return '${height.round()} cm';
    }
    final totalInches = height / 2.54;
    final feet = (totalInches / 12).floor();
    final inches = (totalInches % 12).round();
    return '$feet\'$inches"';
  }

  File? get profilePhoto => profilePhotos.cast<File?>().firstWhere(
        (p) => p != null,
        orElse: () => null,
      );

  bool get isBasicInfoComplete =>
      fullName.isNotEmpty &&
      dateOfBirth != null &&
      gender.isNotEmpty &&
      age >= 18;

  bool get isTribeSelected => tribe.isNotEmpty;

  bool get isBioComplete => bio.length >= 50;

  bool get areInterestsSelected => interests.length >= 5;

  bool get isPhotoUploaded => profilePhotos.where((p) => p != null).isNotEmpty;

  OnboardingData copyWithPhotoAt(int index, File? file) {
    final updated = List<File?>.from(profilePhotos);
    if (index >= 0 && index < updated.length) {
      updated[index] = file;
    }
    return copyWith(profilePhotos: updated);
  }

  OnboardingData copyWith({
    String? fullName,
    DateTime? dateOfBirth,
    String? gender,
    String? tribe,
    String? race,
    String? bio,
    List<String>? interests,
    List<File?>? profilePhotos,
    String? userName,
    String? locationName,
    String? intent,
    String? nationality,
    String? education,
    String? occupation,
    String? fashionStyle,
    String? weekendVibe,
    String? religion,
    List<String>? languages,
    List<String>? genres,
    List<String>? values,
    List<String>? photos,
    List<String>? dealbreakers,
    String? interestedIn,
    List<int>? ageRange,
    int? maxDistance,
    double? height,
    String? heightUnit,
    String? lookingFor,
    String? relationshipIntent,
    double? latitude,
    double? longitude,
    String? drinkingPreference,
    String? smokingPreference,
  }) =>
      OnboardingData(
        fullName: fullName ?? this.fullName,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        gender: gender ?? this.gender,
        tribe: tribe ?? this.tribe,
        race: race ?? this.race,
        bio: bio ?? this.bio,
        interests: interests ?? List.from(this.interests),
        profilePhotos: profilePhotos ?? List.from(this.profilePhotos),
        userName: userName ?? this.userName,
        locationName: locationName ?? this.locationName,
        intent: intent ?? this.intent,
        nationality: nationality ?? this.nationality,
        education: education ?? this.education,
        occupation: occupation ?? this.occupation,
        fashionStyle: fashionStyle ?? this.fashionStyle,
        weekendVibe: weekendVibe ?? this.weekendVibe,
        religion: religion ?? this.religion,
        languages: languages ?? List.from(this.languages),
        genres: genres ?? List.from(this.genres),
        values: values ?? List.from(this.values),
        photos: photos ?? List.from(this.photos),
        dealbreakers: dealbreakers ?? List.from(this.dealbreakers),
        interestedIn: interestedIn ?? this.interestedIn,
        ageRange: ageRange ?? List.from(this.ageRange),
        maxDistance: maxDistance ?? this.maxDistance,
        height: height ?? this.height,
        heightUnit: heightUnit ?? this.heightUnit,
        lookingFor: lookingFor ?? this.lookingFor,
        relationshipIntent: relationshipIntent ?? this.relationshipIntent,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        drinkingPreference: drinkingPreference ?? this.drinkingPreference,
        smokingPreference: smokingPreference ?? this.smokingPreference,
      );

  @override
  List<Object?> get props => [
        fullName,
        dateOfBirth,
        gender,
        tribe,
        race,
        bio,
        interests,
        profilePhotos,
        userName,
        locationName,
        intent,
        nationality,
        education,
        occupation,
        fashionStyle,
        weekendVibe,
        religion,
        languages,
        genres,
        values,
        photos,
        dealbreakers,
        interestedIn,
        ageRange,
        maxDistance,
        height,
        heightUnit,
        lookingFor,
        relationshipIntent,
        latitude,
        longitude,
        drinkingPreference,
        smokingPreference,
      ];
}
