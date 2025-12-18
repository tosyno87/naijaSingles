import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:swipable_stack/swipable_stack.dart';

import '../../../../common/widgets/custom_snackbar.dart';
import '../../../../models/user_model.dart';
import '../../../home/bloc/swipebloc_bloc.dart';

class ActionWidget extends StatelessWidget {
  const ActionWidget(
      {required this.currentUser, required this.user, required this.fromStreetview, required this.stackController, super.key,});
  final UserModel currentUser;
  final SwipableStackController stackController;
  final UserModel user;
  final bool fromStreetview;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(25),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            FloatingActionButton(
                heroTag: UniqueKey(),
                backgroundColor: Colors.white,
                child: const Icon(
                  Icons.clear,
                  color: Colors.red,
                  size: 30,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  context.read<SwipeBloc>().add(LeftSwipeEvent(
                      currentUser: currentUser, selectedUser: user,),);
                  if (fromStreetview) {
                    CustomSnackbar.showSnackBarSimple(
                        'you rejects the profile'
                            .tr(args: ["${user.name}'s".toString()]).toString(),
                        context,);
                  }
                  stackController.next(swipeDirection: SwipeDirection.left);
                },),
            FloatingActionButton(
                heroTag: UniqueKey(),
                backgroundColor: Colors.white,
                child: const Icon(
                  Icons.favorite,
                  color: Colors.lightBlueAccent,
                  size: 30,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  context.read<SwipeBloc>().add(RightSwipeEvent(
                      currentUser: currentUser, selectedUser: user,),);
                  if (fromStreetview) {
                    CustomSnackbar.showSnackBarSimple(
                        'you likes the profile'
                            .tr(args: ["${user.name}'s".toString()]).toString(),
                        context,);
                  }
                  stackController.next(swipeDirection: SwipeDirection.right);
                },),
          ],
        ),
      ),
    );
}

class FloatingButton extends StatelessWidget {
  const FloatingButton({required this.onTap, required this.icon, super.key});
  final VoidCallback onTap;

  final Icon icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(18),
        child: Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
                heroTag: UniqueKey(),
                backgroundColor: Colors.white,
                onPressed: onTap,
                child: icon,),),);
}
