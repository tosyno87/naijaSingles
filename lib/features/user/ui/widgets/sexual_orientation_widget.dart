import 'package:flutter/material.dart';

import '../../../../common/constants/app_colors.dart';

class FirebasesexualDataWidget extends StatelessWidget {
  const FirebasesexualDataWidget({required this.data, super.key});
  final List<dynamic> data;

  @override
  Widget build(BuildContext context) {
    final String commaSeparatedString =
        data.map((item) => item.toString()).join(', ');
    return Row(
      children: [
        Text(
          commaSeparatedString,
          style: const TextStyle(
            color: AppColors.secondaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
