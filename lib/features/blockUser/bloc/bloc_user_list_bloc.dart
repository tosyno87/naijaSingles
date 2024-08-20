import '../../../config/app_config.dart';
import '../../../models/block_user_model.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/data/repo/user_messaging_repo.dart';
import '../../../models/user_model.dart';

part 'bloc_user_list_event.dart';
part 'bloc_user_list_state.dart';

class BlocUserListBloc extends Bloc<BlocUserListEvent, BlocUserListState> {
  BlockUserModel? lastDocument;

  BlocUserListBloc() : super(BlocUserListInitial()) {
    on<LoadBlockUserEvent>((event, emit) async {
      emit(BlockUserLoadingState());
      try {
        List<BlockUserModel> blockList =
            await UserMessagingRepo.getBlockUserList(
                event.currentUser, perPageData);
        lastDocument = blockList.isNotEmpty ? blockList.last : null;
        emit(BlockUserLoadedState(blockList));
      } catch (e) {
        emit(BlockUserFailedState());
        rethrow;
      }
    });

    on<LoadMoreBlockUserEvent>((event, emit) async {
      try {
        if (state is BlockUserLoadedState) {
          BlockUserLoadedState currentState = state as BlockUserLoadedState;
          List<BlockUserModel> currentList = currentState.users;
          List<BlockUserModel> moreBlockList =
              await UserMessagingRepo.loadMoreBlockUsers(
            event.currentUser,
            perPageData,
            lastDocumentData: lastDocument,
          );

          if (moreBlockList.isNotEmpty) {
            lastDocument = moreBlockList.last;
          }

          List<BlockUserModel> updatedList = [...currentList, ...moreBlockList];

          emit(BlockUserLoadedState(updatedList));
        }
      } catch (e) {
        emit(BlockUserFailedState());
        rethrow;
      }
    });
  }
}
