import '../../../../models/user_model.dart';

/// Shared filtering helpers for discovery queries and stream pipelines.
class DiscoveryFiltering {
  /// Normalize gender values from profile/query fields to a common form.
  static String normalizeGender(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';
    if (normalized.isEmpty) return '';

    switch (normalized) {
      case 'man':
      case 'male':
      case 'm':
        return 'male';
      case 'woman':
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
      user.userGender?.toString().isNotEmpty == true
          ? user.userGender
          : user.editInfo?['userGender']?.toString(),
    );

    // Missing candidate gender should not fully block discovery.
    if (candidateGender.isEmpty) {
      return true;
    }

    return candidateGender == preference;
  }
}
