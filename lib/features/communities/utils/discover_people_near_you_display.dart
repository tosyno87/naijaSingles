import '../../../models/user_model.dart';

/// Max horizontal cards for "People Near You" on Discover.
const int kPeopleNearYouMax = 16;

/// Sort by [UserModel.distanceBW] ascending, then cap for the carousel.
List<UserModel> sortAndCapPeopleNearYou(List<UserModel> incoming) {
  final List<UserModel> sorted = List<UserModel>.from(incoming)
    ..sort((UserModel a, UserModel b) {
      final int? da = a.distanceBW;
      final int? db = b.distanceBW;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
  if (sorted.length <= kPeopleNearYouMax) return sorted;
  return sorted.take(kPeopleNearYouMax).toList();
}
