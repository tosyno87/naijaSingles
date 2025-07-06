import 'package:flutter/material.dart';

class AfropeepLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const AfropeepLogo({
    super.key,
    this.size = 60,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final logoColor = color ?? Colors.green[700];

    return Stack(
      alignment: Alignment.center,
      children: [
        // Heart shape
        Icon(
          Icons.favorite,
          size: size,
          color: logoColor,
        ),

        // A overlay to create a more unique logo
        Positioned(
          child: Container(
            width: size * 0.5,
            height: size * 0.5,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),

        // African continent silhouette representation
        Positioned(
          top: size * 0.33,
          child: Icon(
            Icons.person,
            size: size * 0.4,
            color: logoColor,
          ),
        ),
      ],
    );
  }
}
