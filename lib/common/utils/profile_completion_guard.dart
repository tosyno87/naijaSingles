import '../../models/user_model.dart';

class ProfileCompletionGuard {
  static bool _isNonEmptyString(Object? value) =>
      value is String && value.trim().isNotEmpty;

  static bool _isTrueFlag(Object? value) => value == true;

  static bool _isFalseFlag(Object? value) => value == false;

  static bool _hasNonEmptyList(Map<String, dynamic> data, String key) =>
      data[key] is List && (data[key] as List).isNotEmpty;

  /// Determine profile completeness from raw Firestore document data.
  /// Honors explicit completion flags first, then falls back to basic
  /// required fields for backward compatibility.
  static bool isDocumentComplete(Map<String, dynamic> data) {
    final onboardingCompleted = data['onboardingCompleted'];
    final isProfileComplete = data['isProfileComplete'];
    final profileSetupComplete = data['profileSetupComplete'];

    if (_isTrueFlag(onboardingCompleted) ||
        _isTrueFlag(isProfileComplete) ||
        _isTrueFlag(profileSetupComplete)) {
      return true;
    }

    final hasName =
        _isNonEmptyString(data['name']) || _isNonEmptyString(data['userName']);
    final hasGender = _isNonEmptyString(data['gender']) ||
        _isNonEmptyString(data['userGender']);
    final hasPhoto = _hasNonEmptyList(data, 'photos') ||
        _hasNonEmptyList(data, 'Pictures') ||
        _hasNonEmptyList(data, 'imageUrl') ||
        _isNonEmptyString(data['profilePicture']);

    final hasLegacyCompleteSignals = hasName && (hasGender || hasPhoto);
    final hasStrongCompleteSignals = hasName && hasGender && hasPhoto;

    // Some legacy records have stale `...Completed: false` flags despite
    // populated profile data. Prefer real profile signals in that case so
    // returning users are not trapped in onboarding.
    if (_isFalseFlag(onboardingCompleted) ||
        _isFalseFlag(isProfileComplete) ||
        _isFalseFlag(profileSetupComplete)) {
      return hasStrongCompleteSignals;
    }

    return hasLegacyCompleteSignals;
  }

  /// Determine profile completeness from parsed user model.
  static bool isUserComplete(UserModel user) {
    final hasName = _isNonEmptyString(user.name);
    final hasGender = _isNonEmptyString(user.userGender);
    final hasPhoto = (user.imageUrl ?? const []).isNotEmpty;

    return hasName && (hasGender || hasPhoto);
  }
}
