/// Pure helpers for Likes You premium gating (testable without UI).
class LikesReceivedGating {
  LikesReceivedGating._();

  /// Free users see only the first liker; premium sees all.
  static bool isCardLocked({
    required bool hasPremiumAccess,
    required int index,
  }) =>
      !hasPremiumAccess && index > 0;

  static int visibleCount({
    required bool hasPremiumAccess,
    required int totalLikers,
  }) {
    if (totalLikers == 0) return 0;
    return hasPremiumAccess ? totalLikers : 1;
  }
}
