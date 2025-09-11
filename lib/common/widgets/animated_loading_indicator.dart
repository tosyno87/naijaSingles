import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedLoadingIndicator extends StatefulWidget {
  final Color color;
  final double size;

  const AnimatedLoadingIndicator({
    Key? key,
    this.color = const Color(0xFF008037),
    this.size = 100,
  }) : super(key: key);

  @override
  State<AnimatedLoadingIndicator> createState() =>
      _AnimatedLoadingIndicatorState();
}

class _AnimatedLoadingIndicatorState extends State<AnimatedLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: const Color(0xFFDFF5E2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.rotate(
              angle: _controller.value * 2 * math.pi,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer circle
                  Container(
                    width: widget.size * 0.6,
                    height: widget.size * 0.6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.color.withValues(alpha: 0.3),
                        width: 3,
                      ),
                    ),
                  ),
                  // Inner circle with dot
                  SizedBox(
                    width: widget.size * 0.6,
                    height: widget.size * 0.6,
                    child: CustomPaint(
                      painter: _LoadingDotPainter(
                        color: widget.color,
                        progress: _controller.value,
                      ),
                    ),
                  ),
                  // Center icon
                  Icon(
                    Icons.favorite,
                    color: widget.color,
                    size: widget.size * 0.25,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoadingDotPainter extends CustomPainter {
  final Color color;
  final double progress;

  _LoadingDotPainter({
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Calculate dot position
    final angle = 2 * math.pi * progress;
    final dotX = center.dx + radius * math.cos(angle);
    final dotY = center.dy + radius * math.sin(angle);

    // Draw dot
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(dotX, dotY), 6, dotPaint);
  }

  @override
  bool shouldRepaint(_LoadingDotPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
