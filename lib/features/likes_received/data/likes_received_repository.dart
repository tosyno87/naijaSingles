import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/user_model.dart';
import '../../match/data/services/match_service.dart';

/// Loads profiles for users who liked the current user.
class LikesReceivedRepository {
  LikesReceivedRepository({
    MatchService? matchService,
    FirebaseFirestore? firestore,
  })  : _matchService = matchService ?? MatchService(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  final MatchService _matchService;
  final FirebaseFirestore _firestore;

  Future<List<UserModel>> fetchUsersWhoLikedMe() async {
    final ids = await _matchService.getUsersWhoLikedMe();
    if (ids.isEmpty) return [];

    final users = <UserModel>[];
    for (final id in ids) {
      try {
        final doc = await _firestore.collection('users').doc(id).get();
        if (doc.exists) {
          users.add(UserModel.fromDocument(doc));
        }
      } on Object {
        // Skip profiles that cannot be loaded.
      }
    }
    return users;
  }
}
