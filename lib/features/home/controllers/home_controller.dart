import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/data/repo/user_search_repo.dart';
import '../../../common/providers/user_provider.dart';
import '../../../models/user_model.dart';

class HomeController {
  late final UserModel currentUser;
  int swipedCount = 0;
  List<String> likedByList = [];

  Future<void> initialize(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    currentUser = userProvider.currentUser!;
    likedByList = await UserSearchRepo.getLikedByList(currentUser);
    swipedCount = await UserSearchRepo.getSwipedCount(currentUser);
  }

  void incrementSwipe() {
    swipedCount++;
  }

  void dispose() {
    // nothing to dispose for now
  }
}
