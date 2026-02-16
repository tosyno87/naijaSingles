import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class Hookup4uBar extends StatelessWidget {
  const Hookup4uBar({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryGreen,
        ),
      );
}
