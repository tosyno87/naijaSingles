import 'package:hookup4u2/common/data/repo/user_repo.dart';

class StretViewPreferences {
  final String userId;

  StretViewPreferences(
    this.userId,
  );

  setView(String value, final List<String> userIds) async {
    UserRepo.streetviewfilter(value, userIds);
  }

  getView() async {
    Map<String, dynamic> streetViewData =
        await UserRepo.getStreetViewData(userId);

    final String savedView = streetViewData['option'];

    switch (savedView) {
      case 'None':
        return 'None';
      case 'Everyone':
        return 'Everyone';
      case 'Only':
        return 'Only';
      case 'My Matches':
        return 'My Matches';
      default:
        return 'None';
    }
  }
}
