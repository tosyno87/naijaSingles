import 'repo/user_repo.dart';

class StretViewPreferences {

  StretViewPreferences(
    this.userId,
  );
  final String userId;

  Future<void> setView(String value, final List<String> userIds) async {
    UserRepo.streetviewfilter(value, userIds);
  }

  Future<String> getView() async {
    final Map<String, dynamic> streetViewData =
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
