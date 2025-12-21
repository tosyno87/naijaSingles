import 'package:flutter/material.dart';

/// Shimmer loading widget for message bubbles
class MessageShimmer extends StatelessWidget {
  const MessageShimmer({
    required this.isCurrentUser,
    super.key,
  });
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Row(
          mainAxisAlignment:
              isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isCurrentUser) ...[
              _buildShimmerCircle(32),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isCurrentUser ? 20 : 4),
                    bottomRight: Radius.circular(isCurrentUser ? 4 : 20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isCurrentUser) ...[
                      _buildShimmerBox(60, 12),
                      const SizedBox(height: 4),
                    ],
                    _buildShimmerBox(120, 14),
                    const SizedBox(height: 4),
                    _buildShimmerBox(40, 10),
                  ],
                ),
              ),
            ),
            if (isCurrentUser) ...[
              const SizedBox(width: 8),
              _buildShimmerCircle(32),
            ],
          ],
        ),
      );

  Widget _buildShimmerBox(double width, double height) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
      );

  Widget _buildShimmerCircle(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          shape: BoxShape.circle,
        ),
      );
}
