import 'package:flutter/material.dart';

import '../../../../common/constants/colors.dart';

class FirebasesexualDataWidget extends StatelessWidget {
  final List<dynamic> data;

  const FirebasesexualDataWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    String commaSeparatedString = data.map((dynamic item) {
      return item.toString();
    }).join(', ');
    return Row(children: [
      Text(
        commaSeparatedString,
        style: TextStyle(
            color: secondryColor, fontSize: 16, fontWeight: FontWeight.w500),
      )
    ]);
  }
}
