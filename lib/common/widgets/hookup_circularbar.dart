import 'package:flutter/material.dart';

import 'package:naijasingles/common/constants/colors.dart';

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
