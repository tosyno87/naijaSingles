part of 'onboarding_bloc.dart';

sealed class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

// Basic info
final class OnboardingFullNameUpdated extends OnboardingEvent {
  const OnboardingFullNameUpdated(this.fullName);

  final String fullName;

  @override
  List<Object?> get props => [fullName];
}

final class OnboardingDateOfBirthUpdated extends OnboardingEvent {
  const OnboardingDateOfBirthUpdated(this.dateOfBirth);

  final DateTime dateOfBirth;

  @override
  List<Object?> get props => [dateOfBirth];
}

final class OnboardingGenderUpdated extends OnboardingEvent {
  const OnboardingGenderUpdated(this.gender);

  final String gender;

  @override
  List<Object?> get props => [gender];
}

final class OnboardingTribeUpdated extends OnboardingEvent {
  const OnboardingTribeUpdated(this.tribe);

  final String tribe;

  @override
  List<Object?> get props => [tribe];
}

final class OnboardingBioUpdated extends OnboardingEvent {
  const OnboardingBioUpdated(this.bio);

  final String bio;

  @override
  List<Object?> get props => [bio];
}

final class OnboardingInterestAdded extends OnboardingEvent {
  const OnboardingInterestAdded(this.interest);

  final String interest;

  @override
  List<Object?> get props => [interest];
}

final class OnboardingInterestRemoved extends OnboardingEvent {
  const OnboardingInterestRemoved(this.interest);

  final String interest;

  @override
  List<Object?> get props => [interest];
}

final class OnboardingGenresUpdated extends OnboardingEvent {
  const OnboardingGenresUpdated(this.genres);

  final List<String> genres;

  @override
  List<Object?> get props => [genres];
}

final class OnboardingLanguagesUpdated extends OnboardingEvent {
  const OnboardingLanguagesUpdated(this.languages);

  final List<String> languages;

  @override
  List<Object?> get props => [languages];
}

final class OnboardingNationalityUpdated extends OnboardingEvent {
  const OnboardingNationalityUpdated(this.nationality);

  final String nationality;

  @override
  List<Object?> get props => [nationality];
}

final class OnboardingIntentUpdated extends OnboardingEvent {
  const OnboardingIntentUpdated(this.intent);

  final String intent;

  @override
  List<Object?> get props => [intent];
}

final class OnboardingFashionStyleUpdated extends OnboardingEvent {
  const OnboardingFashionStyleUpdated(this.fashionStyle);

  final String fashionStyle;

  @override
  List<Object?> get props => [fashionStyle];
}

final class OnboardingWeekendVibeUpdated extends OnboardingEvent {
  const OnboardingWeekendVibeUpdated(this.weekendVibe);

  final String weekendVibe;

  @override
  List<Object?> get props => [weekendVibe];
}

final class OnboardingValuesUpdated extends OnboardingEvent {
  const OnboardingValuesUpdated(this.values);

  final List<String> values;

  @override
  List<Object?> get props => [values];
}

final class OnboardingDealbreakersUpdated extends OnboardingEvent {
  const OnboardingDealbreakersUpdated(this.dealbreakers);

  final List<String> dealbreakers;

  @override
  List<Object?> get props => [dealbreakers];
}

final class OnboardingInterestedInUpdated extends OnboardingEvent {
  const OnboardingInterestedInUpdated(this.interestedIn);

  final String interestedIn;

  @override
  List<Object?> get props => [interestedIn];
}

final class OnboardingAgeRangeUpdated extends OnboardingEvent {
  const OnboardingAgeRangeUpdated(this.ageRange);

  final List<int> ageRange;

  @override
  List<Object?> get props => [ageRange];
}

final class OnboardingMaxDistanceUpdated extends OnboardingEvent {
  const OnboardingMaxDistanceUpdated(this.maxDistance);

  final int maxDistance;

  @override
  List<Object?> get props => [maxDistance];
}

final class OnboardingHeightUpdated extends OnboardingEvent {
  const OnboardingHeightUpdated(this.height, this.unit);

  final double height;
  final String unit;

  @override
  List<Object?> get props => [height, unit];
}

final class OnboardingHeightFromDropdownUpdated extends OnboardingEvent {
  const OnboardingHeightFromDropdownUpdated(this.heightFtIn, this.heightCm);

  final String heightFtIn;
  final int heightCm;

  @override
  List<Object?> get props => [heightFtIn, heightCm];
}

final class OnboardingLookingForUpdated extends OnboardingEvent {
  const OnboardingLookingForUpdated(this.lookingFor);

  final String lookingFor;

  @override
  List<Object?> get props => [lookingFor];
}

final class OnboardingRelationshipIntentUpdated extends OnboardingEvent {
  const OnboardingRelationshipIntentUpdated(this.relationshipIntent);

  final String relationshipIntent;

  @override
  List<Object?> get props => [relationshipIntent];
}

final class OnboardingEducationUpdated extends OnboardingEvent {
  const OnboardingEducationUpdated(this.education);

  final String education;

  @override
  List<Object?> get props => [education];
}

final class OnboardingReligionUpdated extends OnboardingEvent {
  const OnboardingReligionUpdated(this.religion);

  final String religion;

  @override
  List<Object?> get props => [religion];
}

final class OnboardingOccupationUpdated extends OnboardingEvent {
  const OnboardingOccupationUpdated(this.occupation);

  final String occupation;

  @override
  List<Object?> get props => [occupation];
}

final class OnboardingDrinkingPreferenceUpdated extends OnboardingEvent {
  const OnboardingDrinkingPreferenceUpdated(this.preference);

  final String preference;

  @override
  List<Object?> get props => [preference];
}

final class OnboardingSmokingPreferenceUpdated extends OnboardingEvent {
  const OnboardingSmokingPreferenceUpdated(this.preference);

  final String preference;

  @override
  List<Object?> get props => [preference];
}

final class OnboardingLocationUpdated extends OnboardingEvent {
  const OnboardingLocationUpdated(this.latitude, this.longitude, this.name);

  final double latitude;
  final double longitude;
  final String name;

  @override
  List<Object?> get props => [latitude, longitude, name];
}

final class OnboardingProfilePhotoPicked extends OnboardingEvent {
  const OnboardingProfilePhotoPicked(this.source, this.index, this.context);

  final dynamic source; // ImageSource
  final int index;
  final dynamic context; // BuildContext?

  @override
  List<Object?> get props => [source, index];
}

final class OnboardingProfilePhotosPickedBulk extends OnboardingEvent {
  const OnboardingProfilePhotosPickedBulk(this.context);

  final dynamic context; // BuildContext

  @override
  List<Object?> get props => [context];
}

final class OnboardingProfilePhotoRemoved extends OnboardingEvent {
  const OnboardingProfilePhotoRemoved(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

final class OnboardingProfilePhotosReordered extends OnboardingEvent {
  const OnboardingProfilePhotosReordered(this.fromIndex, this.toIndex);

  final int fromIndex;
  final int toIndex;

  @override
  List<Object?> get props => [fromIndex, toIndex];
}

final class OnboardingSaveUserData extends OnboardingEvent {
  const OnboardingSaveUserData(this.context);

  final dynamic context; // BuildContext?

  @override
  List<Object?> get props => [context];
}
