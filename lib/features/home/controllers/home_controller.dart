import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/bloc/user/user_bloc.dart';
import '../../../common/data/repo/user_search_repo.dart';
import '../../../models/user_model.dart';

class HomeController {
  late UserModel currentUser;
  int swipedCount = 0;
  List<String> likedByList = [];

  Future<void> initialize(BuildContext context) async {
    currentUser = context.read<UserBloc>().currentUser!;
    likedByList = await UserSearchRepo.getLikedByList(currentUser);
    swipedCount = await UserSearchRepo.getSwipedCount(currentUser);
  }

  /// Keep Connect's seeker in sync when UserBloc reloads (e.g. location save).
  void syncFromUserBloc(UserModel? user) {
    if (user != null) {
      currentUser = user;
    }
  }

  void incrementSwipe() {
    swipedCount++;
  }

  void dispose() {
    // nothing to dispose for now
  }
}
