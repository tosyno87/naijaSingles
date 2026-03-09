import '../../models/user_model.dart';

class ProfileCompletionGuard {
  static bool _isNonEmptyString(Object? value) =>
      value is String && value.trim().isNotEmpty;

  static bool _isTrueFlag(Object? value) => value == true;

  static bool _isFalseFlag(Object? value) => value == false;

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

    if (_isFalseFlag(onboardingCompleted) ||
        _isFalseFlag(isProfileComplete) ||
        _isFalseFlag(profileSetupComplete)) {
      return false;
    }

    final hasName = _isNonEmptyString(data['name']);
    final hasGender = _isNonEmptyString(data['gender']) ||
        _isNonEmptyString(data['userGender']);
    final photos = data['photos'] is List ? data['photos'] as List : const [];
    final pictures =
        data['Pictures'] is List ? data['Pictures'] as List : const [];
    final hasPhoto = photos.isNotEmpty || pictures.isNotEmpty;

    return hasName && (hasGender || hasPhoto);
  }

  /// Determine profile completeness from parsed user model.
  static bool isUserComplete(UserModel user) {
    final hasName = _isNonEmptyString(user.name);
    final hasGender = _isNonEmptyString(user.userGender);
    final hasPhoto = (user.imageUrl ?? const []).isNotEmpty;

    return hasName && (hasGender || hasPhoto);
  }
}
