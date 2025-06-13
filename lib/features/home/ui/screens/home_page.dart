import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:swipable_stack/swipable_stack.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/premium_swipe.dart';
import '../widgets/swipe_card_list.dart';
import '../widgets/swipe_buttons.dart';
import '../../../../models/user_model.dart';
import '../../controllers/home_controller.dart';
import '../../bloc/searchuser_bloc.dart';
import '../../../../common/constants/constants.dart';

class Homepage extends StatefulWidget {
  final Map items;
  final bool isPurchased;
  const Homepage({super.key, required this.items, required this.isPurchased});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage>
    with AutomaticKeepAliveClientMixin<Homepage> {
  final HomeController controller = HomeController();
  SwipableStackController? stackController;
  final List<UserModel> removedUsers = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    stackController = SwipableStackController();
    controller.initialize(context).then((_) {
      setState(() {});
      context
          .read<SearchUserBloc>()
          .add(LoadUserEvent(currentUser: controller.currentUser));
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Future<void> didChangeDependencies() async {
    await firebaseFireStoreInstance
        .collection('Users')
        .doc(controller.currentUser.id)
        .update({'lastvisited': DateTime.now()});
    super.didChangeDependencies();
  }
  @override
  Widget build(BuildContext context) {
    super.build(context);
    int freeSwipe = widget.items['free_swipes'] != null
        ? int.parse(widget.items['free_swipes'])
        : 10;
    bool exceedSwipes =
        !widget.isPurchased ? controller.swipedCount >= freeSwipe : false;

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Container(
        decoration: BoxDecoration(
          borderRadius:
              const BorderRadius.only(topLeft: Radius.circular(50), topRight: Radius.circular(50)),
          color: Theme.of(context).primaryColor,
        ),
        child: ClipRRect(
          borderRadius:
              const BorderRadius.only(topLeft: Radius.circular(50), topRight: Radius.circular(50)),
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
                            setState(() {
                              removedUsers.clear();
                            });
                          },
                          hasRemoved: removedUsers.isNotEmpty,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              exceedSwipes
                  ? PremiumSwipePage(currentUser: controller.currentUser)
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
