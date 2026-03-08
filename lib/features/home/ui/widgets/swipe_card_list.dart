import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:swipable_stack/swipable_stack.dart';

import '../../../../common/bloc/theme/theme_bloc.dart';
import '../../../../common/widgets/state_views/state_views.dart';
import '../../../../models/user_model.dart';
import '../../../home/controllers/home_controller.dart';
import '../../../match/ui/widget/match_dialog_new.dart';
import '../../bloc/searchuser_bloc.dart';
import '../../bloc/swipebloc_bloc.dart';
import '../screens/swipe_card.dart';

class SwipeCardList extends StatefulWidget {
  const SwipeCardList({
    required this.controller,
    required this.stackController,
    required this.onUserRemoved,
    super.key,
  });
  final HomeController controller;
  final SwipableStackController? stackController;
  final Function(UserModel) onUserRemoved;

  @override
  State<SwipeCardList> createState() => _SwipeCardListState();
}

class _SwipeCardListState extends State<SwipeCardList> {
  @override
  Widget build(BuildContext context) {
    context.watch<ThemeBloc>();
    return BlocListener<SwipeBloc, SwipeblocState>(
      listener: (context, swipeState) {
        if (swipeState is SwipeMatchCreatedState) {
          unawaited(
            showDialog(
              context: context,
              builder: (ctx) => MatchDialogPage(
                matchedUser: swipeState.matchedUser,
                currentUser: widget.controller.currentUser,
              ),
            ),
          );
        }
      },
      child: BlocBuilder<SearchUserBloc, SearchUserState>(
        builder: (context, state) {
          if (state is SearchUserLoadingState) {
            widget.stackController?.dispose();
            return const AppLoadingView(message: 'Loading profiles...');
          }

          if (state is SearchUserFailedState) {
            return AppErrorView(
              title: 'Unable to load profiles',
              message: 'Error to load data.'.tr().toString(),
              onRetry: () {
                context.read<SearchUserBloc>().add(
                      LoadUserEvent(
                        currentUser: widget.controller.currentUser,
                      ),
                    );
              },
            );
          }

          if (state is SearchUserLoadUserState) {
            return Container(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              height: MediaQuery.of(context).size.height * .78,
              width: MediaQuery.of(context).size.width,
              child: state.users.isEmpty
                  ? AppEmptyView(
                      title: "There's no one new around you.".tr().toString(),
                      subtitle:
                          'Try expanding your distance or refreshing discovery.',
                      icon: Icons.explore_off,
                      actionLabel: 'Refresh',
                      onAction: () {
                        context.read<SearchUserBloc>().add(
                              LoadUserEvent(
                                currentUser: widget.controller.currentUser,
                              ),
                            );
                      },
                    )
                  : UsersList(
                      onswiped: (int index, SwipeDirection dir) {
                        final user = state.users[index];
                        if (dir == SwipeDirection.right) {
                          context.read<SwipeBloc>().add(
                                RightSwipeEvent(
                                  currentUser: widget.controller.currentUser,
                                  selectedUser: user,
                                ),
                              );
                          if (index < state.users.length) {
                            widget.onUserRemoved(user);
                          }
                        }
                        if (dir == SwipeDirection.left) {
                          context.read<SwipeBloc>().add(
                                LeftSwipeEvent(
                                  currentUser: widget.controller.currentUser,
                                  selectedUser: user,
                                ),
                              );
                          if (index < state.users.length) {
                            widget.onUserRemoved(user);
                          }
                        }
                        widget.controller.incrementSwipe();
                      },
                      stackController: widget.stackController,
                      users: state.users,
                      currentUser: widget.controller.currentUser,
                      usersList: state.users,
                    ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
