import 'package:flutter/material.dart';

import 'package:hookup4u2/common/constants/colors.dart';

class Hookup4uBar extends StatelessWidget {
  const Hookup4uBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: primaryColor,
      ),
    );
  }
}
