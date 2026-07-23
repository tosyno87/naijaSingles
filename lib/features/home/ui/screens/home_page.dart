import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:swipable_stack/swipable_stack.dart';

import '../../../../common/bloc/user/user_bloc.dart';
import '../../../../common/constants/constants.dart';
import '../../../../models/user_model.dart';
import '../../bloc/searchuser_bloc.dart';
import '../../controllers/home_controller.dart';
import '../widgets/premium_swipe.dart';
import '../widgets/privacy_migration_prompt.dart';
import '../widgets/swipe_buttons.dart';
import '../widgets/swipe_card_list.dart';

class Homepage extends StatefulWidget {
  const Homepage({required this.items, required this.isPurchased, super.key});
  final Map items;
  final bool isPurchased;

  // NOTE: This is the main discovery interface. Do not add profile counters or
  // pagination indicators as they can create user anxiety

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage>
    with AutomaticKeepAliveClientMixin<Homepage> {
  final HomeController controller = HomeController();
  SwipableStackController? stackController;
  final List<UserModel> removedUsers = [];
  bool _shouldShowMigrationPrompt = false;
  bool _migrationPromptDismissed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    stackController = SwipableStackController();
    unawaited(_initializeController());
  }

  Future<void> _initializeController() async {
    await controller.initialize(context);
    if (!mounted) return;
    setState(() {});
    final String? uid = controller.currentUser.id;
    if (uid != null && uid.isNotEmpty) {
      unawaited(
        firebaseFireStoreInstance.collection('users').doc(uid).update({
          'lastvisited': DateTime.now(),
        }),
      );
    }
    context
        .read<SearchUserBloc>()
        .add(LoadUserEvent(currentUser: controller.currentUser));
    context
        .read<SearchUserBloc>()
        .add(CheckMigrationStatusEvent(userId: controller.currentUser.id!));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final int freeSwipe = widget.items['free_swipes'] != null
        ? int.parse(widget.items['free_swipes'])
        : 10;
    final bool exceedSwipes =
        !widget.isPurchased && controller.swipedCount >= freeSwipe;

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(50),
            topRight: Radius.circular(50),
          ),
          color: Theme.of(context).primaryColor,
        ),
        child: BlocListener<SearchUserBloc, SearchUserState>(
          listener: (context, state) {
            if (state is MigrationStatusState) {
              setState(() {
                _shouldShowMigrationPrompt = state.shouldPromptForMigration &&
                    !_migrationPromptDismissed;
              });
            }
          },
          child: BlocListener<UserBloc, UserState>(
            listenWhen: (UserState previous, UserState current) {
              if (current is! UserLoaded || current.user == null) {
                return false;
              }
              final UserModel next = current.user!;
              final UserModel prev = controller.currentUser;
              return next.latitude != prev.latitude ||
                  next.longitude != prev.longitude ||
                  next.maxDistance != prev.maxDistance ||
                  next.lookingFor != prev.lookingFor ||
                  next.showGender != prev.showGender;
            },
            listener: (BuildContext context, UserState state) {
              if (state is! UserLoaded || state.user == null) return;
              controller.syncFromUserBloc(state.user);
              context.read<SearchUserBloc>().add(
                    LoadUserEvent(currentUser: state.user!),
                  );
            },
            child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(50),
              topRight: Radius.circular(50),
            ),
            child: Stack(
              children: [
                AbsorbPointer(
                  absorbing: exceedSwipes,
                  child: Stack(
                    children: [
                      SwipeCardList(
                        controller: controller,
                        stackController: stackController,
                        onUserRemoved: (user) {
                          setState(() {
                            removedUsers
                              ..clear()
                              ..add(user);
                          });
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: SwipeButtons(
                            stackController: stackController,
                            onRewind: () {
                              setState(removedUsers.clear);
                            },
                            hasRemoved: removedUsers.isNotEmpty,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (exceedSwipes)
                  PremiumSwipePage(currentUser: controller.currentUser)
                else
                  const SizedBox.shrink(),

                // Privacy Migration Prompt
                if (_shouldShowMigrationPrompt)
                  Positioned(
                    top: 50,
                    left: 0,
                    right: 0,
                    child: PrivacyMigrationPrompt(
                      onDismiss: () {
                        setState(() {
                          _migrationPromptDismissed = true;
                          _shouldShowMigrationPrompt = false;
                        });
                      },
                      onMigrate: () {
                        // Refresh user list after migration
                        context.read<SearchUserBloc>().add(
                              LoadUserEvent(
                                currentUser: controller.currentUser,
                              ),
                            );
                        setState(() {
                          _shouldShowMigrationPrompt = false;
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}
