import '../../../../models/user_model.dart';

/// Shared filtering helpers for discovery queries and stream pipelines.
class DiscoveryFiltering {
  /// Synonyms accepted when the seeker filters by a primary intent.
  static const Map<String, Set<String>> _intentSynonyms = {
    'dating': {'dating', 'romance', 'relationship', 'love', 'marriage'},
    'friendship': {'friendship', 'friends', 'social'},
    'networking': {'networking', 'business', 'professional'},
  };

  /// Firestore `lookingFor` whereIn values for [intentFilter], including
  /// title-cased synonyms and `Mixed`. Empty when no query filter should apply.
  ///
  /// Firestore whereIn is limited to 10 values; synonym sets stay under that.
  static List<String> lookingForQueryValues(String? intentFilter) {
    final String raw = (intentFilter ?? '').trim();
    if (raw.isEmpty) return const <String>[];
    final String seeker = raw.toLowerCase();
    if (seeker == 'mixed') return const <String>[];

    final Set<String> synonyms = _intentSynonyms[seeker] ?? <String>{seeker};
    final Set<String> values = <String>{'Mixed', raw};
    for (final String synonym in synonyms) {
      values.add(_titleCaseIntent(synonym));
    }
    return values.toList(growable: false);
  }

  static String _titleCaseIntent(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  /// Whether [candidate] should appear for the seeker's [intentFilter].
  ///
  /// Missing/blank/`Mixed` intents are treated as compatible so incomplete
  /// profiles (common after migration) are not wiped from the deck.
  static bool matchesLookingForIntent(
    UserModel candidate,
    String? intentFilter,
  ) {
    final String seeker = (intentFilter ?? '').trim().toLowerCase();
    if (seeker.isEmpty || seeker == 'mixed') {
      return true;
    }

    final String theirs = (candidate.lookingFor ?? '').trim().toLowerCase();
    if (theirs.isEmpty || theirs == 'mixed') {
      return true;
    }
    if (theirs == seeker) {
      return true;
    }

    final Set<String>? synonyms = _intentSynonyms[seeker];
    return synonyms != null && synonyms.contains(theirs);
  }

  /// Normalize gender values from profile/query fields to a common form.
  static String normalizeGender(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';
    if (normalized.isEmpty) return '';

    switch (normalized) {
      case 'man':
      case 'men':
      case 'male':
      case 'm':
        return 'male';
      case 'woman':
      case 'women':
      case 'female':
      case 'f':
        return 'female';
      case 'everyone':
      case 'any':
      case 'all':
      case 'both':
        return 'everyone';
      default:
        return normalized;
    }
  }

  static bool isEveryonePreference(String value) =>
      value.isEmpty || value == 'everyone';

  static bool matchesGenderPreference(UserModel user, UserModel currentUser) {
    final preference = normalizeGender(currentUser.showGender);
    if (isEveryonePreference(preference)) {
      return true;
    }

    final candidateGender = normalizeGender(
      user.userGender?.toString().isNotEmpty ?? false
          ? user.userGender
          : user.editInfo?['userGender']?.toString(),
    );

    // Missing candidate gender should not fully block discovery.
    if (candidateGender.isEmpty) {
      return true;
    }

    return candidateGender == preference;
  }

  /// Whether [candidate] falls within the seeker's preferred age band.
  ///
  /// Missing candidate age or seeker [UserModel.ageRange] does not block
  /// discovery so incomplete / legacy profiles are not wiped from the deck.
  static bool matchesAgePreference(UserModel candidate, UserModel currentUser) {
    final Map? range = currentUser.ageRange;
    if (range == null) {
      return true;
    }
    final int? minAge = currentUser.ageRangeMin;
    final int? maxAge = currentUser.ageRangeMax;
    if (minAge == null || maxAge == null) {
      return true;
    }
    final int? age = candidate.age;
    if (age == null) {
      return true;
    }
    return age >= minAge && age <= maxAge;
  }
}
