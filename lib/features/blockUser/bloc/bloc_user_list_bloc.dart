import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/data/repo/user_messaging_repo.dart';
import '../../../config/app_config.dart';
import '../../../models/block_user_model.dart';
import '../../../models/user_model.dart';

part 'bloc_user_list_event.dart';
part 'bloc_user_list_state.dart';

class BlocUserListBloc extends Bloc<BlocUserListEvent, BlocUserListState> {

  BlocUserListBloc() : super(BlocUserListInitial()) {
    on<LoadBlockUserEvent>((event, emit) async {
      emit(BlockUserLoadingState());
      try {
        final List<BlockUserModel> blockList =
            await UserMessagingRepo.getBlockUserList(
                event.currentUser, perPageData,);
        lastDocument = blockList.isNotEmpty ? blockList.last : null;
        emit(BlockUserLoadedState(blockList));
      } catch (e) {
        emit(BlockUserFailedState());
        log('Error loading block users: $e');
      }
    });

    on<LoadMoreBlockUserEvent>((event, emit) async {
      try {
        if (state is BlockUserLoadedState) {
          final BlockUserLoadedState currentState = state as BlockUserLoadedState;
          final List<BlockUserModel> currentList = currentState.users;
          final List<BlockUserModel> moreBlockList =
              await UserMessagingRepo.loadMoreBlockUsers(
            event.currentUser,
            perPageData,
            lastDocumentData: lastDocument,
          );

          if (moreBlockList.isNotEmpty) {
            lastDocument = moreBlockList.last;
          }

          final List<BlockUserModel> updatedList = [...currentList, ...moreBlockList];

          emit(BlockUserLoadedState(updatedList));
        }
      } catch (e) {
        emit(BlockUserFailedState());
        log('Error loading more block users: $e');
      }
    });
  }
  BlockUserModel? lastDocument;
}
