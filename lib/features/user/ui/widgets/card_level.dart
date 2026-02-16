import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../common/constants/app_colors.dart';

const _labelAngle = math.pi / 2 * 0.2;

class CardLabel extends StatelessWidget {
  const CardLabel._({
    required this.color,
    required this.label,
    required this.angle,
    required this.alignment,
  });

  factory CardLabel.right() => CardLabel._(
        color: AppColors.primaryGreen,
        label: 'LIKE'.tr().toString(),
        angle: -_labelAngle,
        alignment: Alignment.topLeft,
      );

  factory CardLabel.left() => CardLabel._(
        color: Colors.black,
        label: 'NOPE'.tr().toString(),
        angle: _labelAngle,
        alignment: Alignment.topRight,
      );

  factory CardLabel.up() => CardLabel._(
        color: AppColors.primaryGreen,
        label: 'UP'.tr().toString(),
        angle: _labelAngle,
        alignment: const Alignment(0, 0.5),
      );

  factory CardLabel.down() => CardLabel._(
        color: AppColors.primaryGreen,
        label: 'DOWN'.tr().toString(),
        angle: -_labelAngle,
        alignment: const Alignment(0, -0.75),
      );

  final Color color;
  final String label;
  final double angle;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => Container(
        alignment: alignment,
        padding: const EdgeInsets.symmetric(
          vertical: 36,
          horizontal: 36,
        ),
        child: Transform.rotate(
          angle: angle,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: color,
                width: 4,
              ),
              // color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.all(6),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: color,
                height: 1,
              ),
            ),
          ),
        ),
      );
}
