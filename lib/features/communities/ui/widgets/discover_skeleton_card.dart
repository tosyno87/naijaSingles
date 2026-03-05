import 'dart:async';

import 'package:flutter/material.dart';

class DiscoverSkeletonCard extends StatefulWidget {
  const DiscoverSkeletonCard({
    this.width,
    this.height,
    this.radius = 24,
    super.key,
  });

  final double? width;
  final double? height;
  final double radius;

  @override
  State<DiscoverSkeletonCard> createState() => _DiscoverSkeletonCardState();
}

class _DiscoverSkeletonCardState extends State<DiscoverSkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    unawaited(_controller.repeat());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final shimmerValue = _controller.value;
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              gradient: LinearGradient(
                begin: Alignment(-1.0 + 2.0 * shimmerValue, 0),
                end: Alignment(-1.0 + 2.0 * shimmerValue + 1.0, 0),
                colors: const [
                  Color(0xFFEEECE8),
                  Color(0xFFF5F3EF),
                  Color(0xFFEEECE8),
                ],
              ),
            ),
          );
        },
      );
}
