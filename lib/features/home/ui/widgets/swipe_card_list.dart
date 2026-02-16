import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:swipable_stack/swipable_stack.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../../common/bloc/theme/theme_bloc.dart';
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
    final themeBloc = context.watch<ThemeBloc>();
    final isDarkMode = themeBloc.isDarkMode;
    return BlocBuilder<SearchUserBloc, SearchUserState>(
      builder: (context, state) {
        if (state is SearchUserLoadingState) {
          widget.stackController?.dispose();
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.primaryGreen),
            ),
          );
        }

        if (state is SearchUserFailedState) {
          return Center(
            child: Text(
              'Error to load data.'.tr().toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black54,
                fontStyle: FontStyle.normal,
                letterSpacing: 1,
                decoration: TextDecoration.none,
                fontSize: 18,
              ),
            ),
          );
        }

        if (state is SearchUserLoadUserState) {
          return Container(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            height: MediaQuery.of(context).size.height * .78,
            width: MediaQuery.of(context).size.width,
            child: state.users.isEmpty
                ? Align(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            radius: 50,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Image.asset(
                                'asset/hookup4u-Logo-BP.png',
                                fit: BoxFit.contain,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          "There's no one new around you.".tr().toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black54,
                            fontStyle: FontStyle.normal,
                            letterSpacing: 1,
                            decoration: TextDecoration.none,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try expanding your distance or refreshing discovery.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black45,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton(
                          onPressed: () {
                            context.read<SearchUserBloc>().add(
                                  LoadUserEvent(
                                    currentUser: widget.controller.currentUser,
                                  ),
                                );
                          },
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
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
                        if (widget.controller.likedByList.contains(user.id) ||
                            (user.isBot ?? false)) {
                          showDialog(
                            context: context,
                            builder: (ctx) => MatchDialogPage(
                              matchedUser: user,
                              currentUser: widget.controller.currentUser,
                            ),
                          );
                        }
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
    );
  }
}
