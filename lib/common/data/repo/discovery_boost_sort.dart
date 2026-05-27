import '../../../models/user_model.dart';

/// Sorts discovery candidates so boosted user ids appear first.
List<UserModel> sortUsersWithBoostPriority({
  required List<UserModel> users,
  required Set<String> boostedUserIds,
}) {
  if (boostedUserIds.isEmpty) return users;

  final boosted = <UserModel>[];
  final normal = <UserModel>[];
  for (final user in users) {
    final id = user.id;
    if (id != null && boostedUserIds.contains(id)) {
      boosted.add(user);
    } else {
      normal.add(user);
    }
  }
  return [...boosted, ...normal];
}
