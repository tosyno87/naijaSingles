import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:swipable_stack/swipable_stack.dart';

import '../../../../common/constants/colors.dart';

class SwipeButtons extends StatelessWidget {
  final SwipableStackController? stackController;
  final VoidCallback onRewind;
  final bool hasRemoved;

  const SwipeButtons({
    super.key,
    required this.stackController,
    required this.onRewind,
    required this.hasRemoved,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        hasRemoved
            ? FloatingActionButton(
                heroTag: UniqueKey(),
                backgroundColor: Colors.white,
                onPressed: () {
                  log('rewind pressed');
                  stackController?.rewind(duration: const Duration(milliseconds: 500));
                  onRewind();
                },
                child: Icon(
                  hasRemoved ? Icons.replay : Icons.not_interested,
                  color: hasRemoved ? Colors.amber : secondryColor,
                  size: 20,
                ),
              )
            : FloatingActionButton(
                heroTag: UniqueKey(),
                backgroundColor: Colors.white,
                child: const Icon(
                  Icons.refresh,
                  color: Colors.green,
                  size: 20,
                ),
                onPressed: () {},
              ),
        FloatingActionButton(
          heroTag: UniqueKey(),
          backgroundColor: Colors.white,
          child: const Icon(
            Icons.clear,
            color: Colors.red,
            size: 30,
          ),
          onPressed: () {
            stackController?.next(swipeDirection: SwipeDirection.left);
          },
        ),
        FloatingActionButton(
          heroTag: UniqueKey(),
          backgroundColor: Colors.white,
          child: const Icon(
            Icons.favorite,
            color: Colors.lightBlueAccent,
            size: 30,
          ),
          onPressed: () {
            stackController?.next(swipeDirection: SwipeDirection.right);
          },
        ),
      ],
    );
  }
}
