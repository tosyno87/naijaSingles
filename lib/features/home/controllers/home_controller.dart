import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/bloc/user/user_bloc.dart';
import '../../../common/data/repo/user_search_repo.dart';
import '../../../models/user_model.dart';

class HomeController {
  late final UserModel currentUser;
  int swipedCount = 0;
  List<String> likedByList = [];

  Future<void> initialize(BuildContext context) async {
    currentUser = context.read<UserBloc>().currentUser!;
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
