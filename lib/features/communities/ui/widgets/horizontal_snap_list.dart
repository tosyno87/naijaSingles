import 'package:flutter/material.dart';

class HorizontalSnapList extends StatelessWidget {
  const HorizontalSnapList({
    required this.itemWidth,
    required this.itemCount,
    required this.itemBuilder,
    this.itemHeight,
    this.gap = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    super.key,
  });

  final double itemWidth;
  final double? itemHeight;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double gap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: itemHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: padding,
          itemCount: itemCount,
          separatorBuilder: (_, __) => SizedBox(width: gap),
          itemBuilder: (context, index) => SizedBox(
            width: itemWidth,
            child: itemBuilder(context, index),
          ),
        ),
      );
}
