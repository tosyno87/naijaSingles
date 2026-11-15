import '../bloc/onboarding_data.dart';

/// Maps server extraction JSON onto the existing onboarding model.
///
/// Low-confidence and under-18 dates are already stripped server-side;
/// this mapper still refuses to set a minor DOB as a client-side backstop.
class OnboardingDraftMapper {
  const OnboardingDraftMapper();

  OnboardingData apply({
    required OnboardingData current,
    required Map<String, dynamic> fields,
  }) {
    final dob = _adultDob(fields['dateOfBirth']);
    return current.copyWith(
      fullName: _string(fields, 'fullName') ?? current.fullName,
      userName: _string(fields, 'fullName') ?? current.userName,
      dateOfBirth: dob ?? current.dateOfBirth,
      gender: _string(fields, 'gender') ?? current.gender,
      bio: _string(fields, 'bio') ?? current.bio,
      tribe: _string(fields, 'tribe') ?? current.tribe,
      nationality: _string(fields, 'nationality') ?? current.nationality,
      occupation: _string(fields, 'occupation') ?? current.occupation,
      education: _string(fields, 'education') ?? current.education,
      religion: _string(fields, 'religion') ?? current.religion,
      lookingFor: _string(fields, 'lookingFor') ?? current.lookingFor,
      interestedIn: _string(fields, 'interestedIn') ?? current.interestedIn,
      relationshipIntent:
          _string(fields, 'relationshipIntent') ?? current.relationshipIntent,
      weekendVibe: _string(fields, 'weekendVibe') ?? current.weekendVibe,
      fashionStyle: _string(fields, 'fashionStyle') ?? current.fashionStyle,
      drinkingPreference:
          _string(fields, 'drinkingPreference') ?? current.drinkingPreference,
      smokingPreference:
          _string(fields, 'smokingPreference') ?? current.smokingPreference,
      languages: _stringList(fields, 'languages') ?? current.languages,
      interests: _stringList(fields, 'interests') ?? current.interests,
      values: _stringList(fields, 'values') ?? current.values,
      dealbreakers: _stringList(fields, 'dealbreakers') ?? current.dealbreakers,
    );
  }

  String? _string(Map<String, dynamic> fields, String key) {
    final value = fields[key];
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  List<String>? _stringList(Map<String, dynamic> fields, String key) {
    final value = fields[key];
    if (value is! List) return null;
    final items = value
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return items.isEmpty ? null : items;
  }

  DateTime? _adultDob(Object? raw) {
    if (raw is! String) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    final today = DateTime.now();
    var age = today.year - parsed.year;
    if (today.month < parsed.month ||
        (today.month == parsed.month && today.day < parsed.day)) {
      age--;
    }
    if (age < 18) return null;
    return parsed;
  }
}
